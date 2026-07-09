// IWSDK is browser-only (WebXR + WebGL). Disable SSR for this route so the
// heavy client-only chunk never runs in the Worker, matching the AR pages.
export const ssr = false;
export const prerender = false;
