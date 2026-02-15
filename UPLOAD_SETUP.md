# Environment Variables Required for Artwork Upload

To use the artwork upload functionality, you need to set the following environment variables in your Cloudflare Workers environment:

## Required Variables

- `CLOUDFLARE_API_TOKEN`: Your Cloudflare API token with Images permissions
- `CLOUDFLARE_ACCOUNT_ID`: Your Cloudflare Account ID

## Setting Up Environment Variables

### Using Wrangler CLI

```bash
# Set secrets using wrangler
wrangler secret put CLOUDFLARE_API_TOKEN
wrangler secret put CLOUDFLARE_ACCOUNT_ID
```

### Required API Token Permissions

Your Cloudflare API token needs the following permissions:
- Account Resources: All Cloudflare Accounts (or specific account)
- Zone Resources: All zones (or specific zone if needed)
- Account Settings: None required
- Products:
  - Cloudflare Images: Edit (includes read permissions)

### Creating an API Token

1. Go to your Cloudflare dashboard
2. Navigate to "My Profile" > "API Tokens"
3. Click "Create Token"
4. Use the "Edit Cloudflare Images" template or create a custom token with:
   - Permission: Account / Cloudflare Images / Edit
   - Resource: Account / Include / Specific Account / [Your Account ID]

## Database Schema

Make sure your database has all required columns in the artworks table:
- `display_name` TEXT
- `video_id` TEXT  
- `published` BOOLEAN DEFAULT 1
- `order_index` INTEGER DEFAULT 999
- `story_enabled` BOOLEAN DEFAULT 0
- `story_intro` TEXT

Run the update-artworks-table.sql migration to add missing columns if needed.