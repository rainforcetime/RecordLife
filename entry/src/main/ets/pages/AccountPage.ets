
// 账号设置页面：pages/AccountPage.ets
@Component
export struct AccountPage {
  build() {
    Column() {
      Text('账号设置')
        .fontSize(25)
        .margin(20)

      // 用户信息区域
      Row() {
        Image($r('app.media.user_avatar'))
          .width(80)
          .height(80)
          .borderRadius(40)
          .margin(15)

        Column() {
          Text('用户名')
            .fontSize(20)
          Text('编辑资料 >')
            .fontColor(Color.Gray)
        }
      }

      // 设置项列表
      List() {
        ListItem() {
          SettingItem({ label: '通知设置' }) // 修复点
        }
        ListItem() {
          SettingItem({ label: '隐私设置' })
        }
        ListItem() {
          SettingItem({ label: '清除缓存' })
        }
        ListItem() {
          SettingItem({ label: '关于应用' })
        }
      }
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct SettingItem {
  label: string = ''
  build() {
    Row() {
      Text(this.label).fontSize(18)
      Blank()
      Image($r('app.media.arrow_right')).width(20).height(20)
    }.padding(15).width('100%')
  }
}