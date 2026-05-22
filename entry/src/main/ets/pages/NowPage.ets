// 现在页面：pages/NowPage.ets
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { TimelineData, LifeRecord } from '../common/types'
import { NowViewModel } from '../viewmodel/NowViewModel'
import { TimelineSection } from '../components/TimelineSection'
import { AddRecordSection } from '../components/AddRecordSection'
import { EditRecordDialog } from '../components/EditRecordDialog'
import { RefreshManager } from '../common/RefreshManager'
import { PromptAction } from '@kit.ArkUI'

@Entry
@Component
struct NowPage {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 时间线数据
  @State private timelineData: TimelineData = { years: [] }
  
  // 刷新触发器（用于强制刷新）
  @State private refreshTrigger: number = 0
  
  // 正在编辑的记录
  @State private editingRecord: LifeRecord | null = null
  @State private showEditDialog: boolean = false
  @State private editContent: string = ''
  
  // 编辑图片时的临时变量
  @State private editImagePath: string = ''
  @State private editImageUri: string = ''
  
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
          // 页面标题
          Row() {
            Text('此刻')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
            
            Blank()
            
            // 统计信息
            if (this.timelineData.years.length > 0) {
              Text(this.getTotalRecordCount() + ' 条记录')
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
            }
          }
          .width('100%')
          .padding({ left: 4, right: 4, bottom: 16 })
          
          // 时间线内容
          TimelineSection({
            timelineData: this.timelineData,
            timelineDataVersion: this.refreshTrigger,
            onEditRecord: (record: LifeRecord) => {
              this.onEditRecord(record)
            },
            onDeleteRecord: (record: LifeRecord) => {
              this.onDeleteRecord(record)
            }
          })
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
      editImagePath: $editImagePath,
      editImageUri: $editImageUri,
      onSave: () => {
        this.onSaveEdit()
      },
      onCancel: () => {
        this.showEditDialog = false
        this.editingRecord = null as LifeRecord | null
        this.editImagePath = ''
        this.editImageUri = ''
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
  
  // 编辑记录
  private onEditRecord(record: LifeRecord) {
    this.editingRecord = record
    this.editContent = record.content
    
    // 如果有图片，初始化图片路径和 URI（统一为 URI 格式）
    if (record.imagePath) {
      this.editImagePath = record.imagePath  // 已经是 URI 格式
      this.editImageUri = record.imagePath   // 直接使用，无需转换
    } else {
      this.editImagePath = ''
      this.editImageUri = ''
    }
    
    this.showEditDialog = true
  }
  
  // 保存编辑
  private async onSaveEdit() {
    if (!this.viewModel || !this.editingRecord || !this.promptAction) {
      return
    }
    
    // 至少需要文字或图片
    if (this.editContent.trim().length === 0 && this.editImagePath.length === 0) {
      try {
        this.promptAction.showToast({ message: '请输入内容或添加图片' })
      } catch (error) {
        console.error('[NowPage] showToast failed: ' + JSON.stringify(error))
      }
      return
    }
    
    try {
      // 直接传递 editImagePath，空字符串表示移除图片
      const success = await this.viewModel.updateRecord(
        this.editingRecord.id,
        this.editContent.trim(),
        this.editImagePath  // 空字符串表示移除图片
      )
      
      if (success) {
        try {
          this.promptAction.showToast({ message: '修改成功' })
        } catch (error) {
          console.error('[NowPage] showToast failed: ' + JSON.stringify(error))
        }
        this.showEditDialog = false
        this.editingRecord = null as LifeRecord | null
        this.editImagePath = ''
        this.editImageUri = ''
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
