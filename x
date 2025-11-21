import i18n from 'sveltekit-i18n';
import { browser } from '$app/environment';

const config = { fallbackLocale: 'es', loaders: [ /* your loaders */ ] };

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

