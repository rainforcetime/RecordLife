// 用户信息区域组件：components/UserInfoSection.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { ColorUtils } from '../../common/ColorUtils'
import { ResourceUtils } from '../../common/utils/ResourceUtils'

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
  
  // 使用天数统计（我的页 UI 重构：填充右侧信息区）
  @Prop usageDays: number = 0
  
  // 编辑资料回调
  onEditProfile?: () => void
  
  // 更换头像回调
  onChangeAvatar?: () => void
  
  // 获取性别展示符号（♂/♀；其他性别不显示符号，我的页 UI 重构）
  private getGenderSymbol(): string {
    const rm = this.getUIContext().getHostContext()?.resourceManager
    if (rm) {
      if (this.userInfo.userGender === ResourceUtils.getString(rm, 'male')) {
        return '♂'
      }
      if (this.userInfo.userGender === ResourceUtils.getString(rm, 'female')) {
        return '♀'
      }
    }
    return ''
  }
  
  // 获取性别符号颜色（业内通用：♂ 蓝 / ♀ 粉）
  private getGenderColor(): string {
    const rm = this.getUIContext().getHostContext()?.resourceManager
    if (rm) {
      if (this.userInfo.userGender === ResourceUtils.getString(rm, 'male')) {
        return '#4A90D9'
      }
      if (this.userInfo.userGender === ResourceUtils.getString(rm, 'female')) {
        return '#E8547E'
      }
    }
    return ''
  }

  build() {
    Column() {
      // 头像 + 信息行（左对齐式，业内通用个人信息卡结构）
      Row() {
        // 头像展示（可点击更换；去装饰圈，头像 76）
        Stack({ alignContent: Alignment.BottomEnd }) {
          // 头像本体
          if (this.userInfo.hasCustomAvatar && this.userInfo.userAvatar) {
            Image(this.userInfo.userAvatar)
              .width(76)
              .height(76)
              .borderRadius(38)
              .border({ width: 3, color: this.themeColors.primary })
          } else {
            Column() {
              SymbolGlyph($r('sys.symbol.person_fill'))
                .fontSize(40)
                .fontColor([this.themeColors.textSecondary])
            }
            .width(76)
            .height(76)
            .borderRadius(38)
            .backgroundColor(this.themeColors.divider)
            .justifyContent(FlexAlign.Center)
            .border({ width: 3, color: this.themeColors.primary })
          }

          // 相机角标（右下留 2px 边距，与头像分离）
          Column() {
            SymbolGlyph($r('sys.symbol.camera_circle_fill'))
              .fontSize(18)
              .fontColor([Color.White])
          }
          .width(26)
          .height(26)
          .borderRadius(13)
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
        .width(76)
        .height(76)
        .margin({ right: 14 })
        .onClick(() => {
          if (this.onChangeAvatar) {
            this.onChangeAvatar()
          }
        })

        // 右侧信息
        Column() {
          // 昵称 + 性别符号（性别 14 Medium，紧跟昵称右侧）
          Row() {
            Text(this.userInfo.userName)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            if (this.getGenderSymbol().length > 0) {
              Text(this.getGenderSymbol())
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.getGenderColor())
                .margin({ left: 5 })
            }
          }
          .width('100%')

          // 签名/座右铭（✎ 图标 + 文本，有值才展示）
          if (this.userInfo.userSignature && this.userInfo.userSignature.length > 0) {
            Row() {
              SymbolGlyph($r('sys.symbol.square_and_pencil'))
                .fontSize(12)
                .fontColor([this.themeColors.textTertiary])
                .margin({ right: 5, top: 2 })

              Text(this.userInfo.userSignature)
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .margin({ top: 5 })
          }

          // 统计行（使用天数，填充右侧信息区）
          Row() {
            SymbolGlyph($r('sys.symbol.calendar'))
              .fontSize(12)
              .fontColor([this.themeColors.textTertiary])
              .margin({ right: 5, top: 1 })

            Text($r('app.string.used_days', this.usageDays))
              .fontSize(13)
              .fontColor(this.themeColors.textSecondary)
          }
          .width('100%')
          .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 编辑资料按钮（横贯底部，业内通用）
      Button() {
        Row() {
          SymbolGlyph($r('sys.symbol.square_and_pencil'))
            .fontSize(15)
            .fontColor([this.themeColors.primary])
            .margin({ right: 6 })
          Text($r('app.string.edit_profile'))
            .fontSize(15)
            .fontColor(this.themeColors.primary)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .height(38)
      .backgroundColor(ColorUtils.primaryExtraLight(this.themeColors.primary))
      .borderRadius(19)
      .margin({ top: 14 })
      .onClick(() => {
        if (this.onEditProfile) {
          this.onEditProfile()
        }
      })
    }
    .width('90%')
    // 纯色卡片 + 顶部主题色细条（border 顶部 3px，替代渐变，我的页 UI 重构）
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
    .border({
      width: { top: 3, right: 0, bottom: 0, left: 0 },
      color: {
        top: this.themeColors.primary,
        right: Color.Transparent,
        bottom: Color.Transparent,
        left: Color.Transparent
      }
    })
    .margin({ bottom: 16 })
    .padding({ left: 20, right: 20, top: 18, bottom: 18 })
    .shadow({
      radius: 12,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 4
    })
  }
}
