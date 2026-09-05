// 现在页面：pages/NowPage.ets
import { common } from '@kit.AbilityKit'
import { ResourceUtils } from '../common/utils/ResourceUtils'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { TimelineData, LifeRecord, CommentItem, Tag } from '../common/types'
import { getDisplayTagName } from '../common/utils/TagDisplayUtils'
import { NowViewModel } from '../viewmodel/NowViewModel'
import { TimelineSection } from '../components/record/TimelineSection'
import { AddRecordSection } from '../components/record/AddRecordSection'
import { EditRecordDialog } from '../components/dialog/EditRecordDialog'
import { SearchBar } from '../components/common/SearchBar'
import { FilterBar } from '../components/record/FilterBar'
import { CalendarView } from '../components/calendar/CalendarView'
import { RefreshManager } from '../common/managers/RefreshManager'
import { ColorUtils } from '../common/ColorUtils'
import { PromptAction } from '@kit.ArkUI'
import { TagService } from '../service/TagService'
import { Logger } from '../common/utils/Logger'

@Component
struct NowPage {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  // 隐私模式（ConfigManager 同步）：开启时记录页内容亚克力模糊
  @StorageLink('privacyMode') privacyMode: boolean = false
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  
  // 时间线数据
  @State private timelineData: TimelineData = { years: [] }
  
  // 刷新触发器（用于强制刷新）
  @State private refreshTrigger: number = 0
  
  // 搜索状态
  @Watch('onSearchTextChange')
  @State private searchText: string = ''
  @State private isSearching: boolean = false
  @State private searchKeywordVersion: number = 0  // 搜索关键词版本号（用于强制刷新）
  
  // 标签筛选状态
  @Watch('onFilterTagIdsChange')
  @State private filterTagIds: string[] = []
  @State private filterTagIdsVersion: number = 0  // 标签筛选版本号
  
  // 监听搜索关键词改变
  private onSearchTextChange() {
    this.searchKeywordVersion++
    this.refreshTrigger++  // 强制 ForEach key 变化，避免复用残留导致记录不渲染
    Logger.info('[NowPage] searchText 改变: ' + this.searchText + ', version: ' + this.searchKeywordVersion)
  }

  // 监听标签筛选改变
  private onFilterTagIdsChange() {
    this.filterTagIdsVersion++
    this.refreshTrigger++  // 强制 ForEach key 变化（筛选后记录消失修复）
    Logger.info('[NowPage] filterTagIds 改变: ' + JSON.stringify(this.filterTagIds) + ', version: ' + this.filterTagIdsVersion)
  }
  
  // 心情筛选状态（更新计划二期；'' = 全部）
  @Watch('onFilterMoodChange')
  @State private filterMood: string = ''
  @State private filterMoodVersion: number = 0  // 心情筛选版本号

  // 监听心情筛选改变
  private onFilterMoodChange() {
    this.filterMoodVersion++
    this.refreshTrigger++  // 强制 ForEach key 变化（筛选后记录消失修复）
    Logger.info('[NowPage] filterMood 改变: ' + this.filterMood + ', version: ' + this.filterMoodVersion)
  }

  // 视图模式：'timeline' | 'calendar'
  @State private viewMode: string = 'timeline'
  
  // 滚动控制器
  private scroller: Scroller = new Scroller()
  
  // 需要滚动到的日期 ID（用于从日历视图跳转）
  @State private scrollToDateId: string = ''
  
  // 正在编辑的记录
  @State private editingRecord: LifeRecord | null = null
  @State private showEditDialog: boolean = false
  @State private editContent: string = ''
  
  // 编辑图片时的临时变量
  @State private editImagePaths: string[] = []
  
  // 编辑标签时的临时变量
  @State private editTags: string[] = []
  
  // 编辑心情时的临时变量（更新计划二期；'' = 未选择）
  @State private editMood: string = ''

