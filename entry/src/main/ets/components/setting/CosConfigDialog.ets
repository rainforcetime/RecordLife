/**
 * 云存储配置弹窗（图片存储优化 M2）
 * 腾讯云 COS 参数填写 + 测试连接 + 保存；App 不内置任何密钥（用户自填防泄露）
 */
import { promptAction, PromptAction } from '@kit.ArkUI'
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { CosConfig } from '../../model/UserConfigModel'
import { CosService } from '../../service/CosService'
import { Logger } from '../../common/utils/Logger'

@CustomDialog
export struct CosConfigDialog {
  controller: CustomDialogController
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  config: CosConfig = { region: '', bucket: '', secretId: '', secretKey: '' }
  onSaved: (config: CosConfig) => void = () => {}

  @State region: string = ''
  @State bucket: string = ''
  @State secretId: string = ''
  @State secretKey: string = ''
  @State testing: boolean = false
  private promptAction: PromptAction | null = null

  aboutToAppear() {
    this.region = this.config.region
    this.bucket = this.config.bucket
    this.secretId = this.config.secretId
    this.secretKey = this.config.secretKey
    this.promptAction = this.getUIContext().getPromptAction()
  }

  // 表单是否完整
  private isFormComplete(): boolean {
    return this.region.length > 0 && this.bucket.length > 0 &&
      this.secretId.length > 0 && this.secretKey.length > 0
  }

  // 测试连接
  private async onTest() {
    if (!this.promptAction) {
      return
    }
    if (!this.isFormComplete()) {
      this.promptAction.showToast({ message: $r('app.string.cloud_test_failed'), duration: 2000 })
      return
    }
    this.testing = true
    const ok = await CosService.testConnection({
      region: this.region,
      bucket: this.bucket,
      secretId: this.secretId,
      secretKey: this.secretKey
    })
    this.testing = false
    try {
      this.promptAction.showToast({
        message: ok ? $r('app.string.cloud_test_success') : $r('app.string.cloud_test_failed'),
        duration: 2000
      })
    } catch (error) {
      Logger.error('[CosConfigDialog] showToast 失败: ' + JSON.stringify(error))
    }
  }

  // 保存配置
  private onSave() {
    if (!this.isFormComplete()) {
      return
    }
    this.onSaved({
      region: this.region,
      bucket: this.bucket,
      secretId: this.secretId,
      secretKey: this.secretKey
    })
    this.controller.close()
  }

  // 表单字段
  @Builder
  Field(label: ResourceStr, value: string, isPassword: boolean, onChange: (v: string) => void) {
    Column() {
      Text(label)
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 4 })
      TextInput({ text: value })
        .type(isPassword ? InputType.Password : InputType.Normal)
        .fontSize(15)
        .fontColor(this.themeColors.textPrimary)
        .backgroundColor(this.themeColors.background)
        .borderRadius(8)
        .height(40)
        .padding({ left: 12, right: 12 })
        .onChange((v: string) => {
          onChange(v)
        })
    }
    .width('100%')
    .margin({ top: 8 })
  }

  build() {
    Column() {
      Text($r('app.string.cloud_storage'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ bottom: 6 })

      Text($r('app.string.cloud_secret_warning'))
        .fontSize(12)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 4 })

      this.Field($r('app.string.cos_region'), this.region, false, (v: string) => {
        this.region = v
      })
      this.Field($r('app.string.cos_bucket'), this.bucket, false, (v: string) => {
        this.bucket = v
      })
      this.Field($r('app.string.cos_secret_id'), this.secretId, false, (v: string) => {
        this.secretId = v
      })
      this.Field($r('app.string.cos_secret_key'), this.secretKey, true, (v: string) => {
        this.secretKey = v
      })

      // 测试连接 + 保存
      Row() {
        Button($r('app.string.cloud_test'))
          .fontSize(14)
          .height(40)
          .layoutWeight(1)
          .backgroundColor(this.themeColors.background)
          .fontColor(this.themeColors.primary)
          .borderRadius(20)
          .enabled(!this.testing)
          .onClick(() => {
            this.onTest()
          })

        Blank()
          .width(12)

        Button($r('app.string.save'))
          .fontSize(14)
          .height(40)
          .layoutWeight(1)
          .backgroundColor(this.themeColors.primary)
          .fontColor(Color.White)
          .borderRadius(20)
          .enabled(this.isFormComplete())
          .onClick(() => {
            this.onSave()
          })
      }
      .width('100%')
      .margin({ top: 16 })

      Button($r('app.string.cancel'))
        .fontSize(14)
        .height(40)
        .width('100%')
        .margin({ top: 8 })
        .backgroundColor(this.themeColors.background)
        .fontColor(this.themeColors.textSecondary)
        .borderRadius(20)
        .onClick(() => {
          this.controller.close()
        })
    }
    .width('82%')
    .padding(20)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
  }
}
