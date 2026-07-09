// See https://svelte.dev/docs/kit/types#app.d.ts
// for information about these interfaces
declare global {
	namespace App {
		interface Error {}

		// Set in src/hooks.server.js. These mirror exactly what the hooks assign;
		// typed loosely (where upstream Cloudflare/D1 types are missing) so strict
		// checkJs stops flagging every access while still catching real mistakes.
		interface Locals {
			user: {
				id: string | number;
				username: string;
				email: string | null;
				role: string;
			} | null;
			isAdmin: boolean;
			session: any; // session object from validateSession(), or null
			locale?: 'en' | 'es' | 'fr';
		}

		// Common PageData returned by +layout.server.js and individual loaders.
		// Kept permissive so route-specific fields still type-check.
		interface PageData {
			preferredLanguage?: string;
			isAdmin?: boolean;
			username?: string | null;
			artworks?: any[];
			videos?: any[];
			form?: any;
			[key: string]: any;
		}

		interface PageState {}

		// Cloudflare Workers bindings via adapter-cloudflare. `env` is typed as
		// any because there's no generated worker-configuration.d.ts in this
		// project and the bindings (ARTWORKS_DB, stories_db, DB_users, …) are
		// declared in wrangler.jsonc, not reflected in TS types.
		interface Platform {
			env: any;
		}
	}
}

export {};
