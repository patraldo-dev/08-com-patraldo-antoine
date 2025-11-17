<!-- src/routes/admin/analytics/+page.svelte -->
<script>
  import { onMount } from 'svelte';
  
  let analytics = $state({ visits: [], favorites: [], countries: [] });
  let days = $state(30);
  let loading = $state(true);
  
  onMount(() => {
    loadAnalytics();
  });
  
  async function loadAnalytics() {
    loading = true;
    try {
      const res = await fetch(`/api/analytics?days=${days}`);
      analytics = await res.json();
    } catch (error) {
      console.error('Failed to load analytics:', error);
    } finally {
      loading = false;
    }
  }
  
  function handleDaysChange(event) {
    days = parseInt(event.target.value);
    loadAnalytics();
  }
</script>

<svelte:head>
  <title>Analytics Dashboard - Antoine Patraldo</title>
</svelte:head>

<div class="analytics-dashboard">
  <header>
    <h1>Analytics Dashboard</h1>
    
    <div class="controls">
      <label for="days">Time period:</label>
      <select id="days" value={days} onchange={handleDaysChange}>
        <option value="7">Last 7 days</option>
        <option value="30">Last 30 days</option>
        <option value="90">Last 90 days</option>
        <option value="365">Last year</option>
      </select>
    </div>
  </header>
  
  {#if loading}
    <div class="loading">Loading analytics...</div>
  {:else}
    <section class="stats-overview">
      <div class="stat-card">
        <h3>Total Artworks Visited</h3>
        <p class="big-number">{analytics.visits?.length || 0}</p>
      </div>
      <div class="stat-card">
        <h3>Total Favorites</h3>
        <p class="big-number">{analytics.favorites?.reduce((sum, f) => sum + (f.net_favorites || 0), 0) || 0}</p>
      </div>
      <div class="stat-card">
        <h3>Countries</h3>
        <p class="big-number">{analytics.countries?.length || 0}</p>
      </div>
    </section>
    
    <section class="data-section">
      <h2>Most Visited Artworks</h2>
      {#if analytics.visits && analytics.visits.length > 0}
        <table>
          <thead>
            <tr>
              <th>Artwork ID</th>
              <th>Total Visits</th>
              <th>Unique Visitors</th>
            </tr>
          </thead>
          <tbody>
            {#each analytics.visits as visit}
              <tr>
                <td><a href="/#artwork-{visit.artwork_id}">{visit.artwork_id}</a></td>
                <td>{visit.visit_count}</td>
                <td>{visit.unique_visitors}</td>
              </tr>
            {/each}
          </tbody>
        </table>
      {:else}
        <p class="empty">No visit data available</p>
      {/if}
    </section>
    
    <section class="data-section">
      <h2>Most Favorited Artworks</h2>
      {#if analytics.favorites && analytics.favorites.length > 0}
        <table>
          <thead>
            <tr>
              <th>Artwork ID</th>
              <th>Net Favorites</th>
            </tr>
          </thead>
          <tbody>
            {#each analytics.favorites.filter(f => f.net_favorites > 0).sort((a, b) => b.net_favorites - a.net_favorites) as fav}
              <tr>
                <td><a href="/#artwork-{fav.artwork_id}">{fav.artwork_id}</a></td>
                <td>{fav.net_favorites}</td>
              </tr>
            {/each}
          </tbody>
        </table>
      {:else}
        <p class="empty">No favorite data available</p>
      {/if}
    </section>
    
    <section class="data-section">
      <h2>Geographic Distribution</h2>
      {#if analytics.countries && analytics.countries.length > 0}
        <table>
          <thead>
            <tr>
              <th>Country</th>
              <th>Visits</th>
            </tr>
          </thead>
          <tbody>
            {#each analytics.countries as country}
              <tr>
                <td>{country.country}</td>
                <td>{country.count}</td>
              </tr>
            {/each}
          </tbody>
        </table>
      {:else}
        <p class="empty">No geographic data available</p>
      {/if}
    </section>
  {/if}
</div>

<style>
  .analytics-dashboard {
    max-width: 1200px;
    margin: 0 auto;
    padding: 6rem 2rem 4rem;
  }
  
  header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 3rem;
    flex-wrap: wrap;
    gap: 1rem;
  }
  
  h1 {
    font-size: 2.5rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0;
  }
  
  .controls {
    display: flex;
    align-items: center;
    gap: 1rem;
  }
  
  .controls label {
    font-weight: 500;
    color: #666;
  }
  
  .controls select {
    padding: 0.5rem 1rem;
    border: 2px solid #e0e0e0;
    border-radius: 6px;
    font-size: 0.95rem;
    cursor: pointer;
    background: white;
  }
  
  .loading {
    text-align: center;
    padding: 4rem;
    color: #666;
    font-size: 1.2rem;
  }
  
  .stats-overview {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
    margin-bottom: 3rem;
  }
  
  .stat-card {
    background: white;
    padding: 2rem;
    border-radius: 12px;
    border: 1px solid #e0e0e0;
    box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  }
  
  .stat-card h3 {
    font-size: 0.9rem;
    font-weight: 500;
    color: #666;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin: 0 0 1rem 0;
  }
  
  .big-number {
    font-size: 2.5rem;
    font-weight: 700;
    color: #1a1a1a;
    margin: 0;
  }
  
  .data-section {
    background: white;
    padding: 2rem;
    border-radius: 12px;
    border: 1px solid #e0e0e0;
    box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    margin-bottom: 2rem;
  }
  
  .data-section h2 {
    font-size: 1.5rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 1.5rem 0;
  }
  
  table {
    width: 100%;
    border-collapse: collapse;
  }
  
  thead {
    background: #f8f8f8;
  }
  
  th {
    text-align: left;
    padding: 1rem;
    font-weight: 600;
    color: #666;
    font-size: 0.9rem;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  
  td {
    padding: 1rem;
    border-top: 1px solid #f0f0f0;
  }
  
  td a {
    color: #1a1a1a;
    text-decoration: none;
    font-weight: 500;
  }
  
  td a:hover {
    color: #666;
    text-decoration: underline;
  }
  
  tbody tr:hover {
    background: #fafafa;
  }
  
  .empty {
    text-align: center;
    padding: 2rem;
    color: #999;
    font-style: italic;
  }
  
  @media (max-width: 768px) {
    .analytics-dashboard {
      padding: 4rem 1rem 2rem;
    }
    
    header {
      flex-direction: column;
      align-items: flex-start;
    }
    
    h1 {
      font-size: 2rem;
    }
    
    .stats-overview {
      grid-template-columns: 1fr;
    }
    
    table {
      font-size: 0.9rem;
    }
    
    th, td {
      padding: 0.75rem 0.5rem;
    }
  }
</style>
