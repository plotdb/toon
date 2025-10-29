# TOON LiveScript 實作開發需知

## 專案概述

本專案使用 LiveScript 實作 TOON (Token-Oriented Object Notation) 格式的編碼器和解碼器。

**TOON** 是一個為 LLM 優化的資料格式，相比 JSON 可節省 30-60% 的 token 數量，特別適合處理大量統一結構的複雜物件。

## 專案目標

1. **JSON → TOON 轉換器**：將標準 JSON 資料編碼為 TOON 格式
2. **TOON → JSON 轉換器**：將 TOON 格式解析回 JSON 資料
3. **完整測試套件**：涵蓋簡單、複雜和邊界案例的測試

## 資料夾結構

```
/workspace
├── src/
│   └── index.ls              # 主要實作檔案
├── tests/
│   ├── encoder.test.ls       # 編碼器測試
│   ├── decoder.test.ls       # 解碼器測試
│   └── integration.test.ls   # 整合測試
├── samples/
│   ├── simple/               # 簡單案例
│   │   ├── 01-primitives.json
│   │   ├── 01-primitives.toon
│   │   ├── 02-simple-object.json
│   │   └── 02-simple-object.toon
│   ├── complex/              # 複雜案例
│   │   ├── 01-nested-objects.json
│   │   ├── 01-nested-objects.toon
│   │   ├── 02-tabular-arrays.json
│   │   ├── 02-tabular-arrays.toon
│   │   ├── 03-mixed-structures.json
│   │   └── 03-mixed-structures.toon
│   └── edge-cases/           # 邊界案例
│       ├── 01-empty-containers.json
│       ├── 01-empty-containers.toon
│       ├── 02-special-strings.json
│       ├── 02-special-strings.toon
│       ├── 03-unicode-emoji.json
│       └── 03-unicode-emoji.toon
├── spec.md                   # TOON 規格文件
├── lsc-coding-guide.md       # LiveScript 編程風格指南
└── DEV.md                    # 本文件

```

## 實作架構設計

### 核心模組設計

#### 1. 編碼器 (Encoder)

```livescript
encoder = (options = {}) ->
  @ <<<
    indent: 2
    delimiter: ','
    length-marker: false
  @ <<< options
  @

encoder.prototype = Object.create(Object.prototype) <<<
  constructor: encoder

  # 主要編碼方法
  encode: (value) ->
    # 根據值的類型分派到不同的處理器

  # 類型處理器
  encode-object: (obj, depth) ->
  encode-array: (arr, depth) ->
  encode-primitive: (value) ->

  # 輔助方法
  should-quote: (str) ->
  quote-string: (str) ->
  is-tabular: (arr) ->
  format-tabular: (arr, depth) ->
```

#### 2. 解碼器 (Decoder)

```livescript
decoder = (options = {}) ->
  @ <<<
    strict: false
  @ <<< options
  @

decoder.prototype = Object.create(Object.prototype) <<<
  constructor: decoder

  # 主要解碼方法
  decode: (toon-str) ->
    # 解析 TOON 字串為 JSON

  # 解析器
  parse-lines: (lines) ->
  parse-object: (lines, start-idx, depth) ->
  parse-array: (lines, start-idx, depth) ->
  parse-tabular: (lines, start-idx, header) ->

  # 輔助方法
  parse-header: (line) ->
  parse-value: (str) ->
  split-values: (str, delimiter) ->
  unquote: (str) ->
```

#### 3. 公開 API

```livescript
# 便捷函式
encode = (value, options) ->
  enc = new encoder(options)
  enc.encode value

decode = (toon-str, options) ->
  dec = new decoder(options)
  dec.decode toon-str

# 匯出
if window?
  window <<< { encoder, decoder, encode, decode }
else
  module.exports = { encoder, decoder, encode, decode }
```

### 關鍵實作要點

#### 1. 引號規則 (Quoting Rules)

**物件鍵 (Object Keys)**
- 符合識別符模式免引號：`/^[a-zA-Z_][a-zA-Z0-9_\.]*$/`
- 其他情況需引號：空字串、包含特殊字元、以數字開頭等

**字串值 (String Values)**
需要引號的情況：
- 空字串
- 前後有空白
- 包含當前分隔符、冒號、引號、反斜線、控制字元
- 看起來像 boolean/number/null
- 以 `"- "` 開頭（看起來像列表項）
- 看起來像結構標記（如 `[5]`, `{key}`）

#### 2. 表格格式檢測 (Tabular Format Detection)

