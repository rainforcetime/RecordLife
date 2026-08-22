// 带信息的设置项组件
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

@Component
export struct SettingItemWithInfo {
  label: ResourceStr = ''
  @Prop info: ResourceStr = ''  // 使用@Prop装饰器，支持父组件数据更新
  icon: string = ''  // emoji 图标（可选，更新计划五期）
  // 直接从 AppStorage 监听主题变化
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  build() {
    Row() {
      // emoji 图标
      if (this.icon.length > 0) {
        Text(this.icon)
          .fontSize(20)
          .margin({ right: 12 })
      }

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
