// 带信息的设置项组件
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'

@Component
export struct SettingItemWithInfo {
  label: string = ''
  @Prop info: string = ''  // 使用@Prop装饰器，支持父组件数据更新
  // 直接从 AppStorage 监听主题变化
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  build() {
    Row() {
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