  // 撤销删除提示条（更新计划二期）
  @State private showUndoBar: boolean = false
  @State private undoCount: number = 1
  @State private undoProgress: number = 100  // 3s 倒计时进度（100 → 0，满到空）
  private undoBarTimer: number = -1
  
  // 记录此刻弹窗
  @State private showAddRecordDialog: boolean = false

  // 追加想法（评论）面板状态（需求3）
  @State private showCommentSheet: boolean = false
  @State private commentTarget: LifeRecord | null = null
  @State private commentText: string = ''

  // 桌面卡片「快速记录」标记（AppStorage 同步；@Watch 覆盖已构建场景，aboutToAppear 覆盖首次构建场景）
  @StorageLink('cardQuickRecord') @Watch('onCardQuickRecord') cardQuickRecord: boolean = false
  
  // ViewModel（普通成员变量，不需要 @State）
  private viewModel: NowViewModel | null = null

  // 自定义标签（用于搜索时标签名称查找）
  @State private customTags: Tag[] = []
  @State private tagVersion: number = 0  // 标签版本号，变化时触发 FilterBar 重载
  
  // PromptAction（用于显示 Toast）
  private promptAction: PromptAction | null = null
  
  // AppStorage 标记变化时消费（NowPage 已构建的场景）
  onCardQuickRecord() {
    this.consumeCardQuickRecord()
  }

  // 消费桌面卡片「快速记录」标记：打开新建记录弹窗
  private consumeCardQuickRecord(): void {
    if (this.cardQuickRecord === true) {
      AppStorage.setOrCreate('cardQuickRecord', false)
      this.showAddRecordDialog = true
    }
  }

  async aboutToAppear() {
    Logger.info('[NowPage] aboutToAppear')
    // 首次构建时消费卡片标记（@StorageLink 初始化值）
    this.consumeCardQuickRecord()
    
    // 获取 PromptAction
    this.promptAction = this.getUIContext().getPromptAction()
    
    // 初始化 ViewModel
    this.viewModel = await NowViewModel.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
    
    // 注册全局刷新回调
    RefreshManager.getInstance().register('NowPage', () => {
      Logger.info('[NowPage] 收到全局刷新通知')
      this.reloadCustomTags()
      this.refreshTimeline()
    })
    
    // 加载自定义标签（用于搜索时标签名称匹配）
    try {
      const ts = await TagService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.customTags = ts.getCustomTags()
    } catch (error) {
      Logger.error('[NowPage] 加载自定义标签失败: ' + JSON.stringify(error))
    }
    
    // 加载时间线数据
    this.refreshTimeline()
  }
  
  aboutToDisappear() {
    Logger.info('[NowPage] aboutToDisappear')
    // 注销刷新回调
    RefreshManager.getInstance().unregister('NowPage')
  }
  
