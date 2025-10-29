# LiveScript Constructor Pattern 編程指南

## 概述

這份指南介紹如何在 LiveScript 中使用 old-style constructor pattern，包含原型鏈管理、context 處理和最佳實踐。

## 基本結構

### Constructor 函式

```livescript
widget = (param1, param2) ->
  # 初始化實例變數
  @property1 = param1
  @property2 = param2
  @state = false
  
  # 調用初始化方法
  @init!
  
  # 回傳 @ 確保 new 操作正確
  @
```

### 批次設定實例變數

使用 import 語法可以批次設定多個實例變數：

```livescript
widget = (options = {}) ->
  # 批次匯入預設值
  @ <<<
    is-active: false
    is-visible: true
    count: 0
    handlers: {}
    
  # 覆蓋用戶提供的選項
  @ <<< options
  
  @init!
  @
```

### 乾淨的 Prototype 重建

使用 `Object.create` 重新建構 prototype 避免 pollution：

```livescript
# 重新建構乾淨的 prototype 並一次性匯入所有方法
widget.prototype = Object.create(Object.prototype) <<<
  constructor: widget
  
  init: ->
    # 初始化邏輯
    console.log "初始化完成"
  
  method1: ->
    # 一般方法
    @property1
    
  method2: (param) ~>
    # 需要綁定 context 的方法
    @state = param
```

## 關鍵語法特色

### 1. `@` (this) 的使用
- `@property`：存取實例屬性
- `@method!`：調用實例方法（無參數時使用 `!`）
- `@method(param)`：調用帶參數的實例方法

### 2. `~>` vs `->` 
- `->` 普通函式，`this` 會隨調用方式改變
- `~>` 綁定箭頭，`this` 永遠指向定義時的 context

### 3. `<<<` Object Import
```livescript
MyClass.prototype = Object.create(Object.prototype) <<<
  method1: -> ...
  method2: -> ...
  method3: -> ...
```

### 4. 單行條件和函式

對於簡短的條件語句和函式，可以寫成一行：

```livescript
# 簡短條件 - 使用 => 取代 then
if condition => action1 else action2
return value if condition

# 緊湊的 try-catch
try a = b catch e => console.log e
try @parse-data! catch => @handle-error!

# 簡短函式
get-value: -> @property
set-active: (state) -> @is-active = state

# 簡短事件處理
on-click: (e) -> if @is-enabled => @toggle! else @show-warning!
```

**注意 Nested 條件的優先順序問題：**

```livescript
# ❌ 可能有歧義
if a => if b => c else d else e

# ✅ 使用括號明確化
if a => (if b => c else d) else e

# ✅ 或者刻意換行縮排
if a 
  if b => c else d
else 
  e

# ✅ 複雜邏輯建議完整縮排
if @is-dragging and @left-panel?
  if new-width > @min-width
    @update-width new-width
  else
    @reset-width!
```

### 5. 快速 Local Scoped Context

當需要建立臨時的 local scope 或執行帶 context 的程式碼：

```livescript
# 快速建立 local scoped context
<-(-> it.apply {}) _

# 實際應用範例
# 建立臨時 context 執行初始化
<-(-> 
  @temp-data = it.process-config config
  @validate-data!
  it.apply @
) @

# 或用於資料處理
result <-(-> it.map (.toUpperCase!) .filter (.length > 0)) data

# 配合物件建立臨時 scope
<-(-> 
  {width, height} = it
  @resize width, height
  it.apply @container
) dimensions
```

## 跨環境匯出

支援瀏覽器和 Node.js 環境的標準匯出模式：

```livescript
# 定義 constructor
widget = (container, options = {}) ->
  # ... constructor 實作

# 設定 prototype
widget.prototype = Object.create(Object.prototype) <<<
  # ... 方法定義

# 跨環境匯出
if window?
  window.widget = widget
else
  module.exports = widget
```

## Event Handler Context 處理

當使用成員函式作為事件處理器時，必須正確處理 context：

### ❌ 錯誤寫法
```livescript
setup-events: ->
  element.add-event-listener 'click', @on-click  # context 會跑掉
```

### ✅ 正確寫法
```livescript
setup-events: ->
  element.add-event-listener 'click', (e) ~> @on-click.apply @, [e]
  
  # 或使用 bind（但 apply 更明確）
  element.add-event-listener 'click', @on-click.bind(@)
```

### Event Handler 方法定義
```livescript
on-click: (e) ~>  # 使用 ~> 確保能存取實例變數
  e.prevent-default!
  @state = !@state  # 正確存取實例屬性
```

## 完整範例

