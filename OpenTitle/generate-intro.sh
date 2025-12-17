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

# Validate image
if ! command -v convert &>/dev/null; then
  echo "Error: ImageMagick 'convert' not found. Install with: sudo apt install imagemagick" >&2
  exit 1
fi

if [[ ! -f "$INPUT_IMG" ]]; then
  echo "Error: Input image '$INPUT_IMG' not found." >&2
  exit 1
fi

# Normalize path
INPUT_IMG="$(realpath "$INPUT_IMG")"
OUTPUT_HTML="$OUTPUT_DIR/intro.html"

# Step 1: Extract dominant colors (6)
echo "🎨 Extracting color palette from $(basename "$INPUT_IMG")..."
PALETTE_HEX=()
while IFS= read -r color; do
  PALETTE_HEX+=("$color")
done < <(convert "$INPUT_IMG" -resize 150x -kmeans 6 -unique-colors txt:- | awk '/#/{print $3}' | head -6)

if [[ ${#PALETTE_HEX[@]} -lt 3 ]]; then
  echo "⚠️ Warning: Only ${#PALETTE_HEX[@]} colors found. Using fallback palette."
  PALETTE_HEX=( "#E85A4F" "#2D3047" "#A8D0E6" "#F2F2F2" "#C3423F" "#3F7D75" )
fi

# Convert #AAAAAA → 0xAAAAAA for JS
PALETTE_JS=$(IFS=,; echo "${PALETTE_HEX[*]}" | sed 's/#/0x/g')

# Step 2: Copy image to output dir (for relative path in HTML)
BACKDROP_NAME="backdrop$(date +%s).jpg"
cp "$INPUT_IMG" "$OUTPUT_DIR/$BACKDROP_NAME"
BACKDROP_URL="$BACKDROP_NAME"

# Step 3: Generate HTML
cat > "$OUTPUT_HTML" <<EOF
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Antoine Patraldo Intro</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/matter-js/0.18.0/matter.min.js"></script>
  <style>
    body { margin: 0; overflow: hidden; background: #000; }
    #canvas-container { position: fixed; inset: 0; }
  </style>
</head>
<body>
  <div id="canvas-container"></div>

  <script>
    const TEXT_LINES = ["Antoine Patraldo", "creaciones fantasiosas"];
    const DURATION_SEC = 7;
    const PALETTE = [${PALETTE_JS}];

    // === BACKDROP ===
    const backdrop = new Image();
    backdrop.src = "${BACKDROP_URL}";
    backdrop.onload = init; // Start only when backdrop loads

    function init() {
      // ==== THREE.JS ====
      const container = document.getElementById('canvas-container');
      const scene = new THREE.Scene();
      const camera = new THREE.PerspectiveCamera(50, window.innerWidth/window.innerHeight, 0.1, 1000);
      camera.position.z = 25;
      const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
      renderer.setSize(window.innerWidth, window.innerHeight);
      renderer.setPixelRatio(window.devicePixelRatio);
      container.appendChild(renderer.domElement);

      // Add backdrop as background texture
      const bgTexture = new THREE.Texture(backdrop);
      bgTexture.needsUpdate = true;
      const bgMat = new THREE.MeshBasicMaterial({ map: bgTexture, transparent: true, opacity: 0.3 });
      const bgGeo = new THREE.PlaneGeometry(50, 50);
      const bgMesh = new THREE.Mesh(bgGeo, bgMat);
      bgMesh.position.z = -20;
      scene.add(bgMesh);

      // Lights
      scene.add(new THREE.AmbientLight(0xffffff, 0.6));
      const dirLight = new THREE.DirectionalLight(0xffffff, 0.8);
      dirLight.position.set(5, 10, 7);
      scene.add(dirLight);

      // ==== MATTER.JS ====
      const { Engine, World, Bodies, Body } = Matter;
      const engine = Engine.create();
      engine.gravity.y = 0.3;
      const w = window.innerWidth, h = window.innerHeight;
      World.add(engine.world, [
        Bodies.rectangle(w/2, h+50, w, 100, { isStatic: true }),
        Bodies.rectangle(-50, h/2, 100, h, { isStatic: true }),
        Bodies.rectangle(w+50, h/2, 100, h, { isStatic: true })
      ]);

      const droplets = [];
      const dropletMeshes = [];
      for (let i = 0; i < 100; i++) {
        const x = -200 + Math.random() * (w + 400);
        const y = -200 - Math.random() * 300;
        const r = 4 + Math.random() * 12;
        const color = PALETTE[Math.floor(Math.random() * PALETTE.length)];
        const body = Bodies.circle(x, y, r, {
          restitution: 0.4, friction: 0.01, frictionAir: 0.02
        });
        Body.setVelocity(body, { x: (Math.random()-0.5)*20, y: 5+Math.random()*20 });
        World.add(engine.world, body);
        droplets.push({ body, color, radius: r });
      }

      droplets.forEach(d => {
        const geom = new THREE.SphereGeometry(d.radius * 0.008, 12, 12);
        const mat = new THREE.MeshPhongMaterial({ color: d.color, transparent: true, opacity: 0.9 });
        const mesh = new THREE.Mesh(geom, mat);
        scene.add(mesh);
        dropletMeshes.push({ mesh, body: d.body });
      });

      Engine.run(engine);

      // ==== 3D TEXT ====
      let titleGroup = null;
      const loader = new THREE.FontLoader();
      loader.load('https://cdn.jsdelivr.net/npm/three@0.128/examples/fonts/helvetiker_bold.typeface.json', (font) => {
        const group = new THREE.Group();
        TEXT_LINES.forEach((line, i) => {
          const size = line.includes('Antoine') ? 3.5 : 2.2;
          const textGeo = new THREE.TextGeometry(line, {
            font: font, size: size, height: 0.3, curveSegments: 6,
            bevelEnabled: true, bevelThickness: 0.08, bevelSize: 0.04, bevelSegments: 4
          });
          textGeo.computeBoundingBox();
          const cx = -0.5 * (textGeo.boundingBox.max.x - textGeo.boundingBox.min.x);
          const textMat = new THREE.MeshPhongMaterial({ color: PALETTE[0], shininess: 90 });
          const text = new THREE.Mesh(textGeo, textMat);
          text.position.set(cx, i === 0 ? 1.5 : -1.5, 0);
          text.visible = false;
          group.add(text);
        });
        group.position.y = -5;
        scene.add(group);
        titleGroup = group;
      });

      // ==== ANIMATION ====
      let time = 0, showTitle = false;
      const clock = new THREE.Clock();

      function animate() {
        requestAnimationFrame(animate);
        time += clock.getDelta();

        // Update droplets
        dropletMeshes.forEach(({mesh, body}) => {
          mesh.position.x = (body.position.x - w/2) * 0.01;
          mesh.position.y = -(body.position.y - h/2) * 0.01;
        });

        // Transition at 3.5s
        if (time > 3.5 && titleGroup && !showTitle) {
          showTitle = true;
          dropletMeshes.forEach(d => d.mesh.material.opacity = 0);
          titleGroup.children.forEach(c => c.visible = true);
        }

        // Animate title in
        if (titleGroup && showTitle) {
          const prog = Math.min(1, (time - 3.5) / 1.5);
          const ease = prog < 0.5 ? 2*prog*prog : 1 - Math.pow(-2*prog + 2, 2)/2;
          titleGroup.position.y = -5 + ease * 5;
        }

        // Camera dolly
        camera.position.z = 25 - Math.min(1, time / DURATION_SEC) * 12;
        camera.lookAt(scene.position);
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

echo "✅ Generated: $OUTPUT_HTML"
echo "👉 Open in Chrome: google-chrome --kiosk '$OUTPUT_HTML'"
