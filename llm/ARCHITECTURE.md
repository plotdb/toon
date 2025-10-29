# TOON LiveScript 實作架構設計

## 概述

本文件詳細說明 TOON 編碼器和解碼器的內部架構、演算法設計和實作細節。

## 模組結構

```
src/index.ls
├── Encoder (編碼器)
│   ├── Constructor
│   ├── encode() - 主入口
│   ├── encode-value() - 值類型分派
│   ├── encode-object() - 物件編碼
│   ├── encode-array() - 陣列編碼
│   ├── encode-primitive() - 基本型別編碼
│   ├── format-tabular() - 表格格式化
│   ├── should-quote() - 引號判斷
│   └── quote-string() - 字串引號處理
│
├── Decoder (解碼器)
│   ├── Constructor
│   ├── decode() - 主入口
│   ├── parse-lines() - 行解析
│   ├── parse-object() - 物件解析
│   ├── parse-array() - 陣列解析
│   ├── parse-tabular() - 表格解析
│   ├── parse-value() - 值解析
│   └── unquote() - 反引號處理
│
└── Exports (公開 API)
    ├── encoder (類)
    ├── decoder (類)
    ├── encode() (便捷函式)
    └── decode() (便捷函式)
```

---

## Encoder 編碼器

### Constructor

```livescript
encoder = (options = {}) ->
  @ <<<
    indent: 2                # 每層縮排空格數
    delimiter: ','           # 陣列分隔符 (','|'\t'|'|')
    length-marker: false     # 是否在長度前加 # 標記
    _depth: 0                # 內部使用：當前深度

  @ <<< options
  @
```

### 主要方法

#### `encode(value)`
編碼入口，處理根層級值。

**流程:**
1. 檢查值類型
2. 根層級物件：返回物件內容（不含外層大括號）
3. 根層級陣列：返回陣列格式
4. 根層級基本型別：返回編碼後的值
5. 空物件在根層級：返回空字串

**返回:** TOON 格式字串（無尾隨換行）

```livescript
encode: (value) ->
  | value is null => 'null'
  | typeof value is 'undefined' => 'null'
  | typeof value is 'object' and not Array.is-array value =>
      # 物件
      if Object.keys(value).length is 0
        ''  # 空物件在根層級返回空字串
      else
        @encode-object value, 0
  | Array.is-array value =>
      # 陣列
      @encode-array value, 0, null  # null 表示無鍵名
  | otherwise =>
      # 基本型別
      @encode-primitive value
```

---

#### `encode-value(value, depth, key)`
內部方法，根據值類型分派到對應的編碼器。

**參數:**
- `value` - 要編碼的值
- `depth` - 當前嵌套深度
- `key` - 屬性鍵名（可選）

**返回:** 編碼後的行陣列

```livescript
encode-value: (value, depth, key) ->
  indent-str = ' ' * (depth * @indent)

  | value is null => ["#{indent-str}#{key}: null"]
  | typeof value is 'boolean' => ["#{indent-str}#{key}: #{value}"]
  | typeof value is 'number' => ["#{indent-str}#{key}: #{@normalize-number value}"]
  | typeof value is 'string' => ["#{indent-str}#{key}: #{@encode-string value}"]
  | typeof value is 'object' and not Array.is-array value =>
      # 嵌套物件
      header = "#{indent-str}#{key}:"
      if Object.keys(value).length is 0
        [header]  # 空物件
      else
        [header] ++ @encode-object value, depth + 1
  | Array.is-array value =>
      # 陣列
      @encode-array value, depth, key
  | otherwise => ["#{indent-str}#{key}: null"]
```

---

#### `encode-object(obj, depth)`
編碼物件為 TOON 格式。

**演算法:**
1. 取得所有鍵
2. 對每個鍵值對：
   - 格式化鍵名（需要時加引號）
   - 遞歸編碼值
3. 組合所有行

**返回:** 行陣列

```livescript
encode-object: (obj, depth) ->
  lines = []
  indent-str = ' ' * (depth * @indent)

  for key, value of obj
    formatted-key = @format-key key
    value-lines = @encode-value value, depth, formatted-key
    lines ++= value-lines

  lines.join '\n'
```

