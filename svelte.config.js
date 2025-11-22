// svelte.config.js
import adapter from "@sveltejs/adapter-cloudflare";
import { sveltekit } from "@sveltejs/kit/vite";
import { paraglideVitePlugin } from "@inlang/paraglide-js";
import { defineConfig } from "vite";

/** @type {import('@sveltejs/kit').Config} */
const config = {
  // SvelteKit-specific options
  kit: {
    adapter: adapter(),
    // You may also want to alias $lib/paraglide later if needed,
    // but the Vite plugin handles codegen so usually not required.
  },
};

export default defineConfig({
  plugins: [
    sveltekit(),
    paraglideVitePlugin({
      project: "./project.inlang",
      outdir: "./src/lib/paraglide", // matches your earlier choice
      strategy: ["url", "cookie", "baseLocale"],
    }),
  ],
  // Pass SvelteKit config through
  ...config,
});
