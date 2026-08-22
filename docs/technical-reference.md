# RecordLife 技术文档（当前实现参考）

> **用途**：本文档是 RecordLife 项目的**现状实现快照**，供不同窗口/会话的 AI 重构任务作为唯一参考，避免每次从头通读全部源码。
> **配套文档**：`docs/refactoring-plan.md` 是重构方案与进度跟踪；本文档只描述**当前代码实际怎么实现**，两者配合使用。
> **最后更新**：2026-08-22（重构全部完成——P0~P8 + A5 + 国际化 + 日志收敛；基于当前工作区源码逐文件核对）
> **阅读方式**：全文关键结论均附 `file:line` 引用，可快速定位源码；改动任何涉及数据模型 / 持久化 / 备份导入导出的代码前，**必须先读 §5 与 §6**。

---

## 1. 项目概览

| 维度 | 值 |
| --- | --- |
| 项目类型 | HarmonyOS 应用（stage 模型，单模块 `entry` 单 HAP） |
| 包名 / bundleName | `com.rainforcetime.recordlife` |
| 应用名 | 「活着 / Alive」 |
| 版本 | `versionName=2.0.0`，`versionCode=20000`（AppScope/app.json5） |
| SDK | `targetSdkVersion=6.0.2(22)`，`compatibleSdkVersion=6.0.2(22)`，`runtimeOS=HarmonyOS` |
| 语言 | ArkTS / ArkUI（`apiType=stageMode`） |
| 依赖 | 业务零第三方依赖；devDependencies 仅 `@ohos/hypium@1.0.25`、`@ohos/hamock@1.0.0`（测试框架） |
| 构建 | hvigor（`hvigorfile.ts` 标准无定制）；release 未开混淆（`obfuscation.enable=false`） |
| 业务领域 | 生命倒计时首页、生活记录时间线、标签管理、主题切换、数据备份/导入导出、图片存储管理 |

**核心页面**（6 个）：`Index`（主 Tab 容器）、`HomePage`（存活时间）、`NowPage`（时间线）、`AccountPage`（账号设置）、`MorePage`（更多/备份，路由页）、`StorageImagePage`（图片存储，路由页）。

**数据流总览**：
```text
页面/组件 → ViewModel（NowViewModel / AccountViewModel）→ ConfigManager / BackupManager（单例）
         → Preferences（record_life_config、now_page_records）+ 沙箱文件系统（filesDir、cacheDir）
全局状态：AppStorage（uiContext / appTheme / isDarkMode / themeColors / currentTheme）
跨页刷新：RefreshManager（观察者 Map<key, callback>）
```

---

## 2. 目录结构（`entry/src/main/ets/`）

```text
├── entryability/           EntryAbility.ets（启动入口，注入 uiContext + 初始化主题）
├── entrybackupability/     EntryBackupAbility.ets（系统备份扩展，空实现占位）
├── pages/                  Index / HomePage / NowPage / MorePage / AccountPage / StorageImagePage
├── viewmodel/              NowViewModel.ets（记录数据管理）/ AccountViewModel.ets（13.9KB，P4 瘦身后）
├── model/                  ★ 统一领域模型（P1 重构产物）：
│   ├── CommonModel.ets         TimeData、DateDifference
│   ├── TagModel.ets            Tag、DEFAULT_TAGS、getAllTags/getTagNameById/getTagById
│   ├── RecordModel.ets         LifeRecord、ImageInfo、TimelineData/Year/Month/Day、CalendarDay
│   ├── UserConfigModel.ets     持久化层 UserProfile/AppSettings/BackupConfig/DataStatistics 等 + 工厂/校验
│   └── AccountModel.ets        UI 层 AccountProfile/ThemeSettings/AccountDataStatistics/AvatarInfo
├── config/                 ConfigManager（9.8KB，P3 瘦身后）/ UserConfig（barrel）/ ThemeConfig / ThemeManager / AppInfoConfig
├── common/
│   ├── types.ets               re-export barrel → model/（兼容旧 import 路径）
│   ├── ColorUtils.ets          十六进制色 → rgba 透明度工具
│   ├── handlers/               MorePageBackupHandler.ets（19.9KB）/ MorePageConfigHandler.ets
│   ├── managers/               RefreshManager.ets
│   └── utils/                  TimeUtils / AccountUtils / ImageBase64Utils / ImagePickerUtils / MorePageHelper / ImagePathUtils / ShareUtils / ImageGenerator（后两者 P5 自顶层 utils/ 迁入）
├── service/                ★ P3/P4 新增：ImageFileService.ets（图片 IO）/ TagService.ets（标签 CRUD）/ ZipTransferService.ets（zip picker 传输）/ ConfigTransferService.ets（配置导入导出）/ StorageService.ets（存储统计，P4）/ BackupManager.ets（自 common/managers 迁入）
├── components/             home(1) / calendar(5) / common(4) / dialog(4) / record(5) / setting(4) / share(2) / user(4)
```

> `model/` 是 P1 新建目录；`common/types.ets` 与 `config/UserConfig.ets` 现为 re-export barrel；顶层 `utils/` 已于 P5 并入 `common/utils/`（C1 已解决）。

---

## 3. 数据模型层（`model/`）

> 重构约束：**所有持久化字段语义不得改变**（见 §6 兼容性约束 C2/C3/C4）。新增字段必须可选。

### 3.1 记录与时间线（`model/RecordModel.ets`）

```ts
interface LifeRecord {
  id: string;            // 唯一标识（generateId: Date.now().toString(36) + Math.random().toString(36).substring(2)）
  timestamp: number;     // 毫秒时间戳
  content: string;
  imagePaths?: string[]; // 可选，URI 或旧沙箱路径
  tags?: string[];       // 可选，标签 ID 数组
  isPinned?: boolean;    // 可选，置顶
  mood?: string;         // 可选，心情 id（更新计划二期：预置 'happy' 等或自定义 'mood_xxx'，emoji 经 MoodUtils 映射）
}
interface ImageInfo { path: string; uri?: string; thumbnailPath?: string; }
interface TimelineData { years: TimelineYear[] }
- 纯函数 `buildTimelineData(records, now): TimelineData`（P4 新增）：按年/月/日分组、降序排列、当前年月默认展开，逻辑原在 NowViewModel.buildTimeline，现可单测。
interface TimelineYear  { year: number; months: TimelineMonth[]; isExpanded: boolean }
interface TimelineMonth { month: number; days: TimelineDay[]; isExpanded: boolean }
interface TimelineDay   { day: number; records: LifeRecord[]; isExpanded: boolean }
interface CalendarDay   { date: Date; year; month; day; isCurrentMonth; isToday; recordCount; records: LifeRecord[] }
```

### 3.2 标签（`model/TagModel.ets`）

```ts
interface Tag { id: string; name: string; color: string; /* 十六进制 */ icon?: string /* emoji */ }
```
- `DEFAULT_TAGS`：10 个预设标签（work 工作#4A90D9 / life 生活#67C23A / travel 旅行#E6A23C / food 美食#F56C6C / health 健康#909399 / study 学习#9B59B6 / sport 运动#FF69B4 / hobby 爱好#00BCD4 / friend 社交#FF9800 / other 其他#607D8B）。
- 用户自定义标签存于 `settings.customTags: Tag[]`（见 3.3）。
- 工具函数：`getAllTags(customTags?)`（预设+自定义合并）、`getTagNameById(tagId, customTags?)`（找不到时**返回 tagId 本身**）、`getTagById(tagId, customTags?)`。
- ⚠️ 示例数据中使用了 `'entertainment'`、`'family'` 两个**不在预设表内**的标签 id（NowViewModel.ets:139/165），显示时会直接回退显示 id 字符串。

### 3.3 用户配置（`model/UserConfigModel.ets`，持久化层）

