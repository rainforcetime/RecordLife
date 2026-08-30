// 桌面卡片：点击后跳转应用并打开「新建记录」弹窗
// 样式：渐变背景 + 半透明装饰圆 + 白色圆底加号 + 日期 + 操作提示
let storage = new LocalStorage();

@Entry
@Component
struct QuickRecordCard {
  readonly ACTION_TYPE: string = 'router';
  readonly ABILITY_NAME: string = 'EntryAbility';
  readonly MESSAGE_ADD_RECORD: string = 'addRecord';

  // 卡片构建时计算当天日期（M/D 格式，无语言依赖）
  private get todayText(): string {
    const now = new Date();
    return `${now.getMonth() + 1}/${now.getDate()}`;
  }

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
      Column() {
        // 顶部行：应用名（左） + 今天日期（右）
        Row() {
          Text($r('app.string.app_name'))
            .fontSize(11)
            .fontColor('#B3FFFFFF')

          Blank()

          Text(this.todayText)
            .fontSize(11)
            .fontColor('#B3FFFFFF')
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16 })

        // 中部：加号容器（白色圆底，视觉焦点）
        Column() {
          Text('＋')
            .fontSize(42)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FF4E7CFF')
        }
        .width(60)
        .height(60)
        .borderRadius(30)
        .backgroundColor('#FFFFFF')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 12 })

        // 底部：主文案 + 操作提示
        Text($r('app.string.quick_record_card_name'))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .margin({ top: 10 })

        Text($r('app.string.quick_record_card_hint'))
          .fontSize(10)
          .fontColor('#99FFFFFF')
          .textAlign(TextAlign.Center)
          .margin({ top: 3 })
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
