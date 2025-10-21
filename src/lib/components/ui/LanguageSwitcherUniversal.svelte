<!-- src/lib/components/ui/LanguageSwitcher.svelte -->
<script>
  import LanguageSwitcherDesktop from './LanguageSwitcherDesktop.svelte';
  import LanguageSwitcherMobile from './LanguageSwitcherMobile.svelte';
</script>

<div class="language-switcher">
  <LanguageSwitcherDesktop />
  <LanguageSwitcherMobile />
</div>

<style>
  .language-switcher {
    display: none;
  }

  @media (min-width: 769px) {
    .language-switcher :global(.language-switcher-mobile) {
      display: none;
    }
  }

  @media (max-width: 768px) {
    .language-switcher :global(.language-switcher-desktop) {
      display: none;
    }
  }
</style>
