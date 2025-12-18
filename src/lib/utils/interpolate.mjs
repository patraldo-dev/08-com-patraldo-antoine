// src/lib/utils/interpolate.mjs
export function interpolate(str, values) {
  return str.replace(/\{(\w+)\}/g, (_, key) => String(values[key] ?? `{${key}}`));
}
