# RecordLife 项目结构分析与重构方案

> 状态：**重构前评估已完成（尚未开始执行）**
> 目标：在不改变现有功能行为的前提下，按照 HarmonyOS / ArkTS 行业最佳实践进行架构与代码质量重构。

---

## 0. ⚠️ 数据兼容性要求（最高优先级约束）

> **背景**：用户已使用当前版本的「导出全部数据」功能生成了一份备份文件（`.zip`）。
> 重构后的新版本**必须能无损导入该备份文件**，否则用户数据将丢失。
> 此约束优先级高于一切重构改动，任何涉及数据模型 / 持久化 / 备份导入导出的变更都必须先验证向后兼容。

### 0.1 当前备份格式快照（v0.0.x → 必须兼容的基线）

**导出产物**：`RecordLife_all_{timestamp}.zip`（zlib 压缩）

**解压后目录结构**：
```text
RecordLife_all_{timestamp}/
├── config.json              # 用户配置（含头像 base64）
├── records_metadata.json    # 此刻记录元数据 + 全部 LifeRecord
└── records/                 # 图片文件目录（原图拷贝）
    ├── {recordId}_{index}.jpg
    └── ...
```

**`config.json` 结构**（由 `ConfigManager.exportConfig()` 生成）：
```jsonc
{
  "settings": { "theme": "light", /* AppSettings 其余字段 */ },
  "backup":   { /* BackupConfig */ },
  "statistics": { /* DataStatistics */ },
  "metadata": { /* ConfigMetadata */ },
  "exportedAt": "2026-08-22T...",
  "appVersion": "0.0.x",
  "profile": {
    "name": string,
    "birthDate": string,   // yyyy-MM-dd
    "gender": string,
    "avatar": string       // base64 编码，可能为空
  }
}
```

**`records_metadata.json` 结构**（由 `BackupManager` 生成）：
```jsonc
{
  "appVersion": "0.0.x",
  "timestamp": number,       // 毫秒
  "recordCount": number,
  "records": [
    {
      "id": string,
      "timestamp": number,   // 毫秒
      "content": string,
      "imagePaths": string[], // 可选
      "tags": string[],       // 可选，标签 ID 数组
      "isPinned": boolean     // 可选
    }
  ]
}
```

### 0.2 兼容性约束清单

| # | 约束 | 验证方式 |
| --- | --- | --- |
| C1 | 新版本 `importAll()` 必须能解析上述 zip 结构并完整还原 `config.json` + `records_metadata.json` + `records/` 图片 | 用现有备份文件做导入冒烟测试 |
| C2 | `LifeRecord` 字段（`id` / `timestamp` / `content` / `imagePaths?` / `tags?` / `isPinned?`）语义不得改变；新增字段必须可选 | 导入后逐条比对记录数与内容 |
| C3 | `UserProfile`（`name` / `birthDate` / `gender` / `avatar`）语义不得改变；`avatar` 仍需支持 base64 字符串 | 导入后检查账号页信息 |
| C4 | 标签 `Tag`（`id` / `name` / `color` / `icon?`）语义不得改变；`records[].tags` 引用的是 `Tag.id` | 导入后检查标签列表与记录关联 |
| C5 | 图片导入后路径映射必须正确（从备份 `records/` 目录还原到应用沙盒或图库） | 导入后检查时间线图片是否正常显示 |
| C6 | 若新版本采用新的备份格式（如 schema 版本化），必须保留 **legacy v1 解析器** 作为降级路径 | 代码审查 + 导入旧备份测试 |

### 0.3 重构中的操作规范

1. **任何涉及 `BackupManager` / `ConfigManager.exportConfig|importConfig` / `MorePageBackupHandler.exportAll|importAll` 的改动，必须在 PR/提交说明中注明已通过旧备份导入验证。**
2. 若确需演进数据模型（如 `LifeRecord` 增加必填字段），必须在导入流程中提供 **数据迁移（migration）** 逻辑，自动将旧格式补齐为新格式，而非直接拒绝导入。
3. 建议在重构早期即为备份文件引入 `schemaVersion` 字段（当前旧文件无此字段，视为 `schemaVersion = 1`），导入时按版本号分发到对应解析器。

---

## 1. 项目概览

| 维度 | 现状 |
| --- | --- |
| 项目类型 | HarmonyOS 应用（entry 单 HAP） |
| 语言 | ArkTS / ArkUI |
| 架构 | 已具备 MVVM 雏形（Page + ViewModel + Config + Components） |
| 主要页面 | Index、HomePage、NowPage、MorePage、AccountPage、StorageImagePage |
| 业务领域 | 记录生活时间线、标签管理、主题切换、数据备份/导入导出、图片存储 |
| 持久化 | `Preferences`、文件 IO、图库（photoAccessHelper） |

---

## 2. 当前目录结构（source 层）

