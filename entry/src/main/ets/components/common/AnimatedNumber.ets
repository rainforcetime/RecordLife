// 数字滚动动画组件：components/AnimatedNumber.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

@Component
export struct AnimatedNumber {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 当前显示的数字
  @Prop @Watch('onNumberChange') number: number = 0
  
  // 字体大小
  @Prop fontSize: number = 28
  
  // 字体颜色
  @Prop fontColor: string = '#FF6B6B'
  
  // 字体粗细
  @Prop fontWeight: FontWeight = FontWeight.Bold
  
  // 动画时长（毫秒）
  @Prop animationDuration: number = 300
  
  // 上一次的数字（用于动画）
  @State private previousNumber: number = 0
  
  // 是否需要动画
  @State private needAnimation: boolean = false
  
  // 动画偏移量
  @State private offsetY: number = 0
  
  // 透明度（重命名避免与内置属性冲突）
  @State private opacityValue: number = 1
  
  aboutToAppear() {
    this.previousNumber = this.number
  }
  
  // 数字变化时触发动画
  private onNumberChange() {
    if (this.previousNumber !== this.number) {
      // 触发滚动动画
      this.needAnimation = true
      this.offsetY = -20  // 从上方滑入
      this.opacityValue = 0
    
      // 动画结束后更新
      setTimeout(() => {
        this.previousNumber = this.number
        this.offsetY = 0
        this.opacityValue = 1
        this.needAnimation = false
      }, this.animationDuration)
    }
  }
  
  build() {
    Text(this.number.toString())
      .fontSize(this.fontSize)
      .fontColor(this.fontColor)
      .fontWeight(this.fontWeight)
      .translate({ y: this.offsetY })
      .opacity(this.opacityValue)
      .animation(this.needAnimation ? {
        duration: this.animationDuration,
        curve: Curve.EaseOut,
        playMode: PlayMode.Normal
      } : undefined)
  }
}

// 带单位的时间卡片动画组件
@Component
export struct AnimatedTimeValue {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 数值
  @Prop value: number = 0
  
  // 单位标签
  @Prop label: string = ''
  
  // 描述文字
  @Prop description: string = ''
  
  // 卡片背景色
  @Prop cardColor: string = '#FFE8E8'
  
  // 数值颜色
  @Prop valueColor: string = '#FF6B6B'
  
  // 数值字体大小
  @Prop valueFontSize: number = 28
  
  build() {
    Column() {
      // 数值和单位
      Row() {
        AnimatedNumber({
          number: this.value,
          fontSize: this.valueFontSize,
          fontColor: this.valueColor,
          fontWeight: FontWeight.Bold,
          animationDuration: 300
        })
        
        Text(this.label)
          .fontSize(16)
          .fontColor(this.valueColor)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 4 })
      }
      .height(this.valueFontSize + 8)
      
      // 描述文字
      Text(this.description)
        .fontSize(12)
        .fontColor(this.themeColors.textSecondary)
        .margin({ top: 8 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 16, bottom: 16, left: 12, right: 12 })
    .backgroundColor(this.cardColor)
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
