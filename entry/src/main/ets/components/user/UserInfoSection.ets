// 用户信息区域组件：components/UserInfoSection.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { ColorUtils } from '../../common/ColorUtils'

// 用户信息数据模型
export interface UserInfo {
  userName: string
  userBirthday: string
  userGender: string
  userAvatar: string
  hasCustomAvatar: boolean
  userSignature: string
}

@Component
export struct UserInfoSection {
  // 主题颜色配置
  @Prop themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 用户信息
  @Prop userInfo: UserInfo = {
    userName: '',
    userBirthday: '1990-01-15',
    userGender: '',
    userAvatar: '',
    hasCustomAvatar: false,
    userSignature: ''
  }
  
  // 隐私模式（更新计划三期：隐藏出生日期）
  @Prop privacyMode: boolean = false
  
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
      // 深色模式：使用深色背景
      return '#2A2A2A'
    } else {
      // 浅色模式：使用浅灰色背景
      return '#F5F5F5'
    }
  }
  
  // 获取装饰元素颜色（深色模式使用蓝色）
  private getAccentColor(): string {
    if (this.isDarkMode()) {
      // 深色模式：使用蓝色
      return '#4A90E2'
    } else {
      // 浅色模式：使用主题色
      return this.themeColors.primary
    }
  }

  build() {
    Row() {
      // 头像展示（可点击更换）
      Stack({ alignContent: Alignment.BottomEnd }) {
        // 头像装饰外圈
        Circle()
          .width(100)
          .height(100)
          .fill('transparent')
          .stroke(this.getAccentColor())
          .strokeWidth(2)
          .position({ x: -6, y: -6 })

        // 头像
        if (this.userInfo.hasCustomAvatar && this.userInfo.userAvatar) {
          // 显示用户自定义头像
          Image(this.userInfo.userAvatar)
            .width(88)
            .height(88)
            .borderRadius(44)
            .border({ width: 3, color: this.themeColors.primary })
        } else {
          // 显示默认头像（使用系统图标）
          Column() {
            SymbolGlyph($r('sys.symbol.person_fill'))
              .fontSize(46)
              .fontColor([this.themeColors.textSecondary])
          }
          .width(88)
          .height(88)
          .borderRadius(44)
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
        .margin({ right: 0, bottom: 0 })
        .shadow({
          radius: 6,
          color: this.themeColors.primary + '40',
          offsetX: 0,
          offsetY: 2
        })
      }
      .width(88)
      .height(88)
      .margin({ right: 16 })
      .onClick(() => {
        if (this.onChangeAvatar) {
          this.onChangeAvatar()
        }
      })

      // 右侧信息（左对齐列表式，我的页 UI 重构轮次2）
      Column() {
        // 顶部行：用户名 + 编辑按钮（右上角）
        Row() {
          Text(this.userInfo.userName)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeColors.textPrimary)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 编辑资料按钮（右上角胶囊）
          Text($r('app.string.edit'))
            .fontSize(13)
            .fontColor(this.getAccentColor())
            .fontWeight(FontWeight.Medium)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor(this.themeColors.cardBackground)
            .borderRadius(15)
            .onClick(() => {
              if (this.onEditProfile) {
                this.onEditProfile()
              }
            })
        }
        .width('100%')

        // 签名/座右铭（有值才展示，更新计划一期）
        if (this.userInfo.userSignature && this.userInfo.userSignature.length > 0) {
          Text(this.userInfo.userSignature)
            .fontSize(14)
            .fontColor(this.themeColors.textSecondary)
            .textAlign(TextAlign.Start)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: 6 })
        }

        // 用户信息标签
        Row() {
          // 性别标签
          Row() {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(13)
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

          // 出生日期标签（隐私模式隐藏，更新计划三期）
          if (this.privacyMode) {
            Row() {
              Text('🔒')
                .fontSize(13)
              Text($r('app.string.privacy_mode_on'))
                .fontSize(13)
                .fontColor(this.getLabelTextColor())
                .fontWeight(FontWeight.Medium)
                .margin({ left: 4 })
            }
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(this.getLabelBackgroundColor())
            .borderRadius(12)
            .margin({ left: 8 })
          } else {
            Row() {
              SymbolGlyph($r('sys.symbol.calendar'))
                .fontSize(13)
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
        }
        .margin({ top: 10 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('90%')
    // 主题色渐变背景（更新计划五期；上下渐变：顶部主题色淡出到底部卡片背景）
    // 注意：linearGradient 终点 stop 必须为实色（不透明），半透明终点会导致整个渐变渲染异常
    .linearGradient({
      angle: 0,
      colors: [
        [ColorUtils.withAlpha(this.getAccentColor(), 0.45), 0],
        [ColorUtils.withAlpha(this.getAccentColor(), 0.20), 0.55],
        [this.themeColors.cardBackground, 1]
      ]
    })
    .borderRadius(16)
    .margin({ bottom: 16 })
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .shadow({
      radius: 12,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 4
    })
  }
}