```ts
interface UserProfile { name: string; birthDate: string /* yyyy-MM-dd */; gender: string /* 'male'|'female'|'other'|'' */; avatar: string /* file:// URI 或沙箱路径或 base64 */; signature?: string /* 签名/座右铭，可选，更新计划一期 */ }
interface AppSettings {
  theme: string;             // 'light' | 'dark' | 'auto'
  language: string;          // 'zh-CN' | 'en-US'
  showTimeDetails: boolean;
  enableNotifications: boolean;
  timeFormat: string;        // 'standard' | 'compact'
  isAccumulatedMode: boolean;// true 累计模式
  isRemainingMode: boolean;  // true 剩余模式（false 已存活）
  targetAge: number;         // 默认 80
  customTags: Tag[];         // 用户自定义标签
  fontSize?: string;         // 'small'|'medium'|'large'，默认 'medium'，更新计划一期；经 AppStorage('fontScale') 0.9/1.0/1.15 作用于记录内容文本
  customMoods?: Mood[];      // 用户自定义心情（更新计划二期，MoodService 管理）
  privacyMode?: boolean;     // 隐私模式（更新计划三期，默认 false：首页出生日期/里程碑遮罩）
  recordTemplates?: RecordTemplate[]; // 记录模板（更新计划三期，TemplateService 管理）
}
interface BackupConfig { autoBackup: boolean; backupFrequency: number; lastBackupTime: string; backupPath: string; cloudBackup: CloudBackupConfig | null }
interface CloudBackupConfig { enabled: boolean; provider: string /* 'huawei'|'custom' */; syncInterval: number }
interface DataStatistics { usageDays: number; lastActiveTime: string; dataVersion: number }
interface ConfigMetadata { createdAt: string; updatedAt: string; deviceId: string }
interface AppInfo { appName; appVersion; buildNumber; developer; website; description }
interface UserConfig { version: string /* '1.0.0' */; profile; settings; backup; statistics; metadata }
```
- 工厂函数：`createDefaultConfig()`（异步，默认值见上）/ `createDefaultConfigSync()`（同步）——**两者几乎重复**（重构问题 B5）。默认 profile：name=`''`、birthDate=`'1990-01-01'`、gender=`''`、avatar=`''`。
- 校验 `validateConfig(config)`：birthDate 必须匹配 `^\d{4}-\d{2}-\d{2}$`、不晚于今天、年份 ≥1900；`backupFrequency` ∈ [1, 365]。**导入失败条件**：校验不过 → 导入返回 false。

### 3.4 UI 层 DTO（`model/AccountModel.ets`，与持久化层区分）

```ts
interface AccountProfile { name: string; birthday: string /* 对应持久层 birthDate */; gender: string; avatar: string; hasCustomAvatar: boolean }
interface ThemeSettings { currentTheme: string }
interface AccountDataStatistics { usageDays: number; dataVersion: string /* UI 层为 string，持久层为 number */; lastActiveTime: string; storageSize: string }
interface AvatarInfo { avatar: string; hasCustomAvatar: boolean }
```
> ⚠️ `AccountViewModel.ets:15` 仍 `export { AccountProfile, AccountDataStatistics }` 向后兼容 `AccountPage.ets` 的 import。

### 3.5 通用（`model/CommonModel.ets`）

```ts
interface TimeData { years; months; days; hours; minutes; seconds }   // HomePage 倒计时展示
interface DateDifference { years; months; days }
```

---

## 4. 持久化与文件存储（数据存放位置速查）

### 4.1 Preferences（两个 store，两个 key）

> **P2 重构后**：所有 Preferences 访问已收敛至 `repository/` 层，业务层不再直接 `import preferences`。

| Store 名 | Key | Repository 方法 | 调用方 | 内容 |
| --- | --- | --- | --- | --- |
| `record_life_config` | `user_config` | `ConfigRepository.getConfigString()` / `saveConfigString()` | `ConfigManager.loadConfig()` / `saveConfig()` | 整个 `UserConfig` 的 JSON 字符串 |
| `now_page_records` | `life_records` | `RecordRepository.getRecords()` / `saveRecords()` / `clearRecords()` | `NowViewModel.loadRecords()` / `saveRecords()`；备份恢复：`BackupManager.restoreRecordsToPreferences` / `MorePageBackupHandler.restoreRecordsToPreferences`；清空：`MorePageConfigHandler.deleteAllRecords` | `LifeRecord[]` 的 JSON 字符串 |

> 重构 Repository 时**必须保持上述 store/key 与 JSON 结构不变**（refactoring-plan §7 风险 1）。store/key 常量定义：`ConfigRepository.ets:12-13`、`RecordRepository.ets:13-14`。

### 4.2 Repository 层（P2 新增）

> 依赖方向：`viewmodel / config / handler / manager → repository → @ohos.data.preferences`

| 文件 | 类 | 职责 | 方法 |
| --- | --- | --- | --- |
| `repository/ConfigRepository.ets` | `ConfigRepository`（全静态） | 封装 `record_life_config` store 读写 | `getConfigString(ctx): Promise<string>`、`saveConfigString(ctx, str): Promise<boolean>` |
| `repository/RecordRepository.ets` | `RecordRepository`（全静态） | 封装 `now_page_records` store 读写 + 清空 | `getRecords(ctx): Promise<LifeRecord[]>`、`saveRecords(ctx, records): Promise<boolean>`、`clearRecords(ctx): Promise<boolean>` |

- **设计原则**：无状态静态方法，每次调用内部 `preferences.getPreferences()` 获取缓存实例；不持有 `Preferences` 引用。
- **`RecordRepository.getRecords()`** 内部完成 `JSON.parse`，返回 `LifeRecord[]`（空数据或异常返回 `[]`）；排序等业务逻辑仍由 `NowViewModel` 处理。
- **`ConfigRepository`** 仅做字符串读写，`JSON.parse` / `validateConfig` / `metadata.updatedAt` 更新等业务逻辑仍由 `ConfigManager` 处理。
- **迁移前**：5 个文件直接 `import preferences`，store/key 常量散落 4 处（ConfigManager、NowViewModel、BackupManager、MorePageBackupHandler、MorePageConfigHandler）。
- **迁移后**：仅 `repository/` 下 2 个文件 `import preferences`，store/key 常量集中定义。

### 4.2 沙箱文件目录

| 目录 | 用途 | 写入方 |
| --- | --- | --- |
| `${context.filesDir}/records/` | **记录图片**（`record_<timestamp>.jpg`，URI 经 `fileUri.getUriFromPath` 生成） | `NowViewModel.saveImageToSandbox`（NowViewModel.ets:428-431）；`ImageGenerator.generateSolidColorImage` |
| `${context.filesDir}/sample_images/` | 渐变示例图（`sample_gradient.png`） | `ImageGenerator.generateGradientImage`（ImageGenerator.ets:155） |
| `${context.filesDir}/avatar*.jpg` | 头像（`avatar_<timestamp>.jpg`） | `AccountViewModel.copyImageToSandbox`（AccountViewModel.ets:434）；导入时 `ImageBase64Utils.base64ToImage` → `filesDir/avatar.jpg`（ImageBase64Utils.ets:105） |
| `${context.cacheDir}/backup_temp/`、`backup_temp_restore/` | 备份/恢复临时目录 | BackupManager |
| `${context.cacheDir}/export_all_temp/`、`import_all_temp/` | 导出/导入全部数据临时目录 | MorePageBackupHandler |
| `${context.cacheDir}/share_*.jpg` | 分享截图缓存 | ShareUtils.saveImageToSandbox |
| `${context.cacheDir}/RecordLife_backup_*.zip`、`RecordLife_all_*.zip`、`temp_backup.zip`、`temp_import_all.zip` | zip 临时文件 | BackupManager / MorePageBackupHandler |

### 4.3 图片路径两种格式的兼容约定