陣列需滿足以下條件才使用表格格式：
1. 所有元素都是物件
2. 所有物件的鍵集合完全相同
3. 所有值都是基本型別（無嵌套）
4. 至少有一個元素

#### 3. 縮排管理

- 每層縮排：2 空格（預設）
- 物件屬性：縮排 + `key: value`
- 陣列項目：縮排 + `"- "` + 內容
- 表格行：縮排 + 以分隔符分隔的值

#### 4. 類型轉換

| 輸入 | 輸出 |
|---|---|
| 有限數字 | 十進位形式（不用科學記號）|
| `NaN`, `±Infinity` | `null` |
| `BigInt` | 十進位數字字串（無引號）|
| `Date` | ISO 字串（有引號）|
| `undefined` | `null` |
| `function` | `null` |
| `symbol` | `null` |

## 測試案例規劃

### 簡單案例 (Simple Cases)

#### 1. 基本型別 (Primitives)
```json
{
  "string": "hello",
  "number": 42,
  "boolean": true,
  "null": null
}
```

#### 2. 簡單物件 (Simple Object)
```json
{
  "id": 123,
  "name": "Ada",
  "active": true
}
```

#### 3. 簡單陣列 (Simple Array)
```json
{
  "tags": ["admin", "ops", "dev"]
}
```

#### 4. 嵌套物件 (Nested Object)
```json
{
  "user": {
    "id": 123,
    "name": "Ada"
  }
}
```

### 複雜案例 (Complex Cases)

#### 1. 深層嵌套 (Deep Nesting)
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

#### 2. 表格陣列 (Tabular Array)
```json
{
  "items": [
    { "sku": "A1", "qty": 2, "price": 9.99 },
    { "sku": "B2", "qty": 1, "price": 14.5 }
  ]
}
```

#### 3. 混合陣列 (Mixed Array)
```json
{
  "items": [1, "text", { "a": 1 }, true]
}
```

#### 4. 陣列的陣列 (Array of Arrays)
```json
{
  "pairs": [[1, 2], [3, 4]]
}
```

#### 5. 嵌套表格 (Nested Tabular)
```json
{
  "orders": [
    {
      "items": [
        { "id": 1, "name": "Widget" },
        { "id": 2, "name": "Gadget" }
      ],
      "status": "active"
    }
  ]
}
```

### 邊界案例 (Edge Cases)

#### 1. 空容器 (Empty Containers)
```json
{
  "empty_object": {},
  "empty_array": [],
  "nested_empty": {
    "items": []
  }
}
```

#### 2. 特殊字串 (Special Strings)
```json
{
  "with_comma": "hello, world",
  "with_colon": "key: value",
  "with_quote": "say \"hi\"",
  "with_backslash": "C:\\Users",
  "looks_like_bool": "true",
  "looks_like_number": "42",
  "looks_like_null": "null",
  "list_like": "- item",
  "leading_space": " padded",
  "trailing_space": "padded ",
  "empty": ""
}
```

#### 3. Unicode 和 Emoji
```json
{
  "chinese": "你好世界",
  "emoji": "hello 👋 world",
  "mixed": "混合 text 🚀"
}
```

#### 4. 不規則表格候選 (Irregular Tabular Candidates)
```json
{
  "irregular": [
    { "id": 1, "name": "Alice" },
    { "id": 2, "name": "Bob", "extra": true }
  ]
}
```

#### 5. 根層級陣列 (Root-level Array)
```json
["x", "y", "z"]
```

#### 6. 特殊數值 (Special Numbers)
```json
{
  "zero": 0,
  "negative_zero": -0,
  "negative": -42,
  "float": 3.14159,
  "scientific": 1e6,
  "large": 999999999999
}
```

#### 7. 鍵名特殊字元 (Special Key Names)
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

## 開發步驟

### Phase 1: 編碼器基礎實作
1. ✅ 建立專案結構
2. ⏳ 實作基本型別編碼
3. ⏳ 實作物件編碼
4. ⏳ 實作陣列編碼（列表格式）
5. ⏳ 實作引號規則
6. ⏳ 測試簡單案例

### Phase 2: 編碼器進階功能
1. ⏳ 實作表格格式檢測
2. ⏳ 實作表格格式輸出
3. ⏳ 實作分隔符選項（comma, tab, pipe）
4. ⏳ 實作 length-marker 選項
5. ⏳ 測試複雜案例

### Phase 3: 編碼器邊界處理
1. ⏳ 處理空容器
2. ⏳ 處理特殊字串
3. ⏳ 處理 Unicode/Emoji
4. ⏳ 處理特殊數值
5. ⏳ 測試邊界案例

