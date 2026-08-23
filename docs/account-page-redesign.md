# 「我的」页 UI 重构方案（AccountPage Redesign）

> **状态**：方案评审中（2026-08-23），确认后按 §6 轮次执行
> **前置**：当前「我的」页为四分组悬浮卡片结构（常规/数据/个性化/更多），用户区居中卡片 + emoji/SymbolGlyph 混用
> **配套文档**：`docs/refactoring-plan.md`（重构历史）、`docs/update-plan.md`（功能路线）、`docs/technical-reference.md`（实现参考，涉及数据/持久化改动先读）
> **提交规范**：git 提交沿用 `2.2.x` 前缀；UI 微调不单独提交，整轮收尾统一提交（仅本地，推送需明确要求）

---

## 1. 重构目标

1. **信息架构更清晰**：分组按用途重排（外观/数据/个性化/更多），隐私模式归入外观组。
2. **视觉风格统一**：设置项统一「emoji + 彩色圆角容器」图标；用户区改左对齐列表式；样式抽公共组件消除重复。
3. **交互一致**：隐私模式行并入 SettingItem 体系（带 Switch），不再内联手写。
4. **行为零变更**：所有入口（跳转/弹窗/保存逻辑）保持不变，只改 UI 呈现。

## 2. 现状与问题

| 问题 | 位置 |
| --- | --- |
| 分组卡片样式重复 4 份（90% 宽 + shadow 块） | AccountPage.ets 509–519 / 564–574 / 589–599 / 629–639 |
| 图标风格混用（emoji 与 SymbolGlyph 并存） | AccountPage.ets 标题区 vs 设置行 |
| 隐私模式行脱离 SettingItem 体系内联实现，无 chevron、视觉不统一 | AccountPage.ets 479–507 |
| 用户区居中卡片信息密度低 | UserInfoSection.ets 全篇 |
| 页面底部无版本 footer（版本仅「关于应用」行/弹窗可见） | AccountPage.ets 412–413 |

## 3. 新信息架构

```
我的（Tab 页，无独立标题栏）
├── 用户信息区（左对齐列表式卡片，渐变背景）
│    头像(左) + 姓名/签名/标签(右) + 编辑按钮(右上)
│
└── 设置区
    ├── 外观        主题 / 字体大小 / 隐私模式
    ├── 数据        数据看板 / 存储空间 / 清理缓存
    ├── 个性化      个性化管理（标签/心情/模板）
    └── 更多        更多设置 / 关于应用
```

## 4. 分区设计详述

### 4.1 用户信息区（UserInfoSection 左对齐改造）

```
┌──────────────────────────────────────┐
│  [头像88px]   姓名(22 Bold)      [编辑]│ ← 编辑按钮右上角
│  [相机角标]   签名(14 灰,2行省略)      │
│               🔒 隐私模式已开启(标签行) │
└──────────────────────────────────────┘
```

- **布局**：卡片内 `Row`：左头像（88px 圆 + 右下 28px 相机角标，点击换头像）→ 右 `Column`（姓名 22 Bold / 签名 14 灰 2 行省略 / 性别·出生日期标签行，隐私模式时出生日期换 🔒「隐私模式已开启」）→ 右上角「编辑」胶囊按钮（36×28 或 64×28 小按钮）。
- **背景**：保留上下渐变（主色 0.45 → 0.20 → cardBackground 实色）+ borderRadius 16 + shadow；卡片内 padding 调整（左 20 右 16）。
- **其他**：深色模式判断改为 `ThemeConfig` 提供的能力（消除 `textPrimary === '#FFFFFF'` 硬编码，若存在则一并处理）。

### 4.2 外观组

| 设置项 | 图标 | 容器色 | 交互（不变） |
| --- | --- | --- | --- |
| 主题 | 🎭 | 紫 | TextPickerDialog（跟随系统/浅色/深色） |
| 字体大小 | 🔠 | 蓝 | TextPickerDialog（小/中/大） |
| 隐私模式 | 🔒 | 橙 | **Switch 行**（并入 SettingItem 体系，新增右侧 Switch 槽位） |

