// @ts-nocheck — IWSDK/Three.js dynamic scene code; excluded from strict type-checking.
// ═══════════════════════════════════════════════════════════
//  world-builder.js — Antoine's Worlds & Portals (IWSDK ECS)
//
//  A WORLD is a place you inhabit: its own palette, fog, particle
//  atmosphere, ambient drifting art, and trilingual narrative.
//
//  A PORTAL is a framed Antoine artwork floating within a world.
//  On approach it glows; tapping OPENS the artwork (scale/brighten
//  transition) and delivers you to the destination world, where
//  other artworks are themselves portals. The collection is navigation.
//
//  Adapted from the proven ~/.openclaw/workspace/portal-engine
//  reference (same World.create boot, same teardown/rebuild, same
//  camera-orbit + narrative systems), with the cube→portal split.
// ═══════════════════════════════════════════════════════════
import { World, Transform } from '@iwsdk/core';
import { createComponent, createSystem, Types } from 'elics';
import * as THREE from 'three';

// Cloudflare Images account hash (shared with the rest of the site).
const CF_HASH = '4bRSwPonOXfEIBVZiDXg0w';

function artUrl(imageId, variant = 'segment=foreground,width=512') {
	return `https://imagedelivery.net/${CF_HASH}/${imageId}/${variant}`;
}

// ── ECS Components ──

// A navigational doorway: one framed artwork that opens to another world.
const Portal = createComponent('Portal', {
	targetWorldId: { type: Types.String, default: '' },
	artId:         { type: Types.String, default: '' },
	title:         { type: Types.String, default: '' },
	color:         { type: Types.String, default: '#d4c9a8' },
	floatPhase:    { type: Types.Float32, default: 0 },
	floatSpeed:    { type: Types.Float32, default: 0.5 },
	baseY:         { type: Types.Float32, default: 0 },
	ring:          { type: Types.Float32, default: 0 },    // which orbit ring
	angle:         { type: Types.Float32, default: 0 },    // base angle on ring
	hovered:       { type: Types.Boolean, default: false },
	opening:       { type: Types.Float32, default: 0 },    // 0→1 transition state
});

// Ambient floating art — the world's own character, NOT navigation.
const AmbientArt = createComponent('AmbientArt', {
	floatPhase: { type: Types.Float32, default: 0 },
	floatSpeed: { type: Types.Float32, default: 0.3 },
	baseY:      { type: Types.Float32, default: 0 },
});

const CameraOrbit = createComponent('CameraOrbit', {
	angle:   { type: Types.Float32, default: 0 },
	radiusA: { type: Types.Float32, default: 6 },
	radiusB: { type: Types.Float32, default: 5 },
	height:  { type: Types.Float32, default: 2 },
	speed:   { type: Types.Float32, default: 0.03 },
	boost:   { type: Types.Float32, default: 0 },
});

const NarrativeState = createComponent('NarrativeState', {
	stateIndex:  { type: Types.Int32, default: 0 },
	lastAdvance: { type: Types.Float32, default: 0 },
});

// ── ECS Systems ──

const FloatSystem = class extends createSystem({
	portals:  { required: [Portal, Transform] },
	ambient:  { required: [AmbientArt, Transform] },
}) {
	update(dt) {
		const time = performance.now() / 1000;

		// Portals: gentle spin + bob + billboard to camera. Hover/opening
		// handled by PortalSystem (writes scale/opacity), here we keep them
		// alive on their orbit ring and facing the viewer.
		for (const entity of this.queries.portals.entities) {
			const obj = entity.object3D;
			if (!obj) continue;
			const phase = entity.getValue(Portal, 'floatPhase');
			const speed = entity.getValue(Portal, 'floatSpeed');
			const baseY = entity.getValue(Portal, 'baseY');
			obj.position.y = baseY + Math.sin(time * speed + phase) * 0.12;
			// Slow yaw so the artwork catches the light, but stays readable.
			obj.rotation.y += 0.002;
		}

		// Ambient art: looser drift, fuller rotation — scenery, not doors.
		for (const entity of this.queries.ambient.entities) {
			const obj = entity.object3D;
			if (!obj) continue;
			const phase = entity.getValue(AmbientArt, 'floatPhase');
			const speed = entity.getValue(AmbientArt, 'floatSpeed');
			const baseY = entity.getValue(AmbientArt, 'baseY');
			obj.position.y = baseY + Math.sin(time * speed + phase) * 0.25;
			obj.rotation.y += 0.004;
		}
	}
};

