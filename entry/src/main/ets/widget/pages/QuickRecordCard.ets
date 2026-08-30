// 桌面卡片：点击后跳转应用并打开「新建记录」弹窗
// 样式：渐变背景（铺满 Stack 自身，圆角平滑）+ 内部装饰圆 + 白色圆底加号 + 日期 + 操作提示
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
      // 右上装饰圆（完全在卡片内部，不越界）
      Column()
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor('#26FFFFFF')
        .position({ x: '70%', y: '8%' })

      // 左下装饰圆（完全在卡片内部）
      Column()
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor('#14FFFFFF')
        .position({ x: '8%', y: '76%' })

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
    // 渐变背景铺满整个矩形，不设内容圆角——由卡片宿主统一裁切圆角，
    // 避免内容圆角与宿主圆角不匹配导致四角露出宿主白底
    .linearGradient({
      angle: 135,
      colors: [
        ['#FF8FB2F5', 0.0],
        ['#FF4E7CFF', 0.55],
        ['#FF3A5BD9', 1.0]
      ]
    })
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
