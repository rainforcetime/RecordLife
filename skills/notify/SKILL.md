---
name: notify
description: 弹出 Windows 右下角通知弹窗（任务完成提醒）。在每次完成任务/提交/推送后调用，向用户反馈执行结果。基于 scripts/notify.ps1（.NET NotifyIcon，零依赖）。
---

# Skill: notify

弹出 Windows 右下角气泡通知，用于任务完成后的用户提醒。**全局安装**——任何项目工作区均可调用。

## 何时调用
- 一轮改动完成（提交/推送/修复/文档更新）后
- 用户要求发测试通知时

## 执行方法

脚本随 skill 包一起安装，位置（全局）：
`<Reasonix home>/skills/notify/scripts/notify.ps1`

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill 包>/scripts/notify.ps1" -Title "<标题>" -Message "<正文>" -DurationMs 6000
```

- 典型全局路径：`C:\Users\<用户名>\.reasonix\skills\notify\scripts\notify.ps1`
- 本项目内也保留了 `scripts/notify.ps1`（项目根相对路径），可直接用
- 中文标题/正文直接传参即可（脚本为 UTF-8 BOM，已验证中文正常）
- 显示时长默认 5000ms，常规提醒用 6000ms

## 参数
| 参数 | 说明 |
| --- | --- |
| `-Title` | 标题，如 "✅ 推送完成 3.0.56" |
| `-Message` | 正文，简要说明执行结果（改了什么、是否推送） |
| `-DurationMs` | 显示毫秒数（默认 5000） |
| `-MessageFile` | 兜底：从 UTF-8 文件读正文（命令行传参乱码时用） |

## 标题规范
- 任务完成：`✅ <动作> <版本号>`（如 "✅ 提交完成 3.0.56"）
- 失败/异常：`⚠️ <动作>失败`
- 测试：`📢 <内容>`

## 注意事项
- 若系统开启「专注助手/勿扰模式」可能不显示，提示用户手动关闭即可
- 脚本 exit 0 表示已触发通知；非 0 表示失败（检查 $LASTEXITCODE）