const CameraOrbitSystem = class extends createSystem({
	cam: { required: [CameraOrbit] },
}) {
	update(dt) {
		for (const entity of this.queries.cam.entities) {
			const angle = entity.getValue(CameraOrbit, 'angle');
			const radiusA = entity.getValue(CameraOrbit, 'radiusA');
			const radiusB = entity.getValue(CameraOrbit, 'radiusB');
			const height = entity.getValue(CameraOrbit, 'height');
			const speed = entity.getValue(CameraOrbit, 'speed');
			const boost = entity.getValue(CameraOrbit, 'boost');
			const newAngle = angle + dt * (speed + boost);
			entity.setValue(CameraOrbit, 'boost', boost * 0.95);
			entity.setValue(CameraOrbit, 'angle', newAngle);
			const time = performance.now() / 1000;
			this.world.camera.position.set(
				Math.sin(newAngle) * radiusA,
				height + Math.sin(time * 0.3) * 0.2,
				Math.cos(newAngle) * radiusB,
			);
			this.world.camera.lookAt(0, 0, 0);
			this.world.camera.rotation.z = Math.sin(time * 0.15) * 0.03;
		}
	}
};

// PortalSystem — drives hover lift, glow, and the opening transition,
// plus billboards the frames to face the camera. Split from FloatSystem
// so navigation logic (hover/open) is isolated from ambient motion.
const PortalSystem = class extends createSystem({
	portals: { required: [Portal, Transform] },
}) {
	update(dt) {
		for (const entity of this.queries.portals.entities) {
			const obj = entity.object3D;
			if (!obj) continue;
			const hovered = entity.getValue(Portal, 'hovered');
			const opening = entity.getValue(Portal, 'opening');

			// Keep frames upright; FloatSystem owns the slow yaw drift.
			obj.rotation.x = 0;

			// Ease scale toward target: resting 1.0, hovered 1.12, opening → 2.2.
			const targetScale = 1.0 + (hovered ? 0.12 : 0) + opening * 1.2;
			const cur = obj.scale.x;
			obj.scale.setScalar(cur + (targetScale - cur) * Math.min(1, dt * 8));

			// Advance the opening transition toward 1 once triggered.
			if (opening > 0 && opening < 1) {
				entity.setValue(Portal, 'opening', Math.min(1, opening + dt * 1.6));
			}

			// Drive the glow frame opacity from hover/opening state.
			const frame = obj.userData.frame;
			if (frame && frame.material) {
				const target = 0.25 + (hovered ? 0.35 : 0) + opening * 0.4;
				frame.material.opacity += (target - frame.material.opacity) * Math.min(1, dt * 8);
			}
			// Brighten the artwork plane as it opens.
			const plane = obj.userData.plane;
			if (plane && plane.material) {
				plane.material.opacity = 0.9 + opening * 0.1;
			}
		}
	}
};

// ── Overlay helpers (DOM, outside the WebGL canvas) ──

let currentOverlay = null;

function removeOverlay() {
	if (currentOverlay) { currentOverlay.remove(); currentOverlay = null; }
}

function showOverlay(text) {
	removeOverlay();
	const color = '#e8d5b5';
	const el = document.createElement('div');
	el.style.cssText = `position:fixed!important;top:15%!important;left:50%!important;transform:translateX(-50%)!important;color:${color}!important;font-family:Georgia,serif!important;font-size:clamp(18px,3.5vw,26px)!important;letter-spacing:0.05em!important;text-shadow:0 0 20px ${color}99,0 0 40px ${color}44!important;opacity:0;transition:opacity 0.8s ease;pointer-events:none;z-index:2147483647!important;text-align:center!important;max-width:80vw!important;white-space:pre-line!important;display:block!important;`;
	el.textContent = text;
	document.body.appendChild(el);
	currentOverlay = el;
	requestAnimationFrame(() => { el.style.opacity = '1'; });
	setTimeout(() => {
		el.style.opacity = '0';
		setTimeout(() => { if (el === currentOverlay) currentOverlay = null; el.remove(); }, 800);
	}, 5000);
}