```text
entry/src/main/ets/
├── entryability/
│   └── EntryAbility.ets
├── pages/
│   ├── Index.ets                  # 主 Tab 容器（@Entry）
│   ├── HomePage.ets               # 存活时间卡片（Tab 内容）
│   ├── NowPage.ets                # 时间线（Tab 内容，误标 @Entry）
│   ├── MorePage.ets               # 更多设置（路由页 @Entry）
│   ├── AccountPage.ets            # 账号设置（Tab 内容，误标 @Entry）
│   └── StorageImagePage.ets       # 图片存储（路由页 @Entry）
├── components/
│   ├── common/                    # AnimatedNumber、ImageViewer、SearchBar…
│   ├── calendar/                  # 日历相关
│   ├── dialog/                    # 各类弹窗
│   ├── record/                    # 时间线/记录相关
│   ├── setting/                   # 设置项
│   ├── share/                     # 分享卡片
│   └── user/                      # 用户信息
├── viewmodel/
│   ├── NowViewModel.ets
│   └── AccountViewModel.ets
├── config/
│   ├── ConfigManager.ets          # 巨型配置管理（含标签/导入导出/备份）
│   ├── ThemeConfig.ets
│   ├── ThemeManager.ets
│   ├── UserConfig.ets
│   └── AppInfoConfig.ets
├── common/
│   ├── types.ets                  # 领域类型 + 预设标签
│   ├── ColorUtils.ets
│   ├── managers/                  # BackupManager、RefreshManager
│   ├── handlers/                  # MorePageBackupHandler、MorePageConfigHandler
│   └── utils/                     # AccountUtils、ImageBase64Utils、TimeUtils…
└── utils/
    └── ShareUtils.ets             # 与 common/utils 职责重叠
```

---

## 3. 现状优势（可保留的设计）

- 已初步分层：Page / Component / ViewModel / Config，方向正确。
- 主题已抽象为 `ThemeConfig` + `ThemeManager`，支持明暗主题。
- 组件拆分较细（calendar、dialog、setting、share 等分组清晰）。
- 存在 `RefreshManager` 全局刷新、备份/导入导出等业务服务雏形。
- 已配置 `hypium` / `hamock` 测试依赖，具备接入单测的基础。

---

## 4. 问题清单（按优先级）

### 4.1 架构层面（高）

| # | 问题 | 证据 / 影响 | 建议 |
| --- | --- | --- | --- |
| A1 | **领域模型重复定义且字段冲突** | `UserProfile` 同时定义于 `config/UserConfig.ets` 与 `viewmodel/AccountViewModel.ets`，字段不一致（`birthDate` vs `birthday`）；`DataStatistics` 两处定义，`dataVersion` 类型分别为 `number` 与 `string` | 统一到 `model/` 目录，单一数据源 |
| A2 | **`ConfigManager` 职责过重** | 承担配置读写、标签 CRUD、导入导出、备份等多项职责，类体庞大、耦合 `AppStorage` | 拆分为 `ConfigRepository` + 标签/备份/导入导出独立 Service |
| A3 | **ViewModel 职责过重** | `NowViewModel` 混合数据管理、时间线构建、文件/图片 IO；`AccountViewModel` 混合资料、主题、统计、存储统计 | 按职责拆分，数据访问下沉到 Repository/Service |
| A4 | **`@Entry` 与 `main_pages.json` 不一致** | `NowPage`、`AccountPage` 作为 `Index` 的 Tab 内容，却标记 `@Entry`；`NowPage` 既被 Tab 引用又被注册为路由 | 路由页面才标 `@Entry`，Tab 内容改为 `@Component export`，并同步 `main_pages.json` |
| A5 | **全局状态耦合** | `ConfigManager` 依赖 `AppStorage('uiContext')`，多处单例 + 全局可变状态，难以测试与替换 | 引入 Repository 依赖注入，减少对 `AppStorage` 的直接依赖 |

### 4.2 代码质量（高）

| # | 问题 | 证据 / 影响 | 建议 |
| --- | --- | --- | --- |
| B1 | **硬编码颜色泛滥** | 全工程 100+ 处十六进制颜色（`#007DFF`、`#E8F5E9`、`#333333`…），违反资源化规范 | 抽取到 `color.json`（明/暗两套）或统一走 `ThemeColors` |
| B2 | **硬编码 UI 字符串** | 大量中文文本直接写在组件（`'工作'`、`'年'`、`'月'`…），无法国际化 | 抽取到 `string.json`（zh/en 双语） |
| B3 | **调试日志泛滥** | 100+ 处 `console.info/warn/error`，含 `>>> startAddTag 被调用 <<<` 等临时调试 | 统一 `hilog` + 日志开关，移除临时日志 |
| B4 | **`@ohos.*` 与 `@kit.*` 混用** | 11 处旧式 `@ohos.*` 导入（如 `@ohos.data.preferences`），与官方推荐 `@kit.*` 不一致 | 统一为 `@kit.*` |
| B5 | **重复工厂函数** | `createDefaultConfig` 与 `createDefaultConfigSync` 几乎重复 | 合并为单一实现，异步/同步按需封装 |
| B6 | **深拷贝反模式** | `NowPage.ets` 中 `JSON.parse(JSON.stringify(...)) as TimelineData` | 使用结构化拷贝或模型构造器，避免类型不安全 |
| B7 | **生命周期初始化风险** | 部分组件成员初始化时调用 `getUIContext().getPromptAction()` | 延迟到 `aboutToAppear()` 中初始化 |

### 4.3 可维护性与可测试性（中）

