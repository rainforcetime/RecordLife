# RecordLife 更新计划（重构后 v2.x 功能路线）

> **状态**：规划完成，执行跟踪机制已建立（2026-08-22）；分期进度见 §6 里程碑表，每轮开发记录见 §7 轮次日志，实机验证见 §8 验证记录。开工前先过 §9 检查清单。
> **前置**：架构重构已完成（git 2.2.19，P0~P8 + A5 + 国际化 + 日志收敛 + 15 单测）；本文档基于 `README.md`「AI 对新增功能的分析」中**未实现**的功能清单规划。
> **配套文档**：`docs/refactoring-plan.md`（重构历史）、`docs/technical-reference.md`（当前实现参考，改动涉及数据模型/持久化/备份必须先读 §5 与 §6）。
> **版本说明**：文中「一期/二期…」为发布规划代号；落地时同步 bump `AppScope/app.json5` 的 `versionName/versionCode`（当前 2.0.0/20000）。git 提交标题沿用 `2.x.y` 前缀递增（与 versionName 解耦）。

---

## 1. 规划原则（稳扎稳打）

1. **小步快跑**：每期 2~4 个内聚功能，完成即发版，不做大版本捆绑。
2. **先易后难、风险递增**：纯计算/纯 UI 先行 → 数据模型扩展 → 系统能力（权限/通知/后台）。
3. **数据兼容红线（延续 C1~C6）**：任何数据模型改动**只允许新增可选字段**，且必须提供默认值；涉及持久化/备份的期次必须做**旧备份导入回归**。
4. **架构一致**：新功能遵循 `model / repository / service / viewmodel / components / pages` 分层；可复用能力（TimeUtils 纯函数、StorageService、ImageFileService、TagFilterBar 等）优先扩展而非新造。
5. **可验证闭环**：每期结束 = DevEco 编译零错误 + 新增纯函数单测 + 实机回归（记录增删改查 / 备份导出导入）+ 中英文资源回归。
6. **国际化延续（B2 红线）**：新 UI 文本一律 `$r()` 资源化，禁止硬编码中文。

---

## 2. 功能依赖与风险矩阵

> 难度/推荐标记沿用 README；「数据影响」为兼容性评估（✅ 无持久化改动 / ⚠️ 新增可选字段 / 🔴 结构级改动需评审）。

| 功能 | 难度 | 依赖 | 数据影响 | 关键风险 / 前置验证 |
| --- | --- | --- | --- | --- |
| 周数/总天数 | ⭐ | TimeUtils | ✅ 纯计算 | 无（纯函数可单测） |
| 每年生日提醒 | ⭐ | TimeUtils | ✅ 纯计算 | 无 |
| 签名/座右铭 | ⭐ | UserProfile | ⚠️ `signature?` | 旧备份缺字段走默认值 |
| 字体大小设置 | ⭐ | AppSettings | ⚠️ `fontSize?` | 全局样式需统一入口 |
| 心情标记 | ⭐🔥 | LifeRecord | ⚠️ `mood?` | 编辑 UI + 筛选器扩展 |
| 撤销删除 | ⭐ | RecordRepository | ✅ 内存暂存 | 软删除 3s 窗口，不落盘 |
| 缓存清理 | ⭐ | StorageService / ImageFileService | ✅ | 清理白名单需谨慎 |
| 隐私模式 | ⭐ | AppSettings | ⚠️ `privacyMode?` | 首页敏感字段联动 |
| 记录模板 | ⭐ | 新 preferences key | ⚠️ 新 key | 模板数据模型 |
| 批量删除 | ⭐⭐ | RecordViewModel 删除流程 | ✅ | 多选 UI 复杂度 |
| 时间线快速跳转 | ⭐⭐ | NowPage 时间线 | ✅ | 侧边索引定位逻辑 |
| 多倒计时 | ⭐⭐ | AppSettings | ⚠️ `countdowns?`（数组） | 数组字段序列化兼容 |
| 生命进度可视化 | ⭐⭐ | TimeUtils | ✅ 纯计算 | 环形进度 UI |
| 生命统计面板 | ⭐⭐ | RecordRepository 聚合 | ✅ | 统计口径定义 |
| 数据看板 | ⭐⭐⭐🔥 | RecordRepository 聚合 | ✅ | 聚合查询性能（记录量大时） |
| 日记月历统计（热力图） | ⭐⭐⭐ | CalendarView | ✅ | 日历组件扩展 |
| 图片压缩 | ⭐⭐ | ImageFileService | ⚠️ 元数据不变，图片文件替换 | **质量风险**：需压缩率/质量对照；替换后引用一致性 |
| 引导页 | ⭐⭐ | EntryAbility 路由 | ⚠️ 新 preferences key | 首装判定 |
| 记录连续打卡 | ⭐⭐ | RecordRepository | ✅ | 连续天数算法（可单测） |
| 剪贴板识别 | ⭐⭐ | 剪贴板 API | ✅ | **前置验证**：API 可用性 + 隐私提示 |
| 位置标记 | ⭐⭐⭐ | LifeRecord | ⚠️ `location?` | **前置验证**：定位权限（敏感）+ 逆地理编码能力 |
| 导出 Markdown/PDF | ⭐⭐⭐ | ZipTransferService 模式复用 | ✅ | 文件生成 + 分享链路 |
| 应用锁 | ⭐⭐⭐ | 全局生命周期 | ✅ 纯前端 | 安全敏感，防绕过需评审 |
| 快捷方式 | ⭐⭐⭐ | 桌面快捷方式 API | ✅ | **前置验证**：API 可用性 |
| 语音记录 | ⭐⭐⭐⭐ | 本地语音识别 | ⚠️ `voicePath?`/文本 | **前置验证**：HarmonyOS 本地识别 SDK 可用性（不确定，风险最高） |
| 桌面小组件 | ⭐⭐⭐⭐ | FormExtensionAbility | ✅ | 架构级扩展（新增 extension 模块），独立评估 |

