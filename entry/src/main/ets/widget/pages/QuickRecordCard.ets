// 桌面卡片：点击后跳转应用并打开「新建记录」弹窗
let storage = new LocalStorage();

@Entry
@Component
struct QuickRecordCard {
  readonly ACTION_TYPE: string = 'router';
  readonly ABILITY_NAME: string = 'EntryAbility';
  readonly MESSAGE_ADD_RECORD: string = 'addRecord';

  build() {
    Column({ space: 8 }) {
      Text('＋')
        .fontSize(52)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')

      Text($r('app.string.quick_record_card_name'))
        .fontSize(14)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FF4E7CFF')
    .borderRadius(24)
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