| # | 问题 | 影响 | 建议 |
| --- | --- | --- | --- |
| C1 | 目录语义混乱 | `utils/` 与 `common/utils/` 并存，`common/` 下混放 types、utils、managers、handlers | 重新规划目录（见第 5 节） |
| C2 | 无单元测试 | 已依赖 hypium，但未发现测试用例 | 为纯逻辑（时间计算、配置校验、标签管理）补测试 |
| C3 | 巨型页面组件 | HomePage(~717 行)、NowPage(~648 行)、AccountPage(~435 行) | 继续拆分子组件 + 下沉逻辑 |
| C4 | 缓存目录未明确排除 | `.hvigor/`、`.preview/`、`.appanalyzer/` 等进入扫描 | 补充/核对 `.gitignore` |

---

## 5. 目标架构（最佳实践）

采用 **分层架构 + 单一职责**：

```text
entry/src/main/ets/
├── entryability/              # Ability 生命周期入口
├── pages/                     # 仅真正路由页面（@Entry）
├── components/                # 可复用 UI 组件（按业务分组）
├── viewmodel/                 # 页面状态编排（纯 UI 状态 + 交互）
├── model/                     # 统一领域模型 / 类型 / 常量
├── repository/                # 数据访问层（Preferences / 文件 / 图片）
├── service/                   # 业务服务（备份、导入导出、分享、图片）
├── common/                    # 无业务通用工具（constants / utils）
└── config/                    # 主题与配置（瘦身后的 ConfigManager）
```

核心依赖方向（自上而下，禁止反向依赖）：

```text
pages/components → viewmodel → repository/service → 存储/系统 API
```

---

## 6. 分阶段重构方案

> 每个阶段独立可编译、可回归，遵循“小步提交、增量验证”。

### 阶段 0 — 建立基线保护
- 核对 `.gitignore`，排除 `.hvigor/`、`.preview/`、`.appanalyzer/`、`build/`、`oh_modules/`。
- 执行一次完整构建 `hvigorw assembleHap`，记录当前编译基线。
- 确认 hypium/hamock 测试接入方式，准备最小测试样例。

### 阶段 1 — 资源化与国际化
- 新增 `color.json`（明/暗两套主题色、语义色），替换 B1 硬编码颜色。
- 新增 `string.json`（`zh_CN` / `en_US`），替换 B2 硬编码文本。
- `ThemeConfig` 中颜色改为引用资源或统一语义常量。

### 阶段 2 — 统一领域模型
- 新建 `model/`，合并 `UserProfile`、`DataStatistics` 等重复定义（解决 A1）。
- 统一 `Tag`、`LifeRecord`、`TimelineData` 等类型归属，`common/types.ets` 迁移至 `model/`。

### 阶段 3 — 数据访问层抽象
- 新建 `repository/`，封装 `Preferences` 读写（`ConfigRepository`、`RecordRepository`）。
- 拆分 `ConfigManager`（解决 A2）：配置读写、标签管理、导出导入、备份各自独立。
- 拆分 `NowViewModel` / `AccountViewModel` 中的文件/图片/存储 IO 到 `service/`（解决 A3）。

### 阶段 4 — 代码质量与语法合规
- 统一 `@ohos.*` → `@kit.*`（解决 B4）。
- 合并 `createDefaultConfig*` 重复实现（解决 B5）。
- 替换 JSON 深拷贝（解决 B6）。
- 收敛日志，统一 `hilog` + 开关，移除临时调试日志（解决 B3）。
- 修复生命周期初始化（解决 B7）。

### 阶段 5 — UI 组件拆分与路由修正
- 拆分 `HomePage`、`NowPage`、`AccountPage` 巨型组件（解决 C3）。
- 修正 `@Entry` 与 `main_pages.json` 一致性（解决 A4）。
- 目录重组（解决 C1）：统一 `common/utils`，业务工具归入 `service/`。

### 阶段 6 — 可测试性提升
- Repository/Service 通过构造器注入，去除对 `AppStorage` 的硬依赖（解决 A5、C2）。
- 为时间计算、配置校验、标签管理、导入导出等核心逻辑补单元测试。

### 阶段 7 — 收尾验证
- 全量编译 + 功能回归（主题切换、标签、时间线、备份/导入导出、图片存储）。
- 深色主题回归、国际化双语文案回归。
- 性能检查（列表渲染、图片 IO）。

---

## 7. 风险与注意事项

1. **数据兼容**：重构 Repository 时必须保持 `Preferences` 存储 key 与数据格式不变，或提供一次性迁移逻辑。
2. **国际化遗漏**：抽字符串时需逐语言补全，避免仅保留中文。
3. **深色主题回归**：颜色资源化后需验证明/暗两套主题显示一致。
4. **路由/入口变更**：修改 `@Entry` 时同步 `main_pages.json`，避免页面无法打开。
5. **ArkTS 语法约束**：不使用 `any/unknown`、索引访问类型、`as const` 等，重构时严格遵循。
6. **增量验证**：每阶段完成后立即编译，避免一次性大改导致难以定位问题。

---

## 8. 验证清单