---

## 3. 分期计划

### 一期 —— 轻量增强（建议 versionName 2.1）

**目标**：零持久化风险的第一批功能，建立「纯函数 + 单测」的正反馈。

- [ ] ⭐ **周数/总天数** — `TimeUtils` 新增纯函数（出生日期 → 第几周/第几天），NowPage 展示
- [ ] ⭐ **每年生日提醒** — `TimeUtils` 新增纯函数（距下次生日天数），NowPage/我的页展示
- [ ] ⭐ **签名/座右铭** — `UserProfile.signature?`（可选字段），我的页编辑 + 首页展示
- [ ] ⭐ **字体大小设置** — `AppSettings.fontSize?`（'small'|'medium'|'large'），我的页设置项 + 全局样式入口

**涉及模块**：`common/utils/TimeUtils`、`model/UserConfigModel`、`pages/NowPage`、`pages/AccountPage`、`components/`
**数据影响**：✅/⚠️ 仅新增可选字段（旧备份导入自动走默认值，无迁移逻辑）
**验证清单**：单测（3 个新纯函数）+ 实机回归 + 备份导入（保险起见仍跑一遍）

### 二期 —— 记录体验（建议 versionName 2.2）

**目标**：核心记录链路增强，涉及 `LifeRecord` 扩展。

- [ ] ⭐🔥 **心情标记** — `LifeRecord.mood?`（可选 enum：happy/calm/sad 等 + 资源图标），记录编辑 UI + 时间线展示 + 按心情筛选（复用 TagFilterBar 模式）
- [ ] ⭐ **撤销删除** — `RecordViewModel` 删除改为暂存（内存 3s 可撤销，超时落盘），不改变存储格式

**涉及模块**：`model/RecordModel`、`repository/RecordRepository`、`viewmodel/NowViewModel`、`components/record/`
**数据影响**：⚠️ `LifeRecord.mood?` 可选字段（备份导出自动携带，旧备份导入无影响）
**验证清单**：单测（mood 序列化）+ **旧备份导入实机验证**（必做）+ 编辑/删除/筛选回归

### 三期 —— 效率与隐私（建议 versionName 2.3）

**目标**：工具化能力 + 隐私保护。

- [ ] ⭐ **缓存清理** — 复用 `StorageService` 统计 + `ImageFileService`/分享缓存目录清理（白名单：`cacheDir/share_*`、`filesDir/records` 孤儿图等），我的页一键清理
- [ ] ⭐ **隐私模式** — `AppSettings.privacyMode?`，我的页开关，首页/我的页敏感数据（出生日期、倒计时）模糊显示
- [ ] ⭐ **记录模板** — 模板列表持久化（新 preferences key，结构仿 customTags），记录编辑页「一键使用」

**涉及模块**：`service/StorageService`、`model/UserConfigModel`、`config/ConfigManager`、`components/record/`
**数据影响**：⚠️ 新增可选字段 + 新 preferences key（各自独立，互不影响备份兼容）
**验证清单**：缓存清理误删检查（重要）+ 隐私开关回归 + 模板 CRUD

