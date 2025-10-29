# TOON LiveScript 實作專案總覽

## 專案狀態

**目前階段**: ✅ 規劃完成，準備開始實作

## 專案目標

使用 LiveScript 實作 TOON (Token-Oriented Object Notation) 格式的雙向轉換器：
1. **JSON → TOON** 編碼器
2. **TOON → JSON** 解碼器

## 專案結構

```
/workspace
├── src/
│   └── index.ls              # 主要實作檔案（待實作）
│
├── tests/
│   ├── encoder.test.ls       # 編碼器測試（待實作）
│   ├── decoder.test.ls       # 解碼器測試（待實作）
│   └── integration.test.ls   # 整合測試（待實作）
│
├── samples/                  # 測試樣本資料夾
│   ├── README.md             # ✅ 測試案例規劃文件
│   ├── simple/               # 簡單案例資料夾（待填充樣本）
│   ├── complex/              # 複雜案例資料夾（待填充樣本）
│   └── edge-cases/           # 邊界案例資料夾（待填充樣本）
│
├── DEV.md                    # ✅ 開發需知文件
├── ARCHITECTURE.md           # ✅ 架構設計文件
├── PROJECT.md                # ✅ 本文件（專案總覽）
├── spec.md                   # ✅ TOON 規格文件
├── lsc-coding-guide.md       # ✅ LiveScript 編程風格指南
│
├── package.json              # Node.js 專案設定
└── build                     # 建置腳本

```

## 已完成的規劃文件

### 1. DEV.md - 開發需知文件
包含：
- 專案概述與目標
- 資料夾結構說明
- 實作架構設計概要
- 測試案例規劃摘要
- 開發步驟（Phase 1-5）
- 編碼風格規範說明
- API 使用範例
- 開發注意事項

### 2. ARCHITECTURE.md - 架構設計文件
包含：
- 模組結構圖
- **Encoder** 詳細設計
  - Constructor 和選項
  - 所有方法的演算法說明
  - 引號規則實作
  - 表格格式檢測邏輯
  - 程式碼範例
- **Decoder** 詳細設計
  - Constructor 和選項
  - 解析器演算法
  - 格式偵測邏輯
  - 值類型推斷
  - 程式碼範例
- 公開 API 設計
- 演算法複雜度分析
- 錯誤處理策略
- 測試策略
- 優化機會

### 3. samples/README.md - 測試案例規劃
包含：
- **簡單案例** (5 組)
  - 基本型別
  - 簡單物件
  - 簡單陣列
  - 嵌套物件
  - 嵌套陣列
- **複雜案例** (6 組)
  - 深層嵌套
  - 表格格式
  - 混合陣列
  - 陣列的陣列
  - 嵌套表格
  - 非統一物件列表
- **邊界案例** (8 組)
  - 空容器
  - 特殊字串（需引號）
  - Unicode 和 Emoji
  - 特殊數值
  - 特殊鍵名
  - 根層級陣列
  - 根層級基本型別
  - 空的根容器
- **選項測試** (3 組)
  - Tab 分隔符
  - Pipe 分隔符
  - Length marker

**總計**: 22 組測試案例，44 個樣本檔案（待建立）

## 技術規格

### 輸入/輸出
- **輸入**: JSON 相容的 JavaScript 值
- **輸出**: TOON 格式字串（無尾隨換行）

### 編碼選項
```livescript
{
  indent: 2              # 縮排空格數（預設 2）
  delimiter: ','         # 分隔符: ',' | '\t' | '|'
  length-marker: false   # 長度前綴 '#' 標記
}
```

### 解碼選項
```livescript
{
  strict: false          # 嚴格模式（保留）
}
```

### 公開 API
```livescript
# Classes
encoder = new encoder(options)
decoder = new decoder(options)

# 便捷函式
toon-str = encode(value, options)
json-value = decode(toon-str, options)
```

## TOON 格式特性

### 基本規則
- **縮排**: 2 空格（可設定）
- **物件**: `key: value` 或 `key:` (嵌套)
- **陣列長度**: `[N]` 或 `[N<delim>]`
- **表格格式**: `[N]{field1,field2}:`
- **列表格式**: `"- "` 前綴

