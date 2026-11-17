// src/routes/api/search/+server.js
//
// First-party site search backed by the account's AI Search instance
// (proud-wildflower-e16c, web-crawler over this site, hybrid retrieval).
// Replaces the dead wizard-deployed NLWeb worker the dropdown used to
// load from a *.workers.dev domain that no longer exists.
//
// GET /api/search?q=…  → { query, results: [{url, title?, description,
//                        snippet, score}] } — chunks grouped per page,
// best chunk wins, top 6.

import { json } from '@sveltejs/kit';
import { env } from 'cloudflare:workers';

const MAX_QUERY_CHARS = 200;
const MAX_RESULTS = 6;
const FETCH_CHUNKS = 12; // over-fetch, then group per page

/** In-isolate query cache — repeated queries cost nothing. */
const cache = new Map();
const CACHE_MAX = 64;

/** Light markdown cleanup so indexed chunks read as plain snippets. */
function toSnippet(text) {
    return (text || '')
        .replace(/#{1,6}\s*/g, '') // headings
        .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1') // links → text
        .replace(/[*_`>]/g, '')
        .replace(/\s+/g, ' ')
        .trim()
        .slice(0, 180);
}

/**
 * @type {import('./$types').RequestHandler}
 */
export async function GET({ url }) {
    const q = (url.searchParams.get('q') || '').trim().slice(0, MAX_QUERY_CHARS);
    if (q.length < 2) {
        return json({ query: q, results: [] });
    }

    const cacheKey = q.toLowerCase();
    const hit = cache.get(cacheKey);
    if (hit) return json(hit);

    const ai = env.AI_SEARCH;
    if (!ai) {
        return json({ query: q, results: [], error: 'search-unavailable' }, { status: 503 });
    }

    try {
        const res = await ai.search({
            query: q,
            ai_search_options: {
                retrieval: {
                    max_num_results: FETCH_CHUNKS,
                    // Lower than the instance default (0.4): an 11-page
                    // index needs generosity more than precision.
                    match_threshold: 0.25
                },
                cache: { enabled: true }
            }
        });

        // Group chunks by page URL — the crawler indexes several chunks
        // per page and we show one card per page, best chunk wins.
        const byPage = new Map();
        for (const chunk of res?.chunks || []) {
            const pageUrl = chunk?.item?.key;
            if (!pageUrl) continue;
            const prev = byPage.get(pageUrl);
            if (!prev || (chunk.score ?? 0) > (prev.score ?? 0)) {
                byPage.set(pageUrl, chunk);
            }
        }

        const results = [...byPage.values()]
            .sort((a, b) => (b.score ?? 0) - (a.score ?? 0))
            .slice(0, MAX_RESULTS)
            .map((c) => ({
                url: c.item.key,
                description:
                    typeof c.item?.metadata?.description === 'string'
                        ? c.item.metadata.description
                        : null,
                snippet: toSnippet(c.text),
                score: Math.round((c.score ?? 0) * 100) / 100
            }));

        const payload = { query: q, results };

        if (cache.size >= CACHE_MAX) cache.delete(cache.keys().next().value);
        cache.set(cacheKey, payload);

        return json(payload, {
            headers: { 'cache-control': 'public, max-age=60' }
        });
    } catch (/** @type {unknown} */ e) {
        const err = e instanceof Error ? e : new Error(String(e));
        console.error('[api/search] failed:', err.message);
        return json({ query: q, results: [], error: 'search-failed' }, { status: 500 });
    }
}
