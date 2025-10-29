// Simple test script for TOON encoder

const { encode } = require('../dist/index.js');

console.log('=== Test 1: Simple primitives ===');
const test1 = {
  string: "hello",
  number: 42,
  float: 3.14,
  boolean_true: true,
  boolean_false: false,
  null: null
};
console.log(encode(test1));
console.log('');

console.log('=== Test 2: Simple object ===');
const test2 = {
  id: 123,
  name: "Ada",
  active: true
};
console.log(encode(test2));
console.log('');

console.log('=== Test 3: Simple array ===');
const test3 = {
  tags: ["admin", "ops", "dev"],
  numbers: [1, 2, 3, 4, 5]
};
console.log(encode(test3));
console.log('');

console.log('=== Test 4: Nested object ===');
const test4 = {
  user: {
    id: 123,
    name: "Ada"
  }
};
console.log(encode(test4));
console.log('');

console.log('=== Test 5: Tabular array ===');
const test5 = {
  items: [
    { sku: "A1", qty: 2, price: 9.99 },
    { sku: "B2", qty: 1, price: 14.5 },
    { sku: "C3", qty: 5, price: 7.25 }
  ]
};
console.log(encode(test5));
console.log('');

console.log('=== Test 6: Mixed array (list format) ===');
const test6 = {
  items: [
    1,
    "text",
    { a: 1 },
    true,
    null
  ]
};
console.log(encode(test6));
console.log('');

console.log('=== Test 7: Empty containers ===');
const test7 = {
  empty_object: {},
  empty_array: [],
  nested: {
    items: []
  }
};
console.log(encode(test7));
console.log('');

console.log('=== Test 8: Special strings (need quotes) ===');
const test8 = {
  with_comma: "hello, world",
  with_colon: "key: value",
  looks_like_bool: "true",
  looks_like_number: "42",
  empty: ""
};
console.log(encode(test8));
console.log('');

console.log('=== Test 9: Root-level array ===');
const test9 = ["x", "y", "z"];
console.log(encode(test9));
console.log('');

console.log('=== Test 10: Root-level primitive ===');
const test10 = "hello";
console.log(encode(test10));
console.log('');

console.log('=== Test 11: Empty root object ===');
const test11 = {};
console.log(`"${encode(test11)}"  (should be empty string)`);
console.log('');