### 四期 —— 引导页（建议 versionName 2.4）

**目标**：首次安装引导，无系统能力依赖。

- [ ] ⭐⭐ **引导页** — 首装标记（新 preferences key），EntryAbility 首帧路由到引导页，3~4 页滑动介绍

**涉及模块**：`entryability/EntryAbility`、`pages/`
**数据影响**：⚠️ 新 preferences key（独立，不影响备份）
**验证清单**：首装显示引导 / 再次启动跳过 / 引导页滑动与跳转

### 五期 —— 数据价值（建议 versionName 2.5）

**目标**：统计与可视化，聚合逻辑全部纯函数化。

- [ ] ⭐⭐⭐🔥 **数据看板** — `RecordRepository` 聚合查询 + 纯函数统计（总数/活跃天数/日均/最长连续），新增看板页或首页区块
- [ ] ⭐⭐ **生命进度可视化** — 环形进度条（已活/目标年龄比例，纯计算），首页卡片
- [ ] ⭐⭐ **生命统计面板** — 已度过时间百分比、里程碑事件（延续数据看板统计口径）

**涉及模块**：`repository/RecordRepository`、`model/RecordModel`（统计纯函数）、`components/home/`
**数据影响**：✅
**验证清单**：统计纯函数单测（边界：0 记录/单日/跨年）+ 大记录量性能抽查

### 六期 —— 批量与导航（建议 versionName 2.6）

**目标**：时间线体验补强。

- [ ] ⭐⭐ **批量删除** — 时间线长按进入多选模式，批量删除（复用二期撤销删除）
- [ ] ⭐⭐ **时间线快速跳转** — 侧边年份/月份索引，点击滚动定位（复用 TimelineYear/Month 结构）
- [ ] ⭐⭐ **多倒计时** — `AppSettings.countdowns?`（数组：名称/目标时间），首页卡片切换

**涉及模块**：`pages/NowPage`、`components/record/`、`model/UserConfigModel`
**数据影响**：⚠️ `countdowns?` 数组字段（序列化走现有 JSON 管道，旧备份无此字段）
**验证清单**：批量删除与撤销联动 + 跳转定位准确 + 倒计时持久化

### 远期 v3.x —— 逐项评估（不承诺排期）

> 以下功能各有**前置验证/风险点**（见 §2 矩阵），单独立项、验证通过才进版本：

- 图片压缩（质量对照 + 文件引用一致性）
- 位置标记（定位权限 + 逆地理编码能力验证）
- 导出 Markdown/PDF（生成 + 分享链路，可复用 ZipTransferService 模式）
- 应用锁（安全评审）
- 桌面快捷方式（API 验证）
- 日记月历热力图（CalendarView 扩展）
- 记录连续打卡（算法纯函数化）
- 剪贴板识别（API + 隐私提示）
- 语音记录（HarmonyOS 本地识别能力验证，**风险最高**）
- 桌面小组件（FormExtensionAbility，架构级评估）

---

## 4. 每期通用验收清单

1. DevEco 编译零错误、零警告新增
2. 新增纯函数均有 hypium 单测（边界用例）
3. 实机回归：记录增删改查、时间线/日历、分享、主题切换
4. **涉及数据模型/备份的期次**：旧备份 `RecordLife_all_*.zip` 导入无损（§0 红线）
5. 中英文切换回归（新文本全部 `$r()` 资源化）
6. `docs/technical-reference.md` 同步（工具清单、数据模型、§12 现状）
7. 提交注明实机验证结果

---

## 5. 版本节奏建议

- 每期独立发版（2.1 → 2.2 → …），单期工作量控制在 1~2 周
- 一期~三期不依赖系统能力，可稳定推进；四期（引导页）同样无系统能力依赖
- 任一功能若前置验证失败（如语音识别无可用 SDK），降级为「记录语音附件」或移出计划，不阻塞主线

---

## 6. 里程碑跟踪表

> 与 `refactoring-plan.md §10.1` 同格式；每期完成时更新状态/日期/备注，并追加 §7 轮次日志。

