// 编辑资料弹窗组件
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { ResourceUtils } from '../../common/utils/ResourceUtils'
import { Logger } from '../../common/utils/Logger'

@CustomDialog
export struct EditProfileDialog {
  // 编辑字段状态
  @State editName: string = ''
  @State editBirthday: string = ''
  @State editGender: string = ''
  @State selectedGenderIndex: number = 0
  @State editSignature: string = ''

  // 回调函数
  onSave: (name: string, birthday: string, gender: string, signature: string) => void = () => {}

  // 弹窗控制器
  controller: CustomDialogController

  // 接收父组件传递的数据
  @Prop userName: string = ''
  @Prop userBirthday: string = ''
  @Prop userGender: string = ''
  @Prop userSignature: string = ''
  
  // 主题颜色配置
  @Prop themeColors: ThemeColors = ThemeConfig.getColors(false)

  aboutToAppear() {
    // 初始化编辑字段
    this.editName = this.userName
    this.editBirthday = this.userBirthday
    this.editGender = this.userGender
    this.editSignature = this.userSignature
    this.selectedGenderIndex = this.getGenderOptions().indexOf(this.userGender)
    if (this.selectedGenderIndex < 0) {
      this.selectedGenderIndex = 0
    }
  }

  // 性别选项（国际化：读资源）
  private getGenderOptions(): string[] {
    const rm = this.getUIContext().getHostContext()?.resourceManager
    if (!rm) {
      return []
    }
    return [ResourceUtils.getString(rm, 'male'), ResourceUtils.getString(rm, 'female'), ResourceUtils.getString(rm, 'gender_other')]
  }

  build() {
    Column() {
      // 标题
      Text($r('app.string.edit_profile'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ top: 20, bottom: 20 })

      // 可滚动内容区（签名输入框上移 + Scroll：输入法弹出时可滚动到输入框）
      Scroll() {
        Column() {
          // 用户名输入
          Column() {
            Text($r('app.string.username'))
              .fontSize(14)
              .fontColor(this.themeColors.textSecondary)
              .width('100%')
              .margin({ bottom: 8 })

            TextInput({ text: this.editName, placeholder: $r('app.string.input_username') })
              .fontSize(16)
              .height(45)
              .backgroundColor(this.themeColors.background)
              .fontColor(this.themeColors.textPrimary)
              .placeholderColor(this.themeColors.textTertiary)
              .borderRadius(8)
              .onChange((value: string) => {
                this.editName = value
              })
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 签名/座右铭输入（更新计划一期；上移：键盘弹出时可见）
          Column() {
            Text($r('app.string.signature'))
              .fontSize(14)
              .fontColor(this.themeColors.textSecondary)
              .width('100%')
              .margin({ bottom: 8 })

            TextInput({ text: this.editSignature, placeholder: $r('app.string.signature_hint') })
              .fontSize(16)
              .height(45)
              .backgroundColor(this.themeColors.background)
              .fontColor(this.themeColors.textPrimary)
              .placeholderColor(this.themeColors.textTertiary)
              .borderRadius(8)
              .onChange((value: string) => {
                this.editSignature = value
              })
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 出生日期选择
          Column() {
            Text($r('app.string.birth_date'))
              .fontSize(14)
              .fontColor(this.themeColors.textSecondary)
              .width('100%')
              .margin({ bottom: 8 })

            Column() {
              DatePicker({
                selected: this.parseDate(this.editBirthday)
              })
                .lunar(false)
                .onDateChange((value: Date) => {
                  // 格式化日期为 YYYY-MM-DD
                  const year = value.getFullYear()
                  const month = (value.getMonth() + 1).toString().padStart(2, '0')
                  const day = value.getDate().toString().padStart(2, '0')
                  this.editBirthday = `${year}-${month}-${day}`
                })
            }
            .width('100%')
            .backgroundColor(this.themeColors.background)
            .borderRadius(8)
            .padding(8)
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 性别选择
          Column() {
            Text($r('app.string.gender'))
              .fontSize(14)
              .fontColor(this.themeColors.textSecondary)
              .width('100%')
              .margin({ bottom: 8 })

            Row() {
              ForEach(this.getGenderOptions(), (option: string, index: number) => {
                Row() {
                  Radio({ value: option, group: 'genderGroup' })
                    .checked(this.selectedGenderIndex === index)
                    .onChange((isChecked: boolean) => {
                      if (isChecked) {
                        this.selectedGenderIndex = index
                        this.editGender = option
                      }
                    })
                    .width(20)
                    .height(20)

                  Text(option)
                    .fontSize(16)
                    .fontColor(this.themeColors.textPrimary)
                    .margin({ left: 8 })
                }
                .margin({ right: 20 })
              })
            }
            .width('100%')
            .backgroundColor(this.themeColors.background)
            .borderRadius(8)
            .padding(12)
          }
          .width('100%')
          .margin({ bottom: 20 })
        }
        .width('100%')
      }
      .width('100%')
      .height('65%')
      .scrollBar(BarState.Off)

      // 操作按钮
      Row() {
        Button($r('app.string.cancel'))
          .fontSize(16)
          .backgroundColor(this.themeColors.border)
          .fontColor(this.themeColors.textPrimary)
          .borderRadius(20)
          .width(100)
          .height(40)
          .onClick(() => {
            this.controller.close()
          })

        Blank().width(20)

        Button($r('app.string.save'))
          .fontSize(16)
          .backgroundColor(this.themeColors.primary)
          .fontColor(Color.White)
          .borderRadius(20)
          .width(100)
          .height(40)
          .onClick(() => {
            // 验证输入
            if (this.editName.trim().length === 0) {
              return
            }

            // 调用保存回调
            this.onSave(this.editName.trim(), this.editBirthday, this.editGender, this.editSignature.trim())

            // 关闭弹窗
            this.controller.close()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 10, bottom: 20 })
    }
    .width(320)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(15)
    .padding({ left: 20, right: 20 })
  }

  // 解析日期字符串
  private parseDate(dateStr: string): Date {
    try {
      const parts = dateStr.split('-')
      if (parts.length === 3) {
        const year = parseInt(parts[0])
        const month = parseInt(parts[1]) - 1 // Date的月份从0开始
        const day = parseInt(parts[2])
        return new Date(year, month, day)
      }
    } catch (error) {
      Logger.error('日期解析失败: ' + error)
    }
    // 返回默认日期
    return new Date(1990, 0, 1)
  }
}