- **新写入**统一为 **URI**：`saveImageToSandbox` 返回 `fileUri.getUriFromPath(sandboxPath)`（NowViewModel.ets:441）。
- **旧数据**可能是裸沙箱路径：读取显示走 `NowViewModel.getImageUri(path)`（`file://` 开头直接返回，否则转 URI，实现已下沉至 `service/ImageFileService.getImageUri`）；文件操作走统一工具 `ImagePathUtils.uriToSandboxPath(uri)`（`common/utils/ImagePathUtils.ets:11`，去 `file://` 前缀后取第一个 `/` 之后的路径；原 NowViewModel/BackupManager/MorePageHelper 三处重复实现已收敛）。
- ⚠️ 示例数据（NowViewModel.ets:146/153）的 `imagePaths` 写的是**沙箱路径**（非 URI），依赖 getImageUri 兼容。

---

## 5. 全局状态与单例

### 5.1 AppStorage keys

| key | 类型 | 写入位置 | 消费方 |
| --- | --- | --- | --- |
| `uiContext` | `common.UIAbilityContext` | `EntryAbility.onCreate`（EntryAbility.ets:14，必须在主题初始化之前） | ConfigManager.ets:56/409、BackupManager.ets:43、NowViewModel.ets:41、ThemeManager.ets:136 |
| `context` | `UIAbilityContext` | 无写入（仅 fallback 读取） | BackupManager.ets:45、NowViewModel.ets:43 |
| `appTheme` | `'light'\|'dark'\|'auto'` | ThemeManager（init/updateTheme） | ThemeManager:95、EntryAbility:70 |
| `isDarkMode` | `boolean` | ThemeManager（init/updateTheme/onSystemColorModeChange） | ThemeManager:100 |
| `themeColors` | `ThemeColors` | ThemeManager | **全项目 30+ 处 `@StorageLink('themeColors')`**（6 页面 + 24 组件） |
| `currentTheme` | `string` | `AccountViewModel.onThemeChange`（AccountViewModel.ets:315） | 页面监听主题切换结果 |

### 5.2 单例类清单

| 类 | 文件 | 获取方式 | 职责 |
| --- | --- | --- | --- |
| `ConfigManager` | config/ConfigManager.ets:27 | `await ConfigManager.getInstance()` | 配置读写/重置（标签 CRUD 已拆至 `TagService`、导入导出已拆至 `ConfigTransferService`，P3） |
| `ConfigTransferService` | service/ConfigTransferService.ets:24 | 静态方法（依赖传入 ConfigManager） | 用户配置导出/导入（含头像 base64 转换；拆自 ConfigManager，P3 轮次 7） |
| `TagService` | service/TagService.ets:9 | `await TagService.getInstance()` | 自定义标签 CRUD（拆自 ConfigManager，P3 轮次 5；内部依赖 ConfigManager 单例） |
| `ThemeManager` | config/ThemeManager.ets:13 | `await ThemeManager.getInstance()` | 主题状态管理（数据源是 ConfigManager，本类只是 AppStorage 便捷层） |
| `AppInfoManager` | config/AppInfoConfig.ets:21 | `await AppInfoManager.getInstance()` | 从 bundleManager 读应用版本信息 |
| `NowViewModel` | viewmodel/NowViewModel.ets:10 | `await NowViewModel.getInstance()` | 记录 CRUD + 时间线构建（图片 IO 已下沉至 `service/ImageFileService`，P3） |
| `AccountViewModel` | viewmodel/AccountViewModel.ets:18 | `new AccountViewModel()`（非单例，页面持有，`initialize(context)`） | 账号页数据加载/主题/头像 |
| `BackupManager` | service/BackupManager.ets:19 | `await BackupManager.getInstance()` | 创建/恢复 zip 备份 |
| `RefreshManager` | common/managers/RefreshManager.ets:5 | `RefreshManager.getInstance()`（同步） | 跨页刷新观察者 |

> 所有单例均支持 `getInstance(context?)` 显式注入（A5 已解决，轮次 17）：context 注入优先，未传时回退 `AppStorage.get('uiContext')`；EntryAbility 入口注入 `this.context`，各页面/组件/Handler 传 `getUIContext().getHostContext()` 或自身 context。

### 5.3 RefreshManager 跨页刷新

- `register(key, callback)` / `unregister(key)` / `refresh()`（同步遍历执行所有回调，RefreshManager.ets:19-41）。
- 注册方：HomePage（HomePage.ets:144）、NowPage（NowPage.ets:94）、AccountPage（AccountPage.ets:124）、StorageImagePage（StorageImagePage.ets:44）；均在 `aboutToDisappear` 注销。
- 触发方：`NowPage.onSaveEdit`（:547）、`NowPage.onDeleteRecord`（:627）、`AccountPage.onSaveProfile`（:250）、`TagManagementDialog`（:157/170）、`AddRecordSection`（:260）。
- 各页收到通知行为不同：HomePage 仅同步出生日期；NowPage 重载标签+刷新时间线；AccountPage 置 `hasBackgroundRefresh` 并刷新统计；StorageImagePage 重载图片。

---

## 6. ★ 备份 / 导入导出（数据兼容性最高优先级）

> **背景**：用户已有 `RecordLife_all_{timestamp}.zip` 旧备份文件，重构后**必须能无损导入**（refactoring-plan §0）。以下格式描述以**当前实际代码**为准（与 plan §0.1 快照略有出入处已标注）。

### 6.1 三种导出/导入能力（均在 MorePage 上）

| 能力 | 入口 | 处理器 | 产物 |
| --- | --- | --- | --- |
| 导出/导入配置 | MorePage → 导出/导入 | `MorePageConfigHandler.exportConfig/importConfig` | 单个 `.json` 文件 `RecordLife_config_<ts>.json` |
| 导出/导入备份（仅记录） | 同上 | `MorePageBackupHandler.exportBackup/importBackup` → `BackupManager` | `.zip` `RecordLife_backup_<ts>.zip` |
| **导出/导入全部数据** | 同上（ExportOptionDialog/ImportOptionDialog 二选一） | `MorePageBackupHandler.exportAll/importAll` | `.zip` `RecordLife_all_<ts>.zip` |

操作均使用 `picker.DocumentViewPicker`（保存/选择文件，**免权限**；picker 流程已下沉至 `service/ZipTransferService`，P3 轮次 6），成功 Toast 后 `setTimeout(1000ms)` → `restartApp(want)`（bundleName `com.rainforcetime.recordlife`，abilityName `EntryAbility`）重启应用（MorePageBackupHandler.ets:28-42）。

### 6.2 「导出全部数据」zip 实际结构（`MorePageBackupHandler.exportAll`，MorePageBackupHandler.ets:134-244）

```text
RecordLife_all_<ts>.zip（zlib 压缩，compressFile(tempDir, zipPath)）
├── config.json            # ConfigManager.exportConfig() 输出（结构见 §6.4）
├── records_metadata.json  # { appVersion, timestamp, recordCount, records: LifeRecord[] }
└── records/               # 图片文件，文件名 = 原沙箱文件名（如 record_<ts>.jpg）
```
> ⚠️ **与 plan §0.1 快照的差异**：实际代码图片文件名是 `sandboxPath.split('/').pop()` 保留原文件名（MorePageBackupHandler.ets:194），**不是** `{recordId}_{index}.jpg`；records 数组是完整 `LifeRecord[]`（含 tags/isPinned），文件名为 `records_metadata.json`（不是 `metadata.json`）。**重构验证兼容性时以本文档结构为准**。

### 6.3 导入流程（`importAll`，MorePageBackupHandler.ets:245-393）

