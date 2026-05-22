// 编辑记录对话框组件：components/EditRecordDialog.ets
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { LifeRecord } from '../common/types'
import { ImagePickerUtils, ImagePickMode, ImagePickResult } from '../common/utils/ImagePickerUtils'
import { common } from '@kit.AbilityKit'

@Component
export struct EditRecordDialog {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 编辑的记录
  @Prop record: LifeRecord | null = null
  
  // 编辑内容
  @Link editContent: string
  
  // 图片路径和URI
  @Link editImagePath: string
  @Link editImageUri: string
  
  // 保存回调
  onSave: () => void = () => {}
  
  // 取消回调
  onCancel: () => void = () => {}
  
  // 保存图片到沙箱的回调（由父组件提供）
  saveImageToSandbox: ((uri: string) => Promise<string | null>) | null = null
  
  build() {
    Column() {
      Text('编辑记录')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .width('100%')
        .margin({ bottom: 16 })
      
      // 文字内容输入
      TextArea({ placeholder: '输入内容...', text: $$this.editContent })
        .width('100%')
        .height(100)
        .backgroundColor(this.themeColors.background)
        .borderRadius(12)
        .border({ width: 1, color: this.themeColors.border })
        .fontColor(this.themeColors.textPrimary)
        .padding(12)
      
      // 图片区域
      this.ImageSection()
      
      // 操作按钮
      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.themeColors.background)
          .fontColor(this.themeColors.textSecondary)
          .borderRadius(12)
          .onClick(() => {
            this.onCancel()
          })
        
        Button('保存')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.themeColors.primary)
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 12 })
          .onClick(() => {
            this.onSave()
          })
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(20)
  }
  
  // 图片区域
  @Builder
  ImageSection() {
    Column() {
      if (this.editImageUri) {
        // 已有图片
        this.ExistingImageSection()
      } else {
        // 添加图片按钮
        this.AddImageButtons()
      }
    }
    .width('100%')
    .margin({ top: 16 })
  }
  
  // 已有图片区域
  @Builder
  ExistingImageSection() {
    Column() {
      Image(this.editImageUri)
        .width('100%')
        .height('auto')
        .objectFit(ImageFit.Contain)
        .borderRadius(8)
        .constraintSize({ maxHeight: 200 })
        .margin({ bottom: 12 })
      
      Row() {
        Button('拍照')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.themeColors.background)
          .fontColor(this.themeColors.primary)
          .borderRadius(8)
          .onClick(() => {
            this.onPickImage(ImagePickMode.CAMERA)
          })
        
        Button('从相册选择')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.themeColors.background)
          .fontColor(this.themeColors.primary)
          .borderRadius(8)
          .margin({ left: 8 })
          .onClick(() => {
            this.onPickImage(ImagePickMode.GALLERY)
          })
        
        Button('移除')
          .width(60)
          .height(40)
          .backgroundColor(this.themeColors.background)
          .fontColor(this.themeColors.error)
          .borderRadius(8)
          .margin({ left: 8 })
          .onClick(() => {
            this.editImagePath = ''
            this.editImageUri = ''
          })
      }
      .width('100%')
    }
    .width('100%')
  }
  
  // 添加图片按钮
  @Builder
  AddImageButtons() {
    Row() {
      Button() {
        Column() {
          Text('📷')
            .fontSize(24)
          Text('拍照')
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .height(100)
      .backgroundColor(this.themeColors.background)
      .borderRadius(12)
      .border({ width: 1, color: this.themeColors.border, style: BorderStyle.Dashed })
      .onClick(() => {
        this.onPickImage(ImagePickMode.CAMERA)
      })
      
      Button() {
        Column() {
          Text('🖼️')
            .fontSize(24)
          Text('从相册选择')
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .height(100)
      .backgroundColor(this.themeColors.background)
      .borderRadius(12)
      .border({ width: 1, color: this.themeColors.border, style: BorderStyle.Dashed })
      .margin({ left: 12 })
      .onClick(() => {
        this.onPickImage(ImagePickMode.GALLERY)
      })
    }
    .width('100%')
  }
  
  // 选择图片
  private async onPickImage(mode: ImagePickMode) {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const result: ImagePickResult = await ImagePickerUtils.pickImage(context, mode)
      
      if (result.success && result.uri) {
        // 保存图片到沙箱目录
        if (this.saveImageToSandbox) {
          const savedUri = await this.saveImageToSandbox(result.uri)
          if (savedUri) {
            this.editImagePath = savedUri
            this.editImageUri = savedUri
          }
        }
      } else if (result.errorMessage) {
        ImagePickerUtils.showErrorToast(result.errorMessage)
      }
    } catch (error) {
      console.error('[EditRecordDialog] 选择图片失败: ' + JSON.stringify(error))
      ImagePickerUtils.showErrorToast('选择图片失败，请重试')
    }
  }
}
