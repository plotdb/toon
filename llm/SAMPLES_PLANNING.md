# TOON 測試樣本集

這個資料夾包含用於測試 TOON 編碼器和解碼器的樣本檔案。每個樣本都包含一對檔案：
- `.json` - 原始 JSON 資料
- `.toon` - 對應的 TOON 格式

## 測試案例分類

### 1. 簡單案例 (Simple Cases)

基礎功能測試，涵蓋最常見的資料結構。

#### `simple/01-primitives`
測試所有基本型別的編碼。

**JSON:**
```json
{
  "string": "hello",
  "number": 42,
  "float": 3.14,
  "boolean_true": true,
  "boolean_false": false,
  "null": null
}
```

**TOON:**
```
string: hello
number: 42
float: 3.14
boolean_true: true
boolean_false: false
null: null
```

**測試重點:**
- 字串不需引號（無特殊字元）
- 數字直接輸出
- 布林值 `true`/`false`
- `null` 值

---

#### `simple/02-simple-object`
測試簡單的物件結構。

**JSON:**
```json
{
  "id": 123,
  "name": "Ada",
  "active": true
}
```

**TOON:**
```
id: 123
name: Ada
active: true
```

**測試重點:**
- 物件屬性的基本編碼
- 鍵值對格式 `key: value`

---

#### `simple/03-simple-array`
測試基本型別的陣列（inline 格式）。

**JSON:**
```json
{
  "tags": ["admin", "ops", "dev"],
  "numbers": [1, 2, 3, 4, 5]
}
```

**TOON:**
```
tags[3]: admin,ops,dev
numbers[5]: 1,2,3,4,5
```

**測試重點:**
- 陣列長度標記 `[N]`
- Inline 格式（逗號分隔）
- 無需引號的字串陣列

---

#### `simple/04-nested-object`
測試嵌套物件。

**JSON:**
```json
{
  "user": {
    "id": 123,
    "name": "Ada"
  }
}
```

**TOON:**
```
user:
  id: 123
  name: Ada
```

**測試重點:**
- 嵌套物件的縮排
- 父鍵後的冒號無空格
- 子屬性縮排 2 空格

---

#### `simple/05-nested-array`
測試嵌套在物件中的陣列。

**JSON:**
```json
{
  "user": {
    "name": "Ada",
    "tags": ["admin", "dev"]
  }
}
```

**TOON:**
```
user:
  name: Ada
  tags[2]: admin,dev
```

**測試重點:**
- 嵌套結構中的陣列
- 保持正確縮排

---

### 2. 複雜案例 (Complex Cases)

進階功能測試，包含更複雜的資料結構。

#### `complex/01-deep-nesting`
測試多層嵌套物件。

**JSON:**
```json
{
  "level1": {
    "level2": {
      "level3": {
        "value": "deep"
      }
    }
  }
}
```

**TOON:**
```
level1:
  level2:
    level3:
      value: deep
```

**測試重點:**
- 多層縮排正確性
- 每層 2 空格

---

#### `complex/02-tabular-simple`
測試表格格式（統一結構的物件陣列）。

**JSON:**
```json
{
  "items": [
    { "sku": "A1", "qty": 2, "price": 9.99 },
    { "sku": "B2", "qty": 1, "price": 14.5 },
    { "sku": "C3", "qty": 5, "price": 7.25 }
  ]
}
```

**TOON:**
```
items[3]{sku,qty,price}:
  A1,2,9.99
  B2,1,14.5
  C3,5,7.25
```

**測試重點:**
- 表格格式檢測
- Header 格式 `[N]{field1,field2,...}:`
- 每行以分隔符分隔值
- 行數與 `[N]` 一致

---

#### `complex/03-mixed-array`
測試混合型別的陣列（使用列表格式）。

**JSON:**
```json
{
  "items": [
    1,
    "text",
    { "a": 1 },
    true,
    null
  ]
}
```

**TOON:**
```
items[5]:
  - 1
  - text
  - a: 1
  - true
  - null
```

**測試重點:**
- 列表格式 `"- "` 前綴
- 混合型別處理
- 物件在列表中的表示

---

#### `complex/04-array-of-arrays`
測試陣列包含陣列。

**JSON:**
```json
{
  "pairs": [
    [1, 2],
    [3, 4],
    [5, 6]
  ]
}
```

**TOON:**
```
pairs[3]:
  - [2]: 1,2
  - [2]: 3,4
  - [2]: 5,6
```

**測試重點:**
- 內層陣列的格式
- 列表項目中的 inline 陣列

---

#### `complex/05-nested-tabular`
測試嵌套的表格格式。

