<!-- AR Video page — CF Stream videos as VideoTexture in WebXR -->
<script>
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';

  const { params } = $props();

  let status = $state('loading');
  let errorMsg = $state('');
  let THREE = null;
  let videoInfo = null;
  let posterUrl = '';

  onMount(async () => {
    if (!browser || !navigator.xr) { status = 'unsupported'; return; }
    try {
      const res = await fetch(`/api/stream-video/${params.videoId}`);
      if (!res.ok) throw new Error('Video not found');
      videoInfo = await res.json();
      posterUrl = videoInfo.thumbnail || '';
    } catch (e) {
      errorMsg = 'Failed to load video info: ' + e.message;
      status = 'error';
      return;
    }
    try {
      THREE = await import('three');
    } catch {
      errorMsg = 'Failed to load 3D engine';
      status = 'error';
      return;
    }
    try {
      const supported = await navigator.xr.isSessionSupported('immersive-ar');
      if (!supported) { status = 'unsupported'; return; }
    } catch {
      status = 'unsupported';
      return;
    }
    status = 'ready';
  });

  async function launchAR() {
    if (!THREE || !videoInfo) return;
    status = 'loading';
    try {
      await startAR(THREE);
      status = 'ar-active';
    } catch (e) {
      console.error('[AR Video] Error:', e);
      errorMsg = e.message || 'AR failed to start';
      status = 'error';
    }
  }

  async function startAR(THREE) {
    const session = await navigator.xr.requestSession('immersive-ar', {
      optionalFeatures: ['hit-test', 'dom-overlay', 'local-floor', 'plane-detection', 'mesh-detection', 'anchors'],
      domOverlay: { root: document.body }
    });

    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.xr.enabled = true;
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    document.body.appendChild(renderer.domElement);
    renderer.domElement.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;z-index:9999;';

    const handleResize = () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    };
    window.addEventListener('resize', handleResize);

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
    scene.add(new THREE.AmbientLight(0xffffff, 1.5));
    scene.add(new THREE.DirectionalLight(0xffffff, 0.8));

    // --- Video element — hidden in DOM, required for WebXR ---
    const video = document.createElement('video');
    video.crossOrigin = 'anonymous';
    video.loop = true;
    video.muted = true;
    video.playsInline = true;
    video.preload = 'auto';
    video.style.cssText = 'position:fixed;top:-9999px;left:-9999px;width:1px;height:1px;opacity:0;pointer-events:none;';
    document.body.appendChild(video);

    const streamUrl = videoInfo.streamUrl;

    if (video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = streamUrl;
    } else {
      try {
        const { default: Hls } = await import('https://cdn.jsdelivr.net/npm/hls.js@1.5.13/+esm');
        if (Hls.isSupported()) {
          const hls = new Hls();
          hls.attachMedia(video);
          hls.on(Hls.Events.MEDIA_ATTACHED, () => hls.loadSource(streamUrl));
        }
      } catch {
        console.warn('[AR] hls.js failed to load');
      }
    }

    video.load();

    // Wait for video ready
    await Promise.race([
      new Promise((res) => {
        if (video.readyState >= 3) { res(); return; }
        video.addEventListener('canplay', res, { once: true });
      }),
      new Promise((res) => setTimeout(res, 8000))
    ]);

    // Start playback
    try { await video.play(); } catch (e) { console.warn('[AR] Initial play failed:', e); }

    // Wait for actual frame data
    await Promise.race([
      new Promise((res) => {
        if (video.currentTime > 0) { res(); return; }
        video.addEventListener('timeupdate', function handler() {
          if (video.currentTime > 0) {
            video.removeEventListener('timeupdate', handler);
            res();
          }
        });
      }),
      new Promise((res) => setTimeout(res, 3000))
    ]);

    // Wait for video dimensions to be available
    await new Promise((res) => {
      if (video.videoWidth > 0 && video.videoHeight > 0) {
        res();
      } else {
        video.addEventListener('loadedmetadata', res, { once: true });
      }
    });

    // Reticle
    const reticleGeo = new THREE.RingGeometry(0.03, 0.05, 32);
    reticleGeo.rotateX(-Math.PI / 2);
    const reticleMat = new THREE.MeshBasicMaterial({ color: 0x333333 });
    const reticle = new THREE.Mesh(reticleGeo, reticleMat);
    reticle.matrixAutoUpdate = false;
    reticle.visible = false;
    scene.add(reticle);

    const viewerSpace = await session.requestReferenceSpace('viewer');

    let placed = false;
    let lastHitPose = null;
    let currentMode = null;
    let hideTimer = null;
    let placedAnchorUID = null;
    let pinMesh = null;

    let hitTestSource = null;
    try {
      hitTestSource = await session.requestHitTestSource({ space: viewerSpace });
    } catch (e) {
      console.warn('[AR] Hit test not available');
    }

    let localSpace;
    for (const type of ['local-floor', 'local', 'viewer']) {
      try { localSpace = await session.requestReferenceSpace(type); break; }
      catch (e) { console.warn('[AR] Reference space', type, 'not supported'); }
    }
    if (!localSpace) {
      await session.end();
      throw new Error('No supported reference space');
    }

    // FIX: setSession FIRST — changes the GL context
    await renderer.xr.setSession(session);

    // --- Anchor re-localization ---
    session.addEventListener('anchorsupdated', (event) => {
      for (const anchor of event.data) {
        if (anchor.anchorUID === placedAnchorUID) {
          const pose = localSpace.getPose(anchor.anchorSpace);
          if (pose) {
            const m = new THREE.Matrix4().fromArray(pose.transform.matrix);
            mesh.position.setFromMatrixPosition(m);
            mesh.quaternion.setFromRotationMatrix(m);
          }
        }
      }
    });

    // --- Plane detection ---
    let planeMonitor = null;
    let detectedPlanes = [];
    try {
      planeMonitor = await session.requestPlaneDetection();
    } catch (e) {
      console.warn('[AR] Plane detection not available');
    }
    session.addEventListener('planesdetected', (event) => {
      detectedPlanes = event.data || [];
    });

    const planeGroup = new THREE.Group();
    planeGroup.visible = false;
    scene.add(planeGroup);
    const planeMeshMap = new Map();
    const planeMat = new THREE.MeshBasicMaterial({ color: 0x2c5e3d, transparent: true, opacity: 0.3, side: THREE.DoubleSide });

    function updatePlaneVisuals() {
      const activeIds = new Set();
      for (const plane of detectedPlanes) {
        activeIds.add(plane.id);
        const polygon = plane.polygon;
        if (!polygon || polygon.length < 3) continue;
        const positions = new Float32Array((polygon.length) * 3);
        for (let i = 0; i < polygon.length; i++) {
          positions[i * 3] = polygon[i].x;
          positions[i * 3 + 1] = polygon[i].y;
          positions[i * 3 + 2] = polygon[i].z;
        }
        let triIndices = [];
        for (let i = 1; i < polygon.length - 1; i++) {
          triIndices.push(0, i, i + 1);
        }
        const geo = new THREE.BufferGeometry();
        geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        geo.setIndex(triIndices);
        geo.computeVertexNormals();
        const m = new THREE.Mesh(geo, planeMat);
        const old = planeMeshMap.get(plane.id);
        if (old) { old.geometry.dispose(); planeGroup.remove(old); }
        planeGroup.add(m);
        planeMeshMap.set(plane.id, m);
      }
      for (const [id, mesh2] of planeMeshMap) {
        if (!activeIds.has(id)) {
          mesh2.geometry.dispose();
          planeGroup.remove(mesh2);
          planeMeshMap.delete(id);
        }
      }
    }

    // --- Mesh detection ---
    let meshMonitor = null;
    try {
      meshMonitor = await session.requestMeshDetection();
    } catch (e) {
      console.warn('[AR] Mesh detection not available');
    }

    const meshGroup = new THREE.Group();
    meshGroup.visible = false;
    scene.add(meshGroup);
    let lastMeshFetch = 0;

    // --- Toggle state ---
    let showPlanes = false;
    let showMesh = false;

    // Create VideoTexture AFTER setSession
    const heightToWidthRatio = (videoInfo.aspectRatio === '9:16') ? 16 / 9
      : (videoInfo.aspectRatio === '4:3') ? 3 / 4
      : (videoInfo.aspectRatio === '1:1') ? 1
      : 9 / 16;

    const texture = new THREE.VideoTexture(video);
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.minFilter = THREE.LinearFilter;
    texture.magFilter = THREE.LinearFilter;
    texture.generateMipmaps = false;

    const geo = new THREE.PlaneGeometry(0.5, 0.5 * heightToWidthRatio);
    const mat = new THREE.MeshBasicMaterial({ map: texture, side: THREE.DoubleSide, transparent: true, opacity: 1 });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.matrixAutoUpdate = false;
    mesh.visible = false;
    scene.add(mesh);

    let isPlayRequested = false;

    renderer.setAnimationLoop((time, frame) => {
      if (!frame) return;

      // Keep video playing — WebXR compositor can pause it
      if (video.paused && !isPlayRequested && placed) {
        isPlayRequested = true;
        video.play()
          .then(() => { isPlayRequested = false; })
          .catch((e) => { console.warn('[AR] play() failed:', e); isPlayRequested = false; });
      }

      if (hitTestSource) {
        const results = frame.getHitTestResults(hitTestSource);
        if (results.length > 0) {
          const pose = results[0].getPose(localSpace);
          if (pose) {
            lastHitPose = pose;
            reticle.visible = !placed;
            reticle.matrix.fromArray(pose.transform.matrix);
            if (!placed) {
              mesh.visible = true;
              mesh.matrix.fromArray(pose.transform.matrix);
            }
          }
        } else if (!placed) {
          reticle.visible = false;
          if (!mesh.visible) {
            mesh.visible = true;
            mesh.matrixAutoUpdate = true;
            mesh.position.set(0, -0.5, -1.2);
          }
        }
      }

      // Update plane visuals
      if (showPlanes && detectedPlanes.length > 0) {
        updatePlaneVisuals();
      }

      // Periodically fetch mesh geometry
      if (showMesh && meshMonitor && time - lastMeshFetch > 500) {
        lastMeshFetch = time;
        (async () => {
          try {
            const meshSets = await meshMonitor.getMeshSets();
            for (const ms of meshSets) {
              const geoData = await ms.mesh.geometry();
              if (!geoData || !geoData.vertices || geoData.vertices.length === 0) continue;
              const positions = new Float32Array(geoData.vertices.length * 3);
              for (let i = 0; i < geoData.vertices.length; i++) {
                positions[i * 3] = geoData.vertices[i].x;
                positions[i * 3 + 1] = geoData.vertices[i].y;
                positions[i * 3 + 2] = geoData.vertices[i].z;
              }
              const threeGeo = new THREE.BufferGeometry();
              threeGeo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
              const threeMat = new THREE.PointsMaterial({ color: 0x44aa99, size: 0.01 });
              const points = new THREE.Points(threeGeo, threeMat);
              meshGroup.add(points);
            }
          } catch (e) { /* Mesh not ready yet */ }
        })();
      }

      renderer.render(scene, renderer.xr.getCamera());
    });

    session.addEventListener('select', () => {
      if (!placed && lastHitPose) {
        placed = true;
        const m = new THREE.Matrix4().fromArray(lastHitPose.transform.matrix);
        mesh.position.setFromMatrixPosition(m);
        mesh.quaternion.setFromRotationMatrix(m);
        mesh.matrixAutoUpdate = true;
        mesh.visible = true;
        reticle.visible = false;
        if (video.paused) video.play();
        updateUI();
      }
    });

    // Auto-place if no hit-test
    if (!hitTestSource) {
      mesh.visible = true;
      mesh.matrixAutoUpdate = true;
      mesh.position.set(0, -0.5, -1.2);
      placed = true;
      reticle.visible = false;
    }

    // --- Touch overlay ---
    const touchOverlay = document.createElement('div');
    touchOverlay.style.cssText = `position:fixed;top:0;left:0;width:100%;height:100%;z-index:10000;display:${placed ? 'block' : 'none'};`;
    document.body.appendChild(touchOverlay);

    // --- UI ---
    const uiContainer = document.createElement('div');
    uiContainer.id = 'ar-ui-video';
    uiContainer.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;z-index:10002;pointer-events:none;transition:opacity 0.5s;';
    document.body.appendChild(uiContainer);

    const closeBtn = document.createElement('button');
    closeBtn.style.cssText = 'position:fixed;top:env(safe-area-inset-top, 20px);right:20px;z-index:10003;background:rgba(0,0,0,0.7);color:#fff;border:none;padding:10px 16px;border-radius:8px;font-size:14px;cursor:pointer;pointer-events:auto;';
    closeBtn.onclick = () => session.end();
    uiContainer.appendChild(closeBtn);

    const hintEl = document.createElement('div');
    hintEl.style.cssText = 'position:fixed;top:calc(env(safe-area-inset-top, 20px) + 50px);left:50%;transform:translateX(-50%);background:rgba(0,0,0,0.7);color:#fff;padding:8px 16px;border-radius:8px;font-size:13px;text-align:center;pointer-events:none;max-width:85%;white-space:nowrap;transition:opacity 0.5s;';
    uiContainer.appendChild(hintEl);

    const controlsBar = document.createElement('div');
    controlsBar.style.cssText = 'position:fixed;bottom:calc(env(safe-area-inset-bottom, 0px) + 20px);left:50%;transform:translateX(-50%);display:none;flex-direction:row;gap:8px;pointer-events:auto;z-index:10003;flex-wrap:wrap;justify-content:center;max-width:95vw;transition:opacity 0.5s;';
    uiContainer.appendChild(controlsBar);

    const triggerBtn = document.createElement('button');
    triggerBtn.style.cssText = 'position:fixed;bottom:calc(env(safe-area-inset-bottom, 0px) + 30px);right:20px;z-index:10003;width:50px;height:50px;border-radius:50%;background:rgba(44,94,61,0.4);color:rgba(255,255,255,0.6);border:2px solid rgba(255,255,255,0.2);font-size:22px;cursor:pointer;display:none;pointer-events:auto;transition:opacity 0.3s;';
    triggerBtn.textContent = '⚙';
    triggerBtn.onclick = () => showControls();
    uiContainer.appendChild(triggerBtn);

    const btnStyle = 'background:rgba(0,0,0,0.8);color:#fff;border:2px solid rgba(255,255,255,0.2);padding:12px 16px;border-radius:10px;font-size:14px;cursor:pointer;white-space:nowrap;';

    const playPauseBtn = document.createElement('button');
    playPauseBtn.style.cssText = btnStyle;
    playPauseBtn.textContent = '⏸️ Pause';
    playPauseBtn.onclick = () => {
      if (video.paused) { video.play(); playPauseBtn.textContent = '⏸️ Pause'; }
      else { video.pause(); playPauseBtn.textContent = '▶️ Play'; }
      showControls();
    };
    controlsBar.appendChild(playPauseBtn);

    const wallBtn = document.createElement('button');
    wallBtn.style.cssText = btnStyle;
    wallBtn.textContent = '🧱 Wall';
    wallBtn.onclick = () => { mesh.rotation.set(0, mesh.rotation.y, 0); currentMode = 'wall'; highlightBtn(); showControls(); };
    controlsBar.appendChild(wallBtn);

    const galleryBtn = document.createElement('button');
    galleryBtn.style.cssText = btnStyle;
    galleryBtn.textContent = '🖼️ Gallery';
    galleryBtn.onclick = () => { mesh.rotation.set(0, 0, 0); currentMode = 'gallery'; highlightBtn(); showControls(); };
    controlsBar.appendChild(galleryBtn);

    const planeToggle = document.createElement('button');
    planeToggle.style.cssText = btnStyle;
    planeToggle.textContent = '📐 Planes OFF';
    planeToggle.onclick = () => {
      showPlanes = !showPlanes;
      planeGroup.visible = showPlanes;
      planeToggle.textContent = showPlanes ? '📐 Planes ON' : '📐 Planes OFF';
      showControls();
    };
    controlsBar.appendChild(planeToggle);

    const meshToggle = document.createElement('button');
    meshToggle.style.cssText = btnStyle;
    meshToggle.textContent = '🔲 Mesh OFF';
    meshToggle.onclick = () => {
      showMesh = !showMesh;
      meshGroup.visible = showMesh;
      meshToggle.textContent = showMesh ? '🔲 Mesh ON' : '🔲 Mesh OFF';
      showControls();
    };
    controlsBar.appendChild(meshToggle);

    // --- Pin (anchor) button ---
    const pinBtn = document.createElement('button');
    pinBtn.style.cssText = btnStyle;
    pinBtn.textContent = '📌 Pin';
    pinBtn.onclick = async () => {
      if (!lastHitPose) return;
      try {
        const anchor = await session.createAnchor(lastHitPose.transform, localSpace);
        placedAnchorUID = anchor.anchorUID;
        pinBtn.textContent = '📌 Pinned!';
        pinBtn.style.borderColor = '#4ade80';
        pinBtn.disabled = true;
        // Show pin indicator above artwork
        const pinGeo = new THREE.SphereGeometry(0.01, 16, 16);
        const pinMat = new THREE.MeshBasicMaterial({ color: 0x4ade80 });
        pinMesh = new THREE.Mesh(pinGeo, pinMat);
        pinMesh.position.set(0, 0.3, 0);
        mesh.add(pinMesh);
        console.log('[AR] Anchor created:', anchor.anchorUID);
      } catch (e) {
        pinBtn.textContent = '📌 N/A';
        pinBtn.disabled = true;
        console.warn('[AR] Anchor not available');
      }
      showControls();
    };
    controlsBar.appendChild(pinBtn);

    const resetBtn = document.createElement('button');
    resetBtn.style.cssText = btnStyle;
    resetBtn.textContent = '🔄 Reset';
    resetBtn.onclick = () => {
      placed = false;
      placedAnchorUID = null;
      if (pinMesh) { mesh.remove(pinMesh); pinMesh.geometry.dispose(); pinMesh.material.dispose(); pinMesh = null; }
      pinBtn.textContent = '📌 Pin';
      pinBtn.style.borderColor = 'rgba(255,255,255,0.2)';
      pinBtn.disabled = false;
      mesh.visible = false;
      mesh.scale.set(1, 1, 1);
      mesh.matrixAutoUpdate = false;
      currentMode = null;
      reticle.visible = !!hitTestSource;
      touchOverlay.style.display = 'none';
      clearTimeout(hideTimer);
      updateUI();
    };
    controlsBar.appendChild(resetBtn);

    const allBtns = [playPauseBtn, wallBtn, galleryBtn, pinBtn, planeToggle, meshToggle, resetBtn];

    function highlightBtn() {
      allBtns.forEach((b, i) => {
        const active = (i === 1 && currentMode === 'wall') || (i === 2 && currentMode === 'gallery');
        b.style.borderColor = active ? '#2c5e3d' : 'rgba(255,255,255,0.2)';
        b.style.background = active ? 'rgba(44,94,61,0.8)' : 'rgba(0,0,0,0.8)';
      });
    }

    // Opacity slider (right side)
    const sliderContainer = document.createElement('div');
    sliderContainer.style.cssText = 'position:fixed;right:16px;top:50%;transform:translateY(-50%);z-index:10003;display:none;flex-direction:column;align-items:center;gap:4px;pointer-events:auto;';
    uiContainer.appendChild(sliderContainer);

    const sliderLabel = document.createElement('span');
    sliderLabel.style.cssText = 'color:rgba(255,255,255,0.7);font-size:11px;background:rgba(0,0,0,0.5);padding:2px 6px;border-radius:4px;';
    sliderLabel.textContent = 'Opacity';
    sliderContainer.appendChild(sliderLabel);

    const opacitySlider = document.createElement('input');
    opacitySlider.type = 'range';
    opacitySlider.min = '0.1';
    opacitySlider.max = '1';
    opacitySlider.step = '0.05';
    opacitySlider.value = '1';
    opacitySlider.style.cssText = '-webkit-appearance:slider-vertical;width:30px;height:120px;writing-mode:bt-lr;-webkit-writing-mode:vertical-lr;accent-color:#2c5e3d;background:transparent;cursor:pointer;';
    opacitySlider.addEventListener('input', (e) => {
      mesh.material.opacity = parseFloat(e.target.value);
      sliderLabel.textContent = Math.round(e.target.value * 100) + '%';
    });
    sliderContainer.appendChild(opacitySlider);

    function showControls() {
      uiContainer.style.opacity = '1';
      hintEl.style.opacity = '1';
      controlsBar.style.opacity = '1';
      triggerBtn.style.display = 'none';
      clearTimeout(hideTimer);
      hideTimer = setTimeout(hideControls, 4000);
      sliderContainer.style.display = 'flex';
      sliderContainer.style.opacity = '1';
      sliderLabel.textContent = Math.round(mesh.material.opacity * 100) + '%';
    }

    function hideControls() {
      uiContainer.style.opacity = '0.3';
      hintEl.style.opacity = '0';
      controlsBar.style.opacity = '0';
      triggerBtn.style.display = 'block';
      sliderContainer.style.display = 'flex';
      sliderContainer.style.opacity = '0.4';
    }

    function updateUI() {
      closeBtn.textContent = placed ? '✕ Close AR' : 'Tap to place · ✕ Close AR';
      controlsBar.style.display = placed ? 'flex' : 'none';
      touchOverlay.style.display = placed ? 'block' : 'none';
      triggerBtn.style.display = 'none';
      uiContainer.style.opacity = '1';
      hintEl.style.opacity = '1';
      controlsBar.style.opacity = '1';
      if (placed && !currentMode) {
        currentMode = 'wall';
        hintEl.textContent = 'Drag to rotate · Pinch to resize · ⏸️ to pause';
        clearTimeout(hideTimer);
        hideTimer = setTimeout(hideControls, 4000);
      }
      if (!placed) hintEl.textContent = 'Point at a surface and tap to place video';
      highlightBtn();
    }

    updateUI();

    // --- Touch gestures ---
    let isDragging = false, isPinching = false;
    let touchStartX = 0, touchStartY = 0;
    let touchStartRotX = 0, touchStartRotY = 0, touchStartRotZ = 0;
    let lastPinchDist = 0, lastPinchAngle = 0;
    let lastPinchCenter = { x: 0, y: 0 };

    function angleBetweenTouches(t1, t2) {
      return Math.atan2(t2.clientY - t1.clientY, t2.clientX - t1.clientX);
    }

    touchOverlay.addEventListener('touchstart', (e) => {
      if (placed && uiContainer.style.opacity !== '1') showControls();
      if (e.touches.length === 1) {
        e.preventDefault();
        isDragging = true; isPinching = false;
        touchStartX = e.touches[0].clientX;
        touchStartY = e.touches[0].clientY;
        touchStartRotX = mesh.rotation.x;
        touchStartRotY = mesh.rotation.y;
        touchStartRotZ = mesh.rotation.z;
      } else if (e.touches.length === 2) {
        e.preventDefault();
        isDragging = false; isPinching = true;
        const dx = e.touches[0].clientX - e.touches[1].clientX;
        const dy = e.touches[0].clientY - e.touches[1].clientY;
        lastPinchDist = Math.sqrt(dx * dx + dy * dy);
        lastPinchAngle = angleBetweenTouches(e.touches[0], e.touches[1]);
        lastPinchCenter = {
          x: (e.touches[0].clientX + e.touches[1].clientX) / 2,
          y: (e.touches[0].clientY + e.touches[1].clientY) / 2
        };
      }
    }, { passive: false });

    touchOverlay.addEventListener('touchmove', (e) => {
      if (!placed) return;
      e.preventDefault();
      if (e.touches.length === 2 && isPinching) {
        const dx = e.touches[0].clientX - e.touches[1].clientX;
        const dy = e.touches[0].clientY - e.touches[1].clientY;
        const dist = Math.sqrt(dx * dx + dy * dy);
        const angle = angleBetweenTouches(e.touches[0], e.touches[1]);
        if (lastPinchDist > 0) {
          const factor = dist / lastPinchDist;
          mesh.scale.multiplyScalar(factor);
          const s = Math.max(0.05, Math.min(5, mesh.scale.x));
          mesh.scale.set(s, s, s);
        }
        lastPinchDist = dist;
        mesh.rotation.z += angle - lastPinchAngle;
        lastPinchAngle = angle;
        const cx = (e.touches[0].clientX + e.touches[1].clientX) / 2;
        const cy = (e.touches[0].clientY + e.touches[1].clientY) / 2;
        mesh.position.x += (cx - lastPinchCenter.x) * 0.002;
        mesh.position.y -= (cy - lastPinchCenter.y) * 0.002;
        lastPinchCenter = { x: cx, y: cy };
        return;
      }
      if (!isDragging || e.touches.length !== 1) return;
      const dx = e.touches[0].clientX - touchStartX;
      const dy = e.touches[0].clientY - touchStartY;
      mesh.rotation.x = touchStartRotX + dy * 0.01;
      mesh.rotation.y = touchStartRotY + dx * 0.01;
      mesh.rotation.z = touchStartRotZ;
    }, { passive: false });

    touchOverlay.addEventListener('touchend', () => {
      isDragging = false;
      isPinching = false;
      lastPinchDist = 0;
    });

    // --- Cleanup ---
    const cleanup = () => {
      video.pause();
      video.src = '';
      video.remove();
      renderer.setAnimationLoop(null);
      renderer.domElement.remove();
      uiContainer.remove();
      touchOverlay.remove();
      renderer.dispose();
      texture.dispose();
      geo.dispose();
      mat.dispose();
      reticleGeo.dispose();
      reticleMat.dispose();
      planeMat.dispose();
      for (const [, pm] of planeMeshMap) { pm.geometry.dispose(); }
      planeMeshMap.clear();
      meshGroup.traverse((child) => { if (child.geometry) child.geometry.dispose(); if (child.material) child.material.dispose(); });
      window.removeEventListener('resize', handleResize);
      ['overflow', 'position', 'top', 'width', 'height', 'touchAction'].forEach(p => {
        document.body.style.removeProperty(p);
      });
      document.documentElement.style.cssText = '';
      document.querySelectorAll('#ar-ui-video, [style*="z-index:9999"]').forEach(el => el.remove());
      window.location.replace('/');
    };

    session.addEventListener('end', () => cleanup());
  }
