// 现在页面：pages/NowPage.ets
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { TimelineData, LifeRecord } from '../common/types'
import { NowViewModel } from '../viewmodel/NowViewModel'
import { TimelineSection } from '../components/record/TimelineSection'
import { AddRecordSection } from '../components/record/AddRecordSection'
import { EditRecordDialog } from '../components/dialog/EditRecordDialog'
import { SearchBar } from '../components/common/SearchBar'
import { CalendarView } from '../components/calendar/CalendarView'
import { RefreshManager } from '../common/managers/RefreshManager'
import { PromptAction } from '@kit.ArkUI'

@Entry
@Component
struct NowPage {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 时间线数据
  @State private timelineData: TimelineData = { years: [] }
  
  // 刷新触发器（用于强制刷新）
  @State private refreshTrigger: number = 0
  
  // 搜索状态
  @Watch('onSearchTextChange')
  @State private searchText: string = ''
  @State private isSearching: boolean = false
  @State private searchKeywordVersion: number = 0  // 搜索关键词版本号（用于强制刷新）
  
  // 监听搜索关键词改变
  private onSearchTextChange() {
    this.searchKeywordVersion++
    console.info('[NowPage] searchText 改变: ' + this.searchText + ', version: ' + this.searchKeywordVersion)
  }
  
  // 视图模式：'timeline' | 'calendar'
  @State private viewMode: string = 'timeline'
  
  // 正在编辑的记录
  @State private editingRecord: LifeRecord | null = null
  @State private showEditDialog: boolean = false
  @State private editContent: string = ''
  
  // 编辑图片时的临时变量
  @State private editImagePaths: string[] = []
  
  // 编辑标签时的临时变量
  @State private editTags: string[] = []
  
  // 记录此刻弹窗
  @State private showAddRecordDialog: boolean = false
  
  // ViewModel（普通成员变量，不需要 @State）
  private viewModel: NowViewModel | null = null
  
  // PromptAction（用于显示 Toast）
  private promptAction: PromptAction | null = null
  
  async aboutToAppear() {
    console.info('[NowPage] aboutToAppear')
    
    // 获取 PromptAction
    this.promptAction = this.getUIContext().getPromptAction()
    
    // 初始化 ViewModel
    this.viewModel = await NowViewModel.getInstance()
    
    // 注册全局刷新回调
    RefreshManager.getInstance().register('NowPage', () => {
      console.info('[NowPage] 收到全局刷新通知')
      this.refreshTimeline()
    })
    
    // 加载时间线数据
    this.refreshTimeline()
  }
  
  aboutToDisappear() {
    console.info('[NowPage] aboutToDisappear')
    // 注销刷新回调
    RefreshManager.getInstance().unregister('NowPage')
  }
  
