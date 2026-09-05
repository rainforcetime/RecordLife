<!--
  本模板为一次性维护文件，请勿在其中写入版本号/提交数等具体内容。
  新建 PR 时：标题写版本号，正文按模板结构填写，变更明细从 docs/CHANGELOG.md
  顶部最新章节复制。仓库不因 PR 描述变化产生任何 git 变更。
-->

# 📦 PR: <版本号> <一句话主题>

> **Base** `master` ← **Head** `<当前分支>` ｜ 应用版本 `<versionName>（<versionCode>）`

## 1. Summary — 摘要
<!-- 本次 PR 解决什么、为什么 -->

## 2. Type of Change — 变更类型
- [ ] ✨ feat：新功能
- [ ] 🐛 fix：缺陷修复
- [ ] 🔧 refactor：重构
- [ ] 📝 docs：文档
- [ ] ✅ test / 构建验证

## 3. What's Changed — 变更明细
<!-- 从 docs/CHANGELOG.md 顶部最新章节复制（按功能分组），保留文件级说明 -->

## 4. Scope / Affected Areas — 影响范围
<!-- 影响的模块/页面/数据/构建链 -->

## 5. Testing — 测试与验证
- [ ] 本地 hvigor 构建通过
- [ ] 真机回归项：
<!-- 列出需真机确认的项 -->

## 6. Breaking Changes — 破坏性变更
<!-- 无则填「无」 -->

## 7. Migration / Compatibility — 兼容性说明
<!-- 数据/备份/权限/版本兼容 -->

## 8. Checklist — 合并前检查
- [ ] 版本号与 git 提交号一致
- [ ] 双语资源补齐
- [ ] 无构建产物残留（BuildInfo.ets 已恢复占位）
- [ ] CHANGELOG 已增量更新

## 9. After Merge — 合并后动作
1. master 自动构建
2. 打 tag `v<版本号>` → 自动发布 GitHub Release
3. gitee master 同步