1. Picker 选择 zip → 复制到 `cacheDir/temp_import_all.zip` → `zlib.decompressFile` 解压到 `cacheDir/import_all_temp`。
2. **配置导入**：读 `config.json` → `ConfigManager.importConfig(configStr)`（见 6.4）。
3. **记录导入**：读 `records_metadata.json` → 遍历 `metadata.records`，逐条：
   - 对每条 `imagePaths` 旧值取文件名（`uriToSandboxPath(old).split('/').pop()`），从解压目录 `records/<fileName>` **复制到 `filesDir/records/<fileName>`**，新路径拼接为 `file://${destPath}`（:424）；备份中缺失的图片直接跳过（路径不加入）。
   - 重建 `LifeRecord`（id/timestamp/content/tags/isPinned 原样保留，imagePaths 用新 URI 列表）。
   - `restoreRecordsToPreferences(context, updatedRecords)` → 写入 store `now_page_records` / key `life_records`（覆盖写）。
4. 清理临时文件；任一成功即 Toast（文案拼接 `import_success_prefix + 用户配置、此刻记录 + import_success_suffix`）并重启应用。

> **路径映射关键**：图片依赖「文件名」在备份与 `filesDir/records` 间对应；`saveImageToSandbox` 生成 `record_<ts>.jpg` 保证不重名。导入后 `imagePaths` 为 `file://` URI 格式。

### 6.4 `config.json` 结构与头像 base64 处理

- **导出**（`ConfigTransferService.exportConfig`，service/ConfigTransferService.ets:26-73）：若 `profile.avatar` 非空，先 `MorePageHelper.uriToSandboxPath` → 文件存在则 `ImageBase64Utils.imageToBase64` 转 base64 放入 `profile.avatar`；输出 JSON 含 `settings/backup/statistics/metadata/exportedAt/appVersion/profile`（`appVersion` 来自 AppInfoManager，失败回退 `'0.0.2'`）。
- **导入**（`ConfigTransferService.importConfig`，service/ConfigTransferService.ets:75-150）：
  - 先 `validateConfig`，失败直接返回 false（**旧备份若因校验问题导入失败，重构时需处理**）。
  - 头像判定：`!startsWith('file://') && length > 200` 视为 base64 → `ImageBase64Utils.base64ToImage(avatar, filesDir/avatar.jpg)` 落盘，`profile.avatar` 存为**沙箱路径**（非 URI）。
  - 复制 version / profile / settings / backup / statistics / metadata（createdAt/deviceId 保留，updatedAt 刷新为当前）。

### 6.5 备份（仅记录）流程（`BackupManager`）

- `createBackup()`（BackupManager.ets:58-157）：临时目录 `cacheDir/backup_temp` → 从 `NowViewModel.getInstance().getRecords()` 取记录 → 写 `metadata.json`（`{appVersion, timestamp, recordCount, records}`）→ 复制图片到 `backup_temp/records/` → `zlib.compressFile` 生成 `RecordLife_backup_<ts>.zip` → 删临时目录。
- `restoreBackup(zipPath)`（BackupManager.ets:160-274）：解压到 `backup_temp_restore` → 读 `metadata.json` → 图片恢复逻辑与 6.3 完全一致（`sandboxPathToUri` 拼接 `file://`）→ 写 Preferences → 删临时目录。

### 6.6 兼容性约束清单（重构红线，摘自 plan §0.2）

| # | 约束 |
| --- | --- |
| C1 | 新版本 `importAll()` 必须能解析上述 zip 结构并完整还原 config.json + records_metadata.json + records/ |
| C2 | `LifeRecord` 字段语义不得改变，新增字段必须可选 |
| C3 | `UserProfile`（name/birthDate/gender/avatar）语义不得改变，avatar 仍需支持 base64 |
| C4 | `Tag` 语义不变，`records[].tags` 引用 `Tag.id` |
| C5 | 图片导入后路径映射正确（还原到 `filesDir/records` 并转 `file://` URI） |
| C6 | 若改格式需保留 legacy v1 解析器降级路径 |

**操作规范**（plan §0.3）：凡改动 `BackupManager` / `ConfigManager.exportConfig|importConfig` / `MorePageBackupHandler.exportAll|importAll`，必须在提交说明注明**已通过旧备份导入验证**；建议尽早引入 `schemaVersion`（当前旧文件无此字段，视为 v1）。

---

## 7. 页面层

### 7.1 路由与 Tab 关系

- `main_pages.json` 注册 3 页：`pages/Index`、`pages/MorePage`、`pages/StorageImagePage`（resources/base/profile/main_pages.json；`NowPage` 已移除——P5 修正，Tab 内容页不需注册路由）。
- `Index`（@Entry，struct `MainPage`）是唯一桌面入口，含 3 个 TabContent：
  - Tab0 `HomePage()`（图标 `sys.symbol.house`）
  - Tab1 `NowPage()`（`sys.symbol.clock`）
  - Tab2 `AccountPage()`（`sys.symbol.person`）
  - `@State currentIndex` 控制，`@Builder TabBarBuilder` 自定义底部栏，激活色 `themeColors.primary`（Index.ets:10-50）。
- **路由跳转**（无参数、无 replaceUrl）：`AccountPage` → `pushUrl('pages/MorePage')`（:284）、`pushUrl('pages/StorageImagePage')`（:296）；`MorePage` → `getRouter().back()`（:328）。

### 7.2 ⚠️ `@Entry` 标注问题（重构 A4）

| 文件 | 标注 | 实际情况 |
| --- | --- | --- |
| Index.ets | `@Entry @Component` | ✅ 正确（入口） |
| NowPage.ets | 无 `@Entry`，`export { NowPage }` | ✅ 已修正（P5）：纯 Tab 内容页，不再注册路由 |
| HomePage / AccountPage | 无 `@Entry`，`export struct` | ✅ 正确（纯 Tab 内容） |
| MorePage / StorageImagePage | `@Entry` | ✅ 正确（路由页） |

### 7.3 各页面职责速查

**Index.ets（MainPage）**：Tab 容器。见 7.1。

**HomePage.ets（~717 行，struct `HomePage`）**：存活时间首页。
- 状态：`@State timeData: TimeData`、`@State @Watch birthDate`、`@State @Watch targetAge`、`@State isAccumulatedMode/isRemainingMode`（HomePage.ets:26-38）。
- `aboutToAppear`：初始化 ConfigManager → 加载 birthDate/模式/targetAge → `calculateTime()` → `setInterval` 每秒刷新 → 注册 RefreshManager（HomePage.ets:121-153）。
- 计算逻辑（核心，HomePage.ets:192-320）：
  - 累计模式：已存活年 + **总月数（years*12+months）** + 总天数 + 总时分秒（:236-245）；非累计模式：年月日精确差值 + 时分秒为 UTC+8 当前时间（:247-256）。
  - 剩余模式：`targetDate = birthDate + targetAge 年`（`TimeUtils.setFullYear`，:265-266）；超过目标年龄全 0；累计显示剩余总月/天/时/分/秒，非累计显示剩余精确年月日 + 时分秒取模（:298-318）。
- UI：`BirthDateSelector`（出生日期+目标年龄，:344）、6 张 `TimeCard`（年/月/日/时/分/秒，:482-582）、模式切换（:385-477）、分享按钮 → `ShareUtils.shareComponent(uiContext, 'share-home-card', ...)` 截取 `ShareHomeCard`（:695-730）。