  // 页面显示时刷新数据
  onPageShow() {
    console.info('[NowPage] onPageShow')
    this.refreshTimeline()
  }
  
  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 时间线展示区域（全屏）
      Scroll() {
        Column() {
          // 页面标题和视图切换
          Row() {
            Text('此刻')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
            
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
              .backgroundColor(this.viewMode === 'timeline' ? this.themeColors.primary + '20' : 'transparent')
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
              .backgroundColor(this.viewMode === 'calendar' ? this.themeColors.primary + '20' : 'transparent')
              .borderRadius(8)
              .margin({ left: 8 })
              .onClick(() => {
                this.viewMode = 'calendar'
              })
            }
            .margin({ right: 12 })
            
            // 统计信息
            if (this.timelineData.years.length > 0) {
              Text(this.getTotalRecordCount() + ' 条记录')
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
              placeholder: '搜索记录...'
            })
            .margin({ bottom: 8 })
            
            // 搜索结果数量提示
            if (this.searchText.length > 0) {
              Row() {
                SymbolGlyph($r('sys.symbol.checkmark_circle'))
                  .fontSize(16)
                  .fontColor([this.themeColors.primary])
                
                Text(`找到 ${this.getFilteredRecordCount()} 条相关记录`)
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
                  Text(`共 ${this.getTotalRecordCount()} 条记录`)
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
              onEditRecord: (record: LifeRecord) => {
                this.onEditRecord(record)
              },
              onDeleteRecord: (record: LifeRecord) => {
                this.onDeleteRecord(record)
              }
            })
          } else {
            // 日历视图
            CalendarView({
              timelineData: this.timelineData,
              onRecordsClick: (records: LifeRecord[], dateStr: string) => {
                // 点击查看全部记录时，切换到时间线视图
                // TODO: 可以滚动到对应日期
                this.viewMode = 'timeline'
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
        console.info('[NowPage] 点击加号按钮，showAddRecordDialog 设置为 true')
        this.showAddRecordDialog = true
        console.info('[NowPage] showAddRecordDialog 当前值: ' + this.showAddRecordDialog)
      })
      .bindSheet($$this.showAddRecordDialog, this.AddRecordDialogBuilder(), {
        height: '80%',
        backgroundColor: this.themeColors.cardBackground,
        dragBar: true,
        showClose: true
      })
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
          console.info('[NowPage] AddRecordSection onSaveSuccess 回调被调用')
          this.showAddRecordDialog = false
          this.refreshTimeline()
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
  
  // 编辑对话框
  @Builder
  EditDialogBuilder() {
    EditRecordDialog({
      record: this.editingRecord,
      editContent: $editContent,
      editImagePaths: this.editImagePaths,  // ✅ 传递当前值
      editTags: $editTags,  // ✅ 双向绑定标签
      onImagePathsChange: (paths: string[]) => {
        // ✅ 通过回调更新图片数组
        console.info('[NowPage] 收到图片更新回调，旧数量: ' + this.editImagePaths.length + ', 新数量: ' + paths.length)
        console.info('[NowPage] 旧数组: ' + JSON.stringify(this.editImagePaths))
        console.info('[NowPage] 新数组: ' + JSON.stringify(paths))
        
        // 强制创建新数组引用，确保触发 UI 更新
        this.editImagePaths = [...paths]
        
        console.info('[NowPage] 图片数组已更新，当前数量: ' + this.editImagePaths.length)
      },
      onSave: () => {
        this.onSaveEdit()
      },
      onCancel: () => {
        this.showEditDialog = false
        this.editingRecord = null as LifeRecord | null
        this.editImagePaths = []
        this.editTags = []
      },
      saveImageToSandbox: async (uri: string) => {
        if (this.viewModel) {
          return await this.viewModel.saveImageToSandbox(uri)
        }
        return null
      }
    })
  }
  
  // 刷新时间线
  private refreshTimeline() {
    if (this.viewModel) {
      console.info('[NowPage] 开始刷新时间线')
      
      // 构建新的时间线数据
      const newTimelineData = this.viewModel.buildTimeline()
      
      // 深拷贝确保触发 @State 更新
      this.timelineData = JSON.parse(JSON.stringify(newTimelineData))
      
      // 增加刷新触发器
      this.refreshTrigger++
      
      console.info('[NowPage] 时间线刷新完成，年份数: ' + this.timelineData.years.length + 
        ', 总记录数: ' + this.getTotalRecordCount() + 
        ', trigger: ' + this.refreshTrigger)
    } else {
      console.warn('[NowPage] viewModel 未初始化，无法刷新')
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
        const tagName = this.getTagNameById(tagId)
        if (tagName && tagName.toLowerCase().includes(keyword)) {
          return true
        }
      }
    }
    
    return false
  }
  
  // 根据标签ID获取标签名称
  private getTagNameById(tagId: string): string | null {
    const tagMap: Record<string, string> = {
      'work': '工作',
      'life': '生活',
      'travel': '旅行',
      'food': '美食',
      'health': '健康',
      'study': '学习',
      'entertainment': '娱乐',
      'family': '家庭'
    }
    return tagMap[tagId] || null
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
        this.promptAction.showToast({ message: '请输入内容或添加图片' })
      } catch (error) {
        console.error('[NowPage] showToast failed: ' + JSON.stringify(error))
      }
      return
    }
    
    try {
      // 传递图片路径数组和标签数组
      const success = await this.viewModel.updateRecord(
        this.editingRecord.id,
        this.editContent.trim(),
        this.editImagePaths,  // ✅ 直接传递，空数组也会更新
        this.editTags  // ✅ 传递标签
      )
      
      if (success) {
        try {
          this.promptAction.showToast({ message: '修改成功' })
        } catch (error) {
          console.error('[NowPage] showToast failed: ' + JSON.stringify(error))
        }
        this.showEditDialog = false
        this.editingRecord = null as LifeRecord | null
        this.editImagePaths = []
        this.editTags = []
        // 触发全局刷新
        RefreshManager.getInstance().refresh()
        this.refreshTimeline()
      } else {
        try {
          this.promptAction.showToast({ message: '修改失败' })
        } catch (error) {
          console.error('[NowPage] showToast failed: ' + JSON.stringify(error))
        }
      }
    } catch (error) {
      console.error('[NowPage] 保存编辑失败: ' + JSON.stringify(error))
      try {
        this.promptAction.showToast({ message: '修改失败: ' + (error as Error).message })
      } catch (e) {
        console.error('[NowPage] showToast failed: ' + JSON.stringify(e))
      }
    }
  }
  
  
  // 删除记录
  private onDeleteRecord(record: LifeRecord) {
    this.getUIContext().showAlertDialog({
      title: '删除记录',
      message: '确定要删除这条记录吗？此操作不可恢复。',
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('[NowPage] 取消删除')
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: this.themeColors.error,
        action: async () => {
          if (!this.viewModel || !this.promptAction) {
            return
          }
          
          try {
            const success = await this.viewModel.deleteRecord(record.id)
            
            if (success) {
              try {
                this.promptAction.showToast({ message: '删除成功' })
              } catch (error) {
                console.error('[NowPage] showToast failed: ' + JSON.stringify(error))
              }
              // 触发全局刷新
              RefreshManager.getInstance().refresh()
              this.refreshTimeline()
            } else {
              try {
                this.promptAction.showToast({ message: '删除失败' })
              } catch (error) {
                console.error('[NowPage] showToast failed: ' + JSON.stringify(error))
              }
            }
          } catch (error) {
            console.error('[NowPage] 删除失败: ' + JSON.stringify(error))
            try {
              this.promptAction.showToast({ message: '删除失败: ' + (error as Error).message })
            } catch (e) {
              console.error('[NowPage] showToast failed: ' + JSON.stringify(e))
            }
          }
        }
      }
    })
  }
}

export { NowPage }