function showPortalOverlay(name, desc, safeColor) {
	removeOverlay();
	const wrap = document.createElement('div');
	wrap.style.cssText = `position:fixed!important;top:18%!important;left:50%!important;transform:translateX(-50%)!important;text-align:center!important;max-width:80vw!important;opacity:0;transition:opacity 0.8s ease;pointer-events:none;z-index:2147483647!important;display:block!important;`;

	const heading = document.createElement('div');
	heading.style.cssText = `color:${safeColor}!important;font-family:Georgia,serif!important;font-size:clamp(20px,4vw,30px)!important;font-weight:700!important;letter-spacing:0.08em!important;text-transform:uppercase!important;text-shadow:0 0 16px ${safeColor}cc!important;margin-bottom:8px!important;`;
	heading.textContent = `\u27e1 ${name}`;

	const subtitle = document.createElement('div');
	subtitle.style.cssText = `color:${safeColor}!important;font-family:"Courier New",monospace!important;font-size:clamp(16px,3vw,22px)!important;font-style:italic!important;letter-spacing:0.03em!important;text-shadow:0 0 12px ${safeColor}66!important;`;
	subtitle.textContent = desc;

	wrap.appendChild(heading);
	wrap.appendChild(subtitle);
	document.body.appendChild(wrap);
	currentOverlay = wrap;
	requestAnimationFrame(() => { wrap.style.opacity = '1'; });
	setTimeout(() => { wrap.style.opacity = '0'; setTimeout(() => { if (wrap === currentOverlay) currentOverlay = null; wrap.remove(); }, 800); }, 4000);
}

// ── Navigation state (module-level, survives world swaps) ──

const nav = {
	history: [],
	currentWorldId: '',
	allConfigs: {},
	artworks: [], // live artwork list from D1, for binding portal art
};

// Pick an artwork id for a portal: prefer an explicit binding in the link,
// otherwise cycle through the live collection, otherwise fall back to the
// world's own representative art.
function resolveArtForLink(link, config, fallbackArt) {
	if (link.art && link.art.length > 0) return link.art;
	if (nav.artworks.length > 0) {
		// Deterministic by world + target so it stays stable across rebuilds.
		const seed = (config.portal.id + link.target)
			.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
		return nav.artworks[seed % nav.artworks.length].image_id;
	}
	return fallbackArt;
}

// ── World builder ──

