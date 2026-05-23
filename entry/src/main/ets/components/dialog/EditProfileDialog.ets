// 编辑资料弹窗组件
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

@CustomDialog
export struct EditProfileDialog {
  // 编辑字段状态
  @State editName: string = ''
  @State editBirthday: string = ''
  @State editGender: string = '男'
  @State selectedGenderIndex: number = 0

  // 性别选项
  private genderOptions: string[] = ['男', '女', '其他']

  // 回调函数
  onSave: (name: string, birthday: string, gender: string) => void = () => {}

  // 弹窗控制器
  controller: CustomDialogController

  // 接收父组件传递的数据
  @Prop userName: string = ''
  @Prop userBirthday: string = ''
  @Prop userGender: string = ''
  
  // 主题颜色配置
  @Prop themeColors: ThemeColors = ThemeConfig.getColors(false)

  aboutToAppear() {
    // 初始化编辑字段
    this.editName = this.userName
    this.editBirthday = this.userBirthday
    this.editGender = this.userGender
    this.selectedGenderIndex = this.genderOptions.indexOf(this.userGender)
    if (this.selectedGenderIndex < 0) {
      this.selectedGenderIndex = 0
    }
  }

  build() {
    Column() {
      // 标题
      Text('编辑资料')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ top: 20, bottom: 20 })

      // 用户名输入
      Column() {
        Text('用户名')
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
          .width('100%')
          .margin({ bottom: 8 })

        TextInput({ text: this.editName, placeholder: '请输入用户名' })
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

      // 出生日期选择
      Column() {
        Text('出生日期')
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
          .width('100%')
          .margin({ bottom: 8 })

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
      .margin({ bottom: 20 })

      // 性别选择
      Column() {
        Text('性别')
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
          .width('100%')
          .margin({ bottom: 8 })

        Row() {
          ForEach(this.genderOptions, (option: string, index: number) => {
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
      }
      .width('100%')
      .margin({ bottom: 30 })

      // 操作按钮
      Row() {
        Button('取消')
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

        Button('保存')
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
            this.onSave(this.editName.trim(), this.editBirthday, this.editGender)

            // 关闭弹窗
            this.controller.close()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 20 })
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
      console.error('日期解析失败: ' + error)
    }
    // 返回默认日期
    return new Date(1990, 0, 1)
  }
}
