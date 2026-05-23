// 选中日期记录预览组件：components/calendar/CalendarSelectedRecords.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { LifeRecord } from '../../common/types'
import { CalendarUtils } from './CalendarUtils'

/**
 * 选中日期记录预览组件
 * 显示选中日期的记录列表预览
 */
@Component
export struct CalendarSelectedRecords {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 选中的日期
  @Prop selectedYear: number = 0
  @Prop selectedMonth: number = 0
  @Prop selectedDay: number = 0
  
  // 选中的记录
  @Prop selectedRecords: LifeRecord[] = []
  
  // 记录点击回调
  onRecordsClick?: (records: LifeRecord[], dateStr: string) => void
  
  build() {
    Column() {
      // 日期标题区域
      this.DateHeader()
      
      // 记录预览
      if (this.selectedRecords.length > 0) {
        this.RecordsList()
      } else {
        this.EmptyState()
      }
    }
    .width('100%')
    .backgroundColor(this.themeColors.background)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .margin({ top: 16 })
    .shadow({
      radius: 12,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: -4
    })
  }
  
  // 日期标题区域
  @Builder
  DateHeader() {
    Row() {
      Column() {
        Row() {
          Text(`${this.selectedMonth}月${this.selectedDay}日`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeColors.textPrimary)
          
          // 星期显示
          Text(this.weekdayText)
            .fontSize(14)
            .fontColor(this.themeColors.textSecondary)
            .margin({ left: 8 })
        }
        
        Text(`${this.selectedRecords.length} 条记录`)
          .fontSize(13)
          .fontColor(this.themeColors.textSecondary)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 查看全部按钮
      if (this.selectedRecords.length > 0) {
        this.ViewAllButton()
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
  }
  
  // 查看全部按钮
  @Builder
  ViewAllButton() {
    Row() {
      SymbolGlyph($r('sys.symbol.list_bullet'))
        .fontSize(14)
        .fontColor([this.themeColors.primary])
        .margin({ right: 4 })
      
      Text('全部')
        .fontSize(13)
        .fontColor(this.themeColors.primary)
        .fontWeight(FontWeight.Medium)
    }
    .height(32)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.themeColors.primary + '15')
    .borderRadius(16)
    .onClick(() => {
      if (this.onRecordsClick) {
        const dateStr = `${this.selectedYear}年${this.selectedMonth}月${this.selectedDay}日`
        this.onRecordsClick(this.selectedRecords, dateStr)
      }
    })
  }
  
  // 记录列表
  @Builder
  RecordsList() {
    Column() {
      ForEach(this.selectedRecords.slice(0, 3), (record: LifeRecord, index: number) => {
        this.RecordItem(record, index)
      }, (record: LifeRecord) => record.id)
      
      // 更多记录提示
      if (this.selectedRecords.length > 3) {
        this.MoreRecordsHint()
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
  }
  
  // 单条记录项
  @Builder
  RecordItem(record: LifeRecord, index: number) {
    Row() {
      // 记录类型图标
      this.RecordTypeIcon(record)
      
      // 记录内容
      Column() {
        Text(record.content.length > 40 ? record.content.substring(0, 40) + '...' : record.content)
          .fontSize(14)
          .fontColor(this.themeColors.textPrimary)
          .lineHeight(20)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        // 时间标签
        if (record.timestamp) {
          Text(CalendarUtils.formatTime(record.timestamp))
            .fontSize(11)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(12)
    .margin({ bottom: index < Math.min(this.selectedRecords.length, 3) - 1 ? 8 : 0 })
    .shadow({
      radius: 4,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 1
    })
  }
  
  // 记录类型图标
  @Builder
  RecordTypeIcon(record: LifeRecord) {
    Row() {
      if (record.imagePaths && record.imagePaths.length > 0) {
        SymbolGlyph($r('sys.symbol.camera'))
          .fontSize(12)
          .fontColor([this.themeColors.primary])
      } else if (record.tags && record.tags.length > 0) {
        SymbolGlyph($r('sys.symbol.bookmark'))
          .fontSize(12)
          .fontColor([this.themeColors.success])
      } else {
        SymbolGlyph($r('sys.symbol.doc_text'))
          .fontSize(12)
          .fontColor([this.themeColors.textSecondary])
      }
    }
    .width(24)
    .height(24)
    .backgroundColor(this.getRecordIconBackground(record))
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .margin({ right: 12 })
  }
  
  // 更多记录提示
  @Builder
  MoreRecordsHint() {
    Row() {
      Text(`还有 ${this.selectedRecords.length - 3} 条记录`)
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)
      
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(14)
        .fontColor([this.themeColors.textSecondary])
        .margin({ left: 4 })
    }
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.onRecordsClick) {
        const dateStr = `${this.selectedYear}年${this.selectedMonth}月${this.selectedDay}日`
        this.onRecordsClick(this.selectedRecords, dateStr)
      }
    })
  }
  
  // 空状态
  @Builder
  EmptyState() {
    Column() {
      SymbolGlyph($r('sys.symbol.doc_text'))
        .fontSize(48)
        .fontColor([this.themeColors.textTertiary])
        .margin({ bottom: 12 })
      
      Text('这一天没有记录')
        .fontSize(15)
        .fontColor(this.themeColors.textSecondary)
      
      Text('点击日期可添加新记录')
        .fontSize(13)
        .fontColor(this.themeColors.textTertiary)
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(32)
  }
  
  // 获取星期文本
  private get weekdayText(): string {
    return CalendarUtils.getWeekdayText(this.selectedYear, this.selectedMonth, this.selectedDay)
  }
  
  // 获取记录图标背景色
  private getRecordIconBackground(record: LifeRecord): string {
    if (record.imagePaths && record.imagePaths.length > 0) {
      return this.themeColors.primary + '20'
    }
    if (record.tags && record.tags.length > 0) {
      return this.themeColors.success + '20'
    }
    return this.themeColors.cardBackground
  }
}
