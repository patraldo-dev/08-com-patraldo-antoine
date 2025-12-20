// scripts/generate-routes.js
import { readdirSync, statSync, writeFileSync } from 'fs';
import { join } from 'path';

const ROUTES_DIR = 'src/routes';
const OUTPUT_FILE = 'src/lib/generated-routes.json';

// Routes to exclude from sitemap
const EXCLUDE_PATTERNS = [
  /^api\//,           // API routes
  /^admin\//,         // Admin routes
  /\[.*\]/,           // Dynamic routes like [id]
  /^\+/,              // SvelteKit files (+page, +layout, etc)
  /^subscription-confirmed/, // One-time pages
  /^verify/,          // Utility pages
];

// Special route configurations
const ROUTE_CONFIG = {
  '': { priority: '1.0', changefreq: 'daily' },
  'collection': { priority: '0.9', changefreq: 'weekly' },
  'cine': { priority: '0.8', changefreq: 'weekly' },
  'cine/gallery': { priority: '0.8', changefreq: 'weekly' },
  'stories': { priority: '0.7', changefreq: 'weekly' },
  'tools': { priority: '0.6', changefreq: 'monthly' },
  // Tool pages get default config below
};

function shouldExclude(path) {
  return EXCLUDE_PATTERNS.some(pattern => pattern.test(path));
}

function scanDirectory(dir, baseRoute = '') {
  const routes = [];
  
  try {
    const items = readdirSync(dir);
    
    for (const item of items) {
      const fullPath = join(dir, item);
      const stat = statSync(fullPath);
      
      if (stat.isDirectory()) {
        // Build the route path
        const routePath = baseRoute ? `${baseRoute}/${item}` : item;
        
        // Skip excluded patterns
        if (shouldExclude(routePath)) {
          continue;
        }
        
        // Check if directory has a +page.svelte (makes it a valid route)
        const hasPage = items.includes('+page.svelte') || items.includes('+page.server.js');
        
        if (hasPage && !baseRoute.includes(item)) {
          // This is a valid route
          const config = ROUTE_CONFIG[routePath] || getDefaultConfig(routePath);
          routes.push({
            url: routePath,
            ...config
          });
        }
        
        // Recursively scan subdirectories
        routes.push(...scanDirectory(fullPath, routePath));
      }
    }
  } catch (error) {
    console.error(`Error scanning ${dir}:`, error.message);
  }
  
  return routes;
}

function getDefaultConfig(route) {
  // Default configurations based on route patterns
  if (route.startsWith('tools/')) {
    return { priority: '0.6', changefreq: 'weekly' };
  }
  if (route.startsWith('cine/')) {
    return { priority: '0.7', changefreq: 'weekly' };
  }
  if (route.startsWith('stories/')) {
    return { priority: '0.7', changefreq: 'monthly' };
  }
  
  // Default for everything else
  return { priority: '0.5', changefreq: 'monthly' };
}

function generateRoutes() {
  console.log('🔍 Scanning routes directory...');
  
  const routes = scanDirectory(ROUTES_DIR);
  
  // Add root route
  routes.unshift({
    url: '',
    ...ROUTE_CONFIG['']
  });
  
  // Sort by priority (highest first), then alphabetically
  routes.sort((a, b) => {
    const priorityDiff = parseFloat(b.priority) - parseFloat(a.priority);
    if (priorityDiff !== 0) return priorityDiff;
    return a.url.localeCompare(b.url);
  });
  
  // Remove duplicates
  const uniqueRoutes = routes.filter((route, index, self) =>
    index === self.findIndex(r => r.url === route.url)
  );
  
  // Write to file
  writeFileSync(
    OUTPUT_FILE,
    JSON.stringify(uniqueRoutes, null, 2),
    'utf-8'
  );
  
  console.log(`✅ Generated ${uniqueRoutes.length} routes`);
  console.log(`📝 Written to ${OUTPUT_FILE}`);
  
  // Log discovered routes
  console.log('\n📋 Discovered routes:');
  uniqueRoutes.forEach(route => {
    const url = route.url || '/';
    console.log(`  - ${url} (priority: ${route.priority}, changefreq: ${route.changefreq})`);
  });
}

// Run the script
generateRoutes();
