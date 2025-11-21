// src/routes/+layout.js
import { loadTranslations, locale } from '$lib/translations';

/** @type {import('@sveltejs/kit').Load} */
export const load = async ({ url, data }) => {
  const { pathname } = url;

  // Use a fixed initial locale (e.g., 'es')
  const initLocale = 'es';

  console.log('🌍 Loading locale:', initLocale, 'for path:', pathname);

  // Load translations for the fixed initial locale
  await loadTranslations(initLocale, pathname);

  // Set the locale AFTER loading translations
  locale.set(initLocale);

  return {
    ...data
  };
};

