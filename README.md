

# RecordLife 活着

**一款记录生活、追踪人生数据的 HarmonyOS 移动应用**

只是想写一个记录自己活着的软件。

## 应用简介

RecordLife（活着）是一款基于 HarmonyOS Next 构建的生活记录与数据追踪应用，旨在帮助用户记录和可视化自己的生命历程。通过设置出生日期、目标年龄等个人信息，应用可以计算并展示用户在有限人生中的进度和统计数据。

## 功能特性

| 功能 | 说明 |
|------|------|
| 个人信息管理 | 设置和管理个人资料，包括出生日期、头像、昵称等信息 |
| 数据统计 | 记录并可视化生活中的各项关键数据统计信息 |
| 时间计算 | 根据设置的出生日期和目标年龄，计算人生进度百分比 |
| 多页面导航 | 提供首页、此刻、账户、模块、更多等核心功能页面 |
| 主题切换 | 支持深色/浅色主题模式一键切换 |
| 数据备份 | 支持应用配置数据的备份与恢复功能 |
| 时间线展示 | 展示人生重要节点的时间线视图 |

## 技术栈

- **框架**: HarmonyOS Next / ArkUI
- **开发语言**: TypeScript / ETS (Extension TypeScript)
- **开发工具**: DevEco Studio

## 项目架构

```
entry/src/main/ets/
├── common/                   # 通用基础模块
│   ├── types.ets             # 类型定义
│   ├── RefreshManager.ets   # 刷新管理器
│   └── utils/               # 工具函数集
│       ├── AccountUtils.ets # 账户工具
│       ├── BackupManager.ets # 备份管理
│       └── TimeUtils.ets    # 时间工具
├── components/               # 可复用 UI 组件
│   ├── TimeCard.ets                  # 时间卡片
│   ├── TimelineSection.ets           # 时间线区块
│   ├── DataStatisticsSection.ets     # 数据统计区块
│   ├── UserInfoSection.ets          # 用户信息区块
│   ├── AboutAppDialog.ets           # 关于对话框
│   ├── EditProfileDialog.ets        # 编辑资料对话框
│   ├── BirthDateSelector.ets        # 出生日期选择器
│   ├── SettingItem*.ets             # 设置项系列组件
│   └── ...                         # 其他自定义组件
├── config/                  # 配置管理层
│   ├── ConfigManager.ets     # 配置管理器
│   ├── UserConfig.ets        # 用户配置
│   ├── ThemeManager.ets     # 主题管理器
│   ├── ThemeConfig.ets       # 主题配置
│   └── AppInfoConfig.ets     # 应用信息配置
├── viewmodel/               # 视图模型层
│   ├── NowViewModel.ets     # "此刻"视图模型
│   └── AccountViewModel.ets # 账户视图模型
├── pages/                   # 页面层
│   ├── Index.ets            # 应用入口/导航页
│   ├── HomePage.ets          # 首页
│   ├── NowPage.ets          # 此时此刻页
│   ├── AccountPage.ets      # 账户页面
│   ├── ModulePage.ets        # 模块页面
│   └── MorePage.ets         # 更多页面
└── entryability/
    ├── EntryAbility.ets              # 主入口 Ability
    └── EntryBackupAbility.ets        # 备份 Ability
```

## 快速开始

### 环境要求

- DevEco Studio (建议最新版本)
- HarmonyOS SDK (API 9+)
- Node.js 18+

### 构建运行

1. 使用 DevEco Studio 打开项目根目录
2. 连接真机设备或启动模拟器
3. 执行 `Run` 或 `Build` 进行编译安装

## 核心页面

| 页面 | 路由 | 功能描述 |
|------|------|----------|
| 首页 | `/` | 展示人生进度、已存活时间等核心统计 |
| 此刻 | `/now` | 当前时刻的详细数据记录 |
| 账户 | `/account` | 管理用户账户信息 |
| 模块 | `/module` | 功能模块展示与管理 |
| 更多 | `/more` | 设置、关于等其他功能入口 |

## 配置说明

应用提供以下可配置项：

- **主题模式**: 深色/浅色主题切换
- **用户信息**: 头像、昵称、出生日期
- **目标年龄**: 预期寿命，用于计算人生进度百分比

## 开源协议

本项目基于 **MIT License** 开源，欢迎社区贡献与二次开发。

---

> 希望这个应用能帮助你更好地记录和珍惜生活的每一天。🌸