**JSON:**
```json
{
  "orders": [
    {
      "items": [
        { "id": 1, "name": "Widget" },
        { "id": 2, "name": "Gadget" }
      ],
      "status": "active"
    },
    {
      "items": [
        { "id": 3, "name": "Doohickey" }
      ],
      "status": "pending"
    }
  ]
}
```

**TOON:**
```
orders[2]:
  - items[2]{id,name}:
    1,Widget
    2,Gadget
    status: active
  - items[1]{id,name}:
    3,Doohickey
    status: pending
```

**測試重點:**
- 列表項目中的第一個欄位
- 嵌套表格的縮排
- 後續欄位與表格內容同層

---

#### `complex/06-list-with-objects`
測試列表格式中的物件（非統一結構）。

**JSON:**
```json
{
  "items": [
    { "id": 1, "name": "First" },
    { "id": 2, "name": "Second", "extra": true }
  ]
}
```

**TOON:**
```
items[2]:
  - id: 1
    name: First
  - id: 2
    name: Second
    extra: true
```

**測試重點:**
- 不規則物件使用列表格式
- 第一個欄位在 `"- "` 同行
- 後續欄位縮排對齊

---

### 3. 邊界案例 (Edge Cases)

邊界條件和特殊情況測試。

#### `edge-cases/01-empty-containers`
測試空容器。

**JSON:**
```json
{
  "empty_object": {},
  "empty_array": [],
  "nested": {
    "items": []
  }
}
```

**TOON:**
```
empty_object:
empty_array[0]:
nested:
  items[0]:
```

**測試重點:**
- 空物件表示為 `key:`
- 空陣列表示為 `key[0]:`
- 根層級空物件輸出空字串

---

#### `edge-cases/02-special-strings`
測試需要引號的特殊字串。

**JSON:**
```json
{
  "with_comma": "hello, world",
  "with_colon": "key: value",
  "with_quote": "say \"hi\"",
  "with_backslash": "C:\\Users",
  "with_newline": "line1\nline2",
  "looks_like_bool": "true",
  "looks_like_number": "42",
  "looks_like_null": "null",
  "list_like": "- item",
  "leading_space": " padded",
  "trailing_space": "padded ",
  "empty_string": ""
}
```

**TOON:**
```
with_comma: "hello, world"
with_colon: "key: value"
with_quote: "say \"hi\""
with_backslash: "C:\\Users"
with_newline: "line1\nline2"
looks_like_bool: "true"
looks_like_number: "42"
looks_like_null: "null"
list_like: "- item"
leading_space: " padded"
trailing_space: "padded "
empty_string: ""
```

**測試重點:**
- 包含分隔符需引號
- 包含冒號需引號
- 引號和反斜線需轉義
- 控制字元需轉義
- 看起來像保留字需引號
- 前後空白需引號
- 空字串需引號

---

#### `edge-cases/03-unicode-emoji`
測試 Unicode 和 Emoji（無需引號）。

**JSON:**
```json
{
  "chinese": "你好世界",
  "japanese": "こんにちは",
  "emoji": "hello 👋 world",
  "mixed": "混合 text 🚀 123"
}
```

**TOON:**
```
chinese: 你好世界
japanese: こんにちは
emoji: hello 👋 world
mixed: 混合 text 🚀 123
```

**測試重點:**
- Unicode 字元無需引號
- Emoji 無需引號
- 混合文字正確處理

---

#### `edge-cases/04-special-numbers`
測試特殊數值。

**JSON:**
```json
{
  "zero": 0,
  "negative_zero": -0,
  "negative": -42,
  "float": 3.14159,
  "scientific": 1000000,
  "large": 999999999999,
  "small": 0.0001
}
```

**TOON:**
```
zero: 0
negative_zero: 0
negative: -42
float: 3.14159
scientific: 1000000
large: 999999999999
small: 0.0001
```

**測試重點:**
- `-0` 正規化為 `0`
- 科學記號轉換為十進位
- 不使用科學記號輸出

---

#### `edge-cases/05-special-keys`
測試特殊的鍵名。

**JSON:**
```json
{
  "normal_key": 1,
  "kebab-case": 2,
  "with space": 3,
  "with:colon": 4,
  "123": 5,
  "": 6,
  "_private": 7,
  "dot.notation": 8
}
```

**TOON:**
```
normal_key: 1
kebab-case: 2
"with space": 3
"with:colon": 4
"123": 5
"": 6
_private: 7
dot.notation: 8
```

**測試重點:**
- 符合識別符模式的鍵無需引號
- 包含空格需引號
- 包含冒號需引號
- 純數字需引號
- 空鍵需引號
- 底線開頭、點號符合識別符規則

---

#### `edge-cases/06-root-array`
測試根層級陣列。

**JSON:**
```json
["x", "y", "z"]
```

**TOON:**
```
[3]: x,y,z
```

