// 时间卡片组件：components/TimeCard.ets
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'

@Component
export struct TimeCard {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  @Prop @Watch('onValueChange') value: number = 0
  @Prop label: string = ''
  @Prop description: string = ''
  @Prop cardColor: string = '#FFFFFF'
  @Prop valueColor: string = '#333333'
  @Prop labelColor: string = '#666666'
  @Prop valueFontSize: number = 36
  
  // 动画状态
  @State private displayValue: number = 0
  @State private scaleValue: number = 1
  @State private opacityValue: number = 1
  
  aboutToAppear() {
    this.displayValue = this.value
  }
  
  // 值变化时触发动画
  private onValueChange() {
    if (this.displayValue !== this.value) {
      // 缩放动画效果
      this.scaleValue = 1.1
      this.opacityValue = 0.7
      
      setTimeout(() => {
        this.displayValue = this.value
        this.scaleValue = 1
        this.opacityValue = 1
      }, 150)
    }
  }
  
  build() {
    Column() {
      // 单位标签
      Text(this.label)
        .fontSize(14)
        .fontColor(this.labelColor)
        .margin({ bottom: 6 })

      // 数值显示（带动画）
      Text(`${this.displayValue}`)
        .fontSize(this.valueFontSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.valueColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 4 })
        .scale({ x: this.scaleValue, y: this.scaleValue })
        .opacity(this.opacityValue)
        .animation({
          duration: 150,
          curve: Curve.EaseOut,
          playMode: PlayMode.Normal
        })

      // 描述文字
      Text(this.description)
        .fontSize(11)
        .fontColor(this.themeColors.textSecondary)
        .maxLines(1)
    }
    .width('100%')
    .height(110)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.cardColor)
    .borderRadius(16)
    .padding(12)
    .shadow({
      radius: 8,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 2
    })
  }
}
