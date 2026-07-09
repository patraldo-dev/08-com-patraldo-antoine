<!--
	src/routes/worlds/+page.svelte — Antoine's Worlds & Portals.

	Boots the IWSDK ECS engine: a set of themed worlds connected by portals,
	where each portal is a framed Antoine artwork that opens into another world.
	Runs flat on the page (xr: offer 'none') — the precursor-to-VR mode.
-->
<script>
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { t } from '$lib/i18n';

  const { data } = $props();
  /** @type {{ artworks?: any[], startWorld?: string|null, cfHash?: string }} */
  const d = data ?? {};

  /** @type {HTMLDivElement | null} */
  let containerEl = $state(null);
  let booted = $state(false);
  let bootError = $state('');

  // The world ids available as static configs under /worlds/*.json
  const WORLD_IDS = ['cosmos', 'jardin', 'ciudad', 'fiesta', 'reyes'];

  onMount(() => {
    let cancelled = false;

    async function boot() {
      try {
        if (!containerEl) throw new Error('Scene container not ready');

        // Load all world configs (static JSON).
        /** @type {Record<string, any>} */
        const configs = {};
        for (const id of WORLD_IDS) {
          try {
            const resp = await fetch(`/worlds/${id}.json`);
            if (resp.ok) configs[id] = await resp.json();
          } catch {
            /* ignore individual fetch failures */
          }
        }

        if (Object.keys(configs).length === 0) {
          throw new Error('No world configs found');
        }

        // Resolve the start world: ?world= query, then a random pick so each
        // visit is a small surprise.
        const queryWorld = (d.startWorld && configs[d.startWorld])
          ? d.startWorld
          : null;
        const candidates = WORLD_IDS.filter((id) => configs[id]);
        const startWorld = queryWorld
          || candidates[Math.floor(Math.random() * candidates.length)];

        // Dynamic import keeps IWSDK in a client-only chunk.
        const { bootWorldEngine } = await import('$lib/worlds-ecs/world-builder.js');

        await bootWorldEngine(containerEl, configs, d.artworks || [], startWorld);
        if (cancelled) return;
        booted = true;
      } catch (/** @type {any} */ err) {
        console.error('[worlds] boot failed:', err);
        bootError = err?.message || String(err);
      }
    }

    boot();

    return () => {
      cancelled = true;
    };
  });
</script>

<svelte:head>
  <title>{$t('pages.worlds.metaTitle')}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
</svelte:head>

<svelte:window />

<!-- Fullscreen scene container -->
<div
  id="worlds-scene"
  bind:this={containerEl}
></div>

<!-- Boot error fallback -->
{#if bootError}
  <div class="boot-error">
    <div class="boot-error-card">
      <span class="boot-error-icon">⚠</span>
      <p>{$t('pages.worlds.bootError')}</p>
      <code>{bootError}</code>
      <a href="/" class="boot-error-back">← {$t('common.navhome')}</a>
    </div>
  </div>
{/if}

<!-- Loading state -->
{#if !booted && !bootError}
  <div class="boot-loading">
    <div class="boot-loading-orb"></div>
    <p>{$t('pages.worlds.title')}</p>
  </div>
{/if}

<!-- Hint overlay (hidden once booted to keep the canvas clean) -->
{#if booted}
  <div class="hint-overlay">
    <span>{$t('pages.worlds.tapHint')}</span>
  </div>
{/if}

<style>
  /* Fullscreen, dark — the worlds own the whole viewport. */
  :global(body:has(#worlds-scene)) {
    overflow: hidden !important;
  }

  #worlds-scene {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    z-index: 1;
    background: #05030a;
  }

  :global(#worlds-scene canvas) {
    display: block;
    width: 100% !important;
    height: 100% !important;
    touch-action: none;
  }

  .boot-error {
    position: fixed;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #05030a;
    z-index: 100;
    padding: 2rem;
  }

  .boot-error-card {
    max-width: 460px;
    text-align: center;
    color: #e8d5b5;
    font-family: 'Georgia', serif;
  }

  .boot-error-icon {
    font-size: 2.5rem;
    display: block;
    margin-bottom: 1rem;
  }

  .boot-error-card p {
    font-size: 1.1rem;
    margin: 0 0 1rem;
  }

  .boot-error-card code {
    display: block;
    font-family: 'Courier New', monospace;
    font-size: 0.85rem;
    color: #ff8a8a;
    background: rgba(255, 255, 255, 0.05);
    padding: 0.75rem;
    border-radius: 6px;
    margin-bottom: 1.5rem;
    word-break: break-word;
  }

  .boot-error-back {
    color: #d4c9a8;
    text-decoration: none;
    font-size: 0.95rem;
    border-bottom: 1px solid transparent;
    transition: border-color 0.2s;
  }

  .boot-error-back:hover {
    border-color: #d4c9a8;
  }

  /* Loading state */
  .boot-loading {
    position: fixed;
    inset: 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 1.5rem;
    background: #05030a;
    z-index: 50;
    color: #d4c9a8;
    font-family: 'Georgia', serif;
    font-size: 1.1rem;
    letter-spacing: 0.08em;
  }

  .boot-loading-orb {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    border: 2px solid rgba(212, 201, 168, 0.2);
    border-top-color: #d4c9a8;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  /* Tap hint, auto-fades after the visitor has had a moment. */
  .hint-overlay {
    position: fixed;
    bottom: 1.5rem;
    left: 50%;
    transform: translateX(-50%);
    z-index: 10;
    pointer-events: none;
    color: rgba(212, 201, 168, 0.6);
    font-family: 'Georgia', serif;
    font-size: 0.85rem;
    letter-spacing: 0.06em;
    animation: hintFade 8s ease-in-out forwards;
  }

  @keyframes hintFade {
    0% { opacity: 0; }
    10%, 70% { opacity: 1; }
    100% { opacity: 0; }
  }
</style>