---

#### `encode-array(arr, depth, key)`
編碼陣列，自動選擇格式（inline / tabular / list）。

**決策樹:**
1. 檢查是否為表格格式候選
   - 所有元素都是物件？
   - 鍵集合一致？
   - 所有值都是基本型別？
   - 長度 > 0？
   → 是：使用表格格式
2. 檢查是否為基本型別陣列
   → 是：使用 inline 格式
3. 否則：使用列表格式

```livescript
encode-array: (arr, depth, key) ->
  len = arr.length
  len-marker = if @length-marker => "##{len}" else len
  indent-str = ' ' * (depth * @indent)

  # 檢查表格格式
  if @is-tabular arr
    @format-tabular arr, depth, key, len-marker

  # 檢查 inline 格式（所有元素都是基本型別）
  else if arr.every (el) -> typeof el isnt 'object' or el is null
    delim = @delimiter
    delim-marker = if delim is ',' => '' else delim
    values = arr.map (~> @encode-primitive it) .join delim

    if key?
      ["#{indent-str}#{key}[#{len-marker}#{delim-marker}]: #{values}"]
    else
      ["[#{len-marker}#{delim-marker}]: #{values}"]

  # 列表格式
  else
    @format-list arr, depth, key, len-marker
```

---

#### `is-tabular(arr)`
判斷陣列是否適合表格格式。

**條件:**
1. 長度 > 0
2. 所有元素都是物件
3. 所有物件的鍵集合相同
4. 所有值都是基本型別（非物件、非陣列）

```livescript
is-tabular: (arr) ->
  return false if arr.length is 0
  return false unless arr.every (el) -> typeof el is 'object' and el isnt null and not Array.is-array el

  # 取得第一個物件的鍵集合
  first-keys = Object.keys arr[0] .sort!

  # 檢查所有物件鍵集合一致
  return false unless arr.every (obj) ->
    keys = Object.keys obj .sort!
    keys.length is first-keys.length and keys.every (k, i) -> k is first-keys[i]

  # 檢查所有值都是基本型別
  arr.every (obj) ->
    Object.values obj .every (v) ->
      v is null or typeof v in <[ string number boolean ]>
```

---

#### `format-tabular(arr, depth, key, len-marker)`
格式化表格陣列。

**格式:**
```
key[N]{field1,field2,...}:
  value1,value2,...
  value1,value2,...
```

**演算法:**
1. 取得欄位列表（第一個物件的鍵）
2. 格式化 header：`[N<delim>]{field1<delim>field2}:`
3. 對每個物件：
   - 按欄位順序取值
   - 編碼每個值
   - 以分隔符連接
4. 組合所有行

```livescript
format-tabular: (arr, depth, key, len-marker) ->
  indent-str = ' ' * (depth * @indent)
  row-indent = ' ' * ((depth + 1) * @indent)
  delim = @delimiter
  delim-marker = if delim is ',' => '' else delim

  # 取得欄位
  fields = Object.keys arr[0]
  formatted-fields = fields.map (~> @format-key it) .join delim

  # Header
  header = if key?
    "#{indent-str}#{key}[#{len-marker}#{delim-marker}]{#{formatted-fields}}:"
  else
    "[#{len-marker}#{delim-marker}]{#{formatted-fields}}:"

  # Rows
  rows = arr.map (obj) ~>
    values = fields.map (field) ~> @encode-primitive obj[field]
    "#{row-indent}#{values.join delim}"

  [header] ++ rows
```

---

#### `format-list(arr, depth, key, len-marker)`
格式化列表陣列。

**格式:**
```
key[N]:
  - value1
  - value2
```

**特殊規則:**
- 物件的第一個欄位在 `"- "` 同行
- 後續欄位縮排對齊
- 陣列作為第一個欄位時，內容縮排兩空格

