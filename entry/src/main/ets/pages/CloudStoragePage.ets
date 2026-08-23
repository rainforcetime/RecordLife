// 云存储设置页面：pages/CloudStoragePage.ets（图片存储优化：由弹窗改为独立可滚动页面）
import { common } from '@kit.AbilityKit'
import { promptAction, PromptAction } from '@kit.ArkUI'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { CosConfig } from '../model/UserConfigModel'
import { CosService } from '../service/CosService'
import { NowViewModel } from '../viewmodel/NowViewModel'
import { ConfigManager } from '../config/ConfigManager'
import { Logger } from '../common/utils/Logger'

@Entry
@Component
struct CloudStoragePage {
  // 主题颜色配置（响应式）
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  private context: common.UIAbilityContext | null = null
  private configManager: ConfigManager | null = null
  private promptAction: PromptAction = this.getUIContext().getPromptAction()

  // 表单状态
  @State region: string = ''
  @State bucket: string = ''
  @State secretId: string = ''
  @State secretKey: string = ''
  @State customDomain: string = ''
  @State dedupeUpload: boolean = true
  @State deleteOriginalAfterUpload: boolean = true
  @State compressMode: string = 'balanced'
  @State testing: boolean = false
  @State uploading: boolean = false
  @State progress: number = 0
  @State progressTotal: number = 0
  @State saving: boolean = false

  // 页面初始化
  async aboutToAppear() {
    try {
      this.context = this.getUIContext().getHostContext() as common.UIAbilityContext
      this.configManager = await ConfigManager.getInstance(this.context)
      const cos = this.configManager.getCosConfig()
      // 已保存配置回填；未保存时留空由用户填写（代码中不内置任何账号信息）
      this.region = cos && cos.region.length > 0 ? cos.region : ''
      this.bucket = cos && cos.bucket.length > 0 ? cos.bucket : ''
      this.secretId = cos && cos.secretId.length > 0 ? cos.secretId : ''
      this.secretKey = cos ? cos.secretKey : ''
      this.customDomain = cos && cos.customDomain ? cos.customDomain : ''
      this.dedupeUpload = cos ? cos.dedupeUpload !== false : true
      this.deleteOriginalAfterUpload = cos ? cos.deleteOriginalAfterUpload !== false : true
      this.compressMode = cos && cos.compressMode ? cos.compressMode : 'balanced'
    } catch (error) {
      Logger.error('[CloudStoragePage] 初始化失败: ' + JSON.stringify(error))
    }
  }

  // 表单是否完整
  private isFormComplete(): boolean {
    return this.region.length > 0 && this.bucket.length > 0 &&
      this.secretId.length > 0 && this.secretKey.length > 0
  }

  // 当前表单配置
  private buildConfig(): CosConfig {
    return {
      region: this.region,
      bucket: this.bucket,
      secretId: this.secretId,
      secretKey: this.secretKey,
      customDomain: this.customDomain.length > 0 ? this.customDomain : undefined,
      dedupeUpload: this.dedupeUpload,
      deleteOriginalAfterUpload: this.deleteOriginalAfterUpload,
      compressMode: this.compressMode,
      enabled: true
    }
  }

  // 测试连接
  private async onTest() {
    if (!this.isFormComplete()) {
      this.promptAction.showToast({ message: $r('app.string.cloud_test_failed'), duration: 2000 })
      return
    }
    this.testing = true
    const ok = await CosService.testConnection(this.buildConfig())
    this.testing = false
    this.promptAction.showToast({
      message: ok ? $r('app.string.cloud_test_success') : $r('app.string.cloud_test_failed'),
      duration: 2000
    })
  }

  // 保存配置
  private async onSave() {
    if (!this.isFormComplete()) {
      return
    }
    if (!this.configManager) {
      return
    }
    this.saving = true
    const ok = await this.configManager.setCosConfig(this.buildConfig())
    this.saving = false
    if (ok) {
      this.promptAction.showToast({ message: $r('app.string.cloud_saved'), duration: 2000 })
    }
  }

  // 上传全部图片（历史图片补传 + 失败重试）
  private async onUploadAll() {
    if (!this.isFormComplete() || !this.context) {
      this.promptAction.showToast({ message: $r('app.string.cloud_test_failed'), duration: 2000 })
      return
    }
    // 先保存当前表单配置，确保上传使用最新配置
    if (this.configManager) {
      await this.configManager.setCosConfig(this.buildConfig())
    }
    this.uploading = true
    this.progress = 0
    this.progressTotal = 0
    try {
      const result = await NowViewModel.uploadAllImages(this.context, (current: number, total: number) => {
        this.progress = current
        this.progressTotal = total
      })
      if (result.failed > 0 && result.uploaded === 0 && result.skipped === 0) {
        this.promptAction.showToast({
          message: $r('app.string.cloud_upload_all_failed', result.failed),
          duration: 2500
        })
      } else if (result.skipped > 0 && result.uploaded === 0 && result.failed === 0) {
        this.promptAction.showToast({
          message: $r('app.string.cloud_upload_all_skipped', result.skipped),
          duration: 2500
        })
      } else if (result.uploaded > 0 || result.skipped > 0) {
        this.promptAction.showToast({
          message: result.failed > 0 ?
            $r('app.string.cloud_upload_all_partial', result.uploaded, result.failed) :
            $r('app.string.cloud_upload_all_done', result.uploaded + result.skipped),
          duration: 2500
        })
      } else {
        this.promptAction.showToast({
          message: $r('app.string.cloud_upload_all_none'),
          duration: 2500
        })
      }
    } catch (error) {
      Logger.error('[CloudStoragePage] 上传全部图片失败: ' + JSON.stringify(error))
      this.promptAction.showToast({ message: $r('app.string.cloud_upload_all_failed'), duration: 2000 })
    } finally {
      this.uploading = false
    }
  }

