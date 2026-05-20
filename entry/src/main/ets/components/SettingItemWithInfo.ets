// 带信息的设置项组件
@Component
export struct SettingItemWithInfo {
  label: string = ''
  info: string = ''

  build() {
    Row() {
      Text(this.label)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)

      Text(this.info)
        .fontSize(14)
        .fontColor('#666666')
    }
    .padding(15)
    .width('100%')
  }
}