function rebuildWorld(world, worldId, isNavigation = false) {
	const scene = world.scene;

	const destConfig = nav.allConfigs[worldId];

	// On inter-world navigation, flash the destination name + a color
	// transition tinted to the destination's palette, BEFORE teardown so
	// the swap is hidden under the overlay. Skipped on initial boot.
	if (isNavigation && destConfig) {
		const lang = (typeof document !== 'undefined' && document.documentElement?.lang) || 'es';
		const name = destConfig.world.names?.[lang] || destConfig.world.names?.es || worldId;
		const safeColor = destConfig.palette?.safe_text_color || destConfig.palette?.primary || '#e8d5b5';
		showPortalOverlay(name, '', safeColor);
	}
	const transitionPromise = (isNavigation && destConfig?.palette?.primary)
		? playTransition(destConfig.palette.primary)
		: Promise.resolve();

	// Cleanup previous world's tracked objects (lights, particles, frames…)
	if (world._sceneObjects) {
		for (const obj of world._sceneObjects) {
			if (obj.parent) obj.parent.remove(obj);
			if (obj.geometry) obj.geometry.dispose();
			if (obj.material) {
				if (Array.isArray(obj.material)) obj.material.forEach(m => m.dispose());
				else obj.material.dispose();
			}
		}
	}
	world._sceneObjects = [];

	// Cleanup ECS entities (portals, ambient art, camera, narrative)
	if (world._sceneEntities) {
		for (const entity of world._sceneEntities) {
			if (typeof entity.dispose === 'function') entity.dispose();
			else if (typeof entity.destroy === 'function') entity.destroy();
			else console.warn('[worlds] No dispose/destroy on entity:', entity);
		}
	}
	world._sceneEntities = [];

	const config = nav.allConfigs[worldId];
	if (!config) {
		console.error('[worlds] No config for', worldId);
		return;
	}

	nav.currentWorldId = worldId;
	if (nav.history[nav.history.length - 1] !== worldId) nav.history.push(worldId);

	// Sync URL so back/forward and deep links work.
	window.history.pushState({ worldId }, '', `/worlds/${worldId}`);

	const palette = config.palette;
	const lighting = config.lighting;
	const lang = (typeof document !== 'undefined' && document.documentElement?.lang) || 'es';
	const track = (obj) => { world._sceneObjects.push(obj); return obj; };

	// ── Atmosphere ──
	scene.background = new THREE.Color(palette.background);
	scene.fog = new THREE.FogExp2(palette.fog_color, palette.fog_density);

	// ── Lighting ──
	const ambientLight = new THREE.AmbientLight(lighting.ambient.color, lighting.ambient.intensity);
	scene.add(ambientLight); track(ambientLight);

	const keyLight = new THREE.PointLight(lighting.key_light.color, lighting.key_light.intensity, lighting.key_light.distance);
	keyLight.position.set(...lighting.key_light.position);
	scene.add(keyLight); track(keyLight);

	const rimLight = new THREE.PointLight(lighting.rim_light.color, lighting.rim_light.intensity, lighting.rim_light.distance);
	rimLight.position.set(...lighting.rim_light.position);
	scene.add(rimLight); track(rimLight);

	const underLight = new THREE.PointLight(lighting.under_light.color, lighting.under_light.intensity, lighting.under_light.distance);
	underLight.position.set(...lighting.under_light.position);
	scene.add(underLight); track(underLight);

	// ── Particle atmosphere (the world's signature look) ──
	const ap = config.ambient_particles;
	const starGeo = new THREE.BufferGeometry();
	const starPos = new Float32Array(ap.count * 3);
	const starCol = new Float32Array(ap.count * 3);
	for (let i = 0; i < ap.count; i++) {
		const r = 3 + Math.random() * ap.spawn_radius;
		const theta = Math.random() * Math.PI * 2;
		const phi = Math.acos(2 * Math.random() - 1);
		starPos[i * 3] = r * Math.sin(phi) * Math.cos(theta);
		starPos[i * 3 + 1] = r * Math.sin(phi) * Math.sin(theta) * 0.6;
		starPos[i * 3 + 2] = r * Math.cos(phi);
		const hue = ap.color_range.hue_start + Math.random() * ap.color_range.hue_span;
		const c = new THREE.Color().setHSL(hue, ap.color_range.saturation,
			ap.color_range.lightness_min + Math.random() * (ap.color_range.lightness_max - ap.color_range.lightness_min));
		starCol[i * 3] = c.r; starCol[i * 3 + 1] = c.g; starCol[i * 3 + 2] = c.b;
	}
	starGeo.setAttribute('position', new THREE.BufferAttribute(starPos, 3));
	starGeo.setAttribute('color', new THREE.BufferAttribute(starCol, 3));
	const stars = new THREE.Points(starGeo, new THREE.PointsMaterial({
		size: ap.size, vertexColors: true, transparent: true, opacity: ap.opacity,
		blending: THREE.AdditiveBlending, depthWrite: false, sizeAttenuation: true,
	}));
	scene.add(stars); track(stars);

	const texLoader = new THREE.TextureLoader();
	texLoader.crossOrigin = 'anonymous';

	// ── Ambient art: the world's own drifting pieces (not navigation) ──
	const ambientArtIds = config.environment_art || [];
	const ambientMeshes = [];
	ambientArtIds.forEach((artId, i) => {
		if (!artId) return;
		const a = (i / Math.max(1, ambientArtIds.length)) * Math.PI * 2;
		const radius = 3.6 + (i % 2) * 0.6;
		const ax = Math.cos(a) * radius;
		const ay = 0.4 + (i % 3) * 0.5;
		const az = Math.sin(a) * radius - 1;

		// Define the geometry/material/mesh FIRST, then load the texture
		// onto them asynchronously. (Ordered to avoid forward references.)
		const mat = new THREE.MeshBasicMaterial({
			color: 0xffffff, transparent: true, opacity: 0, side: THREE.DoubleSide,
		});
		const plane = new THREE.Mesh(new THREE.PlaneGeometry(0.9, 0.9), mat);
		const group = new THREE.Group();
		group.add(plane);
		group.position.set(ax, ay, az);
		scene.add(group); track(group);

		texLoader.load(artUrl(artId), (tex) => {
			tex.colorSpace = THREE.SRGBColorSpace;
			plane.scale.y = (tex.image?.height || 1) / (tex.image?.width || 1);
			mat.map = tex;
			mat.opacity = 0.22; // ambient — faint, scenery
			mat.needsUpdate = true;
		});

		const entity = world.createTransformEntity(group);
		entity.addComponent(AmbientArt, {
			floatPhase: Math.random() * Math.PI * 2,
			floatSpeed: 0.25 + Math.random() * 0.25,
			baseY: ay,
		});
		world._sceneEntities.push(entity);
		ambientMeshes.push(group);
	});

	// ── Portals: framed Antoine artworks as doorways ──
	// Each link → one portal. Distributed across two concentric rings for
	// depth, at varied elevations. The frame glows on hover; tapping opens it.
	const links = config.portal_links || [];
	const portalGroups = []; // for raycasting

	const RING_RADII = [2.3, 3.3];
	const ELEVATIONS = [0.5, 1.2, 0.7, 1.5, 0.45, 1.1];

	links.forEach((link, i) => {
		const tc = nav.allConfigs[link.target];
		if (!tc) return;

		const ringIdx = i % 2;
		const radius = RING_RADII[ringIdx];
		const inRingCount = Math.ceil((links.length - ringIdx) / 2);
		const inRingIndex = Math.floor(i / 2);
		const angleOffset = ringIdx === 0 ? 0 : Math.PI / inRingCount;
		const angle = (inRingIndex / inRingCount) * Math.PI * 2 + angleOffset;
		const px = Math.cos(angle) * radius;
		const py = ELEVATIONS[i % ELEVATIONS.length];
		const pz = Math.sin(angle) * radius - 1;

		const artId = resolveArtForLink(link, config, tc.world.art);
		const destName = tc.world.names?.[lang] || tc.world.names?.es || link.target;
		const safeColor = tc.palette?.safe_text_color || tc.palette?.primary || '#d4c9a8';

		// The artwork plane (the doorway image).
		const planeMat = new THREE.MeshBasicMaterial({
			color: 0xffffff, transparent: true, opacity: 0, side: THREE.DoubleSide,
		});

		// The glow frame around the artwork — a slightly larger plane behind it,
		// additive, tinted to the destination palette. Reads as a luminous border.
		const frameMat = new THREE.MeshBasicMaterial({
			color: new THREE.Color(safeColor), transparent: true, opacity: 0.25,
			blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide,
		});

		const group = new THREE.Group();
		const frame = new THREE.Mesh(new THREE.PlaneGeometry(1.28, 1.28), frameMat);
		const plane = new THREE.Mesh(new THREE.PlaneGeometry(1.0, 1.0), planeMat);
		plane.position.z = 0.01; // avoid z-fight with frame
		group.add(frame);
		group.add(plane);
		group.position.set(px, py, pz);
		group.userData.targetWorldId = link.target;
		group.userData.frame = frame;
		group.userData.plane = plane;

		// Texture load AFTER plane/material exist (avoids forward reference).
		texLoader.load(artUrl(artId), (tex) => {
			tex.colorSpace = THREE.SRGBColorSpace;
			plane.scale.y = (tex.image?.height || 1) / (tex.image?.width || 1);
			planeMat.map = tex;
			planeMat.opacity = 0.92;
			planeMat.needsUpdate = true;
		});

		scene.add(group); track(group);

		const entity = world.createTransformEntity(group);
		entity.addComponent(Portal, {
			targetWorldId: link.target,
			artId,
			title: destName,
			color: safeColor,
			floatPhase: Math.random() * Math.PI * 2,
			floatSpeed: 0.4 + Math.random() * 0.4,
			baseY: py,
			ring: ringIdx,
			angle,
			hovered: false,
			opening: 0,
		});
		world._sceneEntities.push(entity);
		portalGroups.push({ group, entity });
	});

	// ── Narrative entity ──
	const narrEntity = world.createEntity();
	narrEntity.addComponent(NarrativeState, {
		stateIndex: 0,
		lastAdvance: performance.now(),
	});
	world._sceneEntities.push(narrEntity);

	// ── Camera orbit entity ──
	const camEntity = world.createEntity();
	camEntity.addComponent(CameraOrbit, {
		angle: 0,
		radiusA: config.camera.orbit.radius_a,
		radiusB: config.camera.orbit.radius_b,
		height: config.camera.orbit.height,
		speed: config.camera.orbit.speed,
	});
	world._sceneEntities.push(camEntity);

	// ── Pointer interaction: hover + tap-to-open ──
	const raycaster = new THREE.Raycaster();
	const pointer = new THREE.Vector2();

	// Remove old handlers from the previous world.
	if (world._pointerMove) {
		world.renderer.domElement.removeEventListener('pointermove', world._pointerMove);
	}
	if (world._tapHandler) {
		world.renderer.domElement.removeEventListener('pointerdown', world._tapHandler);
		world.renderer.domElement.removeEventListener('touchstart', world._tapHandler);
	}
	// Clear any in-flight travel.
	if (world._travelTimeout) { clearTimeout(world._travelTimeout); world._travelTimeout = null; }

	function setPointer(e) {
		const x = e.touches ? e.touches[0].clientX : e.clientX;
		const y = e.touches ? e.touches[0].clientY : e.clientY;
		const rect = world.renderer.domElement.getBoundingClientRect();
		pointer.x = ((x - rect.left) / rect.width) * 2 - 1;
		pointer.y = -((y - rect.top) / rect.height) * 2 + 1;
	}

	function onPointerMove(e) {
		setPointer(e);
		raycaster.setFromCamera(pointer, world.camera);
		const hits = raycaster.intersectObjects(portalGroups.map(p => p.group), true);
		const hitGroup = hits.length > 0 ? findPortalGroup(hits[0].object) : null;
		for (const p of portalGroups) {
			const want = p.group === hitGroup;
			if (p.entity.getValue(Portal, 'hovered') !== want) {
				p.entity.setValue(Portal, 'hovered', want);
			}
		}
	}

	function findPortalGroup(obj) {
		let o = obj;
		while (o && !o.userData?.targetWorldId) o = o.parent;
		return o;
	}

	function onPointerDown(e) {
		setPointer(e);
		raycaster.setFromCamera(pointer, world.camera);
		// A tap also nudges the camera orbit forward (a little momentum).
		camEntity.setValue(CameraOrbit, 'boost', 1.2);

		const hits = raycaster.intersectObjects(portalGroups.map(p => p.group), true);
		if (hits.length === 0) return;
		const group = findPortalGroup(hits[0].object);
		if (!group) return;
		const targetId = group.userData.targetWorldId;
		const tc = nav.allConfigs[targetId];
		if (!tc) return;

		// Find the entity to begin its opening transition.
		const entry = portalGroups.find(p => p.group === group);
		if (entry) entry.entity.setValue(Portal, 'opening', 0.001);

		const name = tc.world.names?.[lang] || tc.world.names?.es || targetId;
		const desc = tc.world.descriptions?.[lang] || tc.world.descriptions?.es || '';
		const safeColor = tc.palette?.safe_text_color || tc.palette?.primary || '#e8d5b5';
		showPortalOverlay(name, desc, safeColor);

		// Travel after the opening transition + color flash have played.
		world._travelTimeout = setTimeout(() => {
			rebuildWorld(world, targetId, true);
		}, 900);
	}

	world._pointerMove = onPointerMove;
	world._tapHandler = onPointerDown;
	world.renderer.domElement.addEventListener('pointermove', onPointerMove);
	world.renderer.domElement.addEventListener('pointerdown', onPointerDown);
	world.renderer.domElement.addEventListener('touchstart', onPointerDown);

	// ── Narrative texts for the system wrapper ──
	const texts = config.narrative_texts?.[lang] || config.narrative_texts?.es || [];

	// ── Update wrapper: narrative cycling + atmosphere animation ──
	if (!world._updateWrapped) {
		const origUpdate = world.update.bind(world);
		world.update = function (delta, time) {
			origUpdate(delta, time);
			const tt = time / 1000;

			// Narrative cycling
			const narrLast = narrEntity.getValue(NarrativeState, 'lastAdvance');
			if (texts.length > 0 && performance.now() - narrLast > 12000) {
				const idx = narrEntity.getValue(NarrativeState, 'stateIndex');
				showOverlay(texts[idx]);
				narrEntity.setValue(NarrativeState, 'stateIndex', (idx + 1) % texts.length);
				narrEntity.setValue(NarrativeState, 'lastAdvance', performance.now());
			}

			// Star drift + light pulse — the world breathing.
			if (stars && stars.material) {
				stars.rotation.y += delta * ap.drift_speed;
				keyLight.intensity = lighting.key_light.intensity + Math.sin(tt * 0.8) * 0.5;
				rimLight.intensity = lighting.rim_light.intensity + Math.cos(tt * 0.6) * 0.4;
				underLight.intensity = lighting.under_light.intensity + Math.sin(tt * 1.2) * 0.3;
			}
		};
		world._updateWrapped = true;
	}

	// ── First narrative ──
	if (texts.length > 0) {
		setTimeout(() => showOverlay(texts[0]), 1500);
	}

	console.log('[worlds] World built:', worldId, 'portals:', portalGroups.length);
}

