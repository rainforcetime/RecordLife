// 目标年龄选择组件
@Component
export struct TargetAgeRow {
  @Link targetAge: number;
  @State showAgePicker: boolean = false;

  build() {
    Row() {
      Text('🎯 目标年龄')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

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
      .backgroundColor('#F5F5F5')
      .onClick(() => {
        this.showAgePicker = true;
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 12 })
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .bindSheet($$this.showAgePicker, this.AgePickerSheet(), {
      height: 350,
      backgroundColor: Color.White,
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
        .margin({ top: 20, bottom: 20 })

      Row() {
        Button('-')
          .width(50)
          .height(50)
          .fontSize(24)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
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
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .onClick(() => {
            if (this.targetAge < 150) {
              this.targetAge++;
            }
          })
      }
      .margin({ bottom: 20 })

      Text('岁')
        .fontSize(16)
        .fontColor('#666666')

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
