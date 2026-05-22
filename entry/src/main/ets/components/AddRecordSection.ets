// 新增记录区域组件：components/AddRecordSection.ets
import { common } from '@kit.AbilityKit'
import { cameraPicker as picker, camera } from '@kit.CameraKit'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { NowViewModel } from '../viewmodel/NowViewModel'
import { RecordType, LifeRecord } from '../common/types'
import { RefreshManager } from '../common/RefreshManager'
import { promptAction } from '@kit.ArkUI'

@Component
export struct AddRecordSection {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 当前模式：'text' 或 'image'
  @State private currentMode: RecordType = 'text'
  
  // 文字内容
  @State private textContent: string = ''
  
  // 图片路径
  @State private imagePath: string = ''
  @State private imageUri: string = ''
  
  // 图片描述
  @State private imageDescription: string = ''
  
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
          .margin({ bottom: '10%' })
        
        // 模式选择
        Row() {
          // 文字模式按钮
          Column() {
            Text('📝')
              .fontSize(28)
            Text('文字')
              .fontSize(12)
              .fontColor(this.currentMode === 'text' ? this.themeColors.primary : this.themeColors.textSecondary)
              .margin({ top: 4 })
          }
          .width(80)
          .height(70)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.currentMode === 'text' ? this.themeColors.primaryLight : this.themeColors.cardBackground)
          .borderRadius(12)
          .border({
            width: this.currentMode === 'text' ? 2 : 1,
            color: this.currentMode === 'text' ? this.themeColors.primary : this.themeColors.border
          })
          .onClick(() => {
            this.currentMode = 'text'
          })
          
          // 图片模式按钮
          Column() {
            Text('📷')
              .fontSize(28)
            Text('拍照')
              .fontSize(12)
              .fontColor(this.currentMode === 'image' ? this.themeColors.primary : this.themeColors.textSecondary)
              .margin({ top: 4 })
          }
          .width(80)
          .height(70)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.currentMode === 'image' ? this.themeColors.primaryLight : this.themeColors.cardBackground)
          .borderRadius(12)
          .border({
            width: this.currentMode === 'image' ? 2 : 1,
            color: this.currentMode === 'image' ? this.themeColors.primary : this.themeColors.border
          })
          .margin({ left: 16 })
          .onClick(() => {
            this.currentMode = 'image'
            this.onTakePhoto()
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 16 })
        
        // 内容输入区域
        if (this.currentMode === 'text') {
          // 文字输入
          TextArea({ placeholder: '记录此刻的想法...', text: $$this.textContent })
            .width('100%')
            .height('60%')
            .backgroundColor(this.themeColors.cardBackground)
            .borderRadius(12)
            .border({ width: 1, color: this.themeColors.border })
            .fontColor(this.themeColors.textPrimary)
            .placeholderColor(this.themeColors.textTertiary)
            .padding(12)
        } else {
          // 图片预览和描述输入
          Column() {
            // 图片预览
            if (this.imageUri) {
              Image(this.imageUri)
                .width(120)
                .height('auto')
                .objectFit(ImageFit.Contain)
                .borderRadius(8)
                .constraintSize({ maxHeight: 150 })
                .margin({ bottom: 12 })
              
              // 重新拍摄按钮
              Button('重新拍摄')
                .fontSize(12)
                .height(32)
                .backgroundColor(this.themeColors.background)
                .fontColor(this.themeColors.primary)
                .borderRadius(8)
                .onClick(() => {
                  this.onTakePhoto()
                })
            } else {
              // 拍照提示
              Column() {
                Text('📷')
                  .fontSize(48)
                Text('点击上方拍照按钮')
                  .fontSize(14)
                  .fontColor(this.themeColors.textSecondary)
                  .margin({ top: 8 })
              }
              .width('100%')
              .height(120)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.themeColors.background)
              .borderRadius(12)
            }
            
            // 图片描述输入
            TextArea({ placeholder: '为这张照片添加描述...', text: $$this.imageDescription })
              .width('100%')
              .height('30%')
              .backgroundColor(this.themeColors.cardBackground)
              .borderRadius(12)
              .border({ width: 1, color: this.themeColors.border })
              .fontColor(this.themeColors.textPrimary)
              .placeholderColor(this.themeColors.textTertiary)
              .padding(12)
              .margin({ top: 12 })
          }
          .width('100%')
        }
        
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
  
  // 判断是否可以保存
  private canSave(): boolean {
    if (this.currentMode === 'text') {
      return this.textContent.trim().length > 0
    } else {
      return this.imagePath.length > 0
    }
  }
  
  // 拍照
  private async onTakePhoto() {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      
      // 配置相机设置
      const pickerProfile: picker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      }
      
      // 使用相机拍照
      const pickerResult: picker.PickerResult = await picker.pick(context, 
        [picker.PickerMediaType.PHOTO], 
        pickerProfile)
      
      if (pickerResult && pickerResult.resultUri && pickerResult.resultCode === 0) {
        console.info('[AddRecordSection] 拍照成功: ' + pickerResult.resultUri)
        
        // 保存图片到沙箱目录
        if (this.viewModel) {
          const savedPath = await this.viewModel.saveImageToSandbox(pickerResult.resultUri)
          if (savedPath) {
            this.imagePath = savedPath
            this.imageUri = this.viewModel.getImageUri(savedPath)
          }
        }
      }
    } catch (error) {
      console.error('[AddRecordSection] 拍照失败: ' + JSON.stringify(error))
      promptAction.showToast({ message: '拍照失败，请重试' })
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
      let record: LifeRecord | null = null
      
      if (this.currentMode === 'text') {
        // 保存文字记录
        record = await this.viewModel.addRecord('text', this.textContent.trim())
      } else {
        // 保存图片记录
        record = await this.viewModel.addRecord('image', this.imagePath, this.imageDescription.trim())
      }
      
      if (record) {
        promptAction.showToast({ message: '记录保存成功' })
        
        // 清空输入
        this.textContent = ''
        this.imagePath = ''
        this.imageUri = ''
        this.imageDescription = ''
        
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
