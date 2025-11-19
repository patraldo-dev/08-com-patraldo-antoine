// src/routes/+layout.js
import { loadTranslations } from '$lib/translations';
import { browser } from '$app/environment';

export const load = async ({ url, data }) => {
  const { pathname } = url;
  
  // Load translations for the current route
  if (browser) {
    await loadTranslations(pathname);
  }
  
  return {
    ...data
  };
};
