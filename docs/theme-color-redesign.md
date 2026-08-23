# 「主题配色」功能设计方案（Theme Color Redesign）

> **状态**：方案评审中（2026-08-23），确认后实施
> **背景**：当前「主题设置」仅提供浅色/深色/跟随系统（模式切换），用户认为不算「主题」；需求 = 新增**可调整整个软件配色**的主题功能，入口放「我的 → 个性化」组
> **配套**：`docs/technical-reference.md`（主题机制参考）、`docs/refactoring-plan.md`（架构约定，数据模型改动遵循 C1~C6：只加可选字段）
> **提交**：自动本地提交（3.0.x 递增），推送需明确要求

---

## 1. 目标

1. **「主题设置」改名「深色模式」**（light/dark/auto 是模式，非主题——命名更贴切）。
2. **新增「主题配色」**：用户从预设色板选择主色，全局配色（primary 及衍生色）实时生效。
3. **入口**：「我的 → 个性化 → 主题配色」。
4. **数据兼容**：AppSettings 新增可选字段，旧备份导入无损（缺省走默认主色）。

## 2. 现状与机制（已核实）

| 层 | 现状 |
| --- | --- |
| 颜色定义 | `ThemeConfig.LightTheme/DarkTheme` 写死（primary `#007DFF` / `#4DA3FF`），`getColors(isDark)` 直接返回 |
| 全局广播 | `ThemeManager` 通过 `AppStorage.setOrCreate('themeColors', ...)` 广播，全组件 `@StorageLink('themeColors')` 自动响应 ✅ |
| 持久化 | `ConfigManager` 读写 `settings.theme`（'light'/'dark'/'auto'） |
| 调色工具 | `ColorUtils.primaryLight(hex)` 已有（调亮）；**primaryDark 缺失**（需新增） |
| UI 引用 | 主题模式用 `SettingItemWithSelector`（通用组） |

## 3. 设计

### 3.1 数据层（C1~C6 兼容）
- `AppSettings` 新增**可选字段** `themeColor?: string`（hex，如 `'#007DFF'`；缺省 → 默认蓝）。
- `ConfigManager`：`getThemeColor(): string`（兜底默认蓝）、`setThemeColor(color): Promise<boolean>`。

### 3.2 颜色生成
- `ThemeConfig.getColors(isDark, primaryColor?)`：
  - 无 `primaryColor` → 保持现有 Light/DarkTheme（行为不变）。
  - 有 → 复制基础色板，替换三个主题色：
    - `primary` = 主色（深色模式**自动调亮 20%** 保证对比度）
    - `primaryLight` = `ColorUtils.primaryLight(主色)`
    - `primaryDark` = `ColorUtils.primaryDark(主色)`（**新增**：hex 调暗）
  - 其余色板（背景/文本/功能色）保持模式默认。

### 3.3 广播（ThemeManager）
- 新增 `updateThemeColor(color)`：保存 ConfigManager → `AppStorage.setOrCreate('themeColors', getColors(isDark, color))` → 更新窗口系统栏颜色。
- `init / updateTheme / onSystemColorModeChange` 三处生成 `themeColors` 时**携带主色**（`getThemeColor()`）。

### 3.4 UI（AccountPage）
- **通用组**：「主题设置」→「**深色模式**」（label 改 `dark_mode`，选项不变）。
- **个性化组**：新增「**主题配色**」行（🎨 图标 + 当前色块预览 + chevron）→ 点击**展开色板**（8 个预设色块 Flex，选中描边，与标签颜色选择器同风格）。
  - 预设色板：默认蓝 `#007DFF` / 翡翠绿 `#07C160` / 紫 `#8E44AD` / 珊瑚红 `#FF6B6B` / 橙 `#FF8C00` / 樱粉 `#FF4D88` / 青 `#00B8A9` / 靛蓝 `#4A4DE0`。
- 切换后 `RefreshManager` 不必（AppStorage 广播即全组件响应）。

### 3.5 资源（新增 ~10 key，417 → ~427）
- `theme_color`（主题配色 / Theme color）
- `theme_color_default`（默认蓝 / Default blue）等 8 个颜色名
- `dark_mode_label` 复用现有 `dark_mode`（深色模式 / Dark mode，已有）
- 删除/弃用 `theme_settings`（主题设置，改名后不再引用）

## 4. 可行性自评

| 项 | 评估 | 风险 |
| --- | --- | --- |
| 全局实时生效 | **低**——AppStorage `themeColors` 广播机制已存在，改色即全组件响应 | 无 |
| primaryLight/primaryDark 衍生 | **低**——`primaryLight` 已有，新增 `primaryDark`（hex 调暗 ~10 行算法） | 无 |
| 数据兼容 | **低**——可选字段 + 默认值，旧备份/旧配置无损（C1~C6） | 无 |
| 深色模式对比度 | **中**——深色底 + 深主色（如靛蓝/紫）可能看不清；对策：深色模式主色自动调亮 20% | 需实机验证各主色 × 深浅模式 |
| 硬编码主题色残留 | **中**——需 grep 全工程 `#007DFF`/`#4DA3FF` 等直接写死的 primary（用户区 `getAccentColor` 已删，但其他组件可能残留） | 需排查替换为 `themeColors.primary` |
| 色板 UI | **低**——复用标签颜色选择器模式（Flex 色块 + 选中描边） | 无 |

**结论：可行**。核心机制（AppStorage 广播）现成，改动集中在数据字段 + 颜色生成 + 一个 UI 入口，无架构级风险；主要验证点在深色模式对比度与硬编码清理。

## 5. 执行计划

### 轮次 1 —— 数据与颜色引擎
- `UserConfigModel.AppSettings.themeColor?` + `ConfigManager.get/setThemeColor`
- `ColorUtils.primaryDark` 新增；`ThemeConfig.getColors(isDark, primaryColor?)` 主色替换
- 单测：`getColors` 主色替换正确性（可选）

### 轮次 2 —— 广播
- `ThemeManager.updateThemeColor` + init/updateTheme/onSystemColorModeChange 携带主色

### 轮次 3 —— UI + 资源
- 通用组「主题设置」→「深色模式」；个性化组「主题配色」色板
- 资源新增/调整；硬编码主题色 grep 清理

### 轮次 4 —— 验证
- DevEco 编译 + 实机：8 主色 × 深浅模式对比度、切换实时生效、重启保留、旧备份导入、中英文

## 6. 验证清单

- [ ] 个性化 → 主题配色：色板展开、选中高亮、切换后全局主色实时变化
- [ ] 深色模式 × 各主色可读性（重点靛蓝/紫/深色系）
- [ ] 重启应用主题色保留
- [ ] 旧备份导入无影响（themeColor 缺省走默认蓝）
- [ ] 中英文资源完整
- [ ] 全工程无硬编码 `#007DFF` 残留（或已明确忽略处）
