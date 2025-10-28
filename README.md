# AGR-Video-Studio

Personal archive and workflow for AI-generated video projects.

## 📁 Structure
- `Project/` — Top-level creative projects (e.g., stories, characters), each with:
  - `scenes/` — Numbered scenes (e.g., `01-opening`, `02-climax`)
    - `drawings/` — Reference sketches (small files only)
    - `prompts/` — Text prompts used with Wan Video
    - `wan_output/` — *Not stored in Git* (hosted on Cloudflare Stream)
    - `edited_clips/` — *Not stored in Git* (processed via FFmpeg)
- `Tools/` — Bash scripts to manage projects and scenes

## 🚫 Media Policy
**No large binaries are committed.**  
All `.mp4`, `.gif`, audio, and large images are stored externally (Cloudflare Stream/Images) and referenced by ID in prompts.

## 🛠️ Usage
```bash
cd Tools
./new_project.sh "MyStory"
./new_scene.sh "001-20251029-MyStory" "opening-shot"
./sync_manifest.sh  # generates project index