### 引號規則
**字串需要引號的情況**:
- 空字串
- 前後空白
- 包含分隔符、冒號、引號、反斜線
- 看起來像保留字（true, false, null）
- 看起來像數字
- 以 `"- "` 開頭
- 看起來像結構標記

**鍵名需要引號的情況**:
- 不符合識別符模式: `/^[a-zA-Z_][a-zA-Z0-9_\.]*$/`

### 表格格式條件
1. 所有元素都是物件
2. 鍵集合完全相同
3. 所有值都是基本型別
4. 長度 > 0

## 開發階段

### Phase 1: 編碼器基礎 ⏳
- [ ] 基本型別編碼
- [ ] 物件編碼
- [ ] 陣列編碼（列表格式）
- [ ] 引號規則
- [ ] 簡單案例測試

### Phase 2: 編碼器進階 ⏳
- [ ] 表格格式檢測
- [ ] 表格格式輸出
- [ ] 分隔符選項
- [ ] Length marker 選項
- [ ] 複雜案例測試

### Phase 3: 編碼器邊界 ⏳
- [ ] 空容器處理
- [ ] 特殊字串處理
- [ ] Unicode/Emoji 支援
- [ ] 特殊數值處理
- [ ] 邊界案例測試

### Phase 4: 解碼器 ⏳
- [ ] 行解析器
- [ ] 物件解析
- [ ] 陣列解析（列表）
- [ ] 表格解析
- [ ] 值解析與反引號
- [ ] 往返測試

### Phase 5: 整合與優化 ⏳
- [ ] 完整測試套件
- [ ] 樣本整合測試
- [ ] 效能優化
- [ ] 錯誤處理
- [ ] 文件完善

## 編碼風格

遵循 `lsc-coding-guide.md` 規範：
- Constructor pattern（小寫）
- kebab-case 命名
- `@ <<<` 批次設定
- `Object.create` 重建 prototype
- `~>` 綁定 context
- 簡短條件使用 `=>`
- 註解解釋「為什麼」

## 效能目標

### Token 節省
- 相比 JSON: 30-60% token 減少
- 相比 XML: 40-70% token 減少

### 處理能力
- 編碼: > 10,000 項目/秒
- 解碼: > 5,000 項目/秒
- 記憶體: O(depth) 空間複雜度

## 測試策略

### 單元測試
- 類型測試
- 格式測試
- 引號測試
- 嵌套測試
- 邊界測試

### 整合測試
- 往返測試 (JSON → TOON → JSON)
- 格式穩定性 (TOON → JSON → TOON)
- 所有樣本檔案測試

### 效能測試
- 大型陣列（10,000+ 項目）
- 深層嵌套（100+ 層）
- 大型表格（1,000+ 行）

## 參考資料

- **TOON 規格**: spec.md
- **架構設計**: ARCHITECTURE.md
- **開發指南**: DEV.md
- **測試規劃**: samples/README.md
- **編碼風格**: lsc-coding-guide.md
- **原始專案**: https://github.com/byjohann/toon

## 下一步行動

1. **實作編碼器基礎**
   - 在 `src/index.ls` 建立 encoder 類
   - 實作基本型別編碼
   - 實作物件編碼
   - 實作陣列編碼（列表格式）

2. **建立測試樣本**
   - 建立簡單案例的 JSON 和 TOON 檔案
   - 用於手動測試和驗證

3. **建立測試框架**
   - 設定測試執行環境
   - 建立測試輔助函式
   - 實作第一個測試

## 專案資訊

- **語言**: LiveScript
- **環境**: Node.js
- **測試**: 手動 + 自動化
- **文件**: Markdown
- **授權**: （待定）

---

**規劃完成日期**: 2025-10-29

**預計開始實作**: 待用戶確認

**規劃文件完整度**: ✅ 100%
- ✅ 開發需知
- ✅ 架構設計
- ✅ 測試規劃
- ✅ 專案總覽
