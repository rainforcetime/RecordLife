// 带开关的设置项组件（隐私模式等，我的页 UI 重构轮次1）
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { SettingIcon } from './SettingIcon'

@Component
export struct SettingItemWithSwitch {
  label: ResourceStr = ''
  summary: ResourceStr = ''
  icon: string = ''  // emoji
  iconBg: string = ''  // 图标容器底色
  @Prop isOn: boolean = false
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  onChange: (isOn: boolean) => void = () => {}

  build() {
    Row() {
      SettingIcon({ icon: this.icon, iconBg: this.iconBg })

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

      Toggle({ type: ToggleType.Switch, isOn: this.isOn })
        .selectedColor(this.themeColors.primary)
        .onChange((isOn: boolean) => {
          this.onChange(isOn)
        })
    }
    .padding({ top: 16, bottom: 16, left: 16, right: 16 })
    .width('100%')
  }
}
