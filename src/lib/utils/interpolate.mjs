// src/lib/utils/interpolate.mjs
/**
 * Simple string interpolation: replaces {key} with values[key]
 * @param {string} str
 * @param {Record<string, string|number>} values
 * @returns {string}
 */
export function interpolate(str, values) {
  return str.replace(/\{(\w+)\}/g, (_, key) => String(values[key] ?? `{${key}}`));
}
