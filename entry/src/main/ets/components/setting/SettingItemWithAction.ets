// 带操作的设置项组件（emoji 彩色圆角图标，更多页 UI 统一）
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { SettingIcon } from './SettingIcon'

@Component
export struct SettingItemWithAction {
  label: ResourceStr = ''
  summary: ResourceStr = ''
  isDestructive: boolean = false
  icon: string = ''  // emoji 图标（可选）
  iconBg: string = ''  // 图标容器底色
  // 直接从 AppStorage 监听主题变化
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  onAction: () => void = () => {}

  build() {
    Row() {
      SettingIcon({ icon: this.icon, iconBg: this.iconBg })

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
