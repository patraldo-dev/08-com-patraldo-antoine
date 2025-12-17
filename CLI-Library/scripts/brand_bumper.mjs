#!/usr/bin/env node

import { execSync } from 'child_process';
import { existsSync } from 'fs';
import { dirname, resolve } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// --- Parse CLI args ---
const args = process.argv.slice(2);
const params = {};
for (let i = 0; i < args.length; i += 2) {
  const key = args[i].replace(/^--/, '');
  params[key] = args[i + 1];
}

const {
  title,
  slogan,
  audio,
  background,
  output = 'studio_intro.mp4',
  format = 'cine', // 'cine' or 'mobile'
  // Title styling
  titleFontName,
  titleFontFile,
  titleSize = '72',
  titleColor = 'white',
  // Slogan styling
  sloganFontName,
  sloganFontFile,
  sloganSize = '48',
  sloganColor = 'white@0.9',
  // Timing
  titleIn = '1.0',
  sloganDelay = '0.7',
  duration = '4.5',
} = params;

// --- Validate required args ---
if (!title || !slogan || !audio || !background) {
  console.error(`
Usage:
  node make_intro.mjs \\
    --title "Studio Patraldo" \\
    --slogan "ilustración · ilusión · improvisación" \\
    --audio sting.mp3 \\
    --background bg.mp4 \\
    [--output out.mp4] \\
    [--format cine|mobile] \\
    [--titleFontName "Montserrat-Bold"] [--titleFontFile ./font.ttf] \\
    [--sloganFontName "Inter-Regular"] [--sloganFontFile ./font.ttf] \\
    [--titleSize 80] [--sloganSize 52] \\
    [--titleColor white] [--sloganColor "white@0.85"]

Note:
  - Use --titleFontName if fonts are installed in ~/.local/share/fonts/
  - Use --titleFontFile for explicit paths (overrides name)
  - Default format: cine (16:9). Use 'mobile' for 9:16.
`);
  process.exit(1);
}

if (!existsSync(audio)) throw new Error(`Audio not found: ${audio}`);
if (!existsSync(background)) throw new Error(`Background video not found: ${background}`);

const absAudio = resolve(audio);
const absBackground = resolve(background);
const absOutput = resolve(output);

// --- Resolve format ---
let w, h;
if (format === 'mobile') {
  w = 1080; h = 1920;
} else if (format === 'cine') {
  w = 1920; h = 1080;
} else {
  throw new Error(`Invalid format: ${format} (use 'cine' or 'mobile')`);
}

// --- Build drawtext filter for one line ---
function buildDrawtext({
  text,
  fontName,
  fontFile,
  fontsize,
  fontcolor,
  yExpr,
  fadeInStart,
  fadeInDur = 0.5,
  fadeOutStart,
  fadeOutDur = 0.5
}) {
  const t0 = parseFloat(fadeInStart);
  const t1 = t0 + fadeInDur;
  const t2 = parseFloat(fadeOutStart) - fadeOutDur;
  const t3 = parseFloat(fadeOutStart);
  const alphaExpr = `if(lt(t,${t1}), (t-${t0})/${fadeInDur}, if(lt(t,${t2}), 1, (${t3}-t)/${fadeOutDur}))`;

  let fontOpt = '';
  if (fontFile) {
    if (!existsSync(fontFile)) throw new Error(`Font file not found: ${fontFile}`);
    fontOpt = `fontfile=${resolve(fontFile)}:`;
  } else if (fontName) {
    fontOpt = `font='${fontName}':`;
  }
  // If neither, FFmpeg uses default sans

  return `drawtext=${fontOpt}text=${text}:fontsize=${fontsize}:fontcolor=${fontcolor}:x=(w-text_w)/2:y=${yExpr}:enable='between(t,${t0},${t3})':alpha='${alphaExpr}'`;
}

// --- Timing ---
const titleStart = titleIn;
const titleEnd = duration;
const sloganStart = (parseFloat(titleIn) + parseFloat(sloganDelay)).toString();
const sloganEnd = duration;

// Proportional Y positions (work for both formats)
const titleY = 'h/2.8';
const sloganY = 'h/1.8';

// --- Build filters ---
const titleFilter = buildDrawtext({
  text: title,
  fontName: titleFontName,
  fontFile: titleFontFile,
  fontsize: titleSize,
  fontcolor: titleColor,
  yExpr: titleY,
  fadeInStart: titleStart,
  fadeOutStart: titleEnd
});

const sloganFilter = buildDrawtext({
  text: slogan,
  fontName: sloganFontName,
  fontFile: sloganFontFile,
  fontsize: sloganSize,
  fontcolor: sloganColor,
  yExpr: sloganY,
  fadeInStart: sloganStart,
  fadeOutStart: sloganEnd
});

// --- Scaling + cropping for target format ---
const scaleFilter = `scale=${w}:${h}:force_original_aspect_ratio=decrease,crop=${w}:${h}`;

const vf = `"${scaleFilter},${titleFilter},${sloganFilter}"`;

// --- FFmpeg command ---
const cmd = [
  'ffmpeg',
  '-y',
  '-i', `"${absBackground}"`,
  '-i', `"${absAudio}"`,
  '-vf', vf,
  '-c:v', 'libx264',
  '-crf', '22',
  '-preset', 'fast',
  '-c:a', 'aac',
  '-shortest',
  `"${absOutput}"`
].join(' ');

console.log(`.Rendering ${format} intro (${w}x${h})...\n`);
console.log(cmd);

try {
  execSync(cmd, { stdio: 'inherit', shell: '/bin/bash' });
  console.log(`\n✅ Success! Saved to: ${absOutput}`);
} catch (err) {
  console.error('\n❌ FFmpeg failed.');
  process.exit(1);
}
