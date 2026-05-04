// Detects WebXR AR support for showing/hiding AR buttons
// Returns: 'hidden' (no xr at all = desktop), 'teaser' (has xr but no AR), 'supported'

export function getARSupport() {
  if (typeof navigator === 'undefined' || !navigator.xr) return 'hidden';
  // Can't check synchronously — return 'check' to trigger async check
  return 'check';
}

export async function checkARSupport() {
  if (typeof navigator === 'undefined' || !navigator.xr) return 'hidden';
  try {
    const supported = await navigator.xr.isSessionSupported('immersive-ar');
    return supported ? 'supported' : 'teaser';
  } catch {
    return 'teaser';
  }
}