  // 返回
  private goBack() {
    this.getUIContext().getRouter().back()
  }

  build() {
    Column() {
      // 页面标题
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([this.themeColors.iconColor])
          .onClick(() => {
            this.goBack()
          })

        Text($r('app.string.cloud_storage'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ left: 12 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      Scroll() {
        Column() {
          Text($r('app.string.cloud_secret_warning'))
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
            .width('100%')
            .margin({ bottom: 8 })

          // 表单
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
          this.Field($r('app.string.cos_custom_domain'), this.customDomain, false, (v: string) => {
            this.customDomain = v
          })

          Text($r('app.string.cos_domain_hint'))
            .fontSize(11)
            .fontColor(this.themeColors.textSecondary)
            .width('100%')
            .margin({ top: 4 })

          // 上传前去重开关（省流量）
          this.SwitchRow($r('app.string.cloud_dedupe_upload'), $r('app.string.cloud_dedupe_summary'),
            this.dedupeUpload, (isOn: boolean) => {
              this.dedupeUpload = isOn
            })

          // 上传后删除原图开关（省空间）
          this.SwitchRow($r('app.string.cloud_delete_original'), $r('app.string.cloud_delete_original_summary'),
            this.deleteOriginalAfterUpload, (isOn: boolean) => {
              this.deleteOriginalAfterUpload = isOn
            })

          // 压缩画质档位
          Column() {
            Text($r('app.string.cloud_compress_quality'))
              .fontSize(15)
              .fontColor(this.themeColors.textPrimary)
              .width('100%')
            Text($r('app.string.cloud_compress_quality_summary'))
              .fontSize(11)
              .fontColor(this.themeColors.textSecondary)
              .width('100%')
              .margin({ top: 2 })

            Row({ space: 8 }) {
              this.CompressOption($r('app.string.cloud_compress_high'), 'high')
              this.CompressOption($r('app.string.cloud_compress_balanced'), 'balanced')
              this.CompressOption($r('app.string.cloud_compress_compact'), 'compact')
            }
            .width('100%')
            .margin({ top: 8 })
          }
          .width('100%')
          .padding({ top: 8 })

          // 测试连接 + 保存
          Row({ space: 12 }) {
            Button($r('app.string.cloud_test'))
              .fontSize(14)
              .height(44)
              .layoutWeight(1)
              .backgroundColor(this.themeColors.background)
              .fontColor(this.themeColors.primary)
              .borderRadius(22)
              .enabled(!this.testing)
              .onClick(() => {
                this.onTest()
              })

            Button($r('app.string.save'))
              .fontSize(14)
              .height(44)
              .layoutWeight(1)
              .backgroundColor(this.themeColors.primary)
              .fontColor(Color.White)
              .borderRadius(22)
              .enabled(this.isFormComplete() && !this.saving)
              .onClick(() => {
                this.onSave()
              })
          }
          .width('100%')
          .margin({ top: 20 })

          // 上传全部图片（历史图片补传 + 失败重试）
          if (this.uploading) {
            Column() {
              Row() {
                Text($r('app.string.cloud_uploading'))
                  .fontSize(13)
                  .fontColor(this.themeColors.textSecondary)
                Blank()
                Text(`${this.progress} / ${this.progressTotal}`)
                  .fontSize(13)
                  .fontColor(this.themeColors.textSecondary)
              }
              .width('100%')
              .margin({ bottom: 6 })

              Progress({ value: this.progress, total: this.progressTotal > 0 ? this.progressTotal : 1, type: ProgressType.Linear })
                .width('100%')
                .height(6)
                .color(this.themeColors.primary)
                .backgroundColor(this.themeColors.divider)
                .borderRadius(3)
            }
            .width('100%')
            .margin({ top: 12 })
          } else {
            Button($r('app.string.cloud_upload_all'))
              .fontSize(14)
              .height(44)
              .width('100%')
              .margin({ top: 12 })
              .backgroundColor(this.themeColors.primary)
              .fontColor(Color.White)
              .borderRadius(22)
              .enabled(this.isFormComplete() && !this.testing)
              .onClick(() => {
                this.onUploadAll()
              })
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 32 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
  }

  // 开关行
  @Builder
  SwitchRow(label: ResourceStr, summary: ResourceStr, isOn: boolean, onChange: (isOn: boolean) => void) {
    Row() {
      Column() {
        Text(label)
          .fontSize(15)
          .fontColor(this.themeColors.textPrimary)
        Text(summary)
          .fontSize(11)
          .fontColor(this.themeColors.textSecondary)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(this.themeColors.primary)
        .onChange((on: boolean) => {
          onChange(on)
        })
    }
    .width('100%')
    .padding({ top: 12 })
  }

  // 压缩档位选项按钮
  @Builder
  CompressOption(label: ResourceStr, mode: string) {
    Button(label)
      .fontSize(12)
      .height(36)
      .layoutWeight(1)
      .backgroundColor(this.compressMode === mode ? this.themeColors.primary : this.themeColors.background)
      .fontColor(this.compressMode === mode ? Color.White : this.themeColors.textSecondary)
      .borderRadius(18)
      .onClick(() => {
        this.compressMode = mode
      })
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
        .height(42)
        .padding({ left: 12, right: 12 })
        .onChange((v: string) => {
          onChange(v)
        })
    }
    .width('100%')
    .margin({ top: 10 })
  }
}