**NowPage.ets（~648 行，struct `NowPage`）**：「此刻」时间线。
- 状态：`@State timelineData`、`refreshTrigger`（强刷版本号）、`searchText @Watch`、`filterTagIds @Watch`、`viewMode: 'timeline'|'calendar'`、编辑态（editingRecord/showEditDialog/editContent/editImagePaths/editTags）、`customTags`（NowPage.ets:23-79）。
- 生命周期：aboutToAppear 注册 RefreshManager + 加载标签 + refreshTimeline（:84-110）；onPageShow 重载（:119-124）。
- `refreshTimeline`（:412-431）：`viewModel.buildTimeline()` → `refreshTrigger++` → 直接赋值新对象触发更新（P5 已移除 `JSON.parse(JSON.stringify())` 深拷贝，B6 解决）。
- 增删改查：`onEditRecord`（:489）、`onSaveEdit`（:511，校验「文字或图片至少其一」→ `viewModel.updateRecord` → RefreshManager.refresh）、`onTogglePin`（:567）、`onDeleteRecord`（:599，AlertDialog 二次确认）；`EditDialogBuilder`（:364）中图片变更通过展开新数组强制触发 UI 更新（:371-381）。
- 日历视图：`CalendarView`，点击单条记录切回 timeline 并 `scroller.scrollTo` 定位 `date-年-月-日` 组件 id（:253-285）。
- 搜索/筛选：`matchRecord`（:469，匹配内容与标签名）、`getFilteredRecordCount`（:447）。

**MorePage.ets（struct `MorePage` + 两个 @CustomDialog）**：设置页（路由）。
- `ExportOptionDialog` / `ImportOptionDialog`（MorePage.ets:12-155）：让用户选择「配置 / 备份 / 全部数据」。
- `FunctionsSection` 3 项：导出（→showExportDialog）、导入（→showImportDialog）、重置应用（`isDestructive`，→onResetApp）（:265-314）。
- 全部动作委托 common/handlers（见 §6.1、§9）：`onResetApp` → `MorePageConfigHandler.resetApp`（AlertDialog 确认 → 删全部记录+清 filesDir/cacheDir+重置配置 → 重启，MorePageConfigHandler.ets:232-279）。

**AccountPage.ets（~435 行，struct `AccountPage`）**：账号设置（Tab 内容）。
- 状态：`@State userInfo: UserInfo`（userName/userBirthday/userGender/userAvatar/hasCustomAvatar）、`currentTheme`、`statisticsInfo: AccountDataStatistics`、`appInfo: AppInfo`（AccountPage.ets:23-50）。
- 生命周期：aboutToAppear 初始化 viewModel 并依次 load（:100-132）；onPageShow 跳过首次与后台已刷新，否则重载统计（:143-156）；**load 方法整体替换对象以触发 @Prop 更新**（:161 注释）。
- `SettingsSection` 列表（:340-434）：主题选择器（跟随系统/浅色/深色）、存储空间信息项（→StorageImagePage）、标签管理（→TagManagementDialog）、更多设置（→MorePage）、关于应用（→AboutAppDialog）。
- 保存资料：`onSaveProfile`（:232-255）→ `viewModel.saveProfile` → 成功 RefreshManager.refresh() 通知 HomePage 同步出生日期。
- 主题切换：`onThemeChange`（:214-223）→ `viewModel.onThemeChange` → `ThemeManager.updateTheme` + `AppStorage.setOrCreate('currentTheme', theme)` + `applicationContext.setColorMode(...)`（AccountViewModel.ets:288-356）。

**StorageImagePage.ets（struct `StorageImagePage`）**：图片存储（路由）。
- 扫描 `${context.filesDir}/records` 目录，按扩展名 `.jpg/.jpeg/.png/.gif/.webp/.bmp/.svg` 过滤（:102-106），逐文件 stat 取大小 + `fileUri.getUriFromPath` 转 URI，按大小降序（:72-151）；`storageStatistics.getFreeSize()` 取可用空间（:154-162）。
- UI：三列 Grid + Loading/空态 + 底部「已使用 X / 可用 Y」（:247-277）。

### 7.4 EntryAbility 启动流程（entryability/EntryAbility.ets）

1. `onCreate`（:11-24）：**先** `AppStorage.setOrCreate('uiContext', this.context)`，再 `initTheme()`。
2. `initTheme`（:27-50）：`ThemeManager.getInstance()`（内部从 ConfigManager 读主题 → `initAppStorage` 写 appTheme/isDarkMode/themeColors）→ `getTheme()` → `themeToColorMode` → `setColorMode`；失败回退 `COLOR_MODE_NOT_SET`。
3. `onConfigurationUpdate`（:66-76）：仅当 `appTheme === 'auto'` 时调 `ThemeManager.onSystemColorModeChange(newConfig.colorMode)`。
4. `onWindowStageCreate`（:82-96）：`loadContent('pages/Index')` → `setWindowSystemBarColor`（:99-123，从 themeColors 取 statusBar/navigationBar 颜色，浅色文字→'light'）。

---

## 8. ViewModel 层方法清单

### 8.1 NowViewModel（viewmodel/NowViewModel.ets，单例）

| 方法 | 行 | 说明 |
| --- | --- | --- |
| `getInstance()` / `init()` | 23/34 | 重试 3 次获取 uiContext + Preferences + loadRecords |
| `loadRecords()` | 76 | 读 `life_records`，**按时间戳降序排序**；空则 `initSampleData()` |
| `initSampleData()` | 100 | 生成 6 条示例记录 + 1 张渐变图（`sample_record_1~6` 字符串资源） |
| `saveRecords()` | 181 | JSON 写 Preferences + flush |
| `getRecords()` | 206 | 返回内部数组引用 |
| `addRecord(content, imagePaths?, tags?)` | 211 | unshift 插入，失败回滚 |
| `updateRecord(id, content, imagePaths?, tags?)` | 233 | 更新内容/标签；**删除不再引用的旧图片文件**（:252-268） |
| `togglePin(id)` / `getPinnedRecords()` | 282/297 | 置顶切换 / 获取收藏 |
| `deleteRecord(id)` | 302 | **删除记录关联的所有图片文件**（:312-324） |
| `buildTimeline()` | 303 | 委托 `model/RecordModel.buildTimelineData(this.records, TimeUtils.now())`（P4 纯函数化，可单测） |
| `saveImageToSandbox(sourceUri)` | 387 | 委托 `service/ImageFileService.saveRecordImage`（P3 下沉） |
| `getImageUri(path)` | 397 | 委托 `service/ImageFileService.getImageUri`（P3 下沉） |
| `generateId()` | 491 | `Date.now().toString(36) + Math.random().toString(36).substring(2)` |

### 8.2 AccountViewModel（viewmodel/AccountViewModel.ets，页面持有非单例）

| 方法 | 行 | 说明 |
| --- | --- | --- |
| `initialize(context)` | 24 | 初始化 ConfigManager / ThemeManager |
| `loadUserProfile()` | 40 | 读 config.profile → `AccountProfile`（性别经 `AccountUtils.convertGenderToDisplay`，默认「男」） |
| `loadThemeSettings()` | 81 | `themeToDisplay`（'light'→浅色模式 等） |
| `loadAppInfo()` | 98 | AppInfoManager 读取（失败回退默认 0.0.1） |
| `loadDataStatistics()` | 130 | 委托 `service/StorageService`（`calcUsageDays` + `getAppStorageSize`，P4 下沉）；dataVersion=`v${appVersion}`；原 `[StorageDebug]` 日志已清除 |
| `loadSavedAvatar()` | 254 | `file://` 直接返回；旧沙箱路径转 URI |
| `onThemeChange(value)` | 288 | 显示格式→存储格式→ThemeManager.updateTheme→applyTheme→`AppStorage('currentTheme')` |
| `onChangeAvatar()` | 359 | PhotoViewPicker 选 1 张图 → copyImageToSandbox |
| `saveProfile(name, birthday, gender, avatarPath)` | 494 | 性别转存储格式（男→male 等）→ `ConfigManager.updateProfile` |
| `copyImageToSandbox(sourceUri)` | 391 | 委托 `service/ImageFileService.copyAvatar`（含删旧 `avatar*` 缓存）→ 存 URI 到 ConfigManager（P3 下沉） |

---

## 9. 组件层清单（`components/`）

> 除标注「父传入」外，`themeColors` 均为 `@StorageLink('themeColors')`（依赖 AppStorage）。全工程**无 @Provide/@Consume**。

