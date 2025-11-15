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
    // COMMON STRINGS (shared across all pages)
    { locale: 'es-MX', key: 'common', loader: () => import('./locales/es-MX/common.json') },
    { locale: 'en-US', key: 'common', loader: () => import('./locales/en-US/common.json') },
    { locale: 'fr-CA', key: 'common', loader: () => import('./locales/fr-CA/common.json') },

    // MAIN SITE PAGES
    { locale: 'es-MX', key: 'pages.home', routes: ['/'], loader: () => import('./locales/es-MX/pages/home.json') },
    { locale: 'en-US', key: 'pages.home', routes: ['/'], loader: () => import('./locales/en-US/pages/home.json') },
    { locale: 'fr-CA', key: 'pages.home', routes: ['/'], loader: () => import('./locales/fr-CA/pages/home.json') },

    { locale: 'es-MX', key: 'pages.about', routes: ['/about'], loader: () => import('./locales/es-MX/pages/about.json') },
    { locale: 'en-US', key: 'pages.about', routes: ['/about'], loader: () => import('./locales/en-US/pages/about.json') },
    { locale: 'fr-CA', key: 'pages.about', routes: ['/about'], loader: () => import('./locales/fr-CA/pages/about.json') },

    { locale: 'es-MX', key: 'pages.contact', routes: ['/contact'], loader: () => import('./locales/es-MX/pages/contact.json') },
    { locale: 'en-US', key: 'pages.contact', routes: ['/contact'], loader: () => import('./locales/en-US/pages/contact.json') },
    { locale: 'fr-CA', key: 'pages.contact', routes: ['/contact'], loader: () => import('./locales/fr-CA/pages/contact.json') },




    // STORYBOOK PAGES
{ locale: 'es-MX', key: 'pages.stories', routes: ['/stories'], loader: () => import('./locales/es-MX/pages/stories.json') },
{ locale: 'en-US', key: 'pages.stories', routes: ['/stories'], loader: () => import('./locales/en-US/pages/stories.json') },
{ locale: 'fr-CA', key: 'pages.stories', routes: ['/stories'], loader: () => import('./locales/fr-CA/pages/stories.json') },

  ],
};

export const { t, locale, locales, loading, loadTranslations } = new i18n(config);

