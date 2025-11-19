// src/routes/+layout.js
import { loadTranslations } from '$lib/translations';

export const load = async ({ url, data }) => {
  const { pathname } = url;
  
  // Get locale from cookie/localStorage, or use fallback
  const getInitialLocale = () => {
    if (typeof document !== 'undefined') {
      return localStorage.getItem('preferredLanguage') || 'es';
    }
    return 'es'; // Server fallback
  };
  
  const initLocale = getInitialLocale();
  
  // Load translations for BOTH server and client
  await loadTranslations(initLocale, pathname);
  
  return {
    ...data
  };
};