### calendar/
| 文件 | struct | 对外参数 / 回调 | 全局依赖 |
| --- | --- | --- | --- |
| CalendarView.ets | CalendarView | `@Prop timelineData: TimelineData @Watch`；`onRecordsClick?(records, dateStr)` / `onRecordClick?(record)` | AppStorage |
| CalendarDayItem.ets | CalendarDayItem | `@Prop calendarDay`、`@Prop isCurrentMonth`、`@Link selectedYear/Month/Day @Watch`；`onDayClick?(y,m,d)` | AppStorage |
| CalendarMonthNavigator.ets | CalendarMonthNavigator | `@Link currentYear/Month`、`@Link selectedYear/Month/Day`；`onMonthChange?()` | AppStorage |
| CalendarSelectedRecords.ets | CalendarSelectedRecords | `@Prop selectedYear/Month/Day`、`@Prop selectedRecords: LifeRecord[]`；回调同 CalendarView | AppStorage |
| CalendarUtils.ets | （纯静态类） | `buildCalendarDays` / `buildRecordMap` / `hasImageRecords` / `hasTagRecords` / `isSelected` / `getWeekdayText` / `formatTime` / `getDayColor`（选中白色、今天主题色、非当月灰色） | 无 |

### common/
| 文件 | struct | 对外参数 / 回调 | 全局依赖 |
| --- | --- | --- | --- |
| AnimatedNumber.ets | AnimatedNumber | `@Prop number @Watch`、`fontSize`、`fontColor`、`fontWeight`、`animationDuration` | AppStorage |
| AnimatedNumber.ets | AnimatedTimeValue | `@Prop value`、`label`、`description`、`cardColor`、`valueColor`、`valueFontSize` | AppStorage |
| ImageViewer.ets | ImageViewer | `@Prop imageUris: string[]`、`@Prop currentIndex`；`onClose?()` | AppStorage；用 photoAccessHelper/fs 保存图片 |
| SearchBar.ets | SearchBar | `@Link searchText`、`@Link isSearching`、`@Prop placeholder` | AppStorage |
| TagSelector.ets | TagSelector | `@Link selectedTagIds: string[]`、`@Prop isCompact` | **TagService**、AppStorage |
| TagSelector.ets | TagDisplay | `@Prop tagIds: string[]` | **TagService**、AppStorage |

### dialog/
| 文件 | struct | 对外参数 / 回调 | 全局依赖 |
| --- | --- | --- | --- |
| AboutAppDialog.ets | AboutAppDialog（@CustomDialog） | `controller`、`@Prop appInfo: AppInfo`、`@Prop themeColors @Watch`（父传入）、`@Prop usageDays` | **AppInfoManager** |
| EditProfileDialog.ets | EditProfileDialog（@CustomDialog） | `controller`、`@Prop userName/userBirthday/userGender`、`@Prop themeColors`（父传入）；`onSave(name,birthday,gender)` | 无 |
| EditRecordDialog.ets | EditRecordDialog | `@Prop record: LifeRecord\|null`、`@Link editContent`、`@Prop editImagePaths`、`@Link editTags`；`onImagePathsChange`、`onSave`、`onCancel`、`saveImageToSandbox` | **NowViewModel**、AppStorage |
| TagManagementDialog.ets | TagManagementDialog（@CustomDialog） | `controller` | **TagService**、**RefreshManager**、AppStorage |

### record/
| 文件 | struct | 对外参数 / 回调 | 全局依赖 |
| --- | --- | --- | --- |
| AddRecordSection.ets | AddRecordSection | `onSaveSuccess?()` | **NowViewModel**、**RefreshManager**、AppStorage |
| RecordCard.ets | RecordCard | `@Prop record`、`@Prop showDate`、`@Prop searchKeyword`；`onEdit?`、`onDelete?`、`onTogglePin?` | **NowViewModel**、AppStorage |
| TagFilterBar.ets | TagFilterBar | `@Link selectedTagIds`、`@Prop tagVersion @Watch`；`onChange?()` | **TagService**、AppStorage |
| TimeCard.ets | TimeCard | `@Prop value @Watch`、`label`、`description`、`cardColor`、`valueColor`、`labelColor`、`valueFontSize` | AppStorage |
| TimelineSection.ets | TimelineSection | `@Prop timelineData`、`searchKeyword`、`searchKeywordVersion @Watch`、`filterTagIds`、`filterTagIdsVersion @Watch`、`timelineDataVersion @Watch`；`onEditRecord?`、`onDeleteRecord?`、`onTogglePin?` | **TagService**、AppStorage |

### setting/（label/summary/options/onAction/onSelect 为无装饰器普通成员）
| 文件 | struct | 对外参数 / 回调 | 全局依赖 |
| --- | --- | --- | --- |
| SettingItem.ets | SettingItem | `label`、`summary` | AppStorage |
| SettingItemWithAction.ets | SettingItemWithAction | `label`、`summary`、`isDestructive`；`onAction`（整行点击） | AppStorage |
| SettingItemWithInfo.ets | SettingItemWithInfo | `label`、`@Prop info: string` | AppStorage |
| SettingItemWithSelector.ets | SettingItemWithSelector | `label`、`@Prop currentValue`、`options`；`onSelect(value)` | AppStorage |

### share/
| 文件 | struct | 对外参数 / 回调 | 全局依赖 |
| --- | --- | --- | --- |
| ShareHomeCard.ets | ShareHomeCard | `@Prop birthDate`、`targetAge`、`timeData`、`isRemainingMode`、`isAccumulatedMode`（id=`share-home-card` 供截图） | AppStorage |
| ShareRecordCard.ets | ShareRecordCard | `@Prop record` | **NowViewModel**、AppStorage |

### user/
| 文件 | struct | 对外参数 / 回调 | 全局依赖 |
| --- | --- | --- | --- |
| BirthDateRow.ets | BirthDateRow | `@Link birthDate: Date`、`@Prop themeColors`（父传入）；内部 `ConfigManager.setBirthDate` | **ConfigManager** |
| BirthDateSelector.ets | BirthDateSelector | `@Link birthDate`、`@Link targetAge`、`@Prop themeColors`（父传入） | 无（委托子组件） |
| TargetAgeRow.ets | TargetAgeRow | `@Link targetAge`、`@Prop themeColors`（父传入）；内部 `ConfigManager.setTargetAge`（1~150） | **ConfigManager** |
| UserInfoSection.ets | UserInfoSection | `@Prop userInfo: UserInfo`、`@Prop themeColors`（父传入）；`onEditProfile?()`、`onChangeAvatar?()`；**导出 `interface UserInfo`**（userName/userBirthday/userGender/userAvatar/hasCustomAvatar） | 无 |

---

## 10. 工具类清单