  // 页面显示时刷新数据
  onPageShow() {
    Logger.info('[NowPage] onPageShow')
    // 重新加载自定义标签
    this.reloadCustomTags()
    this.refreshTimeline()
  }
  
  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 时间线展示区域（全屏）
      Scroll(this.scroller) {
        Column() {
          // 页面标题和视图切换
          Row() {
            Text($r('app.string.now_moment'))
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)

            // 筛选按钮（此刻右侧，点击向下弹出筛选气泡，更新计划五期）
            FilterBar({
              selectedTagIds: $filterTagIds,
              filterMood: $filterMood,
              tagVersion: this.tagVersion
            })
            .margin({ left: 12 })
            
            Blank()
            
            // 视图切换按钮
            Row() {
              // 时间线视图按钮
              Column() {
                SymbolGlyph($r('sys.symbol.list_bullet'))
                  .fontSize(18)
                  .fontColor([this.viewMode === 'timeline' ? this.themeColors.primary : this.themeColors.textSecondary])
              }
              .width(36)
              .height(36)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .backgroundColor(this.viewMode === 'timeline' ? ColorUtils.primaryExtraLight(this.themeColors.primary) : 'transparent')
              .borderRadius(8)
              .onClick(() => {
                this.viewMode = 'timeline'
              })
              
              // 日历视图按钮
              Column() {
                SymbolGlyph($r('sys.symbol.calendar'))
                  .fontSize(18)
                  .fontColor([this.viewMode === 'calendar' ? this.themeColors.primary : this.themeColors.textSecondary])
              }
              .width(36)
              .height(36)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .backgroundColor(this.viewMode === 'calendar' ? ColorUtils.primaryExtraLight(this.themeColors.primary) : 'transparent')
              .borderRadius(8)
              .margin({ left: 8 })
              .onClick(() => {
                this.viewMode = 'calendar'
              })
            }
            .margin({ right: 12 })
            
            // 统计信息
            if (this.timelineData.years.length > 0) {
              Text($r('app.string.record_count', this.getTotalRecordCount()))
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
            }
          }
          .width('100%')
          .padding({ left: 4, right: 4, bottom: 12 })
          
          // 搜索栏（仅时间线视图显示）
          if (this.viewMode === 'timeline') {
            SearchBar({
              searchText: $searchText,
              isSearching: $isSearching,
              placeholder: $r('app.string.search_records')
            })
            .margin({ bottom: 8 })
            
            // 搜索结果数量提示
            if (this.searchText.length > 0) {
              Row() {
                SymbolGlyph($r('sys.symbol.checkmark_circle'))
                  .fontSize(16)
                  .fontColor([this.themeColors.primary])
                
                Text($r('app.string.found_records', this.getFilteredRecordCount()))
                  .fontSize(14)
                  .fontColor(this.themeColors.textSecondary)
                  .margin({ left: 6 })
              }
              .width('100%')
              .padding({ left: 4, bottom: 12 })
            } else {
              // 无搜索时显示总记录数
              if (this.timelineData.years.length > 0) {
                Row() {
                  Text($r('app.string.total_records', this.getTotalRecordCount()))
                    .fontSize(14)
                    .fontColor(this.themeColors.textSecondary)
                }
                .width('100%')
                .padding({ left: 4, bottom: 12 })
              }
            }
          }
          
          // 内容区域
          if (this.viewMode === 'timeline') {
            // 时间线视图
            TimelineSection({
              timelineData: this.timelineData,
              timelineDataVersion: this.refreshTrigger,
              searchKeyword: this.searchText,  // 传递搜索关键词
              searchKeywordVersion: this.searchKeywordVersion,  // 传递搜索关键词版本号
              filterTagIds: this.filterTagIds,  // 传递标签筛选
              filterTagIdsVersion: this.filterTagIdsVersion,  // 传递标签筛选版本号
              filterMood: this.filterMood,  // 传递心情筛选（更新计划二期）
              filterMoodVersion: this.filterMoodVersion,  // 传递心情筛选版本号
              onEditRecord: (record: LifeRecord) => {
                this.onEditRecord(record)
              },
              onDeleteRecord: (record: LifeRecord) => {
                this.onDeleteRecord(record)
              },
              onTogglePin: (record: LifeRecord) => {
                this.onTogglePin(record)
              },
              onComment: (record: LifeRecord) => {
                this.openCommentSheet(record)
              }
            })
          } else {
            // 日历视图
            CalendarView({
              timelineData: this.timelineData,
              onRecordsClick: (records: LifeRecord[], dateStr: string) => {
                // 点击查看全部记录时，切换到时间线视图
                this.viewMode = 'timeline'
              },
              onRecordClick: (record: LifeRecord) => {
                // 点击单条记录时，切换到时间线视图并滚动到对应日期
                this.viewMode = 'timeline'
                // 从记录中提取日期
                if (record.timestamp) {
                  const date = new Date(record.timestamp)
                  const targetId = `date-${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`
                  // 延迟执行滚动，等待视图切换完成
                  setTimeout(() => {
                    try {
                      // 获取目标组件相对于父组件的位置
                      const rect = this.getUIContext().getComponentUtils().getRectangleById(targetId)
                      if (rect) {
                        // 使用 localOffset.y 作为滚动目标位置（相对于父组件的 y 坐标）
                        const targetOffset = Math.max(0, this.getUIContext().px2vp(rect.localOffset.y) - 100)
                        this.scroller.scrollTo({
                          xOffset: 0,
                          yOffset: targetOffset,
                          animation: { duration: 300, curve: Curve.EaseOut }
                        })
                      }
                    } catch (e) {
                      Logger.warn('[NowPage] 滚动到目标位置失败: ' + e)
                    }
                  }, 150)
                }
              }
            })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 100 })
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
      // 追加想法（评论）面板：单独绑定在 Scroll 上，避免与 Stack 上编辑 bindSheet
      // 相互覆盖导致编辑框无法弹出（bug 修复）
      .bindSheet($$this.showCommentSheet, this.CommentSheetBuilder(), {
        height: '58%',
        backgroundColor: this.themeColors.cardBackground,
        dragBar: true,
        showClose: false
      })

