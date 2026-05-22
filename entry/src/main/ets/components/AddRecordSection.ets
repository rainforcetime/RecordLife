// 新增记录区域组件：components/AddRecordSection.ets
import { common } from '@kit.AbilityKit'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { NowViewModel } from '../viewmodel/NowViewModel'
import { LifeRecord } from '../common/types'
import { RefreshManager } from '../common/RefreshManager'
import { promptAction } from '@kit.ArkUI'
import { ImagePickerUtils, ImagePickMode } from '../common/utils/ImagePickerUtils'

@Component
export struct AddRecordSection {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 文字内容
  @State private textContent: string = ''
  
  // 图片路径
  @State private imagePath: string = ''
  @State private imageUri: string = ''
  
  // 是否正在保存
  @State private isSaving: boolean = false
  
  // ViewModel（直接获取单例实例）
  private viewModel: NowViewModel | null = null
  
  // 保存成功回调
  onSaveSuccess?: () => void
  
  // 组件初始化时获取 ViewModel
  aboutToAppear() {
    // 同步获取已初始化的 ViewModel 实例
    NowViewModel.getInstance().then((vm) => {
      this.viewModel = vm
      console.info('[AddRecordSection] ViewModel 获取成功')
    })
  }
  
  build() {
    Scroll() {
      Column() {
        // 标题
        Text('➕ 记录此刻')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .width('100%')
          .margin({ bottom: 16 })
        
        // 文字输入区域
        TextArea({ placeholder: '记录此刻的想法...', text: $$this.textContent })
          .width('100%')
          .height('40%')
          .backgroundColor(this.themeColors.cardBackground)
          .borderRadius(12)
          .border({ width: 1, color: this.themeColors.border })
          .fontColor(this.themeColors.textPrimary)
          .placeholderColor(this.themeColors.textTertiary)
          .padding(12)
        
        // 图片区域（可选）
        Column() {
          // 图片预览或添加按钮
          if (this.imageUri) {
            // 已添加图片
            Column() {
              Image(this.imageUri)
                .width(120)
                .height('auto')
                .objectFit(ImageFit.Contain)
                .borderRadius(8)
                .constraintSize({ maxHeight: 150 })
                .margin({ bottom: 8 })
              
              Row() {
                Button('拍照')
                  .fontSize(12)
                  .height(32)
                  .backgroundColor(this.themeColors.background)
                  .fontColor(this.themeColors.primary)
                  .borderRadius(8)
                  .onClick(() => {
                    this.onPickImage(ImagePickMode.CAMERA)
                  })
                
                Button('从相册选择')
                  .fontSize(12)
                  .height(32)
                  .backgroundColor(this.themeColors.background)
                  .fontColor(this.themeColors.primary)
                  .borderRadius(8)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.onPickImage(ImagePickMode.GALLERY)
                  })
                
                Button('移除')
                  .fontSize(12)
                  .height(32)
                  .backgroundColor(this.themeColors.background)
                  .fontColor(this.themeColors.error)
                  .borderRadius(8)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.imagePath = ''
                    this.imageUri = ''
                  })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          } else {
            // 添加图片按钮
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
        }
        .width('100%')
        .margin({ top: 16 })
        
        // 保存按钮
        Button(this.isSaving ? '保存中...' : '保存记录')
          .width('100%')
          .height(44)
          .backgroundColor(this.themeColors.primary)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .margin({ top: 16 })
          .enabled(!this.isSaving && this.canSave())
          .onClick(() => {
            this.onSave()
          })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .align(Alignment.Top)
  }
  
  // 判断是否可以保存（至少有文字或图片）
  private canSave(): boolean {
    return this.textContent.trim().length > 0 || this.imagePath.length > 0
  }
  
  // 选择图片（拍照或从相册选择）
  private async onPickImage(mode: ImagePickMode) {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const result = await ImagePickerUtils.pickImage(context, mode)
      
      if (result.success && result.uri) {
        // 保存图片到沙箱目录（返回 URI 格式）
        if (this.viewModel) {
          const savedUri = await this.viewModel.saveImageToSandbox(result.uri)
          if (savedUri) {
            this.imagePath = savedUri  // 存储 URI
            this.imageUri = savedUri   // 显示 URI（统一格式，无需转换）
          }
        }
      } else if (result.errorMessage) {
        ImagePickerUtils.showErrorToast(result.errorMessage)
      }
    } catch (error) {
      console.error('[AddRecordSection] 选择图片失败: ' + JSON.stringify(error))
      ImagePickerUtils.showErrorToast('选择图片失败，请重试')
    }
  }
  
  // 保存记录
  private async onSave() {
    if (!this.viewModel) {
      promptAction.showToast({ message: '数据管理器未初始化' })
      return
    }
    
    this.isSaving = true
    
    try {
      // 统一保存记录
      const record = await this.viewModel.addRecord(
        this.textContent.trim(),
        this.imagePath.length > 0 ? this.imagePath : undefined
      )
      
      if (record) {
        promptAction.showToast({ message: '记录保存成功' })
        
        // 清空输入
        this.textContent = ''
        this.imagePath = ''
        this.imageUri = ''
        
        // 触发全局刷新
        console.info('[AddRecordSection] 触发全局刷新')
        RefreshManager.getInstance().refresh()
        
        // 回调
        if (this.onSaveSuccess) {
          this.onSaveSuccess()
        }
      } else {
        promptAction.showToast({ message: '保存失败，请重试' })
      }
    } catch (error) {
      console.error('[AddRecordSection] 保存失败: ' + JSON.stringify(error))
      promptAction.showToast({ message: '保存失败: ' + (error as Error).message })
    } finally {
      this.isSaving = false
    }
  }
}
