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
    // ───────────────────────────────────────
    // COMMON STRINGS (shared across all pages) - Load for each route
    // ───────────────────────────────────────
    { locale: 'es-MX', key: 'common', routes: ['/'], loader: () => import('./locales/es-MX/common.json') },
    { locale: 'en-US', key: 'common', routes: ['/'], loader: () => import('./locales/en-US/common.json') },
    { locale: 'fr-CA', key: 'common', routes: ['/'], loader: () => import('./locales/fr-CA/common.json') },

    { locale: 'es-MX', key: 'common', routes: ['/about'], loader: () => import('./locales/es-MX/common.json') },
    { locale: 'en-US', key: 'common', routes: ['/about'], loader: () => import('./locales/en-US/common.json') },
    { locale: 'fr-CA', key: 'common', routes: ['/about'], loader: () => import('./locales/fr-CA/common.json') },

    { locale: 'es-MX', key: 'common', routes: ['/blog'], loader: () => import('./locales/es-MX/common.json') },
    { locale: 'en-US', key: 'common', routes: ['/blog'], loader: () => import('./locales/en-US/common.json') },
    { locale: 'fr-CA', key: 'common', routes: ['/blog'], loader: () => import('./locales/fr-CA/common.json') },

    { locale: 'es-MX', key: 'common', routes: ['/books'], loader: () => import('./locales/es-MX/common.json') },
    { locale: 'en-US', key: 'common', routes: ['/books'], loader: () => import('./locales/en-US/common.json') },
    { locale: 'fr-CA', key: 'common', routes: ['/books'], loader: () => import('./locales/fr-CA/common.json') },

    { locale: 'es-MX', key: 'common', routes: ['/reviews'], loader: () => import('./locales/es-MX/common.json') },
    { locale: 'en-US', key: 'common', routes: ['/reviews'], loader: () => import('./locales/en-US/common.json') },
    { locale: 'fr-CA', key: 'common', routes: ['/reviews'], loader: () => import('./locales/fr-CA/common.json') },

    { locale: 'es-MX', key: 'common', routes: ['/book-review'], loader: () => import('./locales/es-MX/common.json') },
    { locale: 'en-US', key: 'common', routes: ['/book-review'], loader: () => import('./locales/en-US/common.json') },
    { locale: 'fr-CA', key: 'common', routes: ['/book-review'], loader: () => import('./locales/fr-CA/common.json') },

    { locale: 'es-MX', key: 'common', routes: ['/privacy'], loader: () => import('./locales/es-MX/common.json') },
    { locale: 'en-US', key: 'common', routes: ['/privacy'], loader: () => import('./locales/en-US/common.json') },
    { locale: 'fr-CA', key: 'common', routes: ['/privacy'], loader: () => import('./locales/fr-CA/common.json') },

    { locale: 'es-MX', key: 'common', routes: ['/admin'], loader: () => import('./locales/es-MX/common.json') },
    { locale: 'en-US', key: 'common', routes: ['/admin'], loader: () => import('./locales/en-US/common.json') },
    { locale: 'fr-CA', key: 'common', routes: ['/admin'], loader: () => import('./locales/fr-CA/common.json') },

    { locale: 'es-MX', key: 'common', routes: ['/stories'], loader: () => import('./locales/es-MX/common.json') },
    { locale: 'en-US', key: 'common', routes: ['/stories'], loader: () => import('./locales/en-US/common.json') },
    { locale: 'fr-CA', key: 'common', routes: ['/stories'], loader: () => import('./locales/fr-CA/common.json') },

    { locale: 'es-MX', key: 'common', routes: ['/stories/chapter1'], loader: () => import('./locales/es-MX/common.json') },
    { locale: 'en-US', key: 'common', routes: ['/stories/chapter1'], loader: () => import('./locales/en-US/common.json') },
    { locale: 'fr-CA', key: 'common', routes: ['/stories/chapter1'], loader: () => import('./locales/fr-CA/common.json') },

    // Add more story chapters as needed...

    // ───────────────────────────────────────
    // MAIN SITE PAGES (from your existing structure)
    // ───────────────────────────────────────
    { locale: 'es-MX', key: 'pages.home', routes: ['/'], loader: () => import('./locales/es-MX/pages/home.json') },
    { locale: 'en-US', key: 'pages.home', routes: ['/'], loader: () => import('./locales/en-US/pages/home.json') },
    { locale: 'fr-CA', key: 'pages.home', routes: ['/'], loader: () => import('./locales/fr-CA/pages/home.json') },

    { locale: 'es-MX', key: 'pages.about', routes: ['/about'], loader: () => import('./locales/es-MX/pages/about.json') },
    { locale: 'en-US', key: 'pages.about', routes: ['/about'], loader: () => import('./locales/en-US/pages/about.json') },
    { locale: 'fr-CA', key: 'pages.about', routes: ['/about'], loader: () => import('./locales/fr-CA/pages/about.json') },

    { locale: 'es-MX', key: 'pages.blog', routes: ['/blog'], loader: () => import('./locales/es-MX/pages/blog.json') },
    { locale: 'en-US', key: 'pages.blog', routes: ['/blog'], loader: () => import('./locales/en-US/pages/blog.json') },
    { locale: 'fr-CA', key: 'pages.blog', routes: ['/blog'], loader: () => import('./locales/fr-CA/pages/blog.json') },

    { locale: 'es-MX', key: 'pages.books', routes: ['/books'], loader: () => import('./locales/es-MX/pages/books.json') },
    { locale: 'en-US', key: 'pages.books', routes: ['/books'], loader: () => import('./locales/en-US/pages/books.json') },
    { locale: 'fr-CA', key: 'pages.books', routes: ['/books'], loader: () => import('./locales/fr-CA/pages/books.json') },

    { locale: 'es-MX', key: 'pages.reviews', routes: ['/reviews'], loader: () => import('./locales/es-MX/pages/reviews.json') },
    { locale: 'en-US', key: 'pages.reviews', routes: ['/reviews'], loader: () => import('./locales/en-US/pages/reviews.json') },
    { locale: 'fr-CA', key: 'pages.reviews', routes: ['/reviews'], loader: () => import('./locales/fr-CA/pages/reviews.json') },

    { locale: 'es-MX', key: 'pages.bookReview', routes: ['/book-review'], loader: () => import('./locales/es-MX/pages/bookReview.json') },
    { locale: 'en-US', key: 'pages.bookReview', routes: ['/book-review'], loader: () => import('./locales/en-US/pages/bookReview.json') },
    { locale: 'fr-CA', key: 'pages.bookReview', routes: ['/book-review'], loader: () => import('./locales/fr-CA/pages/bookReview.json') },

    { locale: 'es-MX', key: 'pages.privacy', routes: ['/privacy'], loader: () => import('./locales/es-MX/pages/privacy.json') },
    { locale: 'en-US', key: 'pages.privacy', routes: ['/privacy'], loader: () => import('./locales/en-US/pages/privacy.json') },
    { locale: 'fr-CA', key: 'pages.privacy', routes: ['/privacy'], loader: () => import('./locales/fr-CA/pages/privacy.json') },

    { locale: 'es-MX', key: 'pages.admin', routes: ['/admin'], loader: () => import('./locales/es-MX/pages/admin.json') },
    { locale: 'en-US', key: 'pages.admin', routes: ['/admin'], loader: () => import('./locales/en-US/pages/admin.json') },
    { locale: 'fr-CA', key: 'pages.admin', routes: ['/admin'], loader: () => import('./locales/fr-CA/pages/admin.json') },

    // ───────────────────────────────────────
    // STORYBOOK PAGES (new interactive content)
    // ───────────────────────────────────────
    { locale: 'es-MX', key: 'stories.home', routes: ['/stories'], loader: () => import('./locales/es-MX/stories/home.json') },
    { locale: 'en-US', key: 'stories.home', routes: ['/stories'], loader: () => import('./locales/en-US/stories/home.json') },
    { locale: 'fr-CA', key: 'stories.home', routes: ['/stories'], loader: () => import('./locales/fr-CA/stories/home.json') },

    { locale: 'es-MX', key: 'stories.chapter1', routes: ['/stories/chapter1'], loader: () => import('./locales/es-MX/stories/chapter1.json') },
    { locale: 'en-US', key: 'stories.chapter1', routes: ['/stories/chapter1'], loader: () => import('./locales/en-US/stories/chapter1.json') },
    { locale: 'fr-CA', key: 'stories.chapter1', routes: ['/stories/chapter1'], loader: () => import('./locales/fr-CA/stories/chapter1.json') },

    // Add more story chapters as needed...
  ],
};

export const { t, locale, locales, loading, loadTranslations } = new i18n(config);
