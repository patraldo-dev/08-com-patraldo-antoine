// src/lib/translations.js
import i18n from 'sveltekit-i18n';

/**
 * Internationalization config for Antoine.patraldo.com
 * Supports: Mexican Spanish (es-MX), American English (en-US), Canadian French (fr-CA)
 * @type {import('sveltekit-i18n').Config}
 */
const config = {
  fallbackLocale: 'es-MX',

  loaders: [

// COMMON STRINGS (shared across all pages; but in each page, pages.home.meta.title for browser tab)
{ locale: 'es-MX', key: 'common', loader: () => import('./locales/es-MX/common.json') },
{ locale: 'en-US', key: 'common', loader: () => import('./locales/en-US/common.json') },
{ locale: 'fr-CA', key: 'common', loader: () => import('./locales/fr-CA/common.json') },

// MAIN SITE PAGES
{ locale: 'es-MX', key: 'pages.home', loader: () => import('./locales/es-MX/pages/home.json') },
{ locale: 'en-US', key: 'pages.home', loader: () => import('./locales/en-US/pages/home.json') },
{ locale: 'fr-CA', key: 'pages.home', loader: () => import('./locales/fr-CA/pages/home.json') },

// STORYVIEW PAGES - includes WILDCARD and pages.home.meta.title for browser tab 
{ locale: 'es-MX', key: 'pages.stories', loader: () => import('./locales/es-MX/pages/stories.json') },
{ locale: 'en-US', key: 'pages.stories', loader: () => import('./locales/en-US/pages/stories.json') },
{ locale: 'fr-CA', key: 'pages.stories', loader: () => import('./locales/fr-CA/pages/stories.json') },

// COLLECTION PAGE - includes WILDCARD and pages.home.meta.title for browser tab 
{ locale: 'es-MX', key: 'pages.collection', loader: () => import('./locales/es-MX/pages/collection.json') },
{ locale: 'en-US', key: 'pages.collection', loader: () => import('./locales/en-US/pages/collection.json') },
{ locale: 'fr-CA', key: 'pages.collection', loader: () => import('./locales/fr-CA/pages/collection.json') },

// TOOLS PAGE - includes WILDCARD and pages.home.meta.title for browser tab 
{ locale: 'es-MX', key: 'pages.tools', loader: () => import('./locales/es-MX/pages/tools.json') },
{ locale: 'es-MX', key: 'pages.tools', loader: () => import('./locales/es-MX/pages/tools.json') },
{ locale: 'en-US', key: 'pages.tools', loader: () => import('./locales/en-US/pages/tools.json') },
{ locale: 'fr-CA', key: 'pages.tools', loader: () => import('./locales/fr-CA/pages/tools.json') },

  ],
};

export const { t, locale, locales, loading, loadTranslations } = new i18n(config);
