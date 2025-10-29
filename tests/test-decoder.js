// Test script for TOON decoder

const { encode, decode } = require('../dist/index.js');

console.log('=== DECODER TESTS ===\n');

// Test 1: Simple primitives
console.log('Test 1: Simple primitives');
const toon1 = `string: hello
number: 42
float: 3.14
boolean_true: true
boolean_false: false
null: null`;
const result1 = decode(toon1);
console.log(JSON.stringify(result1, null, 2));
console.log('');

// Test 2: Simple object
console.log('Test 2: Simple object');
const toon2 = `id: 123
name: Ada
active: true`;
const result2 = decode(toon2);
console.log(JSON.stringify(result2, null, 2));
console.log('');

// Test 3: Simple array (inline)
console.log('Test 3: Simple array (inline)');
const toon3 = `tags[3]: admin,ops,dev
numbers[5]: 1,2,3,4,5`;
const result3 = decode(toon3);
console.log(JSON.stringify(result3, null, 2));
console.log('');

// Test 4: Nested object
console.log('Test 4: Nested object');
const toon4 = `user:
  id: 123
  name: Ada`;
const result4 = decode(toon4);
console.log(JSON.stringify(result4, null, 2));
console.log('');

// Test 5: Tabular array
console.log('Test 5: Tabular array');
const toon5 = `items[3]{sku,qty,price}:
  A1,2,9.99
  B2,1,14.5
  C3,5,7.25`;
const result5 = decode(toon5);
console.log(JSON.stringify(result5, null, 2));
console.log('');

// Test 6: Mixed array (list format)
console.log('Test 6: Mixed array (list format)');
const toon6 = `items[5]:
  - 1
  - text
  - a: 1
  - true
  - null`;
const result6 = decode(toon6);
console.log(JSON.stringify(result6, null, 2));
console.log('');

// Test 7: Empty containers
console.log('Test 7: Empty containers');
const toon7 = `empty_object:
empty_array[0]:
nested:
  items[0]:`;
const result7 = decode(toon7);
console.log(JSON.stringify(result7, null, 2));
console.log('');

// Test 8: Special strings
console.log('Test 8: Special strings (with quotes)');
const toon8 = `with_comma: "hello, world"
with_colon: "key: value"
looks_like_bool: "true"
looks_like_number: "42"
empty: ""`;
const result8 = decode(toon8);
console.log(JSON.stringify(result8, null, 2));
console.log('');

// Test 9: Root array
console.log('Test 9: Root array');
const toon9 = `[3]: x,y,z`;
const result9 = decode(toon9);
console.log(JSON.stringify(result9, null, 2));
console.log('');

// Test 10: Root primitive
console.log('Test 10: Root primitive');
const toon10 = `hello`;
const result10 = decode(toon10);
console.log(JSON.stringify(result10, null, 2));
console.log('');

console.log('\n=== ROUND-TRIP TESTS ===\n');

// Round-trip test function
function testRoundTrip(name, data) {
  console.log(`Round-trip: ${name}`);
  const encoded = encode(data);
  const decoded = decode(encoded);
  const match = JSON.stringify(data) === JSON.stringify(decoded);
  console.log(`  Match: ${match ? '✓' : '✗'}`);
  if (!match) {
    console.log('  Original:', JSON.stringify(data));
    console.log('  Decoded: ', JSON.stringify(decoded));
  }
  return match;
}

let passed = 0;
let total = 0;

// Test cases
const tests = [
  ['Simple primitives', {
    string: "hello",
    number: 42,
    float: 3.14,
    boolean_true: true,
    boolean_false: false,
    null: null
  }],
  ['Simple object', {
    id: 123,
    name: "Ada",
    active: true
  }],
  ['Simple array', {
    tags: ["admin", "ops", "dev"],
    numbers: [1, 2, 3, 4, 5]
  }],
  ['Nested object', {
    user: {
      id: 123,
      name: "Ada"
    }
  }],
  ['Tabular array', {
    items: [
      { sku: "A1", qty: 2, price: 9.99 },
      { sku: "B2", qty: 1, price: 14.5 },
      { sku: "C3", qty: 5, price: 7.25 }
    ]
  }],
  ['Mixed array', {
    items: [1, "text", { a: 1 }, true, null]
  }],
  ['Empty containers', {
    empty_object: {},
    empty_array: [],
    nested: {
      items: []
    }
  }],
  ['Special strings', {
    with_comma: "hello, world",
    with_colon: "key: value",
    looks_like_bool: "true",
    looks_like_number: "42",
    empty: ""
  }],
  ['Root array', ["x", "y", "z"]],
  ['Root primitive', "hello"],
  ['Empty root object', {}]
];

tests.forEach(([name, data]) => {
  total++;
  if (testRoundTrip(name, data)) {
    passed++;
  }
});

console.log(`\n=== RESULTS ===`);
console.log(`Passed: ${passed}/${total}`);
console.log(`Success rate: ${(passed / total * 100).toFixed(1)}%`);
