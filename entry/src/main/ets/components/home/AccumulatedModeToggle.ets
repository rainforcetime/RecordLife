// 累计模式切换组件：components/home/AccumulatedModeToggle.ets（P5 自 HomePage 拆分）
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

@Component
export struct AccumulatedModeToggle {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 累计模式开关（双向绑定）
  @Link isAccumulatedMode: boolean
  // 剩余模式标志（只读，决定颜色与文案）
  @Prop isRemainingMode: boolean = false

  // 模式变化回调（由页面执行持久化 + 重算）
  onModeChange?: () => void

  build() {
    Row() {
      Text(this.isRemainingMode ? $r('app.string.remaining_calc_mode') : $r('app.string.alive_calc_mode'))
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)

      Blank()

      Row() {
        Text($r('app.string.accumulated_mode'))
          .fontSize(12)
          .fontColor(this.isAccumulatedMode ? '#FFFFFF' : this.themeColors.textSecondary)
          .fontWeight(this.isAccumulatedMode ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.isAccumulatedMode ? (this.isRemainingMode ? this.getRemainingColor() : this.getPassedColor()) : 'transparent')
          .borderRadius(12)
          .onClick(() => {
            if (!this.isAccumulatedMode) {
              this.isAccumulatedMode = true
              this.onModeChange?.()
            }
          })

        Text($r('app.string.non_accumulated'))
          .fontSize(12)
          .fontColor(!this.isAccumulatedMode ? '#FFFFFF' : this.themeColors.textSecondary)
          .fontWeight(!this.isAccumulatedMode ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(!this.isAccumulatedMode ? (this.isRemainingMode ? this.getRemainingColor() : this.getPassedColor()) : 'transparent')
          .borderRadius(12)
          .onClick(() => {
            if (this.isAccumulatedMode) {
              this.isAccumulatedMode = false
              this.onModeChange?.()
            }
          })
      }
      .backgroundColor(this.themeColors.background)
      .borderRadius(16)
      .padding(2)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  // 获取已过模式颜色（红色系）
  private getPassedColor(): string {
    return this.themeColors.error
  }

  // 获取剩余模式颜色（青色系，深色模式更协调）
  private getRemainingColor(): string {
    return this.themeColors.success
  }
}