### Phase 4: 解碼器實作
1. ⏳ 實作行解析器
2. ⏳ 實作物件解析
3. ⏳ 實作陣列解析（列表格式）
4. ⏳ 實作表格解析
5. ⏳ 實作值解析和反引號
6. ⏳ 測試往返轉換（round-trip）

### Phase 5: 整合測試與優化
1. ⏳ 建立完整測試套件
2. ⏳ 整合測試所有樣本
3. ⏳ 效能優化
4. ⏳ 錯誤處理改善
5. ⏳ 文件完善

## 編碼風格規範

本專案遵循 `lsc-coding-guide.md` 中定義的 LiveScript 編程風格：

### 命名慣例
- Constructor：小寫（`encoder`, `decoder`）
- 方法和屬性：kebab-case（`encode-object`, `is-active`）
- 私有方法：底線前綴（`_parse-internal`）

### Constructor Pattern
```livescript
my-class = (options = {}) ->
  @ <<<
    default-prop: value
  @ <<< options
  @

my-class.prototype = Object.create(Object.prototype) <<<
  constructor: my-class
  method1: -> ...
  method2: -> ...
```

### 註解原則
- 解釋「為什麼」而非「是什麼」
- 關鍵決策需要註解
- 避免冗餘註解

### Context 處理
- 使用 `~>` 綁定需要存取實例變數的方法
- Event handlers 使用 `apply` 處理 context

## API 使用範例

### 編碼 (Encoding)

```livescript
{ encode } = require './src/index.ls'

# 基本使用
data = { id: 1, name: 'Ada' }
toon-str = encode data
# => "id: 1\nname: Ada"

# 使用選項
toon-str = encode data, {
  delimiter: '\t'
  length-marker: '#'
}

# 使用 encoder 實例
enc = new encoder({ indent: 4 })
toon-str = enc.encode data
```

### 解碼 (Decoding)

```livescript
{ decode } = require './src/index.ls'

# 基本使用
toon-str = "id: 1\nname: Ada"
data = decode toon-str
# => { id: 1, name: 'Ada' }

# 使用解碼器實例
dec = new decoder({ strict: true })
data = dec.decode toon-str
```

## 測試執行

```bash
# 編譯 LiveScript
npm run build

# 執行測試（待實作測試框架）
npm test

# 執行特定測試
node tests/encoder.test.js
node tests/decoder.test.js
```

## 參考資料

- **TOON 規格**：`spec.md`
- **LiveScript 文件**：https://livescript.net/
- **編碼風格指南**：`lsc-coding-guide.md`
- **原始 TOON 實作**：https://github.com/byjohann/toon (TypeScript)

## 開發注意事項

### 1. 表格格式的遞歸性
表格格式可以遞歸應用。嵌套在物件屬性或列表項目中的陣列，如果符合表格格式要求，也應使用表格格式。

### 2. 引號的分隔符感知
當使用 tab 或 pipe 分隔符時，引號規則會自動調整。包含當前活動分隔符的字串需要引號，但其他分隔符則是安全的。

### 3. 縮排的正確性
- 物件：`key: value` 或 `key:` (嵌套時)
- 陣列項目：`"- "` 開頭
- 表格行：直接值，無前綴
- 每層額外縮排 N 空格（預設 2）

### 4. 空白處理
- 行尾無多餘空白
- 輸出結尾無換行符
- `key: value` 冒號後有一個空格
- `key:` (嵌套) 冒號後無空格

### 5. 類型保真度
解碼後應盡可能還原原始類型：
- 數字 vs 字串（`42` vs `"42"`）
- 布林 vs 字串（`true` vs `"true"`）
- null vs 字串（`null` vs `"null"`）

### 6. 錯誤處理
解碼器應能處理：
- 格式錯誤的輸入
- 不一致的縮排
- 無效的表格宣告
- 引號不匹配
- 提供有意義的錯誤訊息

## 效能考量

1. **大型陣列**：表格格式應能高效處理數千行
2. **深層嵌套**：避免遞歸溢出
3. **字串處理**：引號檢測應最小化正則表達式使用
4. **記憶體使用**：解碼時避免過多中間字串建立

## 後續擴展計畫

1. **CLI 工具**：命令列轉換工具
2. **串流處理**：支援大檔案的串流編碼/解碼
3. **Schema 驗證**：可選的結構驗證
4. **美化輸出**：可選的對齊和格式化
5. **統計資訊**：token 計數和節省比較

---

**目前狀態**：✅ 規劃完成，準備開始實作

**下一步**：實作編碼器基本型別處理
