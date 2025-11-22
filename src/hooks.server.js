// src/hooks.server.js
/**
 * @typedef {import('@sveltejs/kit').Handle} Handle
 */

import { paraglideMiddleware } from '$lib/paraglide/server';

/** @type {Handle} */
export const handle = ({ event, resolve }) =>
	paraglideMiddleware(event.request, ({ request: localizedRequest, locale }) => {
		event.request = localizedRequest;
		return resolve(event, {
			transformPageChunk: ({ html }) => html.replace('%lang%', locale)
		});
	});