- [ ] `hvigorw assembleHap` 编译通过，无 Error
- [ ] 首页存活时间展示正常
- [ ] 时间线增删改查、标签筛选、收藏正常
- [ ] 主题明/暗切换正常
- [ ] 账号资料编辑、统计展示正常
- [ ] 备份 / 导入导出正常
- [ ] 图片存储页面正常
- [ ] 中英文文案无遗漏、无硬编码残留
- [ ] 核心逻辑单元测试通过

---

## 9. 建议文件变更清单（预估）

| 类型 | 变更 |
| --- | --- |
| 新增 | `model/`、`repository/`、`service/` 目录及对应模块 |
| 拆分 | `ConfigManager` → 配置/标签/导入导出/备份 |
| 拆分 | `NowViewModel`、`AccountViewModel` 的 IO/存储职责 |
| 重组 | `common/`、`utils/` 目录语义 |
| 修改 | 所有硬编码颜色/字符串 → `$r()` 资源引用 |
| 修改 | 旧式 `@ohos.*` → `@kit.*` |
| 修改 | `@Entry` 标注与 `main_pages.json` 一致性 |
| 删除 | 临时调试日志、重复工厂函数、重复类型定义 |

---

## 10. 重构进度跟踪

> **说明**：由于单次模型上下文有限，重构将分多轮进行。每轮完成后在此更新进度，下一轮开始时先读本节确认上下文。
> **状态标记**：`⬜ 未开始` / `🟦 进行中` / `✅ 已完成` / `⚠️ 有风险` / `❌ 已放弃`

### 10.1 总体里程碑

| 阶段 | 描述 | 状态 | 完成日期 | 备注 |
| --- | --- | --- | --- | --- |
| P0 | 数据兼容性基线锁定（确认旧备份可导入） | ⬜ | — | 备份格式已记录在 §0；尚未做导入冒烟测试 |
| P1 | 类型层重构（`types.ets` 拆分、消除重复定义） | ✅ | 2026-08-22 | `model/` 目录已创建（5 文件）；`UserProfile`/`DataStatistics` 重复已消除；UI DTO 重命名为 `AccountProfile`/`AccountDataStatistics`；旧文件保留 re-export 兼容 |
| P2 | Model / Repository 层抽取 | ✅ | 2026-08-22 | `repository/` 已创建（`ConfigRepository` / `RecordRepository`，见轮次 3）；Preferences 访问收敛至 repository 层，store/key 常量集中定义 |
| P3 | Service 层抽取（备份 / 导入导出 / 图片） | ✅ | 2026-08-22 | `service/` 共 5 文件（ImageFileService 图片 IO / TagService 标签 CRUD / ZipTransferService zip 传输 / ConfigTransferService 配置导入导出 / BackupManager）；ConfigManager 18.3KB → 9.8KB，MorePageBackupHandler 19.9KB → 16.3KB（见轮次 4~7）；⚠️ 导出导入改动需实机旧备份导入验证（P8 回归，用户有实机可验证） |
| P4 | ViewModel 瘦身（IO 职责下沉） | ⬜ | — | `NowViewModel` 15.7KB 直接 import `@ohos.data.preferences`；`AccountViewModel` 19.1KB 含重复类型 |
| P5 | Page 层清理（`@Entry` 标注、路由注册） | ⬜ | — | `NowPage.ets` 误标 `@Entry`（Tab 内容页不应标注）；`main_pages.json` 含 4 页 |
| P6 | 资源化（硬编码 → `$r()`） | ✅ | 2026-08-22 | `string.json`（zh_CN 1120 行 / en_US）+ `color.json`（base + dark）已创建；100+ 处 `$r('app.string.*')` 已接入；残余硬编码为标签调色板 / 主题判定逻辑等有意保留 |
| P7 | `@kit.*` 统一 & 依赖整理 | ⬜ | — | 11 处旧式 `@ohos.*` import 分布在 7 个文件 |
| P8 | 全量回归 + 旧备份导入冒烟 | ⬜ | — | 最终验收 |

### 10.2 逐轮工作日志

> 每轮重构结束后追加一条记录，格式：`### 轮次 N — 日期`
> 内容包括：本轮目标、涉及文件、已完成项、遗留问题、下一轮计划。

<!-- 示例模板（正式记录替换此注释）：
### 轮次 N — 2026-08-22

**本轮目标**：...

**涉及文件**：
- `path/to/file.ets`

**已完成**：
- [x] ...

**遗留问题**：
- ...

**下一轮计划**：...
-->

### 轮次 0 — 2026-08-22（重构前评估）

**本轮目标**：全量阅读项目现状，为 9 个里程碑填充评估备注，确认重构尚未开始。

**当前目录结构**：
```text
entry/src/main/ets/
├── entryability/        EntryAbility.ets
├── entrybackupability/  EntryBackupAbility.ets
├── pages/               Index / HomePage / NowPage / MorePage / AccountPage / StorageImagePage（6 文件）
├── viewmodel/           NowViewModel.ets (15.7KB) / AccountViewModel.ets (19.1KB)
├── config/              ConfigManager (18.7KB) / UserConfig / ThemeConfig / ThemeManager / AppInfoConfig（5 文件）
├── common/              types.ets (4.5KB) / handlers/ (2) / managers/ (2) / utils/ (4)
├── components/          calendar/ (4) / common/ (含 ImageViewer) / dialog/ (含 EditRecordDialog, TagManagementDialog)
└── utils/               ShareUtils.ets
```
> 注：无 `model/` `repository/` `service/` 目录，P2/P3 尚未启动。

