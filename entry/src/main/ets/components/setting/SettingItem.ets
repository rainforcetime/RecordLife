// 基础设置项组件（带箭头）
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

@Component
export struct SettingItem {
  label: ResourceStr = ''
  summary: ResourceStr = ''
  icon: string = ''  // emoji 图标（可选，更新计划五期：设置分组图标化）
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

      Column() {
        Text(this.label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.textPrimary)
        if (this.summary) {
          Text(this.summary)
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 3 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([this.themeColors.iconColor])
    }
    .padding({ top: 16, bottom: 16, left: 16, right: 16 })
    .width('100%')
  }
}
