

Based on the code map analysis, this is a HarmonyOS application written in TypeScript/ETS (Extension TypeScript). Let me create a comprehensive README based on the project structure.

---

# RecordLife 活着

**一款记录生活、追踪人生数据的移动应用**

只是想写一个记录自己活着的软件。

## 应用简介

RecordLife（活着）是一款基于 HarmonyOS 开发的生活记录与数据追踪应用，旨在帮助用户记录和可视化自己的生命历程。通过设置出生日期、目标年龄等个人信息，应用可以计算并展示用户在有限人生中的进度和统计数据。

## 功能特性

- **个人信息管理**：设置和管理个人资料，包括出生日期、头像等信息
- **数据统计**：记录并可视化生活中的各项数据统计信息
- **时间计算**：根据设置的出生日期和目标年龄，计算人生进度
- **多页面导航**：包含首页、账户、模块、更多等核心功能页面
- **暗色主题**：支持深色/浅色主题切换
- **数据备份**：支持配置数据的备份功能

## 技术栈

- **框架**：HarmonyOS
- **开发语言**：TypeScript / ETS (Extension TypeScript)
- **UI框架**：ArkUI

## 项目结构

```
entry/
├── src/main/ets/
│   ├── common/          # 通用工具和类型定义
│   │   ├── types.ets    # 类型定义
│   │   └── utils/       # 工具函数
│   ├── components/      # 可复用组件
│   ├── config/         # 配置管理
│   ├── pages/          # 页面
│   ├── viewmodel/      # 视图模型
│   └── entryability/  # 入口能力
└── src/main/
    ├── resources/      # 资源文件
    └── module.json5    # 模块配置
```

## 快速开始

### 环境要求

- DevEco Studio
- HarmonyOS SDK
- Node.js

### 构建运行

1. 使用 DevEco Studio 打开项目目录
2. 连接真机设备或启动模拟器
3. 点击 Run 或 Build 进行编译安装

## 页面说明

| 页面 | 说明 |
|------|------|
| HomePage | 首页，展示主要数据和统计信息 |
| AccountPage | 账户页面，管理用户账户信息 |
| ModulePage | 模块页面，功能模块展示 |
| MorePage | 更多页面，其他功能和设置 |

## 配置说明

应用提供多种配置选项：
- 主题模式：深色/浅色主题切换
- 用户信息：头像、昵称、出生日期等
- 目标年龄：设置预期寿命用于计算人生进度

## 开源协议

本项目基于 MIT 许可证开源。

---

希望这个应用能帮助你更好地记录和珍惜生活的每一天。