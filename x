// src/routes/+layout.js
import { loadTranslations, locale } from '$lib/translations';

export const load = async ({ url, data }) => {
  const { pathname } = url;
  
  // Only run in browser
  if (typeof window !== 'undefined') {
    // Get saved preference or use fallback
    const savedLocale = 
      localStorage.getItem('preferredLanguage') || 
      getCookie('preferredLanguage') || 
      'es';
    
    console.log('🌍 Loading locale:', savedLocale, 'for path:', pathname);
    
    // Load translations with explicit locale
    await loadTranslations(savedLocale, pathname);
    
    // Set locale AFTER loading
    locale.set(savedLocale);
  }
  
  return {
    ...data
  };
};

function getCookie(name) {
  if (typeof document === 'undefined') return null;
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) return parts.pop().split(';').shift();
  return null;
}
