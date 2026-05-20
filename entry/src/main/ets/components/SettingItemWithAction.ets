// 带操作的设置项组件
@Component
export struct SettingItemWithAction {
  label: string = ''
  summary: string = ''
  isDestructive: boolean = false
  onAction: () => void = () => {}

  build() {
    Row() {
      Column() {
        Text(this.label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDestructive ? '#FF0000' : '#000000')
        if (this.summary) {
          Text(this.summary)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 3 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.arrow_right'))
        .width(20)
        .height(20)
    }
    .padding(15)
    .width('100%')
    .onClick(() => {
      this.onAction()
    })
  }
}
