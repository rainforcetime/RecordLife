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
  
  // 判断是否为深色模式
  private isDarkMode(): boolean {
    return this.themeColors.textPrimary === '#FFFFFF'
  }
  
  // 获取标签文字颜色（深色模式适配）
  private getLabelTextColor(): string {
    if (this.isDarkMode()) {
      // 深色模式：使用白色文字，更清晰
      return '#FFFFFF'
    } else {
      // 浅色模式：使用主题色
      return this.themeColors.primary
    }
  }
  
  // 获取标签背景颜色（深色模式适配）
  private getLabelBackgroundColor(): string {
    if (this.isDarkMode()) {
      // 深色模式：使用主题色作为背景，透明度30%
      return this.themeColors.primary + '30'
    } else {
      // 浅色模式：使用浅色主题色背景，透明度20%
      return this.themeColors.primaryLight + '20'
    }
  }

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
            .fontColor([this.getLabelTextColor()])
            .margin({ right: 4 })
          Text(this.userInfo.userGender)
            .fontSize(13)
            .fontColor(this.getLabelTextColor())
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(this.getLabelBackgroundColor())
        .borderRadius(12)

        // 出生日期标签
        Row() {
          SymbolGlyph($r('sys.symbol.calendar'))
            .fontSize(14)
            .fontColor([this.getLabelTextColor()])
            .margin({ right: 4 })
          Text(this.userInfo.userBirthday)
            .fontSize(13)
            .fontColor(this.getLabelTextColor())
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(this.getLabelBackgroundColor())
        .borderRadius(12)
        .margin({ left: 8 })
      }
      .margin({ bottom: 20 })

      // 编辑资料按钮
      Button() {
        Row() {
          SymbolGlyph($r('sys.symbol.square_and_pencil'))
            .fontSize(16)
            .fontColor([Color.White])
            .margin({ right: 6 })
          Text('编辑资料')
            .fontSize(15)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
      }
      .backgroundColor(this.themeColors.primary)
      .borderRadius(24)
      .width(150)
      .height(46)
      .shadow({
        radius: 12,
        color: this.themeColors.primary + '50',
        offsetX: 0,
        offsetY: 6
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