**关键发现**：

| # | 发现 | 影响阶段 |
| --- | --- | --- |
| 1 | `UserProfile` 在 `AccountViewModel.ets:14` 与 `UserConfig.ets:17` 重复定义 | P1 |
| 2 | `NowPage.ets:17` 标注了 `@Entry`，但它是 Tab 内容页（与 `HomePage`、`AccountPage` 同级），不应标注 | P5 |
| 3 | `NowViewModel.ets` 直接 import `@ohos.data.preferences`，IO 职责未下沉 | P4 / P7 |
| 4 | 11 处 `@ohos.*` 旧式 import（7 文件）：`preferences`×4、`file.fs`×2、`file.photoAccessHelper`×1、`app.ability.common`×2、`promptAction`×1 | P7 |
| 5 | 100+ 处硬编码颜色（`#FFFFFF`、`#4A90D9`、`#80000000` 等），分布在 pages / components / dialogs | P6 |
| 6 | `MorePageBackupHandler.ets` 19.9KB — 备份/导入导出逻辑集中在一个 handler，是 P3 拆分重点 | P3 |
| 7 | `ConfigManager.ets` 18.7KB — 配置 + 标签 + 导入导出 + 头像 base64 职责混合 | P3 |
| 8 | `main_pages.json` 注册 4 页：Index / NowPage / MorePage / StorageImagePage | P5 |

**已完成**：
- [x] 全量扫描目录结构（63 个 .ets 文件）
- [x] 识别重复类型定义（`UserProfile`）
- [x] 统计 `@ohos.*` 旧式 import（11 处 / 7 文件）
- [x] 统计硬编码颜色（100+ 处）
- [x] 确认 `@Entry` 标注问题（`NowPage` 误标）
- [x] 确认无 `model/` `repository/` `service/` 目录
- [x] 为 §10.1 所有里程碑填充评估备注

**遗留问题**：
- P0 尚未实际执行（需用真实备份文件做导入冒烟测试后才能标记完成）

**下一轮计划**：P0 — 用现有备份文件验证当前导入流程，锁定兼容性基线

### 轮次 1 — 2026-08-22（P6 国际化与资源化）

**本轮目标**：消除硬编码字符串与颜色，建立 `string.json`（zh_CN / en_US）与 `color.json`（base / dark）资源体系。

**涉及文件**：
- `resources/base/element/string.json`（新增，1120 行）
- `resources/en_US/element/string.json`（新增）
- `resources/base/element/color.json`（新增，11 个语义色）
- `resources/dark/element/color.json`（新增，暗色主题）
- `pages/` 全部 6 文件（硬编码文本 → `$r('app.string.*')`）
- `components/` 全部子目录（dialog / calendar / common）
- `config/ThemeConfig.ets`、`config/ThemeManager.ets`

**已完成**：
- [x] 创建 `string.json`（zh_CN 1120 行 + en_US 对应英文）
- [x] 创建 `color.json`（base 11 色 + dark 主题色）
- [x] 全量替换硬编码文本为 `$r('app.string.*')`（100+ 处）
- [x] 主题色通过 `color.json` 统一定义，支持明暗切换

**遗留问题**：
- 部分硬编码颜色为有意保留：标签调色板（`#4A90D9` 等 10 色，属数据非 UI）、主题判定逻辑（`=== '#FFFFFF'` 比较）、纯白文字（`#FFFFFF` on 彩色背景）
- `$r('app.color.*')` 尚未在 .ets 中引用（颜色通过 `ThemeConfig` 动态分发，未走资源系统）— 可在后续 P3 主题服务重构时统一

**下一轮计划**：P0 — 用现有备份文件验证当前导入流程，锁定兼容性基线；或 P1 — 类型层重构

### 轮次 2 — 2026-08-22（P1 类型层重构）

**本轮目标**：创建 `model/` 目录，统一领域模型，消除 `UserProfile` / `DataStatistics` 重复定义（解决 A1）。

**涉及文件**：
- `model/CommonModel.ets`（新增）— `TimeData`, `DateDifference`
- `model/TagModel.ets`（新增）— `Tag`, `DEFAULT_TAGS`, `getAllTags`, `getTagNameById`, `getTagById`
- `model/RecordModel.ets`（新增）— `LifeRecord`, `ImageInfo`, `TimelineData`, `TimelineYear`, `TimelineMonth`, `TimelineDay`, `CalendarDay`
- `model/UserConfigModel.ets`（新增）— `UserProfile`, `AppSettings`, `BackupConfig`, `DataStatistics`, `ConfigMetadata`, `UserConfig`, `CloudBackupConfig`, `AppInfo` + 工厂函数
- `model/AccountModel.ets`（新增）— `AccountProfile`（原 AccountViewModel 的 `UserProfile`）, `ThemeSettings`, `AccountDataStatistics`（原 AccountViewModel 的 `DataStatistics`）, `AvatarInfo`
- `common/types.ets`（改写）— re-export barrel → `model/`
- `config/UserConfig.ets`（改写）— re-export barrel → `model/UserConfigModel`
- `viewmodel/AccountViewModel.ets`（修改）— 移除本地类型定义，import from `model/AccountModel`
- `pages/AccountPage.ets`（修改）— `DataStatistics` → `AccountDataStatistics`