### 4.3 数据组

| 设置项 | 图标 | 容器色 | 交互（不变） |
| --- | --- | --- | --- |
| 数据看板 | 📊 | 蓝 | 跳 DashboardPage |
| 存储空间 | 💾 | 绿 | 跳 StorageImagePage（右侧显示已用空间） |
| 清理缓存 | 🧹 | 青 | 清理 + toast |

### 4.4 个性化组

| 设置项 | 图标 | 容器色 | 交互（不变） |
| --- | --- | --- | --- |
| 个性化管理 | 🎨 | 粉 | 打开 TagManagementDialog（标签/心情/模板 Tab） |

### 4.5 更多组

| 设置项 | 图标 | 容器色 | 交互（不变） |
| --- | --- | --- | --- |
| 更多设置 | ⚙️ | 灰 | 跳 MorePage（备份/重置） |
| 关于应用 | ℹ️ | 青 | 打开 AboutAppDialog（右侧显示版本号） |

- **版本 footer**（可选新增）：页面底部加「活着 v2.3.0」灰色小字居中（与「关于应用」版本号同一来源）。

## 5. 组件层改动清单

| 文件 | 改动 |
| --- | --- |
| `components/setting/SettingItem.ets` | 图标改为「emoji + 彩色圆角容器」（40px 圆角方块，浅色底 + emoji 居中）；新增 `iconBg` prop（容器底色） |
| `components/setting/SettingItemWithInfo.ets` | 同上图标改造（存储空间/关于应用） |
| `components/setting/SettingItemWithSelector.ets` | 同上图标改造（主题/字体大小） |
| `components/setting/SettingItemWithSwitch.ets` | **新建**：label + 图标容器 + 右侧 Switch（隐私模式用） |
| `components/setting/SettingsGroupCard.ets` | **新建**：分组卡片容器（90% 宽 + borderRadius 16 + shadow + 内 padding），接收 @Builder 内容，消除 AccountPage 4 份重复样式 |
| `components/user/UserInfoSection.ets` | 居中 → **左对齐列表式**改造（布局 + 编辑按钮位置 + 标签行） |
| `pages/AccountPage.ets` | 分组重排（外观/数据/个性化/更多）+ 用 SettingsGroupCard 收敛样式 + 隐私模式行换 SettingItemWithSwitch + （可选）版本 footer |

**不动的**：所有弹窗（EditProfileDialog / AboutAppDialog / TagManagementDialog）、跳转（DashboardPage / StorageImagePage / MorePage）、AccountViewModel 全部逻辑。

## 6. 执行计划（轮次拆分）

### 轮次 1 —— 组件底座
- 新建 `SettingsGroupCard`；重构 `SettingItem` / `SettingItemWithInfo` / `SettingItemWithSelector` 图标容器；新建 `SettingItemWithSwitch`。

### 轮次 2 —— 用户区 + 页面组装
- `UserInfoSection` 左对齐改造；`AccountPage` 分组重排 + 引用新组件 + 隐私模式行替换 + （可选）版本 footer。

### 轮次 3 —— 收口
- DevEco 编译零错误 + 实机回归（主题/字体/隐私/跳转/弹窗/个性化管理）+ 中英文资源检查 + 本地提交。

## 7. 验证清单

- [ ] DevEco 编译零错误（warning 不计）
- [ ] 用户区：头像点击换头像、编辑按钮打开 EditProfileDialog、签名/标签/隐私遮罩正常
- [ ] 主题切换 → 全局配色即时生效（含新图标容器底色随主题）
- [ ] 字体大小切换 → 生效
- [ ] 隐私模式 → 首页与我的页敏感信息隐藏联动
- [ ] 数据看板 / 存储空间 / 更多设置 跳转正常；个性化管理弹窗 3 Tab 正常
- [ ] 关于应用弹窗 + 版本号显示正常
- [ ] 中英文资源无缺漏（新图标无文本，主要核对既有 key）