```livescript
format-list: (arr, depth, key, len-marker) ->
  indent-str = ' ' * (depth * @indent)
  item-indent = ' ' * ((depth + 1) * @indent)
  delim-marker = if @delimiter is ',' => '' else @delimiter

  # Header
  header = if key?
    "#{indent-str}#{key}[#{len-marker}#{delim-marker}]:"
  else
    "[#{len-marker}#{delim-marker}]:"

  # Items
  lines = [header]

  for item in arr
    if typeof item is 'object' and item isnt null and not Array.is-array item
      # 物件：第一個欄位在 "- " 同行
      keys = Object.keys item
      if keys.length > 0
        first-key = keys[0]
        first-value = @encode-primitive item[first-key]
        lines.push "#{item-indent}- #{@format-key first-key}: #{first-value}"

        # 後續欄位
        for i from 1 til keys.length
          k = keys[i]
          v = item[k]
          lines ++= @encode-value v, depth + 1, @format-key k
      else
        lines.push "#{item-indent}-"

    else if Array.is-array item
      # 陣列：inline 格式在 "- " 同行
      len = item.length
      len-marker-inner = if @length-marker => "##{len}" else len
      values = item.map (~> @encode-primitive it) .join @delimiter
      lines.push "#{item-indent}- [#{len-marker-inner}]: #{values}"

    else
      # 基本型別
      lines.push "#{item-indent}- #{@encode-primitive item}"

  lines
```

---

#### `encode-primitive(value)`
編碼基本型別。

**類型處理:**
- `null` → `"null"`
- `boolean` → `"true"` / `"false"`
- `number` → 正規化數字（無科學記號）
- `string` → 必要時加引號
- `undefined`, `function`, `symbol` → `"null"`

```livescript
encode-primitive: (value) ->
  | value is null => 'null'
  | value is undefined => 'null'
  | typeof value is 'boolean' => String value
  | typeof value is 'number' => @normalize-number value
  | typeof value is 'string' => @encode-string value
  | typeof value is 'bigint' => String value
  | value instanceof Date => @quote-string value.toISOString!
  | typeof value is 'function' => 'null'
  | typeof value is 'symbol' => 'null'
  | otherwise => 'null'
```

---

#### `normalize-number(num)`
正規化數字輸出。

**規則:**
- `NaN`, `Infinity`, `-Infinity` → `null`
- `-0` → `0`
- 科學記號轉十進位
- 保留必要的小數位數

```livescript
normalize-number: (num) ->
  return 'null' if not isFinite num
  return '0' if num is 0 or num is -0

  # 轉為字串，避免科學記號
  str = num.toString!
  return str unless /e/i.test str

  # 處理科學記號（簡化版）
  num.toFixed 20 .replace /\.?0+$/, ''
```

---

#### `encode-string(str)`
編碼字串，必要時加引號。

```livescript
encode-string: (str) ->
  if @should-quote str
    @quote-string str
  else
    str
```

---

#### `should-quote(str)`
判斷字串是否需要引號。

**需要引號的條件:**
1. 空字串
2. 前後有空白
3. 包含當前分隔符
4. 包含 `:`
5. 包含 `"`、`\`、控制字元
6. 看起來像 boolean/number/null
7. 以 `"- "` 開頭
8. 看起來像結構標記（`[N]`, `{key}` 等）

```livescript
should-quote: (str) ->
  return true if str is ''
  return true if str.0 is ' ' or str[str.length - 1] is ' '
  return true if str.indexOf(@delimiter) >= 0
  return true if str.indexOf(':') >= 0
  return true if str.indexOf('"') >= 0
  return true if str.indexOf('\\') >= 0
  return true if /[\x00-\x1F]/.test str
  return true if str in <[ true false null ]>
  return true if /^-?\d+(\.\d+)?$/.test str
  return true if str.starts-with '- '
  return true if /^\[.*\]$/.test str
  return true if /^\{.*\}$/.test str
  false
```

---

#### `quote-string(str)`
為字串加引號並轉義特殊字元。

**轉義規則:**
- `"` → `\"`
- `\` → `\\`
- `\n` → `\\n`
- `\r` → `\\r`
- `\t` → `\\t`

```livescript
quote-string: (str) ->
  escaped = str
    .replace /\\/g, '\\\\'
    .replace /"/g, '\\"'
    .replace /\n/g, '\\n'
    .replace /\r/g, '\\r'
    .replace /\t/g, '\\t'

  "\"#{escaped}\""
