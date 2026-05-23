// 记录卡片组件：components/RecordCard.ets
import { LifeRecord } from '../../common/types'
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { NowViewModel } from '../../viewmodel/NowViewModel'
import { ImageViewer } from '../common/ImageViewer'
import { TagDisplay } from '../common/TagSelector'
import { ShareRecordCard } from '../share/ShareRecordCard'
import { ShareUtils } from '../../utils/ShareUtils'
import { common } from '@kit.AbilityKit'

// 记录卡片操作回调
interface RecordCardCallbacks {
  onEdit: (record: LifeRecord) => void
  onDelete: (record: LifeRecord) => void
}

// 文本分段（用于高亮显示）
interface TextSegment {
  text: string
  isHighlight: boolean
}

@Component
export struct RecordCard {
  @Prop record: LifeRecord = { id: '', timestamp: 0, content: '' }
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 是否显示日期（默认显示）
  @Prop showDate: boolean = true
  
  // 搜索关键词（用于高亮）
  @Prop searchKeyword: string = ''
  
  // 回调函数
  onEdit?: (record: LifeRecord) => void
  onDelete?: (record: LifeRecord) => void
  
  // ViewModel
  private viewModel: NowViewModel | null = null
  
  // 图片预览状态
  @State private showImageViewer: boolean = false
  @State private viewerImageUris: string[] = []
  @State private viewerCurrentIndex: number = 0
  
  // 分享相关状态
  @State private showShareDialog: boolean = false
  @State private isSharing: boolean = false
  
  // 分享卡片组件ID（使用记录ID确保唯一性）
  private shareCardId: string = ''
  
  async aboutToAppear() {
    this.viewModel = await NowViewModel.getInstance()
    // 初始化分享卡片ID
    this.shareCardId = `share_card_${this.record.id}`
  }
  