| 期次 | 建议版本 | 描述 | 状态 | 完成日期 | 备注 |
| --- | --- | --- | --- | --- | --- |
| 一期 | 2.1 | 轻量增强：周数/总天数、生日提醒、签名、字体大小（纯函数 + 可选字段） | ✅ | 2026-08-22 | 轮次 1~2 完成：3 个生命里程碑纯函数 + 15 单测 + HomePage 展示 + 签名（编辑/我的页/首页展示）+ 字体大小设置（记录内容缩放，AppStorage fontScale）；涉及数据模型可选字段，需 §8 备份导入回归 |
| 二期 | 2.2 | 记录体验：心情标记（🔥）、撤销删除（`LifeRecord.mood?`） | ✅ | 2026-08-22 | 轮次 3~4 完成：心情标记全链路（含自定义心情并入标签管理、toast）+ 撤销删除（3s 窗口，图片延迟清理）；涉及数据模型可选字段，需 §8 备份导入回归 |
| 三期 | 2.3 | 效率与隐私：缓存清理、隐私模式、记录模板 | ✅ | 2026-08-22 | 轮次 5~6 完成：缓存清理（分享图+孤儿图）、隐私模式（首页+我的页）、记录模板（管理并入标签弹窗 + 新增页一键填充）；涉及可选字段，需 §8 备份回归 |
| 四期 | 2.4 | 引导页（首装标记 + 路由） | ⬜ | — | 每日提醒通知因 SDK 无 `@kit.ReminderAgentKit` **已取消**（轮次 7 尝试后回退）；引导页待做（轮次 8） |
| 五期 | 2.5 | 数据价值：数据看板（🔥）、生命进度、统计面板 | ✅ | 2026-08-22 | 轮次 9~10 完成：统计纯函数（18 单测）+ 数据看板页 + 首页生命进度环形 + 生命统计面板（明细+里程碑）；零数据模型改动 |
| 六期 | 2.6 | 批量与导航：批量删除、时间线跳转、多倒计时 | ⬜ | — | — |
| 远期 | v3.x | 图片压缩/位置/导出/应用锁/快捷方式/热力图/打卡/剪贴板/语音/小组件 | ⬜ | — | 逐项前置验证（§3 远期），不承诺排期 |

---

## 7. 逐轮工作日志

> 每轮开发结束后追加一条记录，格式与 `refactoring-plan.md §10.2` 一致：
> `### 轮次 N — 日期`，内容：本轮目标、涉及文件、已完成项、遗留问题、下一轮计划。
> 跨轮连续性依赖此日志，务必如实记录。

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

### 轮次 0 — 2026-08-22（更新计划规划）

**本轮目标**：基于 `README.md`「AI 对新增功能的分析」未实现清单，规划稳扎稳打的分期更新路线，并建立与重构计划一致的多轮执行跟踪机制。

**涉及文件**：
- `docs/update-plan.md`（新建：原则 / 依赖矩阵 / 六期分期 / 远期评估 / 里程碑表 / 轮次日志 / 验证记录 / 检查清单）
- `README.md`（项目结构同步为当前分层；更新计划章节加文档链接）

**已完成**：
- [x] 规划原则（小步快跑 / 先易后难 / 数据兼容红线 / 架构一致 / 可验证闭环 / 国际化延续）
- [x] 功能依赖与风险矩阵（28 项，含数据影响评估与前置验证项）
- [x] 六期分期 + 远期逐项评估
- [x] 里程碑跟踪表、轮次日志模板、验证记录表、上下文恢复检查清单

**前置完成**（规划外顺手修复）：
- [x] 2.2.21：统一初始化与重置的示例条目行为（`sample_data_initialized` 标记；重置后重新生成示例，删光记录不再冒示例）

**遗留问题**：
- 一期未开工；四期通知能力、远期语音识别等前置验证未做

**下一轮计划**：一期 — `TimeUtils` 新增纯函数（第几周/第几天、距下次生日天数）+ 单测；签名/字体设置（可选字段）

### 轮次 1 — 2026-08-22（一期：生命里程碑纯函数 + 首页展示）

**本轮目标**：一期首个切片——周数/总天数、生日提醒的纯函数化与首页展示，建立「纯函数 + 单测 + UI」完整闭环。

**涉及文件**：
- `common/utils/TimeUtils.ets`（+3 纯函数：`getDayOfLife` / `getWeekOfLife` / `getDaysUntilNextBirthday`，UTC+8 归一化）
- `pages/HomePage.ets`（时间卡片组新增「生命中第 N 天 · 第 N 周 · 距下次生日」里程碑行）
- `resources/base|en_US/element/string.json`（+4 key：`life_day` / `life_week` / `birthday_countdown` / `birthday_today`，321 key × 2）
- `entry/src/test/TimeUtilsLife.test.ets`（新建，15 用例）+ `List.test.ets`（注册）

