// src/lib/i18n/index.js
import { writable, derived } from 'svelte/store';

// Import all translations at build time (no race conditions!)
import en from './locales/en.json';
import es from './locales/es.json';
import fr from './locales/fr.json';

const translations = { en, es, fr };

// Create a writable store for the current locale
export const locale = writable('es'); // Default to Spanish

// Available locales
export const locales = ['en', 'es', 'fr'];

// Create a derived store for the t function
export const t = derived(locale, ($locale) => {
  return (key) => {
    // Simple key lookup in flat structure
    const translation = translations[$locale]?.[key];
    
    // Return translation or the key itself as fallback
    return translation || key;
  };
});

// Helper to set locale
export function setLocale(newLocale) {
  if (locales.includes(newLocale)) {
    locale.set(newLocale);
  }
}

// Helper to get current locale value
export function getLocale() {
  let currentLocale;
  locale.subscribe(value => currentLocale = value)();
  return currentLocale;
}
