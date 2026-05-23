// 用户信息区域组件：components/UserInfoSection.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

// 用户信息数据模型
export interface UserInfo {
  userName: string
  userBirthday: string
  userGender: string
  userAvatar: string
  hasCustomAvatar: boolean
}

@Component
export struct UserInfoSection {
  // 主题颜色配置
  @Prop themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 用户信息
  @Prop userInfo: UserInfo = {
    userName: '张三',
    userBirthday: '1990-01-15',
    userGender: '男',
    userAvatar: '',
    hasCustomAvatar: false
  }
  
  // 编辑资料回调
  onEditProfile?: () => void
  
  // 更换头像回调
  onChangeAvatar?: () => void

  build() {
    Column() {
      // 头像展示（可点击更换）
      Stack({ alignContent: Alignment.BottomEnd }) {
        // 头像
        if (this.userInfo.hasCustomAvatar && this.userInfo.userAvatar) {
          // 显示用户自定义头像
          Image(this.userInfo.userAvatar)
            .width(90)
            .height(90)
            .borderRadius(45)
            .border({ width: 3, color: this.themeColors.primary })
        } else {
          // 显示默认头像（使用系统图标）
          Column() {
            SymbolGlyph($r('sys.symbol.person_fill'))
              .fontSize(50)
              .fontColor([this.themeColors.textSecondary])
          }
          .width(90)
          .height(90)
          .borderRadius(45)
          .backgroundColor(this.themeColors.divider)
          .justifyContent(FlexAlign.Center)
          .border({ width: 3, color: this.themeColors.primary })
        }

        // 编辑图标（使用系统图标：相机圆形填充）
        Column() {
          SymbolGlyph($r('sys.symbol.camera_circle_fill'))
            .fontSize(20)
            .fontColor([Color.White])
        }
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor(this.themeColors.primary)
        .justifyContent(FlexAlign.Center)
        .margin({ right: 2, bottom: 2 })
      }
      .width(90)
      .height(90)
      .margin({ top: 20, bottom: 16 })
      .onClick(() => {
        if (this.onChangeAvatar) {
          this.onChangeAvatar()
        }
      })

      // 用户名
      Text(this.userInfo.userName)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ bottom: 12 })

      // 用户信息标签
      Row() {
        // 性别标签
        Row() {
          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(14)
            .fontColor([this.themeColors.textSecondary])
            .margin({ right: 4 })
          Text(this.userInfo.userGender)
            .fontSize(13)
            .fontColor(this.themeColors.textSecondary)
        }
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(this.themeColors.primaryLight + '20')
        .borderRadius(12)

        // 出生日期标签
        Row() {
          SymbolGlyph($r('sys.symbol.calendar'))
            .fontSize(14)
            .fontColor([this.themeColors.textSecondary])
            .margin({ right: 4 })
          Text(this.userInfo.userBirthday)
            .fontSize(13)
            .fontColor(this.themeColors.textSecondary)
        }
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(this.themeColors.primaryLight + '20')
        .borderRadius(12)
        .margin({ left: 8 })
      }
      .margin({ bottom: 20 })

      // 编辑资料按钮
      Button('编辑资料')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.themeColors.primary)
        .fontColor(Color.White)
        .borderRadius(22)
        .width(140)
        .height(44)
        .shadow({
          radius: 8,
          color: this.themeColors.primary + '40',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => {
          if (this.onEditProfile) {
            this.onEditProfile()
          }
        })
    }
    .width('90%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
    .margin({ bottom: 16 })
    .padding({ left: 20, right: 20, top: 10, bottom: 20 })
    .shadow({
      radius: 12,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 4
    })
  }
}