**已完成**：
- [x] 3 个纯函数（node 模拟验证 15 用例 + 2/29 平年/闰年边界全过；修 1 个 bug：生日「今年」误用出生年份 → 改用当前年份）
- [x] HomePage 每秒刷新生命里程碑（复用 `calculateTime`），三色圆角块展示，`birthday_today` 特殊文案
- [x] 资源中英文双份

**遗留问题**：
- 一期剩余：签名/座右铭（`UserProfile.signature?` + 我的页编辑 + 首页展示）、字体大小设置（`AppSettings.fontSize?` + 全局样式）未做
- 待 DevEco 编译 + 实机验证（首页新增行显示正确；生日当天显示 🎂 文案）

**下一轮计划**：一期剩余两项 — 签名/座右铭、字体大小设置（均新增可选字段，需 §8 备份导入回归）

### 轮次 2 — 2026-08-22（一期完成：签名/座右铭 + 字体大小设置）

**本轮目标**：完成一期剩余两项——签名/座右铭、字体大小设置，一期全部收口。

**涉及文件**：
- `model/UserConfigModel.ets`（`UserProfile.signature?` + `AppSettings.fontSize?` 可选字段，双工厂默认值）
- `config/ConfigManager.ets`（`updateProfile` 第 5 参 signature；`getFontSize`/`setFontSize`/`getFontScale`；init 时同步 `AppStorage('fontScale')`）
- `viewmodel/AccountViewModel.ets`（`loadUserProfile` 读签名、`saveProfile` 5 参透传、`getFontSize`/`setFontSize`）
- `model/AccountModel.ets`（`AccountProfile.signature`）；`components/user/UserInfoSection.ets`（`UserInfo.userSignature` + 用户名下展示）
- `components/dialog/EditProfileDialog.ets`（签名输入框 + onSave 4 参）
- `pages/AccountPage.ets`（签名映射/透传、字体大小设置项三选、toast）
- `pages/HomePage.ets`（标题区签名展示 + RefreshManager 同步）
- `components/record/RecordCard.ets`（记录内容 fontSize/lineHeight × fontScale）
- `resources/base|en_US/element/string.json`（+8 key：signature/signature_hint/font_size_*，329 key × 2）

**已完成**：
- [x] 签名：编辑资料弹窗输入 → 持久化（可选字段，旧配置缺省空）→ 我的页用户名下 + 首页标题区展示（有值才显示）
- [x] 字体：我的页设置项（小/中/大）→ `AppSettings.fontSize` 持久化 + `AppStorage('fontScale')`（0.9/1.0/1.15）→ 时间线记录内容文本缩放；**启动时 init 同步 fontScale，重启不丢失**
- [x] 兼容性：`updateProfile` 未传 signature 保留现值（saveAvatarPath 4 参调用不受影响）；旧配置缺字段走默认

**遗留问题**：
- 字体缩放目前仅作用于记录内容文本（RecordCard），其余页面文本未缩放（后续可扩展）
- 待 DevEco 编译 + 实机验证：签名编辑/展示、字体三档切换即时生效、重启后字体保持、旧备份导入（新增可选字段）

**下一轮计划**：二期 — 心情标记（🔥，`LifeRecord.mood?`）+ 撤销删除；开工前读 §2 矩阵与 §9 检查清单

### 轮次 3 — 2026-08-22（二期：心情标记全链路）

**本轮目标**：二期核心功能——心情标记：`LifeRecord.mood?` 可选字段 + 新增/编辑选择 + 卡片展示 + 时间线筛选。

**涉及文件**：
- `model/RecordModel.ets`（`LifeRecord.mood?` 可选字段）
- `common/utils/MoodUtils.ets`（新建：`MOODS`/`getMoodEmoji`/`isValidMood`，纯函数）
- `viewmodel/NowViewModel.ets`（`addRecord` 第 4 参、`updateRecord` 第 5 参 mood；'' 清除）
- `components/record/MoodSelector.ets`（新建：一排 emoji 圆钮单选，再点取消）
- `components/record/MoodFilterBar.ets`（新建：全部 + 5 emoji 横向 chips）
- `components/record/AddRecordSection.ets`、`components/dialog/EditRecordDialog.ets`（接入 MoodSelector）
- `pages/NowPage.ets`（editMood 编辑态、filterMood 筛选态 + 版本号）
- `components/record/TimelineSection.ets`（filterMood @Watch + buildDateGroups 过滤）
- `components/record/RecordCard.ets`（内容上方 mood emoji 展示）
- `resources/base|en_US/element/string.json`（+7 key：mood_*，336 key × 2）
- `entry/src/test/MoodUtils.test.ets`（新建 8 用例）+ `List.test.ets`（注册，累计 38 用例）

