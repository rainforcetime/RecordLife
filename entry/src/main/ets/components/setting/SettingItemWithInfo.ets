// 带信息的设置项组件（emoji 彩色圆角图标）
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { SettingIcon } from './SettingIcon'

@Component
export struct SettingItemWithInfo {
  label: ResourceStr = ''
  @Prop info: ResourceStr = ''  // 使用@Prop装饰器，支持父组件数据更新
  icon: string = ''  // emoji 图标（可选，更新计划五期）
  iconBg: string = ''  // 图标容器底色（我的页 UI 重构轮次1）
  // 直接从 AppStorage 监听主题变化
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  build() {
    Row() {
      SettingIcon({ icon: this.icon, iconBg: this.iconBg })

      Text(this.label)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.textPrimary)
        .layoutWeight(1)

      Text(this.info)
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
    }
    .padding(15)
    .width('100%')
  }
}
