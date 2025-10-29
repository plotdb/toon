#!/usr/bin/env node
// TOON LiveScript Implementation - Quick Example

const { encode, decode } = require('../dist/index.js');

console.log('╔════════════════════════════════════════╗');
console.log('║  TOON LiveScript 實作範例             ║');
console.log('╚════════════════════════════════════════╝\n');

// 範例資料
const data = {
  user: {
    id: 123,
    name: "Ada Lovelace",
    role: "admin",
    tags: ["developer", "mathematician"]
  },
  orders: [
    { id: "ORD-001", amount: 99.99, status: "completed" },
    { id: "ORD-002", amount: 149.50, status: "pending" },
    { id: "ORD-003", amount: 75.00, status: "completed" }
  ],
  settings: {
    notifications: true,
    theme: "dark",
    language: "en"
  }
};

console.log('📝 原始 JSON 資料:');
console.log(JSON.stringify(data, null, 2));
console.log('');

console.log('🔄 轉換為 TOON 格式:');
console.log('━'.repeat(50));
const toonStr = encode(data);
console.log(toonStr);
console.log('━'.repeat(50));
console.log('');

console.log('🔙 TOON 解碼回 JSON:');
const decoded = decode(toonStr);
console.log(JSON.stringify(decoded, null, 2));
console.log('');

console.log('✅ 驗證往返轉換:');
const match = JSON.stringify(data) === JSON.stringify(decoded);
console.log(`   資料完整性: ${match ? '✓ 完美匹配' : '✗ 不匹配'}`);
console.log('');

// Token 計數（簡單估算）
const jsonStr = JSON.stringify(data);
const jsonTokens = jsonStr.length;
const toonTokens = toonStr.length;
const savings = ((jsonTokens - toonTokens) / jsonTokens * 100).toFixed(1);

console.log('💰 Token 節省估算:');
console.log(`   JSON 長度: ${jsonTokens} 字元`);
console.log(`   TOON 長度: ${toonTokens} 字元`);
console.log(`   節省比例: ${savings}%`);
console.log('');

// 表格格式範例
console.log('📊 表格格式範例:');
console.log('━'.repeat(50));
const tableData = {
  products: [
    { sku: "WIDGET-001", name: "Super Widget", price: 29.99, stock: 150 },
    { sku: "GADGET-002", name: "Mega Gadget", price: 49.99, stock: 75 },
    { sku: "TOOL-003", name: "Power Tool", price: 89.99, stock: 30 }
  ]
};
const tableToon = encode(tableData);
console.log(tableToon);
console.log('━'.repeat(50));
console.log('');

console.log('🎯 使用不同選項:');
console.log('━'.repeat(50));

const { encoder } = require('../dist/index.js');

// Tab 分隔符
const encTab = new encoder({ delimiter: '\t' });
console.log('使用 Tab 分隔符:');
console.log(encTab.encode({ items: [1, 2, 3, 4, 5] }));
console.log('');

// Length marker
const encMarker = new encoder({ lengthMarker: '#' });
console.log('使用 Length Marker:');
console.log(encMarker.encode({ items: [1, 2, 3, 4, 5] }));
console.log('');

console.log('━'.repeat(50));
console.log('✨ 完成！可以開始使用 TOON 了！');