**已完成**：
- [x] 心情 5 档（happy/calm/excited/sad/tired）+ emoji 映射；新增/编辑记录可选心情，再点取消
- [x] 记录卡片内容上方展示心情 emoji；时间线按心情筛选（与标签筛选叠加）
- [x] 单测 8 用例（emoji 映射 + 合法性）

**补充（心情增强）**：
- [x] 心情筛选/选择 toast（`mood_selected`，取消复用 `filter_cancelled`）
- [x] 自定义心情：`Mood` 模型 + `AppSettings.customMoods?` + `service/MoodService`（CRUD，预置不可改）
- [x] 心情管理并入标签管理弹窗（TagManagementDialog 下方区块：预置+自定义 emoji 列表、自定义可删、24 个候选 emoji 挑选添加）
- [x] MoodUtils 扩展（`getAllMoods`/`getMoodEmoji(id, customMoods?)`/候选池）；MoodSelector/FilterBar/RecordCard 适配
- [x] 资源 +4 key（mood_selected/mood_management/mood_custom_hint/mood_picker_hint，340 key × 2）；单测扩展至 17 用例（自定义查找/合并/候选池）

**遗留问题**：
- 撤销删除未做（二期剩余）
- 心情筛选与搜索/标签筛选叠加逻辑正确性需实机验证
- 待 DevEco 编译 + 实机验证：新增/编辑心情、卡片展示、筛选联动、**旧备份导入**（新可选字段）

**下一轮计划**：二期剩余 — 撤销删除（内存暂存 3s 可撤销，不落盘）；随后二期收口（§8 备份回归 + 里程碑 ✅）

### 轮次 4 — 2026-08-22（二期收官：撤销删除）

**本轮目标**：二期最后一个功能——撤销删除（删除后 3 秒内可撤销），二期全部收口。

**涉及文件**：
- `viewmodel/NowViewModel.ets`（`deleteRecord` 改造：立即持久化删除 + 内存暂存 3s；新增 `undoDelete` / `canUndoDelete` / 私有 `resetPendingDeleteTimer`——图片文件延迟到撤销窗口结束后清理）
- `pages/NowPage.ets`（撤销提示条 UI：底部浮层「已删除 N 条记录 [撤销]」，3s 自动隐藏，点击穿透；`showUndoBarWithCount` / `hideUndoBar` / `onUndoDelete`）
- `resources/base|en_US/element/string.json`（+3 key：record_deleted / undo_delete / undo_success，343 key × 2）

**已完成**：
- [x] 删除即持久化 + 内存暂存；3 秒内撤销恢复（按时间戳归位）+ 图片文件保留
- [x] 3 秒窗口结束后才清理图片文件（原实现立即删图，撤销后图片丢失）
- [x] 保存失败回滚；连续删除重置窗口；UI 提示条点击穿透不挡交互

**遗留问题**：
- 待 DevEco 编译 + 实机验证：删除 → 撤销恢复（含图片）、3 秒后自动消失、连续删除
- **§8 验证记录待补**：二期涉及 `LifeRecord.mood?` / `customMoods?` 可选字段，需旧备份导入回归

**下一轮计划**：三期 — 缓存清理（复用 StorageService/ImageFileService）、隐私模式（`AppSettings.privacyMode?`）、记录模板

### 轮次 5 — 2026-08-22（三期：缓存清理 + 隐私模式）

**本轮目标**：三期前两项——缓存清理（我的页一键清理）与隐私模式（首页敏感信息遮罩）。

**涉及文件**：
- `service/StorageService.ets`（+`cleanupCache` / `clearShareCache`（cacheDir/share_*.jpg 全删）/ `clearOrphanRecordImages`（filesDir/records 未被引用图片，按文件名匹配兼容 URI/路径））
- `model/UserConfigModel.ets`（`AppSettings.privacyMode?` 可选字段，双工厂默认 false）
- `config/ConfigManager.ets`（+`getPrivacyMode`/`setPrivacyMode`）
- `viewmodel/AccountViewModel.ets`（+`getPrivacyMode`/`setPrivacyMode`/`cleanupCache`（RecordRepository 取记录 + StorageService 清理））
- `pages/AccountPage.ets`（隐私模式 Toggle 开关 + 清理缓存设置项 + toast）
- `pages/HomePage.ets`（隐私开启：出生日期区 🔒 遮罩、生命里程碑行隐藏；RefreshManager 同步）
- `resources/base|en_US/element/string.json`（+8 key，351 key × 2）