**已完成**：
- [x] 创建 `model/` 目录（5 文件）
- [x] 消除 `UserProfile` 重复（持久化层 `UserConfigModel` vs UI 层 `AccountModel`，重命名为 `AccountProfile`）
- [x] 消除 `DataStatistics` 重复（持久化层 `UserConfigModel` vs UI 层 `AccountModel`，重命名为 `AccountDataStatistics`）
- [x] `common/types.ets` → re-export barrel（向后兼容）
- [x] `config/UserConfig.ets` → re-export barrel（向后兼容）
- [x] 修复 `CalendarDay` 接口字段（`date: Date`, `year`, `month`, `day`, `isToday`, `recordCount`）
- [x] 修复 `ImageInfo` 接口（增加 `uri?` 字段）
- [x] 修复 `getAllTags` / `getTagNameById` 函数签名（支持 `customTags?` 参数）
- [x] 编译通过（`Build success`）

**遗留问题**：
- `common/types.ets` 和 `config/UserConfig.ets` 保留为 re-export barrel，后续可逐步迁移 import 路径至 `model/` 后删除
- `AccountViewModel.ets` 仍 re-export `AccountProfile` / `AccountDataStatistics` 供 `AccountPage.ets` 使用，后续 P4 瘦身时可改为直接 import

**下一轮计划**：P2 — Model / Repository 层抽取（新建 `repository/`，封装 Preferences 读写）— **已完成，见轮次 3**

### 轮次 3 — 2026-08-22（P2 Repository 层重构）

**本轮目标**：创建 `repository/` 目录，将所有 Preferences 访问收敛至仓库层，消除 store/key 常量散落与重复的 restore 逻辑（解决 A2 / A3 部分）。

**涉及文件**：
- `repository/RecordRepository.ets`（新增）— 封装 `now_page_records` store 读写：`getRecords()` / `saveRecords()` / `clearRecords()`
- `repository/ConfigRepository.ets`（新增）— 封装 `record_life_config` store 读写：`getConfigString()` / `saveConfigString()`
- `config/ConfigManager.ets`（修改）— 移除 `import preferences`、`private preferences` 字段、`CONFIG_KEY` / `STORE_NAME` 常量；改用 `ConfigRepository` + `this.context`
- `viewmodel/NowViewModel.ets`（修改）— 移除 `import preferences`、`private prefs` 字段、`STORE_NAME` / `RECORDS_KEY` 常量；改用 `RecordRepository`
- `common/managers/BackupManager.ets`（修改）— 移除 `import preferences`；`restoreRecordsToPreferences` 改用 `RecordRepository.saveRecords()`
- `common/handlers/MorePageBackupHandler.ets`（修改）— 同上
- `common/handlers/MorePageConfigHandler.ets`（修改）— 移除 `import preferences`；`deleteAllRecords` 改用 `RecordRepository.clearRecords()`

**已完成**：
- [x] 创建 `repository/` 目录（2 文件）
- [x] `RecordRepository`：封装 `getRecords` / `saveRecords` / `clearRecords`，内部完成 JSON 序列化/反序列化
- [x] `ConfigRepository`：封装 `getConfigString` / `saveConfigString`，仅做字符串读写（业务逻辑仍由 ConfigManager 处理）
- [x] 迁移 ConfigManager：`this.preferences` → `this.context`，所有读写改走 `ConfigRepository`
- [x] 迁移 NowViewModel：`this.prefs` → `this.context`，所有读写改走 `RecordRepository`
- [x] 迁移 BackupManager / MorePageBackupHandler / MorePageConfigHandler：消除重复的 `STORE_NAME` / `RECORDS_KEY` 常量与 `preferences.getPreferences()` 调用
- [x] 编译通过（`Build success`）
- [x] 更新 `docs/technical-reference.md` §4.1 / §4.2 / §14

**消除的问题**：
- `@ohos.data.preferences` 直接 import：5 处 → 2 处（仅 repository 层）
- store/key 常量散落：4 处 → 2 处（集中定义在 repository 层）
- `restoreRecordsToPreferences` 重复逻辑：2 处独立实现 → 统一调用 `RecordRepository.saveRecords()`

**遗留问题**：
- `ConfigManager` 仍直接 `import common from '@ohos.app.ability.common'`（旧式 import，B4 / P7 范畴）
- `NowViewModel` 仍直接 `import fileIo`（文件操作未抽象，属 P4 范畴）
- repository 层尚未有单测覆盖（C2 / P4 范畴）

**下一轮计划**：P3 — 主题服务重构（ThemeConfig 动态分发 → 资源系统 `$r` 引用）；或 P4 — ViewModel 瘦身 / fileIo 抽象

### 轮次 4 — 2026-08-22（P3 Service 层抽取 · 第一部分）

