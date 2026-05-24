// 带操作的设置项组件
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

@Component
export struct SettingItemWithAction {
  label: string = ''
  summary: string = ''
  isDestructive: boolean = false
  // 直接从 AppStorage 监听主题变化
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  onAction: () => void = () => {}

  build() {
    Row() {
      Column() {
        Text(this.label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDestructive ? '#FF3B30' : this.themeColors.textPrimary)
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
    .onClick(() => {
      this.onAction()
    })
  }
}
