// 设置分组卡片容器（统一悬浮卡片样式，消除 AccountPage 重复代码，我的页 UI 重构轮次1）
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

@Component
export struct SettingsGroupCard {
  @BuilderParam content: () => void
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  build() {
    Column() {
      this.content()
    }
    .width('90%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
    .margin({ bottom: 6 })
    .padding(12)
    .shadow({
      radius: 12,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 4
    })
  }
}
