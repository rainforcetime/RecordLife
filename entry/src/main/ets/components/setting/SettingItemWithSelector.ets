// 带选择器的设置项组件
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

@Component
export struct SettingItemWithSelector {
  label: string = ''
  @Prop currentValue: string = ''
  options: string[] = []
  // 直接从 AppStorage 监听主题变化
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  onSelect: (value: string) => void = () => {}

  build() {
    Row() {
      Text(this.label)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.textPrimary)
        .layoutWeight(1)

      Row() {
        Text(this.currentValue)
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
        Image($r('app.media.arrow_right'))
          .width(20)
          .height(20)
          .fillColor(this.themeColors.iconColor)
          .margin({ left: 5 })
      }
      .onClick(() => {
        // 显示选择器
        this.showSelector()
      })
    }
    .padding(15)
    .width('100%')
  }

  private showSelector() {
    // 使用UIContext.showTextPickerDialog替代已废弃的TextPickerDialog.show
    const uiContext = this.getUIContext()
    uiContext.showTextPickerDialog({
      range: this.options,
      selected: this.options.indexOf(this.currentValue),
      onAccept: (value: TextPickerResult) => {
        const index = value.index as number
        this.onSelect(this.options[index])
      }
    })
  }
}
