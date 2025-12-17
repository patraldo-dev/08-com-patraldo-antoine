#!/usr/bin/env bash
set -euo pipefail

USAGE="Usage: $0 <input_image.jpg> [output_dir]"

if [[ $# -lt 1 ]]; then
  echo "$USAGE" >&2
  exit 1
fi

INPUT_IMG="$1"
OUTPUT_DIR="${2:-.}"
[[ -d "$OUTPUT_DIR" ]] || mkdir -p "$OUTPUT_DIR"

if ! command -v convert &>/dev/null; then
  echo "Error: ImageMagick 'convert' not found." >&2
  exit 1
fi

if [[ ! -f "$INPUT_IMG" ]]; then
  echo "Error: Input image not found." >&2
  exit 1
fi

INPUT_IMG="$(realpath "$INPUT_IMG")"
OUTPUT_HTML="$OUTPUT_DIR/intro.html"
BACKDROP_NAME="backdrop.jpg"
cp "$INPUT_IMG" "$OUTPUT_DIR/$BACKDROP_NAME"

# Extract palette
PALETTE_HEX=()
while IFS= read -r color; do
  PALETTE_HEX+=("$color")
done < <(convert "$INPUT_IMG" -resize 150x -kmeans 6 -unique-colors txt:- | awk '/#/{print $3}' | head -6)
[[ ${#PALETTE_HEX[@]} -ge 3 ]] || PALETTE_HEX=( "#E85A4F" "#2D3047" "#A8D0E6" "#F2F2F2" "#C3423F" "#3F7D75" )
PALETTE_JS=$(IFS=,; echo "${PALETTE_HEX[*]}" | sed 's/#/0x/g')

cat > "$OUTPUT_HTML" <<EOF
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Antoine Patraldo Intro</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/matter-js/0.18.0/matter.min.jar"></script>
  <style> body { margin:0; overflow:hidden; background:#000; } #canvas-container { position:fixed; inset:0; } </style>
</head>
<body>
  <div id="canvas-container"></div>

  <script>
    const TEXT_LINES = ["Antoine Patraldo", "creaciones fantasiosas"];
    const DURATION = 8.0;
    const PALETTE = [${PALETTE_JS}];
    const w = window.innerWidth, h = window.innerHeight;

    const backdrop = new Image();
    backdrop.src = "${BACKDROP_NAME}";
    backdrop.onload = start;

    function start() {
      // ===== THREE.JS =====
      const container = document.getElementById('canvas-container');
      const scene = new THREE.Scene();
      scene.background = new THREE.Color(0x000000);
      const camera = new THREE.PerspectiveCamera(50, w/h, 0.1, 1000);
      camera.position.z = 25;
      const renderer = new THREE.WebGLRenderer({ antialias: true });
      renderer.setSize(w, h);
      renderer.setPixelRatio(window.devicePixelRatio);
      container.appendChild(renderer.domElement);

      // Backdrop
      const bgTex = new THREE.Texture(backdrop);
      bgTex.needsUpdate = true;
      const bg = new THREE.Mesh(
        new THREE.PlaneGeometry(50, 50),
        new THREE.MeshBasicMaterial({ map: bgTex, transparent: true, opacity: 0.25 })
      );
      bg.position.z = -20;
      scene.add(bg);

      // Lights
      scene.add(new THREE.AmbientLight(0xffffff, 0.5));
      const dl = new THREE.DirectionalLight(0xffffff, 0.8);
      dl.position.set(5, 10, 7);
      scene.add(dl);

      // Splat sprites (for paint stains)
      const splats = [];
      const splatGroup = new THREE.Group();
      scene.add(splatGroup);

      // ===== MATTER.JS =====
      const { Engine, World, Bodies, Body } = Matter;
      const engine = Engine.create();
      engine.gravity.y = 0.4;
      World.add(engine.world, [
        Bodies.rectangle(w/2, h+100, w, 200, { isStatic: true }),
        Bodies.rectangle(-100, h/2, 200, h, { isStatic: true }),
        Bodies.rectangle(w+100, h/2, 200, h, { isStatic: true })
      ]);

      const droplets = [];
      const dropletMeshes = [];
      const allColors = [];

      // Create explosive splatter
      for (let i = 0; i < 140; i++) {
        const angle = Math.random() * Math.PI * 2;
        const dist = 50 + Math.random() * 200;
        const x = w/2 + Math.cos(angle) * dist;
        const y = h/2 + Math.sin(angle) * dist - 300; // start above
        const r = 3 + Math.random() * 10;
        const color = PALETTE[Math.floor(Math.random() * PALETTE.length)];
        allColors.push(color);

        const body = Bodies.circle(x, y, r, { restitution: 0.3, friction: 0.005, frictionAir: 0.01 });
        Body.setVelocity(body, {
          x: (Math.random() - 0.5) * 12,
          y: 8 + Math.random() * 15
        });
        Body.setAngularVelocity(body, (Math.random() - 0.5) * 0.1);
        World.add(engine.world, body);

        const geom = new THREE.SphereGeometry(r * 0.008, 10, 10);
        const mat = new THREE.MeshPhongMaterial({ color: color, transparent: true, opacity: 0.92 });
        const mesh = new THREE.Mesh(geom, mat);
        scene.add(mesh);
        dropletMeshes.push({ mesh, body, color, radius: r, hasSplat: false });
      }

      Engine.run(engine);

      // ===== TITLE PARTICLES (initially hidden) =====
      let letterParticles = [];
      let titleVisible = false;

      // Load font and prepare particle targets
      const loader = new THREE.FontLoader();
      loader.load('https://cdn.jsdelivr.net/npm/three@0.128/examples/fonts/helvetiker_bold.typeface.json', (font) => {
        const particleTargets = [];
        let offsetY = 0;

        TEXT_LINES.forEach((line, lineIdx) => {
          const size = line.includes('Antoine') ? 2.8 : 1.8;
          const textGeo = new THREE.TextGeometry(line, {
            font: font, size: size, height: 0.1, curveSegments: 4,
            bevelEnabled: false
          });
          const positions = [];
          textGeo.getAttribute('position').array.forEach((v, i) => {
            if (i % 3 === 0) {
              positions.push([
                textGeo.getAttribute('position').array[i] + (lineIdx === 0 ? 0 : 0),
                textGeo.getAttribute('position').array[i+1] - offsetY,
                textGeo.getAttribute('position').array[i+2]
              ]);
            }
          });
          textGeo.dispose();
          particleTargets.push(...positions);
          offsetY += lineIdx === 0 ? 4.2 : 0;
        });

        // Create particles (same count as droplets)
        const count = Math.min(dropletMeshes.length, particleTargets.length * 3);
        for (let i = 0; i < count; i++) {
          const geom = new THREE.SphereGeometry(0.06, 8, 8);
          const mat = new THREE.MeshPhongMaterial({ 
            color: allColors[i % allColors.length], 
            transparent: true, 
            opacity: 0.0 
          });
          const mesh = new THREE.Mesh(geom, mat);
          mesh.userData = {
            startX: dropletMeshes[i % dropletMeshes.length].mesh.position.x,
            startY: dropletMeshes[i % dropletMeshes.length].mesh.position.y,
            startZ: dropletMeshes[i % dropletMeshes.length].mesh.position.z,
            endX: (particleTargets[i % particleTargets.length][0] - 5) * 0.8,
            endY: (particleTargets[i % particleTargets.length][1] + 2) * 0.8,
            endZ: particleTargets[i % particleTargets.length][2] + 1,
            progress: 0
          };
          scene.add(mesh);
          letterParticles.push(mesh);
        }
      });

      // ===== ANIMATION LOOP =====
      let time = 0;
      const clock = new THREE.Clock();

      function animate() {
        requestAnimationFrame(animate);
        time += clock.getDelta();

        // Update droplets + create splats on impact
        dropletMeshes.forEach(d => {
          const b = d.body;
          d.mesh.position.x = (b.position.x - w/2) * 0.01;
          d.mesh.position.y = -(b.position.y - h/2) * 0.01;
          d.mesh.position.z = 0.1;

          // Create splat when slow and near bottom
          if (!d.hasSplat && b.position.y > h - 100 && Math.abs(b.velocity.y) < 2) {
            d.hasSplat = true;
            const splatSize = d.radius * 0.02;
            const splatGeo = new THREE.PlaneGeometry(splatSize * 3, splatSize);
            const splatMat = new THREE.MeshBasicMaterial({ 
              color: d.color, 
              transparent: true, 
              opacity: 0.18 + Math.random() * 0.12,
              side: THREE.DoubleSide
            });
            const splat = new THREE.Mesh(splatGeo, splatMat);
            splat.position.x = d.mesh.position.x + (Math.random() - 0.5) * 0.3;
            splat.position.y = d.mesh.position.y + (Math.random() - 0.5) * 0.2;
            splat.position.z = 0.05;
            splat.rotation.z = Math.random() * Math.PI;
            splatGroup.add(splat);
            splats.push(splat);
          }
        });

        // Phase 1: Splatter (0–4s)
        // Phase 2: Coalesce into text (4–7s)
        if (time > 4.0 && !titleVisible && letterParticles.length > 0) {
          titleVisible = true;
          // Fade out droplets
          dropletMeshes.forEach(d => {
            d.mesh.material.opacity = 0.0;
          });
        }

        // Animate particles into text
        if (titleVisible) {
          const phase = Math.min(1, (time - 4.0) / 2.5);
          const ease = phase < 0.5 ? 2*phase*phase : 1 - Math.pow(-2*phase + 2, 2)/2;
          letterParticles.forEach(p => {
            p.material.opacity = Math.min(1, ease * 1.2);
            p.position.x = p.userData.startX + (p.userData.endX - p.userData.startX) * ease;
            p.position.y = p.userData.startY + (p.userData.endY - p.userData.startY) * ease;
            p.position.z = p.userData.startZ + (p.userData.endZ - p.userData.startZ) * ease * 0.5;
          });
        }

        // Camera movement
        const camProg = Math.min(1, time / DURATION);
        camera.position.z = 25 - camProg * 14;
        camera.lookAt(0, 0, 0);

        renderer.render(scene, camera);
      }

      window.addEventListener('resize', () => {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
      });

      animate();
    }
  </script>
</body>
</html>
EOF

echo "✅ Generated splatter-intro: $OUTPUT_HTML"
echo "🎥 Open in Chrome and record the tab!"