```

---

#### `format-key(key)`
格式化物件鍵，必要時加引號。

**規則:**
- 符合識別符模式：`/^[a-zA-Z_][a-zA-Z0-9_\.]*$/` 免引號
- 其他：需引號

```livescript
format-key: (key) ->
  if /^[a-zA-Z_][a-zA-Z0-9_\.]*$/.test key
    key
  else
    @quote-string key
```

---

## Decoder 解碼器

### Constructor

```livescript
decoder = (options = {}) ->
  @ <<<
    strict: false    # 嚴格模式（保留未來使用）

  @ <<< options
  @
```

### 主要方法

#### `decode(toon-str)`
解碼入口。

**流程:**
1. 分割為行
2. 偵測根層級類型
3. 解析並返回結果

```livescript
decode: (toon-str) ->
  return {} if toon-str is ''

  lines = toon-str.split '\n'

  # 檢查根層級類型
  first-line = lines[0]

  # 根陣列
  if first-line.starts-with '['
    @parse-root-array lines

  # 根物件
  else
    @parse-object lines, 0, 0
```

---

#### `parse-object(lines, start-idx, depth)`
解析物件。

**演算法:**
1. 從 `start-idx` 開始解析行
2. 對每行：
   - 計算縮排深度
   - 如果深度不符，停止
   - 解析鍵值對
   - 遞歸處理嵌套結構
3. 返回物件和結束索引

**返回:** `{ result, next-idx }`

```livescript
parse-object: (lines, start-idx, depth) ->
  obj = {}
  expected-indent = depth * 2  # 假設 indent = 2
  idx = start-idx

  while idx < lines.length
    line = lines[idx]
    current-indent = @get-indent line

    # 深度不符，結束
    break if current-indent < expected-indent

    # 解析行
    trimmed = line.trim!

    # 鍵值對
    if ':' in trimmed
      { key, value, is-nested } = @parse-key-value trimmed

      if is-nested
        # 嵌套結構
        if lines[idx + 1]? and lines[idx + 1].trim!.starts-with '- '
          # 列表陣列
          { result, next-idx } = @parse-list lines, idx + 1, depth + 1
          obj[key] = result
          idx = next-idx

        else if lines[idx + 1]? and /^\[.*\]\{/.test lines[idx + 1].trim!
          # 表格陣列
          { result, next-idx } = @parse-tabular lines, idx + 1, depth + 1
          obj[key] = result
          idx = next-idx

        else
          # 嵌套物件
          { result, next-idx } = @parse-object lines, idx + 1, depth + 1
          obj[key] = result
          idx = next-idx

      else
        # 基本值
        obj[key] = @parse-value value
        idx++

    else
      idx++

  { result: obj, next-idx: idx }
```

---

#### `parse-array(lines, start-idx, depth)`
解析陣列（自動偵測格式）。

```livescript
parse-array: (lines, start-idx, depth) ->
  header = lines[start-idx].trim!

  # 偵測格式
  if /^\[.*\]\{/.test header
    # 表格格式
    @parse-tabular lines, start-idx, depth

  else if /^\[.*\]:/.test header
    # 檢查下一行
    next-line = lines[start-idx + 1]

    if next-line?.trim!.starts-with '- '
      # 列表格式
      @parse-list lines, start-idx, depth
    else
      # Inline 格式
      @parse-inline lines, start-idx, depth

  else
    { result: [], next-idx: start-idx + 1 }
```

---

#### `parse-tabular(lines, start-idx, depth)`
解析表格格式陣列。

**演算法:**
1. 解析 header：`[N<delim>]{field1<delim>field2}:`
2. 取得長度、分隔符、欄位列表
3. 讀取 N 行
4. 對每行：分割值並對應到欄位
5. 返回物件陣列

```livescript
parse-tabular: (lines, start-idx, depth) ->
  header = lines[start-idx].trim!
  { length, delimiter, fields } = @parse-tabular-header header

  arr = []
  row-indent = (depth + 1) * 2
  idx = start-idx + 1

  for i from 0 til length
    break if idx >= lines.length

    line = lines[idx]
    current-indent = @get-indent line
    break if current-indent < row-indent

    # 分割值
    trimmed = line.trim!
    values = @split-values trimmed, delimiter

    # 建立物件
    obj = {}
    for field, i in fields
      obj[field] = @parse-value values[i] ? null

    arr.push obj
    idx++

  { result: arr, next-idx: idx }
```

---

#### `parse-tabular-header(header)`
解析表格 header。

**格式:** `[N<delim>]{field1<delim>field2}:`

**返回:** `{ length, delimiter, fields }`

```livescript
parse-tabular-header: (header) ->
  # 匹配 [N]{fields}: 或 [N<delim>]{fields}:
  match = header.match /^\[(\d+)(.)?\]\{([^}]+)\}:$/

  throw new Error "Invalid tabular header" unless match

  length = parseInt match[1], 10
  delimiter = match[2] ? ','
  fields-str = match[3]

  # 分割欄位
  fields = @split-values fields-str, delimiter

  { length, delimiter, fields }
```

---

#### `parse-inline(lines, start-idx, depth)`
解析 inline 格式陣列。

**格式:** `[N<delim>]: v1<delim>v2<delim>...`

```livescript
parse-inline: (lines, start-idx, depth) ->
  line = lines[start-idx].trim!

  # 匹配 [N]: values 或 [N<delim>]: values
  match = line.match /^\[(\d+)(.)?\]:\s*(.*)$/

  return { result: [], next-idx: start-idx + 1 } unless match

  length = parseInt match[1], 10
  delimiter = match[2] ? ','
  values-str = match[3]

  # 分割並解析值
  values = @split-values values-str, delimiter
  arr = values.map (~> @parse-value it)

  { result: arr, next-idx: start-idx + 1 }
```

---

#### `parse-list(lines, start-idx, depth)`
解析列表格式陣列。

**演算法:**
1. 解析 header 取得長度
2. 對每個 `"- "` 開頭的行：
   - 解析項目
   - 如果是物件，收集後續同層屬性
   - 如果是基本型別，直接加入
3. 返回陣列

```livescript
parse-list: (lines, start-idx, depth) ->
  header = lines[start-idx].trim!
  match = header.match /^\[(\d+)(.)?\]:$/

  length = if match => parseInt match[1], 10 else 0

  arr = []
  item-indent = (depth + 1) * 2
  idx = start-idx + 1

  while idx < lines.length and arr.length < length
    line = lines[idx]
    current-indent = @get-indent line
    break if current-indent < item-indent

    trimmed = line.trim!

    if trimmed.starts-with '- '
      content = trimmed.substring 2

      # 檢查是否為物件
      if ':' in content
        { key, value, is-nested } = @parse-key-value content
        obj = {}
        obj[key] = @parse-value value

        # 收集後續屬性
        idx++
        while idx < lines.length
          next-line = lines[idx]
          next-indent = @get-indent next-line
          break if next-indent <= item-indent

          { key: k, value: v } = @parse-key-value next-line.trim!
          obj[k] = @parse-value v
          idx++

        arr.push obj

      else
        # 基本型別或陣列
        arr.push @parse-value content
        idx++

    else
      idx++

  { result: arr, next-idx: idx }
```

---

#### `parse-value(str)`
解析基本型別值。

**類型檢測:**
1. `null` → `null`
2. `true`/`false` → boolean
3. 數字模式 → number
4. 引號字串 → unquote 並返回
5. 其他 → 字串

```livescript
parse-value: (str) ->
  return null if str is 'null'
  return true if str is 'true'
  return false if str is 'false'

  # 數字
  if /^-?\d+(\.\d+)?$/.test str
    return parseFloat str

  # 引號字串
  if str.0 is '"' and str[str.length - 1] is '"'
    return @unquote str

  # 一般字串
  str
```

---

#### `unquote(str)`
移除引號並反轉義。

```livescript
unquote: (str) ->
  # 移除前後引號
  content = str.substring 1, str.length - 1

  # 反轉義
  content
    .replace /\\n/g, '\n'
    .replace /\\r/g, '\r'
    .replace /\\t/g, '\t'
    .replace /\\"/g, '"'
    .replace /\\\\/g, '\\'
```

---

#### `split-values(str, delimiter)`
分割值字串，處理引號內的分隔符。

**演算法:**
1. 掃描字串
2. 追蹤引號狀態
3. 只在引號外分割
4. 返回值陣列

```livescript
split-values: (str, delimiter) ->
  values = []
  current = ''
  in-quote = false
  i = 0

  while i < str.length
    char = str[i]

    if char is '"'
      if i > 0 and str[i - 1] is '\\'
        current += char
      else
        in-quote := not in-quote
        current += char

    else if char is delimiter and not in-quote
      values.push current.trim!
      current := ''

    else
      current += char

    i++

  values.push current.trim! if current
  values
```

---

#### `get-indent(line)`
取得行的縮排空格數。

```livescript
get-indent: (line) ->
  count = 0
  for char in line
    break if char isnt ' '
    count++
  count
```

---

#### `parse-key-value(str)`
解析 `key: value` 字串。

**返回:** `{ key, value, is-nested }`

```livescript
parse-key-value: (str) ->
  # 找到第一個非引號內的 ":"
  colon-idx = -1
  in-quote = false

  for char, i in str
    if char is '"' and (i is 0 or str[i - 1] isnt '\\')
      in-quote := not in-quote
    else if char is ':' and not in-quote
      colon-idx := i
      break

  throw new Error "Invalid key-value pair" if colon-idx < 0

  key-str = str.substring 0, colon-idx .trim!
  value-str = str.substring colon-idx + 1 .trim!

  # 解析鍵（可能有引號）
  key = if key-str.0 is '"' => @unquote key-str else key-str

  # 判斷是否為嵌套
  is-nested = value-str is ''

  { key, value: value-str, is-nested }
```

---

## 公開 API

### 便捷函式

```livescript
# 便捷編碼函式
encode = (value, options) ->
  enc = new encoder options
  enc.encode value

# 便捷解碼函式
decode = (toon-str, options) ->
  dec = new decoder options
  dec.decode toon-str
```

### 匯出

```livescript
# 跨環境匯出
if window?
  window <<< { encoder, decoder, encode, decode }
else
  module.exports = { encoder, decoder, encode, decode }
```

---

## 演算法複雜度

### 編碼器
- **時間複雜度**: O(n)，其中 n 是值的總數（包含嵌套）
- **空間複雜度**: O(d)，其中 d 是最大嵌套深度（遞歸堆疊）

### 解碼器
- **時間複雜度**: O(m)，其中 m 是行數
- **空間複雜度**: O(d + m)，d 是嵌套深度，m 是行數

---

## 錯誤處理策略

### 編碼器
- 非可序列化值 → `null`
- 循環引用 → 未處理（假設輸入無循環）
- 特殊數值 (`NaN`, `Infinity`) → `null`

### 解碼器
- 格式錯誤 → 拋出 `Error` 並包含行號
- 不完整結構 → 返回部分結果
- 類型推斷失敗 → 預設為字串

---

## 測試策略

### 單元測試
1. **類型測試**：每種基本型別、物件、陣列
2. **格式測試**：inline、tabular、list 格式
3. **引號測試**：各種需要引號的情況
4. **嵌套測試**：多層嵌套結構
5. **邊界測試**：空容器、特殊字串、極端數值

### 整合測試
1. **往返測試** (Round-trip)：JSON → TOON → JSON
2. **樣本測試**：所有 samples/ 檔案
3. **選項測試**：不同分隔符和選項組合

### 效能測試
1. 大型陣列（10,000+ 項目）
2. 深層嵌套（100+ 層）
3. 大型表格（1,000+ 行）

---

## 優化機會

### 編碼器
1. **字串連接**：使用陣列累積後 join，避免多次字串拼接
2. **引號檢測**：快速路徑檢測常見安全字串
3. **表格檢測**：快取鍵集合比較結果

### 解碼器
1. **行預處理**：一次性計算所有行的縮排
2. **正則表達式**：預編譯常用模式
3. **值解析**：快速路徑識別數字和布林

---

**狀態**: ✅ 架構設計完成

**下一步**: 根據此架構實作 `src/index.ls`
