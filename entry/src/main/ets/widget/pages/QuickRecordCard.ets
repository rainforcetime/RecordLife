// 桌面卡片：点击后跳转应用并打开「新建记录」弹窗
// 样式：渐变背景 + 半透明装饰圆 + 白色圆底加号，简洁有质感
let storage = new LocalStorage();

@Entry
@Component
struct QuickRecordCard {
  readonly ACTION_TYPE: string = 'router';
  readonly ABILITY_NAME: string = 'EntryAbility';
  readonly MESSAGE_ADD_RECORD: string = 'addRecord';

  build() {
    Stack() {
      // 渐变背景
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            ['#FF8FB2F5', 0.0],
            ['#FF4E7CFF', 0.55],
            ['#FF3A5BD9', 1.0]
          ]
        })

      // 右上装饰圆（半透明）
      Column()
        .width(140)
        .height(140)
        .borderRadius(70)
        .backgroundColor('#26FFFFFF')
        .position({ x: '62%', y: '-24%' })

      // 左下装饰圆（更淡）
      Column()
        .width(96)
        .height(96)
        .borderRadius(48)
        .backgroundColor('#14FFFFFF')
        .position({ x: '-14%', y: '70%' })

      // 内容区
      Column({ space: 8 }) {
        Text($r('app.string.app_name'))
          .fontSize(11)
          .fontColor('#B3FFFFFF')

        // 加号容器（白色圆底，视觉焦点）
        Column() {
          Text('＋')
            .fontSize(42)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FF4E7CFF')
        }
        .width(64)
        .height(64)
        .borderRadius(32)
        .backgroundColor('#FFFFFF')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 2 })

        Text($r('app.string.quick_record_card_name'))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .borderRadius(28)
    .clip(true)
    .onClick(() => {
      postCardAction(this, {
        action: this.ACTION_TYPE,
        abilityName: this.ABILITY_NAME,
        params: {
          message: this.MESSAGE_ADD_RECORD
        }
      });
    })
  }
}
