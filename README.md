<div align="center">

# Record Life · 活着

**一款记录生活、珍惜此刻的 HarmonyOS 应用**

[![版本](https://img.shields.io/github/v/release/rainforcetime/RecordLife)](https://github.com/rainforcetime/RecordLife/releases)
[![构建](https://github.com/rainforcetime/RecordLife/workflows/Build%20HAP/badge.svg)](https://github.com/rainforcetime/RecordLife/actions)
[![许可证](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

当前版本 **3.0.87**（versionCode 30087）· [更新记录](docs/CHANGELOG.md)

</div>

---

## ✨ 功能特性

### 🕐 记录生活（此刻）
- **此刻记录**：文字 + 图片 + 标签 + **心情**，时间线 / 日历双视图，搜索 + 心情/标签筛选
- **最后修改时间**：编辑过的记录自动标注「编辑于 X」，可追溯每次变更
- **追加想法**：每条记录可继续追加多条想法/备注（增删、计数角标）
- **图片预览**：滑动翻页 + 捏合缩放（1~5x）+ 双击放大 + 平移
- **记录模板**：预设模板一键填充，支持自定义增删改
- **撤销删除**：删除后 3 秒内一键恢复（含图片与评论）

### 🏠 首页 · 活着
- **生存时间**：出生至今的年/月/日/时/分/秒，已存活/剩余切换，累计/非累计模式
- **生命进度环形** + **里程碑**：11 个生命里程碑（1 万天 / 18 岁 / 目标年龄等）
- **签名/座右铭**、图片形式分享卡片

### 🔐 隐私与数据
- **隐私模式**：一键开启——首页隐藏敏感信息，**记录页亚克力模糊**（内容不可读）
- **云存储（腾讯云 COS）**：本地存压缩图、云端存原图；上传全部/去重/进度、自定义域名
- **数据备份**：本地备份/恢复、导入导出、缓存清理；**数据模型向后兼容**（可选字段演进）
- **数据看板**：记录总数、活跃天数、最长连续、累计字数 + 里程碑统计

### 📱 快捷与体验
- **桌面卡片「快速记录」**：桌面一键新建记录（2×2 ArkTS 卡片）
- **个性化**：8 色主题、自定义标签/心情/模板、字体大小、签名
- **双语支持**：简体中文 / English

---

## 🔧 运行环境

| 项 | 要求 |
|---|---|
| 系统 | HarmonyOS NEXT（API 22，SDK 6.0.2+） |
| 设备 | 华为手机 / 平板 |
| 开发 | DevEco Studio 6.x（hvigor 6.x） |

## 🚀 快速开始（开发）

```bash
# 1. DevEco Studio 打开项目根目录（等待 Sync 完成）
# 2. 连接真机或启动模拟器 → 运行 entry 模块
#    自动签名：DevEco → File → Project Structure → Signing Configs → Automatically generate
```

命令行构建（无 IDE）：

```powershell
# 设 SDK 路径（DevEco 自带 SDK 或独立 SDK）
$env:DEVECO_SDK_HOME = "D:\Software\DevEco Studio\sdk"   # 按实际安装路径
# 构建 debug（产物含 signed/unsigned HAP）
hvigorw.bat assembleHap --mode module -p product=default -p buildMode=debug --no-daemon
# 产物：entry/build/default/outputs/default/*.hap
```

> 每次构建会自动把**真实构建日期**写入 `config/BuildInfo.ets`（关于页 Build 日期即打包当天，勿提交该文件变化）。

## 📦 安装与发版

- **测试包**：仓库 GitHub Actions → 最新 workflow run → Artifacts 下载（保留 90 天）
- **正式版**：GitHub [Releases](https://github.com/rainforcetime/RecordLife/releases) 下载 `RecordLife_V<版本号>.hap`（长期保留）
- 发版流程（维护者）：合并 PR 到 `master` → 打 tag 推送 → 自动构建并发布 Release

## 🤖 CI/CD

`.github/workflows/build-hap.yml`（GitHub Actions，ubuntu + HarmonyOS Command Line Tools 6.0.2.650）：

| 触发 | 行为 |
|---|---|
| push / PR 到 `master` | 构建 unsigned HAP（验证编译，产物入 Artifacts） |
| push tag `v*`（如 `v3.0.81`） | 构建并**自动发布 GitHub Release**（`RecordLife_V<versionName>.hap`） |

Gitee 仅同步代码，不参与打包。

## 🏗 技术栈

- 框架：**HarmonyOS ArkUI**（stage 模型，ArkTS）
- 语言：ETS（ArkTS，API 22）
- 数据：Preferences + 本地文件；云图：腾讯云 COS（V5 自实现签名）
- 架构：`pages → viewmodel → service/repository → model` 分层，单例显式注入，纯函数可单测

## 📁 项目结构

```
entry/src/main/ets/
├── common/        # 工具类与处理器（时间/图片/分享/日志/资源…）
├── components/    # 可复用 UI（calendar/dialog/home/record/setting/share/user…）
├── config/        # 配置管理（ConfigManager/主题/应用信息/BuildInfo）
├── model/         # 领域模型（记录/统计/用户配置，数据演进兼容）
├── pages/         # 页面入口（Index=主框架，Home/Now/Account/More…）
├── repository/    # 数据仓库（记录/配置/引导…）
├── service/       # 服务层（图片/标签/备份/云存储…）
├── viewmodel/     # 页面业务逻辑与状态
├── entryability/  # EntryAbility（含桌面卡片跳转处理）
├── entryformability/ # 桌面卡片（FormExtensionAbility）
└── widget/        # 卡片 UI
```

## 📚 文档

| 文档 | 说明 | 维护方式 |
|---|---|---|
| [CHANGELOG.md](docs/CHANGELOG.md) | 版本更新记录 | **增量追加**（每次发版在顶部新增章节） |
| [technical-reference.md](docs/technical-reference.md) | 实现细节参考 | 增量维护 |
| docs/archive/ | 历史设计与规划文档（已归档） | 不再更新 |
| [LICENSE](LICENSE) | MIT | — |

> 文档规范：`README` 面向用户概述；变更与版本进 `CHANGELOG`；过程性结论（PR 说明、复查记录）不另建零散文档，直接并入 CHANGELOG / 提交说明，保持 `docs/` 整洁、git 历史可读。

## 📄 许可证

[MIT](LICENSE) © rainforcetime
