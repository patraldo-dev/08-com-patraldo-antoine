#!/usr/bin/env node

import { execSync } from 'child_process';
import { resolve } from 'path';

const OUTPUT = "./test_spectral.mp4";

// 🔑 Use absolute paths to your TTF files
const TITLE_FONT = resolve('/home/patrouch/.local/share/fonts/Spectral-SemiBold.ttf');
const SLOGAN_FONT = resolve('/home/patrouch/.local/share/fonts/Spectral-LightItalic.ttf');

// Verify files exist
import { existsSync } from 'fs';
if (!existsSync(TITLE_FONT)) throw new Error(`Title font not found: ${TITLE_FONT}`);
if (!existsSync(SLOGAN_FONT)) throw new Error(`Slogan font not found: ${SLOGAN_FONT}`);

const cmd = `ffmpeg -y -f lavfi -i color=0x121212:s=1920x1080:d=5:r=30 -vf "` +
  `drawtext=fontfile='${TITLE_FONT}':text='Studio Patraldo':` +
    `fontsize=72:fontcolor=white:x=(w-text_w)/2:y=h/2.8:enable='between(t,1,4)',` +
  `drawtext=fontfile='${SLOGAN_FONT}':text='ilustración · ilusión · improvisación':` +
    `fontsize=48:fontcolor=white@0.9:x=(w-text_w)/2:y=h/1.8:enable='between(t,1.7,4)'` +
  `" -c:v libx264 -crf 20 -preset fast -pix_fmt yuv420p "${OUTPUT}"`;

console.log("Rendering with direct fontfile paths...\n");
execSync(cmd, { stdio: 'inherit' });
console.log(`\n✅ Success: ${OUTPUT}`);
