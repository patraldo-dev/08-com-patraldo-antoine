# Antoine Patraldo - Artist Portfolio

This is a portfolio website for visual artist Antoine Patraldo, built with SvelteKit and deployed on Cloudflare Pages.

## Features

- Gallery with support for still images, videos, and animated GIFs
- Email subscription system with verification
- Responsive design for all devices
- Optimized for performance with Cloudflare's global CDN

## Setup Instructions

### Prerequisites

- Node.js (v16 or higher)
- Cloudflare account
- Resend account (for email delivery)

### Installation

1. Clone this repository and navigate to the project directory
2. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

### Database Setup

1. Create a D1 database in your Cloudflare dashboard
2. Execute the schema from \`db/schema.sql\`:
   \`\`\`bash
   npx wrangler d1 execute DB_NAME --file=./db/schema.sql
   \`\`\`
3. Update \`wrangler.jsonc\` with your database binding

### Email Setup

1. Sign up for Resend (or another email service)
2. Add your API key as a secret to your Worker:
   \`\`\`bash
   npx wrangler secret put RESEND_API_KEY
   \`\`\`
3. Set an auth token for sending announcements:
   \`\`\`bash
   npx wrangler secret put AUTH_TOKEN
   \`\`\`

### Image Storage

1. Create an R2 bucket for storing artwork
2. Set up Cloudflare Images for optimized delivery
3. Update the \`CF_IMAGES_BASE\` variable in \`src/lib/components/Gallery.svelte\`
4. Update the artwork URLs in the same file

### Deployment

1. Deploy your Worker:
   \`\`\`bash
   npx wrangler deploy
   \`\`\`
2. Deploy your SvelteKit site to Cloudflare Pages:
   \`\`\`bash
   npm run build
   # Upload the contents of the .svelte-kit/output directory to Cloudflare Pages
   \`\`\`

## Customization

### Adding Artwork

To add new artwork, update the \`artworks\` array in \`src/lib/components/Gallery.svelte\` with:
- Title
- Type (still, animation, gif)
- R2 URL for the full media
- Thumbnail ID for Cloudflare Images
- Description
- Year

### Styling

Global styles are in \`src/app.css\`. Component-specific styles are included in each Svelte component.

## License

© 2025 Antoine Patraldo. All rights reserved.
