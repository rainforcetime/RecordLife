// 时间卡片组件
@Component
export struct TimeCard {
  @Prop value: number = 0;
  @Prop label: string = '';
  @Prop description: string = '';
  @Prop cardColor: string = '#FFFFFF';
  @Prop valueColor: string = '#333333';
  @Prop labelColor: string = '#666666';
  @Prop valueFontSize: number = 36;

  build() {
    Column() {
      // 单位标签
      Text(this.label)
        .fontSize(14)
        .fontColor(this.labelColor)
        .margin({ bottom: 6 })

      // 数值显示（防止换行）
      Text(`${this.value}`)
        .fontSize(this.valueFontSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.valueColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 4 })

      // 描述文字
      Text(this.description)
        .fontSize(11)
        .fontColor('#999999')
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
      color: '#15000000',
      offsetX: 0,
      offsetY: 2
    })
  }
}
