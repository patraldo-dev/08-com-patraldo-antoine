// src/lib/translations.js
import i18n from 'sveltekit-i18n';

/**
 * Internationalization config for Antoine.patraldo.com
 * Supports: Mexican Spanish (es), American English (en), Canadian French (fr)
 * @type {import('sveltekit-i18n').Config}
 */
const config = {
  fallbackLocale: 'es',
  initLocale: 'es', // Keep this for initialization
  
  loaders: [

// COMMON STRINGS (shared across all pages; but in each page, pages.home.meta.title for browser tab)
{ locale: 'es', key: 'common', loader: () => import('./locales/es/common.json') },
{ locale: 'en', key: 'common', loader: () => import('./locales/en/common.json') },
{ locale: 'fr', key: 'common', loader: () => import('./locales/fr/common.json') },

// MAIN SITE PAGES
{ locale: 'es', key: 'pages.home', loader: () => import('./locales/es/pages/home.json') },
{ locale: 'en', key: 'pages.home', loader: () => import('./locales/en/pages/home.json') },
{ locale: 'fr', key: 'pages.home', loader: () => import('./locales/fr/pages/home.json') },

// STORYVIEW PAGES - includes WILDCARD and pages.home.meta.title for browser tab 
{ locale: 'es', key: 'pages.stories', loader: () => import('./locales/es/pages/stories.json') },
{ locale: 'en', key: 'pages.stories', loader: () => import('./locales/en/pages/stories.json') },
{ locale: 'fr', key: 'pages.stories', loader: () => import('./locales/fr/pages/stories.json') },

// COLLECTION PAGE - includes WILDCARD and pages.home.meta.title for browser tab 
{ locale: 'es', key: 'pages.collection', loader: () => import('./locales/es/pages/collection.json') },
{ locale: 'en', key: 'pages.collection', loader: () => import('./locales/en/pages/collection.json') },
{ locale: 'fr', key: 'pages.collection', loader: () => import('./locales/fr/pages/collection.json') },

// TOOLS PAGE - includes WILDCARD and pages.home.meta.title for browser tab 
{ locale: 'es', key: 'pages.tools', loader: () => import('./locales/es/pages/tools.json') },
{ locale: 'en', key: 'pages.tools', loader: () => import('./locales/en/pages/tools.json') },
{ locale: 'fr', key: 'pages.tools', loader: () => import('./locales/fr/pages/tools.json') },

  ],
};

export const { t, locale, locales, loading, loadTranslations } = new i18n(config);
