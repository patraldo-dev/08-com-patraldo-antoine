      // 6. NOW set ready (don't wait for subscription)
      isReady = true;

      // 7. Suppress Cloudflare Stream beacon errors (browser only)
      if (browser) {
        const originalError = console.error;
        console.error = function(...args) {
          if (args[0] && typeof args[0] === 'string' &&
              args[0].includes('cloudflarestream.com/cdn-cgi/beacon/media')) {
            return; // Suppress Cloudflare beacon errors
          }
          originalError.apply(console, args);
        };

        // Also handle uncaught errors from Stream iframes
        window.addEventListener('error', (event) => {
          if (event.target && event.target.src && 
              event.target.src.includes('cloudflarestream.com/cdn-cgi/beacon/media')) {
            event.preventDefault();
          }
        });
      }

     // 8. Handle locale changes with proper cleanup
      const unsubscribeLocale = locale.subscribe(async (newLang) => {
        if (newLang && ['es', 'en', 'fr'].includes(newLang) && newLang !== lang) {
          lang = newLang;
          localStorage.setItem('preferredLanguage', newLang);
          isReady = false;
          // ... rest of your locale change logic ...
        }
      });

      // 9. Cleanup - return unsubscribe function
      return () => {
        unsubscribeLocale();
      };

    } catch (error) {
      console.error('i18n error:', error);
      isReady = true;
    }
  });
