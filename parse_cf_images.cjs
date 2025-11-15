```javascript
// parse_cf_images.cjs
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process'); // To run wrangler command

// --- Configuration ---
// Replace 'your_actual_database_name_or_uuid' with the identifier from your wrangler.toml file
// This should be the value you used for 'database_name' or 'database_id' in the [[ d1_databases ]] section.
const DATABASE_IDENTIFIER = "ARTWORKS_DB"; // e.g., "my-artwork-db" or "12345678-1234-1234-1234-123456789012"
// --- End Configuration ---

// Read the JSON file saved from the API call
const jsonPath = path.join(__dirname, 'cf_images.txt');
const rawData = fs.readFileSync(jsonPath, 'utf8');

// Parse the JSON
let data;
try {
  data = JSON.parse(rawData);
} catch (e) {
  console.error("Error parsing JSON:", e.message);
  process.exit(1);
}

// Extract the images array
const images = data.result.images;

// --- Query D1 for existing image_ids ---
console.log("Querying D1 database for existing image_ids...");
let existingIds = new Set();
try {
  // Use wrangler to execute the D1 query, using the hardcoded DATABASE_IDENTIFIER
  const queryResult = execSync(`npx wrangler d1 execute "${DATABASE_IDENTIFIER}" --command "SELECT image_id FROM artworks;" --json`, { encoding: 'utf-8' });
  const parsedQueryResult = JSON.parse(queryResult);

  if (parsedQueryResult && Array.isArray(parsedQueryResult[0]?.results)) {
    existingIds = new Set(parsedQueryResult[0].results.map(row => row.image_id));
    console.log(`Found ${existingIds.size} existing image_ids in D1.`);
  } else {
    console.warn("D1 query did not return expected results array structure:", parsedQueryResult);
    // Proceed with an empty set if query fails, meaning all CF images will be considered new.
  }
} catch (e) {
  console.error("Error querying D1:", e.message);
  console.error("Error stderr:", e.stderr); // Capture stderr from wrangler
  console.log("Proceeding assuming no existing IDs were found in D1.");
  // Proceed with an empty set if query fails, meaning all CF images will be considered new.
}

// --- Filter Cloudflare images to find new ones ---
console.log("Filtering Cloudflare Images API results against D1...");
const cfImageIds = new Set(images.map(img => img.id));
const newImageIds = [...cfImageIds].filter(id => !existingIds.has(id));
const newImages = images.filter(img => newImageIds.includes(img.id));

console.log(`Found ${newImages.length} new images in Cloudflare Images not present in D1.`);

// Define a simple mapping function (you can customize this)
function mapImageToArtwork(img) {
  // Basic title from filename (remove extension)
  let title = img.filename.replace(/\.[^/.]+$/, "");
  // Capitalize first letter
  title = title.charAt(0).toUpperCase() + title.slice(1);

  // Basic type guess based on extension
  let type = 'still'; // Default
  if (img.filename.toLowerCase().endsWith('.gif')) {
    type = 'gif';
  } else if (img.filename.toLowerCase().endsWith('.webm') || img.filename.toLowerCase().endsWith('.mp4')) {
    type = 'animation'; // Assuming video files are handled as animations for now
  }

  // Basic description
  const description = `Uploaded on ${img.uploaded.split('T')[0]}. Filename: ${img.filename}`;

  // Basic year from upload date
  const year = parseInt(img.uploaded.split('-')[0]);

  return {
    image_id: img.id,
    filename: img.filename,
    title: title,
    type: type,
    description: description,
    year: year,
    published: 1, // Set to 1 to publish immediately, or 0 to hide initially
    order_index: 999 // Placeholder, you can update this manually later based on preference
  };
}

// Map only the NEW images
const mappedArtworks = newImages.map(mapImageToArtwork);

// Generate CSV content for NEW images only
const headers = ['image_id', 'filename', 'title', 'type', 'description', 'year', 'published', 'order_index'];
const csvRows = [headers.join(',')]; // Add header row

mappedArtworks.forEach(artwork => {
  // Basic CSV escaping (handles commas, quotes, newlines in fields)
  const escapedValues = Object.values(artwork).map(field => {
    if (typeof field === 'string' && (field.includes(',') || field.includes('"') || field.includes('\n'))) {
      return `"${field.replace(/"/g, '""')}"`; // Escape quotes by doubling them
    }
    return field;
  });
  csvRows.push(escapedValues.join(','));
});

const csvContent = csvRows.join('\n');

// Write the CSV file for NEW images only
const outputPath = path.join(__dirname, 'cf_images_mapping_new_only.csv');
fs.writeFileSync(outputPath, csvContent);

console.log(`✅ Mapping CSV for NEW images created: ${outputPath}`);

// Optional: Also generate INSERT statements for NEW images only
const insertStatements = mappedArtworks.map(artwork => {
  // Basic SQL escaping for single quotes (CRITICAL: Be very careful with user input)
  const escapedTitle = artwork.title.replace(/'/g, "''");
  const escapedDescription = artwork.description.replace(/'/g, "''");

  return `INSERT INTO artworks (title, type, image_id, description, year, published, order_index) VALUES ('${escapedTitle}', '${artwork.type}', '${artwork.image_id}', '${escapedDescription}', ${artwork.year}, ${artwork.published}, ${artwork.order_index});`;
});

// Write INSERT statements for NEW images only to a file
const insertOutputPath = path.join(__dirname, 'insert_new_artworks_from_cf.sql');
fs.writeFileSync(insertOutputPath, insertStatements.join('\n'));

console.log(`✅ INSERT statements for NEW images created: ${insertOutputPath}`);
console.log(`💡 Review the generated files before executing the SQL.`);
```
