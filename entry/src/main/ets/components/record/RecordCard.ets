// 记录卡片组件：components/RecordCard.ets
import { LifeRecord } from '../../common/types'
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { NowViewModel } from '../../viewmodel/NowViewModel'
import { ImageViewer } from '../common/ImageViewer'
import { TagDisplay } from '../common/TagSelector'
import { ShareRecordDialog } from '../dialog/ShareRecordDialog'
import { MoodUtils } from '../../common/utils/MoodUtils'
import { MoodService } from '../../service/MoodService'
import { Mood } from '../../model/RecordModel'
import { common } from '@kit.AbilityKit'
import { ColorUtils } from '../../common/ColorUtils'
import { Logger } from '../../common/utils/Logger'

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

  // 全局字体缩放系数（更新计划一期；AppStorage fontScale 由字体大小设置写入）
  @StorageProp('fontScale') fontScale: number = 1.0

  // 自定义心情（更新计划二期：展示自定义心情 emoji）
  @State private customMoods: Mood[] = []
  
  // 回调函数
  onEdit?: (record: LifeRecord) => void
  onDelete?: (record: LifeRecord) => void
  onTogglePin?: (record: LifeRecord) => void
  onComment?: (record: LifeRecord) => void
  
  // ViewModel
  private viewModel: NowViewModel | null = null
  
  // 图片预览状态
  @State private showImageViewer: boolean = false
  @State private viewerImageUris: string[] = []
  @State private viewerImageCloudKeys: string[] = []
  @State private viewerCurrentIndex: number = 0
  
  // 分享弹窗控制器（更新计划五期：统一 CustomDialog，居中缩放淡入动画）
  shareDialogController: CustomDialogController = new CustomDialogController({
    builder: ShareRecordDialog({ record: this.record }),
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center,
    maskColor: 'rgba(0, 0, 0, 0.5)'
  })
  
  async aboutToAppear() {
    this.viewModel = await NowViewModel.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
    // 加载自定义心情（更新计划二期）
    try {
      const moodService = await MoodService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.customMoods = moodService.getCustomMoods()
    } catch (error) {
      Logger.error('[RecordCard] 加载自定义心情失败: ' + JSON.stringify(error))
    }
  }
  
  build() {
    Column() {
      Column() {
        // 收藏标识（如果已收藏）
        if (this.record.isPinned) {
          Row({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.pin_fill'))
              .fontSize(14)
              .fontColor([this.themeColors.primary])
            Text($r('app.string.favorited'))
              .fontSize(12)
              .fontColor(this.themeColors.primary)
              .fontWeight(FontWeight.Medium)
          }
          .padding({ left: 8, right: 12, top: 4, bottom: 4 })
          .backgroundColor(ColorUtils.primaryExtraLight(this.themeColors.primary))
          .borderRadius(12)
          .margin({ bottom: 8 })
        }

        // 心情展示（更新计划二期）
        if (this.record.mood && MoodUtils.getMoodEmoji(this.record.mood, this.customMoods).length > 0) {
          Text(MoodUtils.getMoodEmoji(this.record.mood, this.customMoods))
            .fontSize(22)
            .margin({ bottom: 8 })
        }

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

          // 最后修改时间（编辑过才显示）
          if (this.isEdited()) {
            Text($r('app.string.edited_at', this.formatEditedAt(this.record.updatedAt as number)))
              .fontSize(12)
              .fontColor(this.themeColors.textTertiary)
              .margin({ left: 8 })
          }

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
  }
  
  // 高亮文本构建器
  @Builder
  HighlightText(text: string, keyword: string) {
    if (keyword.length === 0) {
      // 无关键词，直接显示原文
      Text(text)
        .fontSize(15 * this.fontScale)
        .fontColor(this.themeColors.textPrimary)
        .width('100%')
        .lineHeight(22 * this.fontScale)
    } else {
      // 有关键词，分段高亮显示
      Text() {
        ForEach(this.splitTextByKeyword(text, keyword), (segment: TextSegment) => {
          Span(segment.text)
            .fontSize(15 * this.fontScale)
            .fontColor(segment.isHighlight ? this.themeColors.primary : this.themeColors.textPrimary)
            .fontWeight(segment.isHighlight ? FontWeight.Bold : FontWeight.Normal)
        }, (segment: TextSegment, index: number) => `segment-${index}`)
      }
      .width('100%')
      .lineHeight(22 * this.fontScale)
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
    Logger.info('[RecordCard] 进入图片打开事件')
    if (!this.viewModel || !this.record.imagePaths) {
      Logger.info('[RecordCard] 没有viewModel 或 imagePaths')
      return
    }
    Logger.info('[RecordCard] 不为空')
    
    const imageUris: string[] = []
    const cloudKeys: string[] = []
    for (let i = 0; i < this.record.imagePaths.length; i++) {
      if (!this.viewModel || !this.record.imagePaths[i]) {
        Logger.info('[RecordCard] 没有viewModel 或 imagePaths[i]')
        continue
      }
      imageUris.push(this.viewModel.getImageUri(this.record.imagePaths[i]))
      // 图片存储优化 M3：云端原图 key 对齐 imagePaths
      if (this.record.imageCloudKeys && this.record.imageCloudKeys[i]) {
        cloudKeys.push(this.record.imageCloudKeys[i])
      } else {
        cloudKeys.push('')
      }
    }
    
    this.viewerImageUris = imageUris
    this.viewerImageCloudKeys = cloudKeys
    this.viewerCurrentIndex = index
    this.showImageViewer = true
  }
  
  // 打开图片预览
  private openImageViewer(uris: string[], index: number) {
    Logger.info('[RecordCard] openImageViewer')
    this.viewerImageUris = uris
    this.viewerCurrentIndex = index
    this.showImageViewer = true
  }
  
  // 图片预览构建器
  @Builder
  ImageViewerBuilder() {
    ImageViewer({
      imageUris: this.viewerImageUris,
      imageCloudKeys: this.viewerImageCloudKeys,
      currentIndex: this.viewerCurrentIndex,
      onClose: () => {
        this.showImageViewer = false
      }
    })
  }
  
  // 操作按钮
  @Builder
  ActionButtons() {
    Row({ space: 24 }) {
      // 收藏/置顶按钮
      SymbolGlyph(this.record.isPinned ? $r('sys.symbol.pin_fill') : $r('sys.symbol.pin'))
        .fontSize(20)
        .fontColor([this.record.isPinned ? this.themeColors.primary : this.themeColors.iconColor])
        .onClick(() => {
          if (this.onTogglePin) {
            this.onTogglePin(this.record)
          }
        })

      // 分享按钮
      Image($r('sys.media.ohos_ic_public_share'))
        .width(20)
        .height(20)
        .fillColor(this.themeColors.iconColor)
        .onClick(() => {
          this.shareDialogController.open()
        })

      // 追加想法（评论）按钮：消息图标 + 条数（与操作条图标风格统一）
      Row({ space: 3 }) {
        SymbolGlyph($r('sys.symbol.message'))
          .fontSize(19)
          .fontColor([this.themeColors.iconColor])
        if (this.commentCount() > 0) {
          Text(`${this.commentCount()}`)
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
        }
      }
      .padding(4)
      .onClick(() => {
        if (this.onComment) {
          this.onComment(this.record)
        }
      })
      
      // 编辑按钮
      Image($r('sys.media.ohos_ic_public_edit'))
        .width(20)
        .height(20)
        .fillColor(this.themeColors.iconColor)
        .onClick(() => {
          if (this.onEdit) {
            this.onEdit(this.record)
          }
        })
      
      // 删除按钮
      Image($r('sys.media.ohos_ic_public_remove'))
        .width(20)
        .height(20)
        .fillColor(this.themeColors.error)
        .onClick(() => {
          if (this.onDelete) {
            this.onDelete(this.record)
          }
        })
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

  // 是否编辑过（updatedAt 存在且晚于创建时间）
  private isEdited(): boolean {
    const updatedAt = this.record.updatedAt
    return updatedAt !== undefined && updatedAt > this.record.timestamp
  }

  // 最后修改时间文本：与创建同日只显时分，跨日补 M/D
  private formatEditedAt(updatedAt: number): string {
    const d = new Date(updatedAt)
    const hh = d.getHours().toString().padStart(2, '0')
    const mm = d.getMinutes().toString().padStart(2, '0')
    const c = new Date(this.record.timestamp)
    const sameDay = d.getFullYear() === c.getFullYear() &&
      d.getMonth() === c.getMonth() && d.getDate() === c.getDate()
    return sameDay ? `${hh}:${mm}` : `${d.getMonth() + 1}/${d.getDate()} ${hh}:${mm}`
  }

  // 追加想法条数（需求3）
  private commentCount(): number {
    return this.record.comments ? this.record.comments.length : 0
  }
}
