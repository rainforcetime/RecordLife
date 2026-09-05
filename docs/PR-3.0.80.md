# PR 合并说明（develop → master）

> 用途：复制本文件内容到 GitHub PR 描述。
> 版本基线：develop `7f4ce26..68daef2`，12 个提交（3.0.69 ~ 3.0.80），应用版本 3.0.80（30080）。

---

## 📋 PR：3.0.80 记录体验增强 + 稳定化（12 个提交）

**develop → master**，覆盖 3.0.69~3.0.80，含三个新需求、build 日期修复与多轮回归修复。

### 🔧 Build 日期修复（3.0.69）

- **问题**：关于页「Build 日期」运行时取当天时间，显示的是查看日期而非构建日期。
- **修复**：新增 hvigor 自定义任务 `WriteBuildInfo`（entry/hvigorfile.ts），挂到 `default@PreBuild` 前，每次构建把真实日期写入 `config/BuildInfo.ets`；AppInfo 读取该常量。DevEco IDE / 命令行 / CI 三种构建一致生效。

### 🎴 需求 1：隐私模式记录页亚克力模糊（3.0.70）

- `privacyMode` 同步进 `AppStorage`（ConfigManager 初始化与设置后），冷/热切换实时生效
- 开启后「此刻」页记录区域亚克力模糊：`backdropBlur(24)` + 半透明底 + 🔒 提示（深浅色自适应、内容居中），FAB 保持可用

### 🕐 需求 2：记录最后修改时间（3.0.71）

- `LifeRecord` 新增可选字段 `updatedAt`（编辑保存时更新；旧数据无该字段 = 未编辑，备份兼容）
- 卡片在**编辑过**时显示「编辑于 X」（同日只显时分、跨日补 M/D），排序分组仍按创建时间

### 💬 需求 3：记录追加想法（评论区）（3.0.72）

- `LifeRecord.comments?`（`CommentItem{id, content, timestamp}`），随记录整体存储，旧备份兼容
- 卡片操作条消息图标 + 条数 → bindSheet 面板：列表 / 添加 / 删除（二次确认）/ 空态，中英双语；增删后即时刷新

### 🔍 复查修复（3.0.73，含问题文档）

- 问题文档 `docs/review-3.0.70-72.md`
- **P1**：评论面板同引用赋值 @State 不刷新 → 显式拷贝新对象 + 新 comments 数组
- **P2-2**：无改动保存不再误标「编辑于」（字段归一化 diff 判定）
- **P2-3**：评论输入框受控清空
- P2-4 遮罩范围维持整页；P2-5/P3 待真机

### 🎨 真机 UI 修复（3.0.74 ~ 3.0.79）

- 隐私提示文字居中、评论按钮图标统一（emoji → `sys.symbol.message`）
- 评论面板高度防键盘顶起；删除评论改系统图标 + 二次确认
- **编辑弹框无法弹出 bug**（bindSheet 同节点覆盖）→ 评论面板独立绑定 Scroll
- 卡片底部「编辑于」不再挤出右侧操作按钮（时间区弹性列）
- 追加想法输入框：占位垂直居中 → 改回多行 TextArea + 自定义占位叠层、高度 56

### 🛡 漏洞复查修复（3.0.80）

- 评论添加**防重入**（连点不重复追加）+ 空校验下沉 viewModel
- 评论增删失败 toast 提示，添加失败自动恢复输入
- `resetToDefault` 同步 AppStorage privacyMode

---

### ✅ 验证

- 每个改动均本地 hvigor 构建通过（BUILD SUCCESSFUL）
- review（隔离子代理逐提交核查）：无必现崩溃/数据损坏级缺陷
- 功能影响面核查：新增字段 JSON 透传、备份导入无白名单校验，旧功能无回归

### 🚀 合并后

1. master 自动构建 → 产物 `RecordLife_V3.0.80.hap`
2. 打 tag 推送 `v3.0.80` → 自动发布 GitHub Release
3. 同步 gitee master