  build() {
    Column() {
      Column() {
        // 标签显示（如果有）
        if (this.record.tags && this.record.tags.length > 0) {
          TagDisplay({ tagIds: this.record.tags })
            .margin({ bottom: 8 })
        }
        
        // 文字内容（如果有）
        if (this.record.content && this.record.content.length > 0) {
          // 使用高亮文本显示
          this.HighlightText(this.record.content, this.searchKeyword)
        }
        
        // 图片网格（如果有）
        if (this.record.imagePaths && this.record.imagePaths.length > 0 && this.viewModel) {
          // 单张图片：大图展示
          if (this.record.imagePaths.length === 1) {
            Image(this.viewModel.getImageUri(this.record.imagePaths[0]))
              .width('100%')
              .height('auto')
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
              .constraintSize({ maxHeight: 300 })
              .margin({ top: this.record.content ? 12 : 0 })
              .onClick(() => {
                this.openImageViewer([this.viewModel!.getImageUri(this.record.imagePaths![0])], 0)
              })
          } else {
            // 多张图片：网格布局（一行三张，正方形）
            Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
              ForEach(this.record.imagePaths, (path: string, index: number) => {
                Image(this.viewModel!.getImageUri(path))
                  .width('32%')
                  .aspectRatio(1)  // 正方形
                  .objectFit(ImageFit.Cover)
                  .borderRadius(4)
                  .margin({ right: index % 3 === 2 ? 0 : '2%', bottom: index < this.record.imagePaths!.length - 3 ? 4 : 0 })
                  .onClick(() => {
                    this.openImageViewerFromPath(index)
                  })
              }, (path: string, index: number) => `image-${index}`)
            }
            .width('100%')
            .margin({ top: this.record.content ? 12 : 0 })
          }
        }
        
        // 底部信息栏：时间 + 操作按钮
        Row() {
          // 时间戳
          Text(this.formatTime(this.record.timestamp))
            .fontSize(13)
            .fontColor(this.themeColors.textSecondary)
          
          Blank()
          
          // 操作按钮
          this.ActionButtons()
        }
        .width('100%')
        .margin({ top: this.record.content || (this.record.imagePaths && this.record.imagePaths.length > 0) ? 12 : 0 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .bindContentCover($$this.showImageViewer, this.ImageViewerBuilder(), {
        modalTransition: ModalTransition.DEFAULT
      })
    }
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .shadow({
      radius: 8,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 2
    })
    .width('100%')
    .bindSheet($$this.showShareDialog, this.ShareDialogBuilder(), {
      height: 'auto',
      backgroundColor: 'transparent',
      dragBar: false
    })
  }
  
  // 高亮文本构建器
  @Builder
  HighlightText(text: string, keyword: string) {
    if (keyword.length === 0) {
      // 无关键词，直接显示原文
      Text(text)
        .fontSize(15)
        .fontColor(this.themeColors.textPrimary)
        .width('100%')
        .lineHeight(22)
    } else {
      // 有关键词，分段高亮显示
      Text() {
        ForEach(this.splitTextByKeyword(text, keyword), (segment: TextSegment) => {
          Span(segment.text)
            .fontSize(15)
            .fontColor(segment.isHighlight ? this.themeColors.primary : this.themeColors.textPrimary)
            .fontWeight(segment.isHighlight ? FontWeight.Bold : FontWeight.Normal)
        }, (segment: TextSegment, index: number) => `segment-${index}`)
      }
      .width('100%')
      .lineHeight(22)
    }
  }
  
  // 将文本按关键词分割
  private splitTextByKeyword(text: string, keyword: string): TextSegment[] {
    const segments: TextSegment[] = []
    const lowerText = text.toLowerCase()
    const lowerKeyword = keyword.toLowerCase()
    
    let lastIndex = 0
    let currentIndex = lowerText.indexOf(lowerKeyword)
    
    while (currentIndex !== -1) {
      // 添加关键词前的普通文本
      if (currentIndex > lastIndex) {
        segments.push({
          text: text.substring(lastIndex, currentIndex),
          isHighlight: false
        })
      }
      
      // 添加高亮的关键词（保持原文大小写）
      segments.push({
        text: text.substring(currentIndex, currentIndex + keyword.length),
        isHighlight: true
      })
      
      lastIndex = currentIndex + keyword.length
      currentIndex = lowerText.indexOf(lowerKeyword, lastIndex)
    }
    
    // 添加剩余的普通文本
    if (lastIndex < text.length) {
      segments.push({
        text: text.substring(lastIndex),
        isHighlight: false
      })
    }
    
    return segments
  }
  
  // 打开图片预览（从路径数组）
  private openImageViewerFromPath(index: number) {
    console.info('[RecordCard] 进入图片打开事件')
    if (!this.viewModel || !this.record.imagePaths) {
      console.info('[RecordCard] 没有viewModel 或 imagePaths')
      return
    }
    console.info('[RecordCard] 不为空')
    
    const imageUris: string[] = []
    for (let i = 0; i < this.record.imagePaths.length; i++) {
      if (!this.viewModel || !this.record.imagePaths[i]) {
        console.info('[RecordCard] 没有viewModel 或 imagePaths[i]')
        continue
      }
      imageUris.push(this.viewModel.getImageUri(this.record.imagePaths[i]))
    }
    
    this.viewerImageUris = imageUris
    this.viewerCurrentIndex = index
    this.showImageViewer = true
  }
  
  // 打开图片预览
  private openImageViewer(uris: string[], index: number) {
    console.info('[RecordCard] openImageViewer')
    this.viewerImageUris = uris
    this.viewerCurrentIndex = index
    this.showImageViewer = true
  }
  
  // 图片预览构建器
  @Builder
  ImageViewerBuilder() {
    ImageViewer({
      imageUris: this.viewerImageUris,
      currentIndex: this.viewerCurrentIndex,
      onClose: () => {
        this.showImageViewer = false
      }
    })
  }
  
  // 操作按钮
  @Builder
  ActionButtons() {
    Row({ space: 16 }) {
      // 分享按钮
      Image($r('sys.media.ohos_ic_public_share'))
        .width(18)
        .height(18)
        .fillColor(this.themeColors.iconColor)
        .onClick(() => {
          this.showShareDialog = true
        })
      
      // 编辑按钮
      Image($r('sys.media.ohos_ic_public_edit'))
        .width(18)
        .height(18)
        .fillColor(this.themeColors.iconColor)
        .onClick(() => {
          if (this.onEdit) {
            this.onEdit(this.record)
          }
        })
      
      // 删除按钮
      Image($r('sys.media.ohos_ic_public_remove'))
        .width(18)
        .height(18)
        .fillColor(this.themeColors.error)
        .onClick(() => {
          if (this.onDelete) {
            this.onDelete(this.record)
          }
        })
    }
  }
  
  // 分享弹窗构建器
  @Builder
  ShareDialogBuilder() {
    Column() {
      // 分享卡片预览区域
      Column() {
        // 分享卡片（固定宽度，居中显示）
        Column() {
          ShareRecordCard({ record: this.record })
            .id(this.shareCardId)  // 设置组件ID用于截图
        }
        .width(340)
      }
      .width('100%')
      .padding(20)
      
      // 操作按钮
      Row({ space: 12 }) {
        // 取消按钮
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .fontColor(this.themeColors.textSecondary)
          .backgroundColor(this.themeColors.cardBackground)
          .borderRadius(22)
          .enabled(!this.isSharing)
          .onClick(() => {
            this.showShareDialog = false
          })
        
        // 分享按钮
        Button(this.isSharing ? '分享中...' : '分享')
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(this.isSharing ? this.themeColors.textTertiary : this.themeColors.primary)
          .borderRadius(22)
          .enabled(!this.isSharing)
          .onClick(() => {
            this.doShare()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
    }
    .width('100%')
    .backgroundColor(this.themeColors.background)
    .borderRadius({ topLeft: 24, topRight: 24 })
  }
  
  // 执行分享
  private async doShare() {
    if (this.isSharing) {
      return
    }
    
    this.isSharing = true
    console.info('[RecordCard] 开始分享，记录ID: ' + this.record.id)
    
    try {
      const context = getContext(this) as common.UIAbilityContext
      const success = await ShareUtils.shareComponent(
        this.getUIContext(),
        this.shareCardId,
        context,
        '记录分享',
        '来自 RecordLife 的记录分享'
      )
      
      if (success) {
        console.info('[RecordCard] 分享成功')
        // 延迟关闭弹窗，让用户看到分享成功
        setTimeout(() => {
          this.showShareDialog = false
          this.isSharing = false
        }, 500)
      } else {
        console.error('[RecordCard] 分享失败')
        this.isSharing = false
        // 可以在这里显示错误提示
      }
    } catch (error) {
      console.error('[RecordCard] 分享异常: ' + JSON.stringify(error))
      this.isSharing = false
    }
  }
  
  // 格式化时间（只显示时分）
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    
    if (this.showDate) {
      // 显示完整日期时间
      const year = date.getFullYear()
      const month = (date.getMonth() + 1).toString().padStart(2, '0')
      const day = date.getDate().toString().padStart(2, '0')
      return `${year}-${month}-${day} ${hours}:${minutes}`
    } else {
      // 只显示时分
      return `${hours}:${minutes}`
    }
  }
}
