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
            .width(100)
            .height(100)
            .borderRadius(50)
            .border({ width: 4, color: this.themeColors.primary })
        } else {
          // 显示默认头像（使用系统图标）
          Column() {
            SymbolGlyph($r('sys.symbol.person_fill'))
              .fontSize(52)
              .fontColor([this.themeColors.textSecondary])
          }
          .width(100)
          .height(100)
          .borderRadius(50)
          .backgroundColor(this.themeColors.divider)
          .justifyContent(FlexAlign.Center)
          .border({ width: 4, color: this.themeColors.primary })
        }

        // 编辑图标（使用系统图标：相机圆形填充）
        Column() {
          SymbolGlyph($r('sys.symbol.camera_circle_fill'))
            .fontSize(22)
            .fontColor([Color.White])
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor(this.themeColors.primary)
        .justifyContent(FlexAlign.Center)
        .margin({ right: 2, bottom: 2 })
        .shadow({
          radius: 6,
          color: this.themeColors.primary + '40',
          offsetX: 0,
          offsetY: 2
        })
      }
      .width(100)
      .height(100)
      .margin({ top: 16, bottom: 18 })
      .onClick(() => {
        if (this.onChangeAvatar) {
          this.onChangeAvatar()
        }
      })

      // 用户名
      Text(this.userInfo.userName)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ bottom: 14 })

      // 用户信息标签
      Row() {
        // 性别标签
        Row() {
          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(14)
            .fontColor([this.getLabelTextColor()])
            .margin({ right: 5 })
          Text(this.userInfo.userGender)
            .fontSize(13)
            .fontColor(this.getLabelTextColor())
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor(this.getLabelBackgroundColor())
        .borderRadius(14)

        // 出生日期标签
        Row() {
          SymbolGlyph($r('sys.symbol.calendar'))
            .fontSize(14)
            .fontColor([this.getLabelTextColor()])
            .margin({ right: 5 })
          Text(this.userInfo.userBirthday)
            .fontSize(13)
            .fontColor(this.getLabelTextColor())
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor(this.getLabelBackgroundColor())
        .borderRadius(14)
        .margin({ left: 10 })
      }
      .margin({ bottom: 22 })

      // 编辑资料按钮
      Button() {
        Row() {
          SymbolGlyph($r('sys.symbol.square_and_pencil'))
            .fontSize(18)
            .fontColor([Color.White])
            .margin({ right: 8 })
          Text('编辑资料')
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
      }
      .backgroundColor(this.themeColors.primary)
      .borderRadius(26)
      .width(160)
      .height(50)
      .shadow({
        radius: 16,
        color: this.themeColors.primary + '50',
        offsetX: 0,
        offsetY: 8
      })
      .onClick(() => {
        if (this.onEditProfile) {
          this.onEditProfile()
        }
      })
    }
    .width('90%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(18)
    .margin({ bottom: 16 })
    .padding({ left: 24, right: 24, top: 12, bottom: 24 })
    .shadow({
      radius: 16,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 6
    })
  }
}