</script>

<svelte:head>
  <title>AR Video — Antoine Patraldo</title>
</svelte:head>

{#if status === 'ar-active'}
  <!-- AR canvas covers everything -->
{:else if status === 'loading'}
  <div class="ar-page">
    <div class="spinner"></div>
    <p>Loading video AR...</p>
  </div>
{:else if status === 'ready'}
  <div class="ar-page">
    <div class="ar-preview">
      {#if posterUrl}
        <img src={posterUrl} alt="Video preview" />
      {:else}
        <div class="video-placeholder">🎬</div>
      {/if}
      <p class="video-label">Video — {videoInfo?.duration ? `${Math.round(videoInfo.duration)}s` : ''}</p>
    </div>
    <button class="launch-btn" onclick={launchAR}>
      👁️ Launch AR Video
    </button>
    <a href="/" class="back-link">← Back</a>
  </div>
{:else if status === 'unsupported'}
  <div class="ar-page">
    <h2>AR Not Supported</h2>
    <p>Your device doesn't support WebXR AR. Try on a mobile device.</p>
    <a href="/" class="back-link">← Back</a>
  </div>
{:else if status === 'error'}
  <div class="ar-page">
    <h2>AR Error</h2>
    <p>{errorMsg}</p>
    <a href="/" class="back-link">← Back</a>
  </div>
{/if}

<style>
  .ar-page {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    gap: 1.5rem;
    padding: 2rem;
    font-family: 'Inter', sans-serif;
    color: #333;
  }
  .ar-preview img {
    max-width: 300px;
    max-height: 300px;
    border-radius: 12px;
    box-shadow: 0 8px 32px rgba(0,0,0,0.15);
  }
  .video-placeholder {
    width: 200px;
    height: 200px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 4rem;
    background: #f0f0f0;
    border-radius: 12px;
  }
  .video-label { margin: 0.5rem 0 0; color: #666; font-size: 0.9rem; }
  .spinner {
    width: 40px;
    height: 40px;
    border: 3px solid #e0e0e0;
    border-top-color: #2c5e3d;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }
  @keyframes spin { to { transform: rotate(360deg); } }
  .ar-page h2 { margin: 0; font-size: 1.5rem; color: #2c5e3d; }
  .ar-page p { margin: 0; color: #666; text-align: center; max-width: 400px; }
  .launch-btn {
    background: #2c5e3d;
    color: white;
    border: none;
    padding: 1rem 2rem;
    border-radius: 12px;
    font-size: 1.1rem;
    font-weight: 600;
    cursor: pointer;
    box-shadow: 0 4px 16px rgba(44, 94, 61, 0.3);
  }
  .launch-btn:hover { opacity: 0.9; }
  .back-link {
    background: transparent;
    color: #666;
    border: 1px solid #ddd;
    padding: 0.75rem 1.5rem;
    border-radius: 8px;
    font-size: 1rem;
    cursor: pointer;
    text-decoration: none;
  }
  .back-link:hover { background: #f5f5f5; }
</style>