| 文件 | 类 | 关键方法 |
| --- | --- | --- |
| common/utils/TimeUtils.ets | TimeUtils | **统一 UTC+8**：`now` / `getFullYear/getMonth/getDate/getHours/getMinutes/getSeconds`（+8h 后取 UTC 分量）/ `setFullYear` / `formatDate`(YYYY-MM-DD) / `parseDate`(YYYY-MM-DD 按 UTC+8 0 点) / `getDateDifference` / `getLastDayOfMonth`（`formatDateCN` 已于 P6 轮次 14 删除） |
| common/utils/AccountUtils.ets | AccountUtils | `themeToDisplay/displayToTheme`、`convertGenderToDisplay/Storage`（均带 `rm` 参数：显示文本读资源、反向匹配按资源值，国际化）/ `showToastSafely(promptAction, message, duration)` |
| common/utils/ImageBase64Utils.ets | ImageBase64Utils | `imageToBase64(path)`（util.Base64Helper）/ `base64ToImage(base64, outPath)` / `uriToSandboxPath` / `getAvatarSavePath` → `filesDir/avatar.jpg` |
| common/utils/ImagePickerUtils.ets | ImagePickerUtils + `ImagePickResult` + `enum ImagePickMode` | `pickImage(context, mode)`：CAMERA 走 `cameraPicker.pick`（需 CAMERA 权限）、GALLERY 走 `photoAccessHelper.PhotoViewPicker`；`showErrorToast` |
| common/utils/MorePageHelper.ets | MorePageHelper | `deleteDirectory` / `uriToSandboxPath`（委托 ImagePathUtils）/ `fileExists`（`readFileContent`/`writeFileContent`/`copyFile`/`ensureDirectory` 死代码已删，P6 轮次 21） |
| common/utils/ImagePathUtils.ets | ImagePathUtils | ★ P3 新增：`uriToSandboxPath`（统一实现）/ `sandboxPathToUri` / `getFileName` |
| common/utils/TagDisplayUtils.ets | TagDisplayUtils | ★ P6 轮次 20 新增：`buildDisplayTags(customTags, rm)` / `getDisplayTagName(tagId, customTags, rm)`（预设标签 id → 资源显示名映射；`DEFAULT_TAGS.name` 保持数据层） |
| common/utils/MoodUtils.ets | MoodUtils | ★ 更新计划二期：`PRESET_MOODS`（5 预置）/ `PRESET_MOOD_EMOJIS`（24 候选池）/ `getMoodEmoji(id, customMoods?)` / `isValidMood` / `getAllMoods(customMoods?)`（纯函数，可单测） |
| service/MoodService.ets | MoodService | ★ 更新计划二期：自定义心情 CRUD（`getCustomMoods`/`addCustomMood`/`deleteCustomMood`，读写 `config.settings.customMoods`，预置不可改） |
| service/TemplateService.ets | TemplateService | ★ 更新计划三期：记录模板 CRUD（`getTemplates`/`addTemplate`/`updateTemplate`/`deleteTemplate`，读写 `config.settings.recordTemplates`） |
| common/utils/Logger.ets | Logger | ★ B3 轮次 19 新增：`info/warn/error`（hilog 封装 + `setDebugEnabled` 开关，error 恒输出）；全工程 `console.*` 已统一至此 |
| service/ImageFileService.ets | ImageFileService | ★ P3 新增：`saveRecordImage` / `getImageUri` / `deleteImageFiles` / `copyAvatar`（记录图片与头像的沙箱 IO） |
| service/ZipTransferService.ets | ZipTransferService | ★ P3 新增：`saveZipToDocument` / `pickZipToSandbox`（DocumentViewPicker zip 保存/选择 + 沙箱复制；取消返回 false，IO 异常冒泡） |
| service/ConfigTransferService.ets | ConfigTransferService | ★ P3 新增：`exportConfig` / `importConfig`（用户配置导出/导入 + 头像 base64 转换，拆自 ConfigManager） |
| service/StorageService.ets | StorageService | ★ P4 新增：`getAppStorageSize(context)` / `formatStorageSize`（纯函数）/ `calcUsageDays`；★ 更新计划三期：`cleanupCache` / `clearShareCache`（cacheDir/share_*.jpg）/ `clearOrphanRecordImages`（filesDir/records 未被引用图） |
| common/ColorUtils.ets | ColorUtils | `withAlpha(hex, alpha)` → rgba、`primaryLight`(α32)/`primaryExtraLight`(α20)/`primaryUltraLight`(α15) |
| common/utils/ShareUtils.ets | ShareUtils | `shareComponent(uiContext, componentId, context, title?, desc?)`：getComponentSnapshot → packToData(jpeg 95) → 存 `cacheDir/share_<ts>.jpg` → `systemShare.ShareController.show`；`cleanupOldShareImages`（P5 自顶层 utils/ 迁入） |
| common/utils/ImageGenerator.ets | ImageGenerator | `generateSolidColorImage`（存 `filesDir/records`）、`generateGradientImage`（存 `filesDir/sample_images`），BGRA_8888 逐像素生成（P5 自顶层 utils/ 迁入） |

---

## 11. 主题机制

### 11.1 颜色体系（三层）

1. **资源层** `color.json`（base/dark 各 11 key，key 完全一致）：`start_window_background`、`divider`、`overlay_mask`、`shadow_light`、`shadow_medium`、`white`、`black`、`error_light`、`success_light`、`warning_light`、`info_light`。⚠️ **.ets 代码中并未引用 `$r('app.color.*')`**，这些资源目前只被 module.json5（启动窗口）等使用；实际 UI 颜色走第 2 层。
2. **代码层** `ThemeConfig.ets`：`interface ThemeColors`（background/cardBackground/divider/textPrimary/textSecondary/textTertiary/primary/primaryLight/primaryDark/success/warning/error/info/border/shadow/avatarBorder/iconColor/overlay）+ `LightTheme`/`DarkTheme` 两套常量 + `ThemeConfig.getColors(isDark)` / `isDarkMode(theme, systemColorMode)`（auto 跟随系统）/ `getDisplayName`/`fromDisplayName`。
3. **标签调色板**（数据非 UI，有意保留硬编码）：`DEFAULT_TAGS` 10 色（§3.2）。

### 11.2 状态流转

```text
用户切换（AccountPage）→ AccountViewModel.onThemeChange
  → ThemeManager.updateTheme(theme)         # ① ConfigManager.setTheme 持久化 ② 算 isDark ③ 写 AppStorage(appTheme/isDarkMode/themeColors) ④ updateWindowSystemBarColor
  → applicationContext.setColorMode(...)     # 系统级
系统级变化（auto 模式）→ EntryAbility.onConfigurationUpdate → ThemeManager.onSystemColorModeChange → 仅更新 AppStorage（不持久化）
```
- 主题数据源唯一：**ConfigManager**（ThemeManager.ets:5 注释）；组件一律 `@StorageLink('themeColors')` 响应。
- 窗口系统栏：`window.getLastWindow(uiContext)` + `setWindowSystemBarProperties`（statusBar/navigationBar 色 = colors.background，内容色按 `textPrimary === '#FFFFFF'` 判定，ThemeManager.ets:133-156）。

---

## 12. 资源体系（国际化）

### 12.1 `string.json`（base 中文 / en_US 英文，约 300+ 个 key，一一对应）

- 命名规范：小写 snake_case；系统约定名（`module_desc`、`EntryAbility_label`）；权限理由 `*_reason`；导航 `tab_*`；功能域前缀分组（`tag_*`、`profile_*`、`remaining_*`/`accumulated_*`/`current_*`/`non_accumulated_*`、`share_*`、`theme_*`、`storage_*`/`clear_cache_*`、`import_*`/`export_*`/`backup_*`/`reset_*`/`restore_*`、`sample_record_1~6`）；语义后缀 `_success/_failed/_hint/_placeholder/_title/_label/_desc/_prefix/_suffix/_confirm/_unit/_short`。
- ✅ 拼接文本国际化已完成（P6 轮次 14）：含动态值的中文拼接（`共 X 条记录` / `X年X月X日` / `今天/昨天/N天前` / `已使用 X / 可用 Y` / 星期标题等）全部改为 `$r('app.string.key', args)` 或 `getStringByNameSync(key, ...args)`，资源带 `%1$d`/`%2$d`/`%s` 占位符，base/en_US 双语言一一对应。
- ✅ 硬编码中文已全部清零（轮次 21）：UI 文本（主题/性别映射、默认值、选择器、toast、时间单位、版本号、拼接文本、预设标签名）全部资源化；`MorePageHelper` 4 处中文异常消息随死方法删除。仅剩合理保留：`DEFAULT_TAGS.name`（数据层，显示映射已国际化）、Logger 日志文本、代码注释。`MorePageBackupHandler` 部分 `getStringByNameSync('...')` 直接按名取（key 名未走 `$r()` 编译期校验）。