      // 隐私模式：记录内容亚克力模糊遮罩（盖住 Scroll 记录区；FAB 在上层保持可用）
      if (this.privacyMode) {
        Column() {
          Column({ space: 12 }) {
            Text('🔒')
              .fontSize(42)
            Text($r('app.string.privacy_mode_on'))
              .fontSize(15)
              .fontColor(this.isDarkMode ? '#CCFFFFFF' : '#66000000')
              .textAlign(TextAlign.Center)
              .lineHeight(22)
              .padding({ left: 32, right: 32 })
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.isDarkMode ? '#B31A1A1A' : '#B3F5F5F5')
        .backdropBlur(24)
      }

      // 右下角浮动按钮
      Button() {
        Column() {
          Text('+')
            .fontSize(28)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width(60)
      .height(60)
      .borderRadius(30)
      .backgroundColor(this.themeColors.primary)
      .shadow({
        radius: 20,
        color: '#50000000',
        offsetX: 0,
        offsetY: 6
      })
      .margin({ right: 20, bottom: 24 })
      .onClick(() => {
        Logger.info('[NowPage] 点击加号按钮，showAddRecordDialog 设置为 true')
        this.showAddRecordDialog = true
        Logger.info('[NowPage] showAddRecordDialog 当前值: ' + this.showAddRecordDialog)
      })
      .bindSheet($$this.showAddRecordDialog, this.AddRecordDialogBuilder(), {
        height: '80%',
        backgroundColor: this.themeColors.cardBackground,
        dragBar: true,
        showClose: false  // 关闭系统 ×（与标题行模板按钮避免重叠；关闭靠 dragBar 下拉/保存后自动关）
      })
      
      // 撤销删除提示条（更新计划二期；全屏容器点击穿透，仅提示条区域可交互）
      if (this.showUndoBar) {
        Column() {
          Column() {
            Row() {
              Text($r('app.string.record_deleted', this.undoCount))
                .fontSize(14)
                .fontColor('#FFFFFF')
                .layoutWeight(1)

              Text($r('app.string.undo_delete'))
                .fontSize(14)
                .fontColor(this.themeColors.primary)
                .fontWeight(FontWeight.Bold)
                .onClick(() => {
                  this.onUndoDelete()
                })
            }
            .width('100%')
            .padding({ left: 16, right: 12, top: 12, bottom: 10 })

            // 3 秒倒计时进度条（满 → 空，动画结束提示条隐藏）
            Progress({ value: this.undoProgress, total: 100, type: ProgressType.Linear })
              .width('100%')
              .height(3)
              .color(this.themeColors.primary)
              .backgroundColor('#40FFFFFF')
              .margin({ bottom: 8 })
          }
          .width('92%')
          .padding({ top: 2 })
          .backgroundColor('#E6202020')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 90 })  // 顶部避让状态栏+标题栏，紧贴标题下方
        .hitTestBehavior(HitTestMode.Transparent)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
    .bindSheet($$this.showEditDialog, this.EditDialogBuilder(), {
      height: '80%',
      backgroundColor: this.themeColors.cardBackground,
      dragBar: true
    })
  }
  
  // 记录此刻弹窗
  @Builder
  AddRecordDialogBuilder() {
    Column() {
      AddRecordSection({
        onSaveSuccess: () => {
          Logger.info('[NowPage] AddRecordSection onSaveSuccess 回调被调用')
          this.showAddRecordDialog = false
          // RefreshManager 会自动触发 refreshTimeline（NowPage 已注册回调）
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  // 追加想法（评论）面板（需求3）
  @Builder
  CommentSheetBuilder() {
    Column() {
      // 标题行
      Row() {
        Text($r('app.string.comments_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
        Blank()
        Text('✕')
          .fontSize(20)
          .fontColor(this.themeColors.textSecondary)
          .onClick(() => {
            this.showCommentSheet = false
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 10 })

      // 评论列表 / 空态
      if (this.commentTarget && this.commentTarget.comments && this.commentTarget.comments.length > 0) {
        List({ space: 8 }) {
          ForEach(this.commentTarget.comments, (item: CommentItem) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.content)
                    .fontSize(15)
                    .fontColor(this.themeColors.textPrimary)
                    .textAlign(TextAlign.Start)
                    .width('100%')
                  Text(this.formatCommentTime(item.timestamp))
                    .fontSize(11)
                    .fontColor(this.themeColors.textTertiary)
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Image($r('sys.media.ohos_ic_public_remove'))
                  .width(18)
                  .height(18)
                  .fillColor(this.themeColors.textTertiary)
                  .margin({ left: 12 })
                  .onClick(() => {
                    this.confirmDeleteComment(item)
                  })
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.themeColors.background)
              .borderRadius(10)
            }
          }, (item: CommentItem) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .padding({ left: 16, right: 16 })
      } else {
        Column() {
          Text($r('app.string.comments_empty'))
            .fontSize(14)
            .fontColor(this.themeColors.textSecondary)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }

      // 底部输入区
      Row({ space: 10 }) {
        TextArea({ placeholder: $r('app.string.comment_input_placeholder'), text: $$this.commentText })
          .layoutWeight(1)
          .height(46)
          .fontSize(15)
          .backgroundColor(this.themeColors.background)
          .borderRadius(10)
        Button($r('app.string.comment_add'))
          .height(46)
          .fontSize(15)
          .backgroundColor(this.themeColors.primary)
          .fontColor(Color.White)
          .borderRadius(10)
          .onClick(() => {
            this.onAddComment()
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.cardBackground)
  }

  // 打开追加想法面板
  private openCommentSheet(record: LifeRecord): void {
    this.commentTarget = record
    this.commentText = ''
    this.showCommentSheet = true
  }

  // 添加追加想法
  private async onAddComment(): Promise<void> {
    const target = this.commentTarget
    const text = this.commentText.trim()
    if (!target || text.length === 0 || !this.viewModel) {
      return
    }
    await this.viewModel.addComment(target.id, text)
    this.commentText = ''
    this.syncCommentTarget()
  }

  // 删除追加想法前二次确认（复查 UI）
  private confirmDeleteComment(item: CommentItem): void {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.confirm_delete'),
      message: $r('app.string.confirm_delete_comment'),
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: $r('app.string.delete'),
        fontColor: Color.Red,
        action: () => {
          this.onDeleteComment(item.id)
        }
      }
    })
  }

  // 删除追加想法
  private async onDeleteComment(commentId: string): Promise<void> {
    const target = this.commentTarget
    if (!target || !this.viewModel) {
      return
    }
    await this.viewModel.deleteComment(target.id, commentId)
    this.syncCommentTarget()
  }

  // 评论变更后：同步 commentTarget 最新数据并刷新时间线（卡片 💬 角标）
  private syncCommentTarget(): void {
    const id = this.commentTarget?.id
    if (id && this.viewModel) {
      const fresh = this.viewModel.getRecordById(id)
      if (fresh) {
        // 显式拷贝为新对象 + 新 comments 数组（ArkTS 不支持对象展开），
        // 确保 @State 感知变化刷新面板（复查 P1）
        this.commentTarget = {
          id: fresh.id,
          timestamp: fresh.timestamp,
          content: fresh.content,
          updatedAt: fresh.updatedAt,
          imagePaths: fresh.imagePaths,
          imageCloudKeys: fresh.imageCloudKeys,
          tags: fresh.tags,
          isPinned: fresh.isPinned,
          mood: fresh.mood,
          comments: fresh.comments ? [...fresh.comments] : undefined
        }
      }
    }
    this.refreshTimeline()
  }

  // 评论时间显示（M/D HH:mm）
  private formatCommentTime(ts: number): string {
    const d = new Date(ts)
    const hh = d.getHours().toString().padStart(2, '0')
    const mm = d.getMinutes().toString().padStart(2, '0')
    return `${d.getMonth() + 1}/${d.getDate()} ${hh}:${mm}`
  }
  
  // 编辑对话框
  @Builder
  EditDialogBuilder() {
    EditRecordDialog({
      record: this.editingRecord,
      editContent: $editContent,
      editImagePaths: this.editImagePaths,  // ✅ 传递当前值
      editTags: $editTags,  // ✅ 双向绑定标签
      editMood: $editMood,  // ✅ 双向绑定心情（更新计划二期）
      onImagePathsChange: (paths: string[]) => {
        // ✅ 通过回调更新图片数组
        Logger.info('[NowPage] 收到图片更新回调，旧数量: ' + this.editImagePaths.length + ', 新数量: ' + paths.length)
        Logger.info('[NowPage] 旧数组: ' + JSON.stringify(this.editImagePaths))
        Logger.info('[NowPage] 新数组: ' + JSON.stringify(paths))
        
        // 强制创建新数组引用，确保触发 UI 更新
        this.editImagePaths = [...paths]
        
        Logger.info('[NowPage] 图片数组已更新，当前数量: ' + this.editImagePaths.length)
      },
      onSave: () => {
        this.onSaveEdit()
      },
      onCancel: () => {
        this.showEditDialog = false
        this.editingRecord = null as LifeRecord | null
        this.editImagePaths = []
        this.editTags = []
        this.editMood = ''
      },
      saveImageToSandbox: async (uri: string) => {
        if (this.viewModel) {
          return await this.viewModel.saveImageToSandbox(uri)
        }
        return null
      }
    })
  }
  
  // 重新加载自定义标签
  private async reloadCustomTags() {
    try {
      const ts = await TagService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.customTags = ts.getCustomTags()
      this.tagVersion++  // 触发子组件重载标签
    } catch (error) {
      Logger.error('[NowPage] 重新加载自定义标签失败: ' + JSON.stringify(error))
    }
  }

  // 刷新时间线
  private refreshTimeline() {
    if (this.viewModel) {
      Logger.info('[NowPage] 开始刷新时间线')

      // 构建新的时间线数据
      const newTimelineData = this.viewModel.buildTimeline()

      // 先递增刷新触发器（让子组件感知变更），再更新数据（确保一次状态变更中完成响应）
      this.refreshTrigger++

      // buildTimelineData 每次返回全新对象图，直接赋值即可触发 @State 更新（P5 移除 JSON 深拷贝）
      this.timelineData = newTimelineData

      Logger.info('[NowPage] 时间线刷新完成，年份数: ' + this.timelineData.years.length +
        ', 总记录数: ' + this.getTotalRecordCount() +
        ', trigger: ' + this.refreshTrigger)
    } else {
      Logger.warn('[NowPage] viewModel 未初始化，无法刷新')
    }
  }
  
  // 获取总记录数（用于日志）
  private getTotalRecordCount(): number {
    let count = 0
    for (const year of this.timelineData.years) {
      for (const month of year.months) {
        for (const day of month.days) {
          count += day.records.length
        }
      }
    }
    return count
  }
  
  // 获取过滤后的记录数量（用于搜索结果显示）
  private getFilteredRecordCount(): number {
    if (this.searchText.length === 0) {
      return this.getTotalRecordCount()
    }
    
    let count = 0
    const keyword = this.searchText.toLowerCase()
    for (const year of this.timelineData.years) {
      for (const month of year.months) {
        for (const day of month.days) {
          for (const record of day.records) {
            if (this.matchRecord(record, keyword)) {
              count++
            }
          }
        }
      }
    }
    return count
  }
  
  // 匹配记录（搜索内容和标签）
  private matchRecord(record: LifeRecord, keyword: string): boolean {
    // 1. 搜索文字内容
    if (record.content.toLowerCase().includes(keyword)) {
      return true
    }
    
    // 2. 搜索标签名称
    if (record.tags && record.tags.length > 0) {
      for (const tagId of record.tags) {
        const tagName = getDisplayTagName(tagId, this.customTags, this.getUIContext().getHostContext()?.resourceManager ?? null)
        if (tagName && tagName.toLowerCase().includes(keyword)) {
          return true
        }
      }
    }
    
    return false
  }
  
  // 编辑记录
  private onEditRecord(record: LifeRecord) {
    this.editingRecord = record
    this.editContent = record.content
    
    // 如果有图片，初始化图片路径列表
    if (record.imagePaths && record.imagePaths.length > 0) {
      this.editImagePaths = [...record.imagePaths]  // 复制数组
    } else {
      this.editImagePaths = []
    }
    
    // 如果有标签，初始化标签列表
    if (record.tags && record.tags.length > 0) {
      this.editTags = [...record.tags]  // 复制数组
    } else {
      this.editTags = []
    }
    
    // 如果有心情，初始化心情（更新计划二期）
    this.editMood = record.mood ?? ''
    
    this.showEditDialog = true
  }
  
  // 保存编辑
  private async onSaveEdit() {
    if (!this.viewModel || !this.editingRecord || !this.promptAction) {
      return
    }
    
    // 至少需要文字或图片
    if (this.editContent.trim().length === 0 && this.editImagePaths.length === 0) {
      try {
        this.promptAction.showToast({ message: $r('app.string.please_input_content') })
      } catch (error) {
        Logger.error('[NowPage] showToast failed: ' + JSON.stringify(error))
      }
      return
    }
    
    try {
      // 传递图片路径数组和标签数组
      const success = await this.viewModel.updateRecord(
        this.editingRecord.id,
        this.editContent.trim(),
        this.editImagePaths,  // ✅ 直接传递，空数组也会更新
        this.editTags,  // ✅ 传递标签
        this.editMood  // ✅ 传递心情（更新计划二期）
      )
      
      if (success) {
        try {
          this.promptAction.showToast({ message: $r('app.string.edit_success') })
        } catch (error) {
          Logger.error('[NowPage] showToast failed: ' + JSON.stringify(error))
        }
        this.showEditDialog = false
        this.editingRecord = null as LifeRecord | null
        this.editImagePaths = []
        this.editTags = []
        this.editMood = ''
        // 通过 RefreshManager 统一刷新（NowPage 已注册回调，会自动触发 refreshTimeline；
        // 同时通知其他注册页面同步刷新）
        RefreshManager.getInstance().refresh()
      } else {
        try {
          this.promptAction.showToast({ message: $r('app.string.edit_failed') })
        } catch (error) {
          Logger.error('[NowPage] showToast failed: ' + JSON.stringify(error))
        }
      }
    } catch (error) {
      Logger.error('[NowPage] 保存编辑失败: ' + JSON.stringify(error))
      try {
        this.promptAction.showToast({ message: ResourceUtils.getString((this.getUIContext().getHostContext() as common.UIAbilityContext).resourceManager, 'edit_failed_prefix') + (error as Error).message })
      } catch (e) {
        Logger.error('[NowPage] showToast failed: ' + JSON.stringify(e))
      }
    }
  }
  
  
  // 切换收藏状态
  private async onTogglePin(record: LifeRecord) {
    if (!this.viewModel || !this.promptAction) {
      return
    }

    try {
      const wasPinned = record.isPinned
      const success = await this.viewModel.togglePin(record.id)
      if (success) {
        try {
          this.promptAction.showToast({
            message: wasPinned ? $r('app.string.unpinned_success') : $r('app.string.pinned_success')
          })
        } catch (error) {
          Logger.error('[NowPage] showToast failed: ' + JSON.stringify(error))
        }
        // 刷新时间线
        this.refreshTimeline()
      } else {
        try {
          this.promptAction.showToast({ message: $r('app.string.operation_failed') })
        } catch (error) {
          Logger.error('[NowPage] showToast failed: ' + JSON.stringify(error))
        }
      }
    } catch (error) {
      Logger.error('[NowPage] 切换收藏失败: ' + JSON.stringify(error))
    }
  }


  // 删除记录
  private onDeleteRecord(record: LifeRecord) {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.delete_record'),
      message: $r('app.string.delete_record_confirm'),
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
          Logger.info('[NowPage] 取消删除')
        }
      },
      secondaryButton: {
        value: $r('app.string.delete'),
        fontColor: this.themeColors.error,
        action: async () => {
          if (!this.viewModel || !this.promptAction) {
            return
          }
          
          try {
            const success = await this.viewModel.deleteRecord(record.id)
            
            if (success) {
              // 显示撤销提示条（3 秒窗口，替代成功 toast；更新计划二期）
              this.showUndoBarWithCount(1)
              // 通过 RefreshManager 统一刷新（已注册回调，自动触发 refreshTimeline）
              RefreshManager.getInstance().refresh()
            } else {
              try {
                this.promptAction.showToast({ message: $r('app.string.delete_failed') })
              } catch (error) {
                Logger.error('[NowPage] showToast failed: ' + JSON.stringify(error))
              }
            }
          } catch (error) {
            Logger.error('[NowPage] 删除失败: ' + JSON.stringify(error))
            try {
              this.promptAction.showToast({ message: ResourceUtils.getString((this.getUIContext().getHostContext() as common.UIAbilityContext).resourceManager, 'delete_failed_prefix') + (error as Error).message })
            } catch (e) {
              Logger.error('[NowPage] showToast failed: ' + JSON.stringify(e))
            }
          }
        }
      }
    })
  }

  // ==================== 撤销删除（更新计划二期） ====================

  // 显示撤销提示条（3 秒倒计时：进度条满 → 空）
  // 注：Progress.value 非可动画属性（animateTo 会直接跳变），用定时器逐步递减实现平滑动画
  private showUndoBarWithCount(count: number) {
    this.undoCount = count
    this.undoProgress = 100
    this.showUndoBar = true
    if (this.undoBarTimer !== -1) {
      clearInterval(this.undoBarTimer)
    }
    // 30ms 递减 1，共 100 步 ≈ 3 秒；走完自动隐藏提示条
    this.undoBarTimer = setInterval(() => {
      this.undoProgress -= 1
      if (this.undoProgress <= 0) {
        this.undoProgress = 0
        clearInterval(this.undoBarTimer)
        this.undoBarTimer = -1
        this.showUndoBar = false
      }
    }, 30)
  }

  // 隐藏撤销提示条
  private hideUndoBar() {
    if (this.undoBarTimer !== -1) {
      clearInterval(this.undoBarTimer)
      this.undoBarTimer = -1
    }
    this.showUndoBar = false
  }

  // 撤销删除
  private async onUndoDelete() {
    if (!this.viewModel) {
      return
    }
    this.hideUndoBar()
    const success = await this.viewModel.undoDelete()
    if (success) {
      try {
        this.promptAction?.showToast({ message: $r('app.string.undo_success') })
      } catch (error) {
        Logger.error('[NowPage] showToast failed: ' + JSON.stringify(error))
      }
      // 通过 RefreshManager 统一刷新（恢复的记录重新出现在时间线）
      RefreshManager.getInstance().refresh()
    }
  }
}

export { NowPage }
