// 模块页面：开发中
@Component
export struct ModulePage {
  build() {
    Column() {
      // 空状态图标
      Column() {
        // 开发中图标（使用系统图标或自定义）
        Text('🚧')
          .fontSize(80)
          .margin({ bottom: 24 })

        // 提示文字
        Text('开发中')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ bottom: 12 })

        Text('功能正在紧张开发中，敬请期待')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .justifyContent(FlexAlign.Center)
  }
}
