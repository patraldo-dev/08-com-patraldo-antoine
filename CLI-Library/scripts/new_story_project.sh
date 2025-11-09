#!/bin/bash
# new_story_project.sh - Create a project optimized for multilingual storytelling
# Usage: new_story_project.sh "StoryName"

set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 \"StoryName\""
  echo "Example: $0 \"CatInParis\""
  exit 1
fi

STORY_NAME="$1"

# Step 1: Use your existing new_project.sh to create base structure
echo "🔄 Creating base project..."
PROJECT_DIR_LINE=$(../CLI-Library/bin/new_project.sh "$STORY_NAME" 2>&1 | grep "✅ Created project" | awk '{print $NF}')
if [[ -z "$PROJECT_DIR_LINE" ]]; then
  echo "❌ Failed to create base project"
  exit 1
fi

# Resolve full project path
PROJECTS_DIR="../Projects"
FULL_PROJECT_DIR="$PROJECTS_DIR/$PROJECT_DIR_LINE"

# Step 2: Add story-specific directories
mkdir -p "$FULL_PROJECT_DIR"/{raw,audio,dist}

# Step 3: Create cuts.tsv template
cat > "$FULL_PROJECT_DIR/cuts.tsv" <<EOF
# scene	path	in	out	notes
1	raw/clip1.mp4	00:00:00.000	00:00:05.000	intro
2	raw/clip2.mp4	00:00:02.100	00:00:08.300	action
EOF

# Step 4: Create render helper script
cat > "$FULL_PROJECT_DIR/render.sh" <<'EOF'
#!/bin/bash
# Render all language versions
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUTS="$PROJECT_DIR/cuts.tsv"
DIST="$PROJECT_DIR/dist"

mkdir -p "$DIST"

# Add your language files here
assemble_story.sh "$CUTS" "$PROJECT_DIR/audio/voice_en.m4a" "$DIST/story-en.mp4"
assemble_story.sh "$CUTS" "$PROJECT_DIR/audio/voice_es.m4a" "$DIST/story-es.mp4"
assemble_story.sh "$CUTS" "$PROJECT_DIR/audio/voice_fr.m4a" "$DIST/story-fr.mp4"

echo "✅ All versions rendered to $DIST/"
EOF
chmod +x "$FULL_PROJECT_DIR/render.sh"

echo "🎬 Story project ready: $FULL_PROJECT_DIR"
echo "   - Edit cuts.tsv to define your sequence"
echo "   - Place raw clips in raw/"
echo "   - Add audio files to audio/ (voice_en.m4a, etc.)"
echo "   - Run ./render.sh to build all versions"
