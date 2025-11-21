// src/lib/translations.js
import i18n from 'sveltekit-i18n';
import { browser } from '$app/environment';

/** @type {import('sveltekit-i18n').Config} */
const config = {
  fallbackLocale: 'es',
  // Remove initLocale from here!
  loaders: [
    // COMMON STRINGS
    { locale: 'es', key: 'common', loader: async () => (await import('./locales/es/common.json')).default },
    { locale: 'en', key: 'common', loader: async () => (await import('./locales/en/common.json')).default },
    { locale: 'fr', key: 'common', loader: async () => (await import('./locales/fr/common.json')).default },

    // MAIN SITE PAGES
    { locale: 'es', key: 'pages.home', loader: async () => (await import('./locales/es/pages/home.json')).default },
    { locale: 'en', key: 'pages.home', loader: async () => (await import('./locales/en/pages/home.json')).default },
    { locale: 'fr', key: 'pages.home', loader: async () => (await import('./locales/fr/pages/home.json')).default },

    // STORYVIEW PAGES
    { locale: 'es', key: 'pages.stories', loader: async () => (await import('./locales/es/pages/stories.json')).default },
    { locale: 'en', key: 'pages.stories', loader: async () => (await import('./locales/en/pages/stories.json')).default },
    { locale: 'fr', key: 'pages.stories', loader: async () => (await import('./locales/fr/pages/stories.json')).default },

    // COLLECTION PAGE
    { locale: 'es', key: 'pages.collection', loader: async () => (await import('./locales/es/pages/collection.json')).default },
    { locale: 'en', key: 'pages.collection', loader: async () => (await import('./locales/en/pages/collection.json')).default },
    { locale: 'fr', key: 'pages.collection', loader: async () => (await import('./locales/fr/pages/collection.json')).default },

    // TOOLS PAGE
    { locale: 'es', key: 'pages.tools', loader: async () => (await import('./locales/es/pages/tools.json')).default },
    { locale: 'en', key: 'pages.tools', loader: async () => (await import('./locales/en/pages/tools.json')).default },
    { locale: 'fr', key: 'pages.tools', loader: async () => (await import('./locales/fr/pages/tools.json')).default },
  ],
};

let t, locale, locales, loading, loadTranslations;

if (browser) {
  const i18nInstance = new i18n(config);
  t = i18nInstance.t;
  locale = i18nInstance.locale;
  locales = i18nInstance.locales;
  loading = i18nInstance.loading;
  loadTranslations = i18nInstance.loadTranslations;
} else {
  // Provide safe no-op defaults for SSR
  t = () => ''; 
  locale = { subscribe: () => () => {} };
  locales = { subscribe: () => () => {} };
  loading = { subscribe: () => () => {} };
  loadTranslations = async () => {};
}

export { t, locale, locales, loading, loadTranslations };