**測試重點:**
- 根層級陣列格式
- 無鍵名，直接 `[N]:`

---

#### `edge-cases/07-root-primitive`
測試根層級基本型別。

**JSON:**
```json
"hello"
```

**TOON:**
```
hello
```

**JSON (number):**
```json
42
```

**TOON:**
```
42
```

**測試重點:**
- 根層級基本型別直接輸出
- 需要引號時加引號

---

#### `edge-cases/08-empty-root`
測試空的根層級容器。

**JSON (empty object):**
```json
{}
```

**TOON:**
```
(empty string)
```

**JSON (empty array):**
```json
[]
```

**TOON:**
```
[0]:
```

**測試重點:**
- 空物件在根層級輸出空字串
- 空陣列輸出 `[0]:`

---

### 4. 分隔符選項測試

#### `options/01-tab-delimiter`
測試 tab 分隔符選項。

**JSON:**
```json
{
  "items": [
    { "id": 1, "name": "Widget" },
    { "id": 2, "name": "Gadget" }
  ]
}
```

**TOON (with `delimiter: '\t'`):**
```
items[2	]{id	name}:
  1	Widget
  2	Gadget
```

**測試重點:**
- Header 顯示分隔符 `[N<delim>]`
- 欄位以 tab 分隔
- 值以 tab 分隔

---

#### `options/02-pipe-delimiter`
測試 pipe 分隔符選項。

**JSON:**
```json
{
  "items": [
    { "id": 1, "name": "Widget" },
    { "id": 2, "name": "Gadget" }
  ]
}
```

**TOON (with `delimiter: '|'`):**
```
items[2|]{id|name}:
  1|Widget
  2|Gadget
```

**測試重點:**
- Header 顯示 pipe 分隔符
- 值以 pipe 分隔

---

#### `options/03-length-marker`
測試 length-marker 選項。

**JSON:**
```json
{
  "tags": ["a", "b", "c"],
  "items": [
    { "id": 1 },
    { "id": 2 }
  ]
}
```

**TOON (with `lengthMarker: '#'`):**
```
tags[#3]: a,b,c
items[#2]{id}:
  1
  2
```

**測試重點:**
- 長度前綴 `#`
- Inline 和表格都套用

---

## 測試執行計畫

### 單元測試
1. **編碼器測試** (`tests/encoder.test.ls`)
   - 載入每個樣本的 `.json` 檔案
   - 執行 `encode()`
   - 比對輸出與對應的 `.toon` 檔案

2. **解碼器測試** (`tests/decoder.test.ls`)
   - 載入每個樣本的 `.toon` 檔案
   - 執行 `decode()`
   - 比對輸出與對應的 `.json` 檔案

3. **往返測試** (`tests/integration.test.ls`)
   - JSON → TOON → JSON
   - 驗證資料完整性
   - TOON → JSON → TOON
   - 驗證格式穩定性

### 測試覆蓋率目標
- ✅ 所有基本型別
- ✅ 物件和陣列的各種組合
- ✅ 嵌套結構
- ✅ 表格格式觸發條件
- ✅ 引號規則的所有情況
- ✅ 空容器
- ✅ 特殊字元和 Unicode
- ✅ 邊界條件
- ✅ 選項變化

## 樣本檔案清單

### Simple (5 組，10 檔案)
- ✅ `01-primitives.{json,toon}`
- ✅ `02-simple-object.{json,toon}`
- ✅ `03-simple-array.{json,toon}`
- ✅ `04-nested-object.{json,toon}`
- ✅ `05-nested-array.{json,toon}`

### Complex (6 組，12 檔案)
- ✅ `01-deep-nesting.{json,toon}`
- ✅ `02-tabular-simple.{json,toon}`
- ✅ `03-mixed-array.{json,toon}`
- ✅ `04-array-of-arrays.{json,toon}`
- ✅ `05-nested-tabular.{json,toon}`
- ✅ `06-list-with-objects.{json,toon}`

### Edge Cases (8 組，16 檔案)
- ✅ `01-empty-containers.{json,toon}`
- ✅ `02-special-strings.{json,toon}`
- ✅ `03-unicode-emoji.{json,toon}`
- ✅ `04-special-numbers.{json,toon}`
- ✅ `05-special-keys.{json,toon}`
- ✅ `06-root-array.{json,toon}`
- ✅ `07-root-primitive.{json,toon}`
- ✅ `08-empty-root.{json,toon}`

### Options (3 組，6 檔案)
- ✅ `01-tab-delimiter.{json,toon}`
- ✅ `02-pipe-delimiter.{json,toon}`
- ✅ `03-length-marker.{json,toon}`

**總計**: 22 組測試案例，44 個檔案

---

**狀態**: ✅ 規劃完成，樣本檔案待建立