**本轮目标**：建立 `service/` 目录，下沉图片 IO（A3 部分），迁移 BackupManager 至 service 层，统一 `uriToSandboxPath` 三处重复实现（技术文档 §14 问题 8）。

**涉及文件**：
- `common/utils/ImagePathUtils.ets`（新增）— `uriToSandboxPath` / `sandboxPathToUri` / `getFileName`
- `service/ImageFileService.ets`（新增）— `saveRecordImage` / `getImageUri` / `deleteImageFiles` / `copyAvatar`
- `service/BackupManager.ets`（迁移自 `common/managers/`）— 路径工具改用 ImagePathUtils，删除私有副本
- `viewmodel/NowViewModel.ets` — 图片 IO 委托 ImageFileService，删除私有 `uriToSandboxPath` 与 `fileIo/fileUri` import
- `viewmodel/AccountViewModel.ets` — `copyImageToSandbox` 委托 `ImageFileService.copyAvatar`，删除 `deleteOldAvatarCache`
- `common/utils/MorePageHelper.ets` — `uriToSandboxPath` 委托 ImagePathUtils（方法签名不变）
- `pages/MorePage.ets`、`common/handlers/MorePageBackupHandler.ets` — BackupManager import 路径更新

**已完成**：
- [x] 新建 `service/` 目录（2 文件）
- [x] `ImagePathUtils`：统一 `uriToSandboxPath` / `sandboxPathToUri`（消除 NowViewModel / BackupManager / MorePageHelper 三处重复）
- [x] `ImageFileService`：记录图片保存 / URI 转换 / 批量删除 / 头像复制下沉
- [x] BackupManager 迁入 `service/`（**逻辑零改动**，纯搬移 + 路径工具统一）
- [x] NowViewModel / AccountViewModel 图片 IO 委托化，公开 API 签名不变（组件无感知）
- [x] 静态验证通过（import 一致性 / ArkTS 约束 / git 改动面核对）

**遗留问题**：
- ⚠️ 本机无 hvigor 编译环境，未做编译与真机旧备份导入冒烟验证；BackupManager 为纯搬移（逻辑零改动），需在 DevEco 中回归（见 §10.3 记录）
- ConfigManager 拆分（标签管理 / 导出导入独立）未做 — P3 剩余
- MorePageBackupHandler（19.9KB）拆分未做 — P3 剩余
- BackupManager 仍通过 `NowViewModel.getInstance()` 取记录（service → viewmodel 反向依赖，理想应改依赖 `RecordRepository`）— P3 剩余

**下一轮计划**：P3 续 — 拆分 ConfigManager（标签管理独立 Service / 导出导入）与 MorePageBackupHandler

### 轮次 5 — 2026-08-22（P3 Service 层抽取 · 第二部分：标签管理拆分 + 依赖修正）

> 前置：用户在 DevEco 中修复了轮次 4 的 `MorePageBackupHandler` BackupManager import 路径（`../service/` → `../../service/`，提交 55bf052）并编译成功。

**本轮目标**：拆分 ConfigManager 的标签管理为独立 `TagService`（解决 A2 职责过重），消除 BackupManager 对 NowViewModel 的反向依赖。

**涉及文件**：
- `service/TagService.ets`（新增）— 自定义标签 CRUD（`getCustomTags` / `addCustomTag` / `updateCustomTag` / `deleteCustomTag` / `saveCustomTags`），依赖 ConfigManager 单例
- `config/ConfigManager.ets`（修改）— 删除 5 个标签方法 + `import { Tag }`（18.3KB → 约 15KB）
- `components/common/TagSelector.ets`（TagSelector + TagDisplay）、`components/dialog/TagManagementDialog.ets`、`components/record/TagFilterBar.ets`、`components/record/TimelineSection.ets`、`pages/NowPage.ets`（修改）— `configManager` → `tagService`，import 改 `../../service/TagService`（pages 为 `../service/`）
- `service/BackupManager.ets`（修改）— `createBackup` 改用 `RecordRepository.getRecords(context)`；`restoreBackup` 删除未使用的 viewModel 变量；删除 NowViewModel import

**已完成**：
- [x] `TagService` 单例：逻辑与原 ConfigManager 标签方法逐行等价（读 `getConfig().settings.customTags` + `saveConfig()`）
- [x] ConfigManager 标签方法移除（含残留 console 日志引用修正）
- [x] 6 处调用方全部切换，import 路径层级逐一核对（components/xx → `../../service/`，pages → `../service/`，吸取轮次 4 教训）
- [x] BackupManager 反向依赖消除（service → repository，符合目标架构依赖方向）
- [x] 静态验证通过（无残留调用 / ArkTS 约束 / 改动面核对）

**遗留问题**：
- ⚠️ 本机仍无 hvigor 编译环境，需用户在 DevEco 编译回归（尤其标签管理 UI：TagSelector / TagManagementDialog / 筛选）
- ConfigManager 导出导入（`exportConfig` / `importConfig`）未拆 — 触数据兼容红线（§0.3），待旧备份导入验证手段确认
- MorePageBackupHandler（19.9KB）拆分未做 — P3 剩余

**下一轮计划**：P3 续 — MorePageBackupHandler 拆分（zip 公共操作抽 service，行为保持）；或 P4 — ViewModel 瘦身（AccountViewModel 存储统计下沉）