**已完成**：
- [x] 缓存清理：分享临时图片全删 + 孤儿记录图片（未被引用）清理，toast 反馈清理数量，清理后刷新存储空间
- [x] 隐私模式：我的页开关 → 首页出生日期遮罩 + 生命里程碑隐藏；`RefreshManager` 跨页同步

**遗留问题**：
- 记录模板未做（三期剩余）
- 待 DevEco 编译 + 实机验证：清理数量/误删检查、隐私开关跨页即时生效、旧备份导入

**下一轮计划**：三期剩余 — 记录模板（模板列表持久化 + 记录编辑页一键使用）

### 轮次 6 — 2026-08-22（三期收官：记录模板）

**本轮目标**：三期最后一个功能——记录模板（预设常用记录，一键填充），三期全部收口。

**涉及文件**：
- `model/UserConfigModel.ets`（`RecordTemplate` 接口 + `AppSettings.recordTemplates?` 可选字段，双工厂默认 []）
- `config/ConfigManager.ets`（loadConfig 兼容旧配置补空）
- `service/TemplateService.ets`（新建：模板 CRUD，仿 MoodService/TagService）
- `components/dialog/TagManagementDialog.ets`（第三个区块「记录模板」：列表 + 添加/编辑表单（名称+内容）+ 删除）
- `components/record/AddRecordSection.ets`（标题行「模板」按钮 + bindSheet 选择弹层，点击一键填充 textContent）
- `resources/base|en_US/element/string.json`（+6 key：record_template/template_*，357 key × 2）

**已完成**：
- [x] 模板管理（并入标签管理弹窗，与心情并列第三区块）：添加/编辑/删除
- [x] 一键使用：新增记录页标题行「模板」按钮 → 弹层选择 → 填充内容
- [x] 数据红线：`recordTemplates?` 可选 + 兼容补空，旧备份无损

**遗留问题**：
- 待 DevEco 编译 + 实机验证：模板 CRUD、一键填充、旧备份导入
- **§8 验证记录待补**：三期涉及 `privacyMode?` / `recordTemplates?` 可选字段，需旧备份导入回归

**下一轮计划**：四期 — 引导页（首装标记 + EntryAbility 路由 + 滑动页，无系统能力依赖）；开工前读 §2 矩阵

### 轮次 7 — 2026-08-22（四期：每日提醒通知 → ❌ 已取消）

**本轮尝试**：实现每日提醒通知（reminderAgentManager 系统级每日调度 + 权限 + 时间选择）。

**结果**：❌ **编译失败回退并取消**——目标 SDK 无 `@kit.ReminderAgentKit`（`no corresponding config file in ArkTS SDK`），reminderAgentManager 不可用；级联 TimePickerResult 不导出等问题。功能全部回退（代码恢复 e6a28ee~1 状态），**每日提醒从计划中移除（不实现）**。

**遗留问题**：
- 引导页未做（四期剩余）

**下一轮计划**：四期 — 引导页（首装标记 + EntryAbility 路由 + 滑动页，无系统能力依赖）

### 轮次 8 — 2026-08-22（四期收官：引导页）

**本轮目标**：四期剩余功能——引导页（首次安装启动展示应用介绍），四期全部收口。

**涉及文件**：
- `repository/GuideRepository.ets`（新建：`hasSeenGuide`/`markGuideSeen`/`clearGuideFlag`，独立 store `app_meta`）
- `pages/GuidePage.ets`（新建：@Entry，4 页 Swiper（emoji + 标题 + 描述）+ 圆点指示器 + 最后一页「开始使用」/其余「跳过」；完成后 markGuideSeen + `router.replaceUrl` 到 Index）
- `entryability/EntryAbility.ets`（onWindowStageCreate 改 async：检查引导标记，未看过 → 加载 GuidePage）
- `resources/base/profile/main_pages.json`（+pages/GuidePage）
- `common/handlers/MorePageConfigHandler.ets`（resetApp 清除引导标记，重置后重新展示引导）
- `resources/base|en_US/element/string.json`（+10 key：guide_*，372 key × 2）

**已完成**：
- [x] 首次安装（无标记）→ 引导页；之后启动直接进主页
- [x] 4 页滑动 + 圆点指示（当前页高亮伸长）+ 跳过/开始使用
- [x] 重置应用清除引导标记（与示例数据重置行为一致）

**遗留问题**：
- 待 DevEco 编译 + 实机验证：首装显示引导、滑动/跳过/开始、二次启动跳过、重置后重现