```livescript
Widget = (container, options = {}) ->
  @container = container
  @options = options
  @is-active = false
  @handlers = {}
  
  @init!
  @

Widget.prototype = Object.create(Object.prototype) <<<
  constructor: Widget
  
```livescript
widget = (container, options = {}) ->
  # 批次匯入預設值和參數
  @ <<<
    container: container
    is-active: false
    is-visible: true
    count: 0
    handlers: {}
  
  # 覆蓋用戶提供的選項
  @ <<< options
  
  @init!
  @

widget.prototype = Object.create(Object.prototype) <<<
  constructor: widget
  
  init: ->
    @setup-events!
    @render!
  
  setup-events: ->
    @container.add-event-listener 'click', (e) ~> @on-click.apply @, [e]
    document.add-event-listener 'keydown', (e) ~> @on-keydown.apply @, [e]
  
  on-click: (e) ~>
    e.prevent-default!
    @toggle!
  
  on-keydown: (e) ~>
    return unless e.key is 'Escape'
    @deactivate!
  
  toggle: ->
    if @is-active then @deactivate! else @activate!
  
  activate: ->
    @is-active = true
    @container.class-list.add 'active'
    @trigger 'activate'
  
  deactivate: ->
    @is-active = false
    @container.class-list.remove 'active'
    @trigger 'deactivate'
  
  trigger: (event-name, data = {}) ->
    event = new CustomEvent event-name, detail: data
    @container.dispatch-event event
  
  render: ->
    # 渲染邏輯
    @container.innerHTML = "<div>Widget Content</div>"

# 跨環境匯出
if window?
  window.widget = widget
else
  module.exports = widget

# 使用方式
container = document.query-selector '#my-widget'
my-widget = new widget(container, { theme: 'dark' })
```

## 最佳實踐

### 1. 命名慣例
- Constructor：全小寫 (`widget`, `modal`, `dropdown`)
- 方法和屬性：kebab-case (`my-method`, `is-active`)
- 私有概念方法：底線前綴 (`_private-method`)
- 實例變數：kebab-case 便於 import 批次設定
- **DOM 根元素**：使用 `root` 而非 `container`
- **原始參數保存**：使用 `@_opt` 保存建構子參數
- **私有狀態**：使用底線前綴如 `@_cache`, `@_state`

### 2. 註解原則
- **主要目的**：解釋「為什麼這樣寫」而非「寫了什麼」
- **簡述用法**：複雜 API 可簡單說明，然後引導查看文件
- **避免冗餘**：不要重述顯而易見的程式碼邏輯
- **關鍵決策**：解釋重要的設計決策和權衡考量

```livescript
# ✅ 好的註解 - 解釋原因和決策
setup-events: ->
  # Use document-level events to handle mouse move/up anywhere
  # This prevents losing drag state when cursor moves outside panels
  document.add-event-listener 'mousemove', @on-mouse-move
  
  # Store original options for potential reconfiguration - see docs
  @_opt = original-options

# ❌ 避免的註解 - 重述程式碼
setup-events: ->
  # Add event listener to document for mousemove
  document.add-event-listener 'mousemove', @on-mouse-move
```

### 2. 實例變數管理
- 使用 `@ <<< { key: value }` 批次設定預設值
- 參數覆蓋：先設定預設值，再 `@ <<< options`
- 保持一致的命名風格便於維護

### 2. 原型鏈安全
- 總是使用 `Object.create(Object.prototype)` 重建乾淨的 prototype
- 明確設定 `constructor` 屬性

### 10. Context 管理
- Event handlers 必須使用 `apply` 或 `bind` 處理 context
- 需要存取實例變數的方法使用 `~>`
- 純函式可以使用 `->`

### 11. 初始化模式
- Constructor 中設定所有實例變數
- 使用 `@init!` 進行複雜初始化
- 最後回傳 `@`

### 13. 記憶體管理
- 適當移除事件監聽器
- 提供 `destroy` 方法進行清理

## 進階技巧

### Mixin 模式
```livescript
event-mixin =
  on: (event, handler) ->
    @listeners ?= {}
    (@listeners[event] ?= []).push handler
  
  trigger: (event, data) ->
    return unless @listeners?[event]
    handler data for handler in @listeners[event]

widget.prototype = Object.create(Object.prototype) <<< event-mixin <<<
  # 其他方法...
```

### 工廠函式
```livescript
create-widget = (type, container, options) ->
  switch type
  | 'modal' => new modal(container, options)
  | 'dropdown' => new dropdown(container, options)
  | _ => new widget(container, options)
```

這種 pattern 提供了類似 class 的功能，同時保持了對原型鏈的完全控制，適合需要高度客製化的場景。