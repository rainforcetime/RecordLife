// 设置项图标（emoji + 彩色圆角容器，我的页 UI 重构轮次1）
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

@Component
export struct SettingIcon {
  icon: string = ''  // emoji
  iconBg: string = ''  // 容器底色（调用方传入固定色；空则默认浅灰）
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  build() {
    if (this.icon.length > 0) {
      Text(this.icon)
        .fontSize(20)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(12)
        .backgroundColor(this.iconBg.length > 0 ? this.iconBg : '#F2F3F5')
        .margin({ right: 12 })
    }
  }
}
