<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';

  onMount(() => {
    // If someone tries to go to /admin/login, send them to /admin
    // Cloudflare Access will catch them at /admin if they aren't logged in.
    goto('/admin', { replaceState: true });
  });
</script>
