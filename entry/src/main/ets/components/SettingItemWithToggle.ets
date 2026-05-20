// 带开关的设置项组件
@Component
export struct SettingItemWithToggle {
  label: string = ''
  summary: string = ''
  @Prop isEnabled: boolean = false
  onToggle: (value: boolean) => void = () => {}

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

      Toggle({ type: ToggleType.Switch, isOn: this.isEnabled })
        .onChange((isOn: boolean) => {
          this.onToggle(isOn)
        })
        .selectedColor('#007DFF')
    }
    .padding(15)
    .width('100%')
  }
}
