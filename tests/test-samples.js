// Test samples round-trip

const fs = require('fs');
const path = require('path');
const { encode, decode } = require('../dist/index.js');

function testSample(jsonPath) {
  const toonPath = jsonPath.replace('.json', '.toon');

  // Check if both files exist
  if (!fs.existsSync(toonPath)) {
    return { name: path.basename(jsonPath), status: 'skip', reason: 'No TOON file' };
  }

  const jsonData = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  const toonExpected = fs.readFileSync(toonPath, 'utf8');

  // Test encoding
  const encoded = encode(jsonData);
  const encodeMatch = encoded === toonExpected;

  // Test decoding
  const decoded = decode(toonExpected);
  const decodeMatch = JSON.stringify(jsonData) === JSON.stringify(decoded);

  // Test round-trip
  const roundTrip = JSON.stringify(jsonData) === JSON.stringify(decode(encode(jsonData)));

  return {
    name: path.basename(jsonPath),
    encodeMatch,
    decodeMatch,
    roundTrip,
    status: (encodeMatch && decodeMatch && roundTrip) ? 'pass' : 'fail'
  };
}

// Find all JSON sample files
const samplesDir = path.join(__dirname, '..', 'samples');
const categories = ['simple', 'complex', 'edge-cases'];
const results = [];

console.log('=== TESTING SAMPLE FILES ===\n');

categories.forEach(category => {
  const categoryPath = path.join(samplesDir, category);

  if (!fs.existsSync(categoryPath)) {
    return;
  }

  const files = fs.readdirSync(categoryPath)
    .filter(f => f.endsWith('.json'))
    .sort();

  files.forEach(file => {
    const jsonPath = path.join(categoryPath, file);
    const result = testSample(jsonPath);
    results.push({ category, ...result });

    if (result.status === 'skip') {
      console.log(`⊘ ${category}/${result.name} - ${result.reason}`);
    } else if (result.status === 'pass') {
      console.log(`✓ ${category}/${result.name}`);
    } else {
      console.log(`✗ ${category}/${result.name}`);
      if (!result.encodeMatch) console.log('  - Encode mismatch');
      if (!result.decodeMatch) console.log('  - Decode mismatch');
      if (!result.roundTrip) console.log('  - Round-trip failed');
    }
  });
});

const passed = results.filter(r => r.status === 'pass').length;
const failed = results.filter(r => r.status === 'fail').length;
const skipped = results.filter(r => r.status === 'skip').length;
const total = results.length;

console.log(`\n=== SUMMARY ===`);
console.log(`Total: ${total}`);
console.log(`Passed: ${passed}`);
console.log(`Failed: ${failed}`);
console.log(`Skipped: ${skipped}`);
console.log(`Success rate: ${total > 0 ? ((passed / (passed + failed)) * 100).toFixed(1) : 0}%`);