### 12.2 权限（module.json5）

- `requestPermissions` 仅 1 项：`ohos.permission.CAMERA`（reason=`camera_reason`，usedScene 限 EntryAbility、when=inuse）。
- 图库选择/保存走 Picker（`PhotoViewPicker`/`DocumentViewPicker`/`cameraPicker`），**无需** WRITE_IMAGE 权限；`string.json` 中虽有 `write_image_reason` 但未声明对应权限。

---

## 13. 工程配置要点

| 文件 | 要点 |
| --- | --- |
| AppScope/app.json5 | bundleName `com.rainforcetime.recordlife`、vendor `rainforcetime`、versionCode 20000 / versionName 2.0.0 |
| entry/src/main/module.json5 | module `entry`、deviceTypes [phone, tablet]；abilities：`EntryAbility`（exported，home 意图）；extensionAbilities：`EntryBackupAbility`（type=backup，metadata `ohos.extension.backup` → `resources/base/profile/backup_config.json` = `{"allowToBackupRestore": true}`） |
| build-profile.json5 | signingConfigs `default`（HarmonyOS，debug 签名，material 指向 `C:\Users\19526\.ohos\config\...`，`signAlg=SHA256withECDSA`）；`strictMode.caseSensitiveCheck=true` |
| code-linter.json5 | 扫描 `**/*.ets`，忽略 ohosTest/test/mock/node_modules/oh_modules/build/.preview；规则 `plugin:@performance/recommended` + `plugin:@typescript-eslint/recommended` + 安全类 `@security/no-unsafe-*`（密码学禁用，全 error 除 no-unsafe-mac 为 warn） |
| .gitignore | `/node_modules`、`/oh_modules`、`/local.properties`、`/.idea`、`**/build`、`/.hvigor`、`.cxx`、`/.appanalyzer`、`/.preview` 等（已覆盖重构 C4） |
| entrybackupability/EntryBackupAbility.ets | 继承 `BackupExtensionAbility`，`onBackup`/`onRestore` 均为**空实现占位**（仅 hilog），实际备份走系统默认机制 |

### 测试现状
- `entry/src/ohosTest/ets/test/Ability.test.ets`、`List.test.ets`（仪器测试）与 `entry/src/test/LocalUnit.test.ets`、`List.test.ets`（本地单测）。
- **业务单测已接入**（P6 轮次 11）：`entry/src/test/` 下 `RecordModel.test.ets`（buildTimelineData 4 用例）、`StorageService.test.ets`（formatStorageSize/calcUsageDays 7 用例）、`ConfigModel.test.ets`（validateConfig/TimeUtils 8 用例），由 `List.test.ets` 注册，共 15 个用例。
- 被测对象均为纯函数；依赖系统 API 的 `StorageService.getAppStorageSize` 未测（可用 hamock 后续补）。
- 依赖已配：`@ohos/hypium@1.0.25`、`@ohos/hamock@1.0.0`。

---

## 14. 已知问题与重构关注点（与 refactoring-plan 呼应）

| # | 问题 | 位置 | 对应重构项 |
| --- | --- | --- | --- |
| 1 | ~~`NowPage` 误标 `@Entry` 且被 Tab 引用~~ ✅ 已修正 | NowPage 去 `@Entry`，`main_pages.json` 3 页（P5 轮次 10） | A4 / P5 已解决 |
| 2 | ~~旧式 `@ohos.*` import~~ ✅ 已清零 | 8 处/6 文件全部统一为 `@kit.*`：`@kit.ArkData`(preferences)、`@kit.CoreFileKit`(fileIo)、`@kit.MediaLibraryKit`(photoAccessHelper)、`@kit.AbilityKit`(common)、`@kit.ArkUI`(promptAction)（P7 轮次 12） | B4 / P7 已解决 |
| 3 | 硬编码颜色残留（有意保留类）：标签调色板 10 色、`getDayColor` 选中 `'#FFFFFF'`（CalendarUtils.ets:193）、主题判定 `textPrimary === '#FFFFFF'`（ThemeManager.ets:147/149）、纯白文字 on 彩色背景 | 多处 | B1 残余说明 |
| 4 | `createDefaultConfig` / `createDefaultConfigSync` 几乎重复 | UserConfigModel.ets:83/138 | B5 |
| 5 | ~~`JSON.parse(JSON.stringify(...))` 深拷贝~~ ✅ 已替换 | NowPage.refreshTimeline 直接赋值（buildTimelineData 每次返回全新对象图，P5 轮次 10） | B6 已解决 |
| 6 | ~~调试日志泛滥（`console.info` 100+，含 `>>>`/`[StorageDebug]`/`[ConfigManager]` 等）~~ ✅ 已收敛 | 全工程 `console.*` 清零（B3 轮次 19）：统一 `common/utils/Logger`（hilog 封装 + 开关，error 恒输出）；`>>>` 临时日志与 `[StorageDebug]` 已移除 | B3 已解决 |
| 7 | `uiContext` 获取失败时 `getPromptAction` 等生命周期初始化风险 | NowPage.ets:82 等 | B7 |
| 8 | ~~`uriToSandboxPath` 三处重复实现~~ ✅ 已收敛 | 统一至 `common/utils/ImagePathUtils.ets`（P3 轮次 4）；MorePageHelper 保留委托兼容 | C1 已解决 |
| 9 | ~~无业务单测~~ ✅ 已解决（15 用例）；ViewModel fileIo 已下沉 | NowViewModel 的 fileIo 已下沉至 `service/ImageFileService`（P3 轮次 4）；AccountViewModel 仍直接 import fileIo（loadSavedAvatar 用）；单测见 `entry/src/test/`（P6 轮次 11） | A3/C2/P4 |
| 10 | ~~页面/组件硬依赖单例 + AppStorage，不可注入~~ ✅ 已解决 | 单例 `getInstance(context?)` 支持显式注入 + AppStorage 兜底（A5 轮次 17） | A5/P6 已解决 |
| 11 | `imagePaths` 存在「URI」与「沙箱路径」两种历史格式 | §4.3 | 重构注意 |
| 12 | 示例数据含预设表外标签 id（`entertainment`/`family`） | NowViewModel.ets:139/165 | 显示回退 |
| 13 | plan §0.1 备份格式快照与当前代码有出入（图片文件名/records 文件名/记录数组） | §6.2 ⚠️ | 验证以实际代码为准 |
| 14 | `AppInfoConfig` 中存在 `interface AppInfoConfig` 与 `class AppInfoManager` 同名近似（前者几乎未被使用，AccountViewModel 用 `AppInfo` 类型） | AppInfoConfig.ets:8/21 | P1 遗留 |

---

## 15. 常用命令

```powershell
# 构建（项目根目录，需要 DevEco/hvigor 环境）
.\hvigorw.bat assembleHap          # 或 hvigorw assembleHap
# 测试
.\hvigorw.bat test                 # 运行 ohosTest / test
# 代码检查
.\hvigorw.bat codeLinter           # 或 IDE 内置 Code Linter
```

> 环境注意：本机无 `hvigorw` 全局命令时需在 DevEco Studio 内构建；`local.properties` 含本机 SDK 路径。

---

## 16. 新窗口任务开工清单（每轮必读）

1. 阅读 `docs/refactoring-plan.md` §0（数据兼容性）与 §10.2（最近一轮工作日志）。
2. 若改动涉及备份/导入导出：阅读本文档 §6，并遵守 plan §0.3 操作规范（提交注明已通过旧备份导入验证）。
3. 改动类型定义：以 `model/` 为单一数据源，`common/types.ets`/`config/UserConfig.ets` 是兼容 barrel，勿重复定义。
4. 改 `@Entry`/路由：同步 `main_pages.json`。
5. 遵守 ArkTS 约束：不使用 `any/unknown`、索引访问类型、`as const`；import 统一 `@kit.*`。