// Fullscreen color transition used when stepping between worlds.
function playTransition(color) {
	return new Promise((resolve) => {
		if (typeof document === 'undefined') return resolve();
		const flash = document.createElement('div');
		flash.style.cssText = `position:fixed;inset:0;background:${color};opacity:0;transition:opacity 0.3s ease;pointer-events:none;z-index:9998;`;
		document.body.appendChild(flash);
		requestAnimationFrame(() => { flash.style.opacity = '0.55'; });
		setTimeout(() => {
			flash.style.opacity = '0';
			setTimeout(() => { flash.remove(); resolve(); }, 300);
		}, 600);
	});
}

// ── Boot ──

/**
 * Boot the worlds & portals engine.
 * @param {HTMLElement} container
 * @param {Record<string, object>} configs  worldId → scene config
 * @param {Array<{image_id:string,title?:string}>} artworks  live collection (for portal art)
 * @param {string} initialWorldId
 */
export async function bootWorldEngine(container, configs, artworks, initialWorldId) {
	if (!container) throw new Error('bootWorldEngine: container is null');
	if (!configs || Object.keys(configs).length === 0) {
		throw new Error('bootWorldEngine: configs is empty');
	}

	nav.allConfigs = configs;
	nav.artworks = (artworks || []).filter(a => a && a.image_id);
	nav.history = [];

	const start = (initialWorldId && configs[initialWorldId])
		? initialWorldId
		: Object.keys(configs)[0];

	const world = await World.create(container, {
		xr: { offer: 'none' },
		render: { defaultLighting: false },
		features: { locomotion: false, grabbing: false, physics: false },
	});

	// Register components & systems.
	world.registerComponent(Portal);
	world.registerComponent(AmbientArt);
	world.registerComponent(CameraOrbit);
	world.registerComponent(NarrativeState);

	world.registerSystem(FloatSystem, { priority: 0 });
	world.registerSystem(PortalSystem, { priority: 0 });
	world.registerSystem(CameraOrbitSystem, { priority: 0 });

	world._sceneObjects = [];
	world._sceneEntities = [];

	// Seed history state for a direct deep link to /worlds/<id>.
	const currentPath = (typeof window !== 'undefined') ? window.location.pathname : '';
	if (typeof window !== 'undefined' && !window.history.state?.worldId && currentPath.startsWith('/worlds/')) {
		window.history.replaceState({ worldId: start }, '', currentPath);
	}

	rebuildWorld(world, start);

	// Browser back/forward support. An unknown/missing state → drop into a
	// random world other than the current one (the index "surprise me" intent).
	if (typeof window !== 'undefined') {
		window.addEventListener('popstate', (event) => {
			const wid = event.state?.worldId;
			if (wid && nav.allConfigs[wid]) {
				rebuildWorld(world, wid, true);
				return;
			}
			const ids = Object.keys(nav.allConfigs).filter((id) => id !== nav.currentWorldId);
			if (ids.length) {
				const randomId = ids[Math.floor(Math.random() * ids.length)];
				window.history.pushState({ worldId: randomId }, '', `/worlds/${randomId}`);
				rebuildWorld(world, randomId, true);
			}
		});
	}

	console.log('[worlds] Engine booted:', start);
	return world;
}
