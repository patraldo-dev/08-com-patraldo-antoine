<script>
    import { onMount, onDestroy } from 'svelte';
    import { browser } from '$app/environment';
    import { goto } from '$app/navigation';
    import { page } from '$app/stores';

    const { data } = $props();

    let container;
    let THREE;
    let renderer;
    let scene;
    let camera;
    let xrSession = $state(null);
    let xrSupported = $state(false);
    let xrActive = $state(false);
    let mode = $state(data.mode || 'wall');
    let loading = $state(false);
    let error = $state('');
    let reticle;
    let hitTestSource;
    let referenceSpace;
    let meshes = [];
    let artworkIndex = $state(0);

    let selectedArtwork = $derived(data.selectedArtwork);
    let artworks = $derived(data.artworks);
    let imageUrl = $derived(selectedArtwork?.imageUrl || '');

    onMount(async () => {
        if (!browser) return;
        // Find index of selected artwork
        artworkIndex = artworks.findIndex(a => a.id === selectedArtwork?.id) || 0;
        xrSupported = navigator.xr ? await navigator.xr.isSessionSupported('immersive-ar') : false;
    });

    async function startAR() {
        if (!xrSupported) { error = 'WebXR no disponible'; return; }
        loading = true;
        try {
            THREE = await import('three');

            renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
            renderer.setPixelRatio(window.devicePixelRatio);
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.xr.enabled = true;
            renderer.xr.referenceSpaceType = 'local-floor';
            container.appendChild(renderer.domElement);

            scene = new THREE.Scene();
            camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.01, 20);

            scene.add(new THREE.AmbientLight(0xffffff, 0.8));
            const dirLight = new THREE.DirectionalLight(0xffffff, 1.2);
            dirLight.position.set(0, 5, 5);
            scene.add(dirLight);

            // Reticle
            const reticleGeo = new THREE.RingGeometry(0.08, 0.12, 32);
            reticleGeo.rotateX(-Math.PI / 2);
            const reticleMat = new THREE.MeshBasicMaterial({ color: 0xc9a87c, transparent: true, opacity: 0.7 });
            reticle = new THREE.Mesh(reticleGeo, reticleMat);
            reticle.matrixAutoUpdate = false;
            reticle.visible = false;
            scene.add(reticle);

            const session = await navigator.xr.requestSession('immersive-ar', {
                requiredFeatures: ['hit-test'],
                optionalFeatures: ['light-estimation']
            });

            xrSession = session;
            xrActive = true;
            renderer.xr.setSession(session);

            session.addEventListener('end', () => {
                xrActive = false;
                xrSession = null;
                cleanup();
            });

            referenceSpace = await renderer.xr.getReferenceSpace();
            session.addEventListener('select', onSelect);

            const viewerSpace = await session.requestReferenceSpace('viewer');
            hitTestSource = await session.requestHitTestSource({ space: viewerSpace });

            if (mode === 'gallery') {
                await loadGallery();
            } else {
                await loadSingleArtwork(imageUrl);
            }

            renderer.setAnimationLoop(onXRFrame);
            loading = false;
        } catch (e) {
            console.error('AR error:', e);
            error = e.message || 'Error al iniciar AR';
            loading = false;
        }
    }

    async function loadSingleArtwork(url) {
        if (!THREE || !url) return;
        clearMeshes();
        const texture = await new THREE.TextureLoader().loadAsync(url);
        const aspect = texture.image.height / texture.image.width;
        const height = 1.5;
        const width = height / aspect;

        const geo = new THREE.PlaneGeometry(width, height);
        const mat = new THREE.MeshStandardMaterial({ map: texture, roughness: 0.3, metalness: 0.1 });
        const mesh = new THREE.Mesh(geo, mat);

        // Frame
        const fGeo = new THREE.BoxGeometry(width + 0.16, height + 0.16, 0.05);
        const fMat = new THREE.MeshStandardMaterial({ color: 0x2a1f14, roughness: 0.6 });
        const frame = new THREE.Mesh(fGeo, fMat);
        frame.position.z = -0.025;
        mesh.add(frame);

        mesh.visible = false;
        mesh.userData.isPlaceable = true;
        scene.add(mesh);
        meshes.push(mesh);
    }

    async function loadGallery() {
        if (!THREE) return;
        clearMeshes();
        const loader = new THREE.TextureLoader();
        const count = Math.min(artworks.length, 8);
        const radius = 3;

        for (let i = 0; i < count; i++) {
            const art = artworks[i];
            if (!art.imageUrl) continue;
            try {
                const texture = await loader.loadAsync(art.imageUrl);
                const aspect = texture.image.height / texture.image.width;
                const h = 1.2;
                const w = h / aspect;
                const geo = new THREE.PlaneGeometry(w, h);
                const mat = new THREE.MeshStandardMaterial({ map: texture, roughness: 0.3 });
                const mesh = new THREE.Mesh(geo, mat);
                const fGeo = new THREE.BoxGeometry(w + 0.1, h + 0.1, 0.04);
                const fMat = new THREE.MeshStandardMaterial({ color: 0x2a1f14, roughness: 0.6 });
                const frame = new THREE.Mesh(fGeo, fMat);
                frame.position.z = -0.02;
                mesh.add(frame);
                const angle = (i / count) * Math.PI * 2;
                mesh.position.set(Math.sin(angle) * radius, 1.2 + Math.sin(i * 1.5) * 0.3, Math.cos(angle) * radius);
                mesh.lookAt(0, 1.2, 0);
                scene.add(mesh);
                meshes.push(mesh);
            } catch (e) { console.warn('Skip artwork:', i); }
        }
    }

    function onSelect(event) {
        if (mode === 'gallery') { artworkIndex = (artworkIndex + 1) % artworks.length; return; }
        if (hitTestSource && xrSession && referenceSpace && meshes.length > 0) {
            const results = event.frame.getHitTestResults(hitTestSource);
            if (results.length > 0) {
                const pose = results[0].getPose(renderer.xr.getReferenceSpace());
                if (pose) {
                    const mesh = meshes[0];
                    mesh.visible = true;
                    mesh.position.setFromMatrixPosition(pose.transform.matrix);
                    mesh.rotation.set(0, 0, 0);
                    mesh.lookAt(mesh.position.x, mesh.position.y, mesh.position.z - 1);
                    mesh.rotation.x = 0;
                    mesh.rotation.z = 0;
                    if (mode === 'float') mesh.position.y += 0.5;
                    reticle.visible = false;
                }
            }
        }
    }

    function onXRFrame(time, frame) {
        if (!xrSession || !renderer) return;
        if (hitTestSource && reticle) {
            const results = frame.getHitTestResults(hitTestSource);
            if (results.length > 0) {
                const pose = results[0].getPose(renderer.xr.getReferenceSpace());
                if (pose) { reticle.visible = true; reticle.matrix.fromArray(pose.transform.matrix); }
            } else { reticle.visible = false; }
        }
        if (mode === 'gallery' || mode === 'float') {
            const t = time * 0.001;
            meshes.forEach((m, i) => { m.position.y += Math.sin(t * 0.5 + i * 0.7) * 0.0002; });
        }
        renderer.render(scene, camera);
    }

    function selectArtwork(idx) {
        artworkIndex = idx;
        const art = artworks[idx];
        if (art) goto(`/ar?id=${art.id}&mode=${mode}`);
    }

    function changeMode(m) {
        mode = m;
        goto(`/ar?id=${selectedArtwork?.id}&mode=${m}`);
    }

    function goBack() {
        if (xrSession) xrSession.end();
        else goto('/');
    }

    function clearMeshes() {
        meshes.forEach(m => { scene?.remove(m); m.geometry?.dispose(); m.material?.map?.dispose(); m.material?.dispose(); });
        meshes = [];
    }

    function cleanup() {
        renderer?.setAnimationLoop(null);
        renderer?.dispose();
        renderer?.domElement?.parentNode?.removeChild(renderer.domElement);
        clearMeshes();
        scene = null; camera = null; renderer = null; reticle = null;
    }

    onDestroy(() => { cleanup(); if (xrSession) xrSession.end(); });
