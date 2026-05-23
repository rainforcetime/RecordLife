// 目标年龄选择组件
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig';

@Component
export struct TargetAgeRow {
  @Link targetAge: number;
  @State showAgePicker: boolean = false;
  
  // 主题颜色配置
  @Prop themeColors: ThemeColors = ThemeConfig.getColors(false)

  build() {
    Row() {
      Text('🎯 目标年龄')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.textPrimary)

      Blank()

      // 目标年龄显示
      Text(`${this.targetAge} 岁`)
        .fontSize(15)
        .fontColor('#4CAF50')
        .margin({ right: 12 })

      // 编辑按钮
      Button({ type: ButtonType.Circle }) {
        Text('✏️')
          .fontSize(16)
      }
      .width(36)
      .height(36)
      .backgroundColor(this.themeColors.background)
      .onClick(() => {
        this.showAgePicker = true;
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
    .margin({ top: 12 })
    .shadow({
      radius: 8,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 2
    })
    .bindSheet($$this.showAgePicker, this.AgePickerSheet(), {
      height: 350,
      backgroundColor: this.themeColors.cardBackground,
      dragBar: true
    })
  }

  // 年龄选择器弹窗
  @Builder
  AgePickerSheet() {
    Column() {
      Text('设置目标年龄')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ top: 20, bottom: 20 })

      Row() {
        Button('-')
          .width(50)
          .height(50)
          .fontSize(24)
          .backgroundColor(this.themeColors.background)
          .fontColor(this.themeColors.textPrimary)
          .onClick(() => {
            if (this.targetAge > 1) {
              this.targetAge--;
            }
          })

        Text(`${this.targetAge}`)
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4CAF50')
          .margin({ left: 30, right: 30 })

        Button('+')
          .width(50)
          .height(50)
          .fontSize(24)
          .backgroundColor(this.themeColors.background)
          .fontColor(this.themeColors.textPrimary)
          .onClick(() => {
            if (this.targetAge < 150) {
              this.targetAge++;
            }
          })
      }
      .margin({ bottom: 20 })

      Text('岁')
        .fontSize(16)
        .fontColor(this.themeColors.textSecondary)

      Button('确定')
        .width('80%')
        .height(44)
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .margin({ top: 20 })
        .onClick(() => {
          this.showAgePicker = false;
        })
    }
    .width('100%')
    .padding(16)
  }
}