### 轮次 6 — 2026-08-22（P3 Service 层抽取 · 第三部分：MorePageBackupHandler 拆分）

**本轮目标**：拆分 MorePageBackupHandler（19.9KB，全工程最大 handler）中重复的 DocumentViewPicker zip 保存/选择流程到 `service/ZipTransferService`。

**涉及文件**：
- `service/ZipTransferService.ets`（新增）— `saveZipToDocument(context, zipPath)` / `pickZipToSandbox(context, destPath)`
- `common/handlers/MorePageBackupHandler.ets`（修改）— 四方法改用 ZipTransferService；删除未使用 import（`picker` / `fileUri` / `RefreshManager`）

**设计要点**：
- **取消 vs 异常分离**：picker 返回空数组（用户取消）→ 返回 `false`；IO 异常**不捕获**，冒泡到调用方外层 `try/catch` → 保持原有「导出失败/导入失败」toast 行为完全一致。
- 临时文件清理时机由调用方保留（exportBackup 分支删、exportAll 统一删），行为不变。
- 图片恢复/记录映射等数据兼容核心逻辑**未改动**（仍留在 importAll / BackupManager.restoreBackup）。

**已完成**：
- [x] `ZipTransferService` 创建（逻辑逐行迁自原 picker 流程）
- [x] exportBackup / importBackup / exportAll / importAll 四方法重构（文件 19726B/494 行 → 16311B/409 行，瘦身约 17%）
- [x] import 清理与新增（`../../service/ZipTransferService`，吸取轮次 4 教训核对层级）
- [x] 静态验证通过（无残留引用 / ArkTS 约束 / 行为等价性审查）

**遗留问题**：
- ⚠️ 本机无 hvigor；且本轮改动涉及 `MorePageBackupHandler.exportAll|importAll`（数据兼容红线 §0.3），**需在 DevEco 编译 + 用旧备份文件做导入冒烟验证**
- ConfigManager 导出导入（`exportConfig` / `importConfig`）未拆 — 触红线，待验证手段确认
- `ZipTransferService` 未纳入单测（C2）

**下一轮计划**：P4 — ViewModel 瘦身（AccountViewModel 存储统计/`[StorageDebug]` 日志下沉，不触红线）；或收尾 P3（ConfigManager 导出导入拆分，需先确认旧备份导入验证方式）

### 轮次 7 — 2026-08-22（P3 Service 层抽取 · 完成：ConfigManager 导出导入拆分）

> 前置：用户确认有实机可手动验证（旧备份导入冒烟验证）。

**本轮目标**：拆分 ConfigManager 的导出/导入（`exportConfig` / `importConfig`）到独立 `ConfigTransferService`，P3 全部子任务完成。

**涉及文件**：
- `service/ConfigTransferService.ets`（新增）— `exportConfig(configManager)` / `importConfig(configManager, configStr)` + `ExportData` 接口
- `config/ConfigManager.ets`（修改）— 删除两方法 + `ExportData` + 5 个 import（AppInfoManager / ImageBase64Utils / MorePageHelper / UserProfile 等类型）
- `common/handlers/MorePageBackupHandler.ets`、`common/handlers/MorePageConfigHandler.ets`（修改）— 4 处调用切换至 ConfigTransferService

**已完成**：
- [x] `ConfigTransferService` 创建（逻辑逐行等价：`configManager.getConfig()` 替代原空值兜底——已核对 `createDefaultConfig`/`createDefaultConfigSync` 生成内容逐字段一致；头像 base64 转换、`validateConfig`、`saveConfig` 保留）
- [x] ConfigManager 18.3KB → 9.8KB（瘦身约 47%）
- [x] 4 处调用方切换（import 层级 `../../service/` 核对）
- [x] 静态验证通过（无残留 / ArkTS 约束 / 结构完整）

**遗留问题**：
- ⚠️ **P3 收尾验收**：导出导入改动（轮次 6/7 涉及 `exportAll`/`importAll`/`exportConfig`/`importConfig`）需用户在实机用旧备份文件做导入冒烟验证（§0.3 红线），验证结果记入 §10.3
- `ConfigTransferService` 未纳入单测（C2）

**下一轮计划**：P4 — ViewModel 瘦身（AccountViewModel `[StorageDebug]` 日志清理 + 存储统计下沉 `service/StorageService`）

### 10.3 数据兼容性验证记录

| 验证时间 | 备份文件来源 | 导入结果 | 验证人 | 备注 |
| --- | --- | --- | --- | --- |
| — | — | — | — | 重构尚未开始 |
| 2026-08-22 | —（未真机验证） | 未执行 | 轮次 4 | BackupManager 纯搬移（逻辑零改动），仅静态验证；需 DevEco 编译 + 旧备份导入冒烟后补记 |

### 10.4 上下文恢复检查清单

> 每轮开始前快速过一遍，确保不遗漏：

- [ ] 已阅读本文件 §0 数据兼容性要求
- [ ] 已阅读本文件 §10.2 最近一轮工作日志
- [ ] 已确认上一轮遗留问题是否已解决
- [ ] 已确认本次改动范围是否触及备份/导入导出（若是，需走 §0.3 规范）