</script>

<svelte:head>
    <title>AR — {selectedArtwork?.display_name || 'Antoine Patraldo'}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no" />
</svelte:head>

<div class="ar-page" bind:this={container}>
    {#if !xrActive}
        <div class="ar-controls">
            <button class="back-btn" onclick={goBack}>← Volver</button>

            <h2 class="ar-title">{selectedArtwork?.display_name || 'Selecciona una obra'}</h2>
            {#if selectedArtwork?.year}
                <span class="ar-year">{selectedArtwork.year}</span>
            {/if}

            <div class="mode-selector">
                <button class="mode-btn {mode === 'wall' ? 'active' : ''}" onclick={() => changeMode('wall')}>🧱 En mi pared</button>
                <button class="mode-btn {mode === 'float' ? 'active' : ''}" onclick={() => changeMode('float')}>🎈 Flotante</button>
                {#if artworks.length > 1}
                    <button class="mode-btn {mode === 'gallery' ? 'active' : ''}" onclick={() => changeMode('gallery')}>🖼️ Galería ({artworks.length})</button>
                {/if}
            </div>

            <p class="mode-desc">
                {#if mode === 'wall'}
                    Apunta a una pared y toca para colocar la obra a tamaño real
                {:else if mode === 'float'}
                    Toca para soltar la obra en el aire
                {:else}
                    {artworks.length} obras en círculo. Camina y explora.
                {/if}
            </p>

            <button class="start-btn" onclick={startAR} disabled={loading || !xrSupported}>
                {loading ? '⏳ Cargando...' : !xrSupported ? '⚠️ WebXR no disponible' : '🚀 Iniciar AR'}
            </button>

            {#if artworks.length > 1 && mode !== 'gallery'}
                <div class="artwork-list">
                    {#each artworks as art, i}
                        <button
                            class="art-thumb {i === artworkIndex ? 'active' : ''}"
                            onclick={() => selectArtwork(i)}
                            title={art.display_name || art.title}
                        >
                            {i === artworkIndex ? '🟡' : '⚪'}
                        </button>
                    {/each}
                </div>
            {/if}
        </div>
    {/if}

    {#if error}
        <div class="ar-error">
            <p>⚠️ {error}</p>
            <button onclick={goBack}>Volver</button>
        </div>
    {/if}

    {#if xrActive}
        <button class="stop-btn" onclick={goBack}>⏹ Salir</button>
    {/if}
</div>

<style>
    .ar-page {
        position: fixed;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        background: #0a0a0a;
        z-index: 9999;
        overflow: hidden;
    }

    .ar-controls {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 1rem;
        padding: 2rem;
        color: #fff;
        font-family: system-ui, sans-serif;
    }

    .back-btn {
        position: absolute;
        top: 16px;
        left: 16px;
        background: rgba(255,255,255,0.1);
        border: 1px solid rgba(255,255,255,0.2);
        color: #fff;
        padding: 0.5rem 1rem;
        border-radius: 8px;
        cursor: pointer;
        font-size: 0.9rem;
    }

    .ar-title {
        font-size: 1.8rem;
        margin: 0;
        color: #c9a87c;
        text-align: center;
    }

    .ar-year {
        color: #888;
        font-style: italic;
    }

    .mode-selector {
        display: flex;
        gap: 0.5rem;
        flex-wrap: wrap;
        justify-content: center;
        margin-top: 1rem;
    }

    .mode-btn {
        background: rgba(255,255,255,0.08);
        border: 1px solid rgba(255,255,255,0.15);
        color: #ccc;
        padding: 0.6rem 1.2rem;
        border-radius: 8px;
        cursor: pointer;
        font-size: 0.9rem;
    }

    .mode-btn.active {
        background: #c9a87c;
        border-color: #c9a87c;
        color: #1a1a1a;
        font-weight: 600;
    }

    .mode-desc {
        font-size: 0.9rem;
        color: #888;
        text-align: center;
        max-width: 320px;
        line-height: 1.4;
    }

    .start-btn {
        background: #c9a87c;
        color: #1a1a1a;
        border: none;
        padding: 0.9rem 2.5rem;
        border-radius: 12px;
        font-size: 1.1rem;
        font-weight: 700;
        cursor: pointer;
        margin-top: 1rem;
    }

    .start-btn:disabled { opacity: 0.5; cursor: not-allowed; }

    .artwork-list {
        display: flex;
        gap: 8px;
        flex-wrap: wrap;
        justify-content: center;
        margin-top: 1rem;
        max-width: 300px;
    }

    .art-thumb {
        background: none;
        border: none;
        font-size: 1.2rem;
        cursor: pointer;
        padding: 4px;
    }

    .stop-btn {
        position: fixed;
        top: 16px;
        right: 16px;
        background: rgba(0,0,0,0.6);
        border: none;
        color: #fff;
        width: 50px;
        height: 50px;
        border-radius: 50%;
        font-size: 1.3rem;
        cursor: pointer;
        z-index: 10000;
    }

    .ar-error {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        text-align: center;
        color: #fff;
    }

    .ar-error button {
        margin-top: 1rem;
        background: #c9a87c;
        border: none;
        color: #1a1a1a;
        padding: 0.5rem 1.5rem;
        border-radius: 8px;
        cursor: pointer;
    }
</style>