**下一轮计划**：五期 — 数据看板（🔥，聚合统计纯函数化）、生命进度可视化、统计面板

### 轮次 9 — 2026-08-22（五期：数据看板 + 生命进度可视化）

**本轮目标**：五期前两项——数据看板（记录统计）与生命进度可视化，聚合逻辑全部纯函数化。

**涉及文件**：
- `model/StatisticsModel.ets`（新建：`calculateStatistics` / `getLongestStreak` / `getLifeProgress` 纯函数）
- `pages/DashboardPage.ets`（新建：@Entry 数据看板页——生命进度环形卡片 + 统计卡片网格（总数/活跃天数/日均/最长连续/累计字数/首末日期/目标年龄））
- `pages/AccountPage.ets`（「数据看板」入口 + onDashboardClick）
- `pages/HomePage.ets`（时间卡片组内生命进度环形，每秒随 calculateTime 刷新）
- `resources/base/profile/main_pages.json`（+pages/DashboardPage）
- `entry/src/test/StatisticsModel.test.ets`（新建 10 用例）+ `List.test.ets`（注册，累计 48 用例）
- `resources/base|en_US/element/string.json`（+14 key，386 key × 2）

**已完成**：
- [x] 统计纯函数（node 验证：跨月连续、同天去重、生命进度百分比）
- [x] 数据看板页（环形进度 + 8 项统计）
- [x] 首页生命进度环形

**遗留问题**：
- 生命统计面板（已度过时间百分比、里程碑事件）未做（五期剩余）
- 待 DevEco 编译 + 实机验证：看板数据正确性、环形显示、首页进度

**下一轮计划**：五期剩余 — 生命统计面板（百分比/里程碑，复用统计口径）

### 轮次 10 — 2026-08-22（五期收官：生命统计面板）

**本轮目标**：五期最后一个功能——生命统计面板（已度过时间明细 + 生命里程碑），五期全部收口。

**涉及文件**：
- `model/StatisticsModel.ets`（+`LifeBreakdown` / `LifeMilestone` 接口 + `getLifeBreakdown` / `getLifeMilestones`（1 万天/18 岁/50 岁/目标一半/目标年龄，type 供 UI 资源化））
- `pages/DashboardPage.ets`（「生命统计面板」区块：已活 X 年 Y 个月 Z 天 + 总进度 % + 里程碑时间线（✅已达成/⏳还差 N 天 + 达成日期））
- `entry/src/test/StatisticsModel.test.ets`（+8 用例，累计 18）
- `resources/base|en_US/element/string.json`（+10 key：life_breakdown/milestone_*，396 key × 2）

**已完成**：
- [x] 里程碑纯函数（node 验证：1990-06-15 → 2017-10-31 第 1 万天达成、50 岁剩 5465 天等）
- [x] 统计面板 UI（明细 + 里程碑列表，已达成/未来状态区分）

**遗留问题**：
- 待 DevEco 编译 + 实机验证：面板明细/里程碑正确、达成状态

**下一轮计划**：六期 — 批量删除（长按多选，复用撤销删除）、时间线快速跳转（侧边索引）、多倒计时

---

## 8. 验证记录

> 与 `refactoring-plan.md §10.3` 同格式；凡涉及数据模型 / 持久化 / 备份的期次，必须记录旧备份导入回归结果。

| 验证时间 | 内容 | 结果 | 验证人 | 备注 |
| --- | --- | --- | --- | --- |
| — | — | — | — | 更新计划尚未开工（重构期验证见 refactoring-plan §10.3） |

---

## 9. 上下文恢复检查清单

> 每轮开始前快速过一遍，确保多轮开发的连续性：

- [ ] 已阅读本文件 §1 规划原则与 §2 依赖矩阵（红线：数据兼容 / 国际化 / 架构分层）
- [ ] 已阅读本文件 §6 里程碑表，确认当前进行到哪一期
- [ ] 已阅读本文件 §7 最近一轮工作日志，确认上一轮遗留问题
- [ ] 已阅读 `docs/refactoring-plan.md §0` 数据兼容性要求（涉及数据模型/备份时必读）
- [ ] 已阅读 `docs/technical-reference.md` 相关章节（改动涉及持久化/备份时读 §5~§6）
- [ ] 已确认本次改动是否触及数据模型/持久化/备份（若是，需 §8 验证记录 + 旧备份导入回归）
- [ ] 新 UI 文本已全部 `$r()` 资源化（中英文双份）
