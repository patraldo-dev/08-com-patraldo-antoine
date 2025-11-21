// src/routes/+layout.js
import { loadTranslations, locale } from '$lib/translations';
import { browser } from '$app/environment';

export const load = async ({ url, data }) => {
  const { pathname } = url;
  
  if (browser) {
    // Get saved language preference BEFORE loading translations
    const savedLocale = 
      localStorage.getItem('preferredLanguage') || 
      getCookie('preferredLanguage') || 
      'es'; // fallback to Spanish
    
    // Set the locale first
    locale.set(savedLocale);
    
    // Then load translations for current route
    await loadTranslations(pathname);
  }
  
  return {
    ...data
  };
};

// Helper to read cookie
function getCookie(name) {
  if (typeof document === 'undefined') return null;
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) return parts.pop().split(';').shift();
  return null;
}
