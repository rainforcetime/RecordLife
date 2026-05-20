// 基础设置项组件（带箭头）
@Component
export struct SettingItem {
  label: string = ''
  summary: string = ''

  build() {
    Row() {
      Column() {
        Text(this.label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
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
  }
}
