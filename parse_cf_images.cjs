// parse_cf_images.js
const fs = require('fs');
const path = require('path');

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

// Map all images
const mappedArtworks = images.map(mapImageToArtwork);

// Generate CSV content
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

// Write the CSV file
const outputPath = path.join(__dirname, 'cf_images_mapping.csv');
fs.writeFileSync(outputPath, csvContent);

console.log(`✅ Mapping CSV created: ${outputPath}`);

// Optional: Also generate INSERT statements directly
const insertStatements = mappedArtworks.map(artwork => {
  // Basic SQL escaping for single quotes (CRITICAL: Be very careful with user input)
  const escapedTitle = artwork.title.replace(/'/g, "''");
  const escapedDescription = artwork.description.replace(/'/g, "''");

  return `INSERT INTO artworks (title, type, image_id, description, year, published, order_index) VALUES ('${escapedTitle}', '${artwork.type}', '${artwork.image_id}', '${escapedDescription}', ${artwork.year}, ${artwork.published}, ${artwork.order_index});`;
});

// Write INSERT statements to a file
const insertOutputPath = path.join(__dirname, 'insert_artworks_from_cf.sql');
fs.writeFileSync(insertOutputPath, insertStatements.join('\n'));

console.log(`✅ INSERT statements created: ${insertOutputPath}`);
console.log(`💡 Review the generated files before executing the SQL.`);
