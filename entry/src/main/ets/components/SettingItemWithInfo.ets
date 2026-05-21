// 带信息的设置项组件
@Component
export struct SettingItemWithInfo {
  label: string = ''
  @Prop info: string = ''  // 使用@Prop装饰器，支持父组件数据更新

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
