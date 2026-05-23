// 日历视图组件：components/CalendarView.ets
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { TimelineData, LifeRecord, CalendarDay } from '../common/types'
import { CalendarUtils } from './calendar/CalendarUtils'
import { CalendarMonthNavigator } from './calendar/CalendarMonthNavigator'
import { CalendarDayItem } from './calendar/CalendarDayItem'
import { CalendarSelectedRecords } from './calendar/CalendarSelectedRecords'

/**
 * 日历视图组件
 * 提供日历展示和日期选择功能
 */
@Component
export struct CalendarView {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 时间线数据（使用 @Watch 监听变化）
  @Prop @Watch('onTimelineDataChange') timelineData: TimelineData = { years: [] }
  
  // 当前显示的年月
  @State private currentYear: number = 0
  @State private currentMonth: number = 0
  
  // 选中的日期
  @State selectedYear: number = 0
  @State selectedMonth: number = 0
  @State selectedDay: number = 0
  
  // 日历数据
  @State private calendarDays: CalendarDay[] = []
  
  // 缓存选中日期的记录（避免重复计算）
  @State private selectedRecords: LifeRecord[] = []
  
  // 记录点击回调
  onRecordsClick?: (records: LifeRecord[], dateStr: string) => void
  
  // 监听 timelineData 变化
  onTimelineDataChange() {
    console.info('[CalendarView] timelineData 变化，重新构建日历')
    this.buildCalendarDays()
    this.updateSelectedRecords()
  }
  
  aboutToAppear() {
    const now = new Date()
    this.currentYear = now.getFullYear()
    this.currentMonth = now.getMonth() + 1
    this.selectedYear = this.currentYear
    this.selectedMonth = this.currentMonth
    this.selectedDay = now.getDate()
    
    this.buildCalendarDays()
    this.updateSelectedRecords()
  }
  
  // 构建日历数据
  private buildCalendarDays() {
    this.calendarDays = CalendarUtils.buildCalendarDays(
      this.currentYear,
      this.currentMonth,
      this.timelineData
    )
  }
  
  // 更新选中日期的记录缓存
  private updateSelectedRecords() {
    const day = this.calendarDays.find(d =>
      d.year === this.selectedYear &&
      d.month === this.selectedMonth &&
      d.day === this.selectedDay
    )
    this.selectedRecords = day?.records || []
    console.info(`[CalendarView] 更新选中记录缓存: ${this.selectedRecords.length} 条`)
  }
  
  build() {
    Column() {
      // 月份导航
      CalendarMonthNavigator({
        currentYear: $currentYear,
        currentMonth: $currentMonth,
        selectedYear: $selectedYear,
        selectedMonth: $selectedMonth,
        selectedDay: $selectedDay,
        onMonthChange: () => {
          this.buildCalendarDays()
        }
      })
      
      // 日历主体（带背景卡片）
      Column() {
        // 星期标题
        this.WeekdayHeader()
        
        // 日历网格
        this.CalendarGrid()
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 12 })
      .backgroundColor(this.themeColors.cardBackground)
      .borderRadius(16)
      .margin({ left: 16, right: 16, top: 8 })
      .shadow({
        radius: 8,
        color: this.themeColors.shadow,
        offsetX: 0,
        offsetY: 2
      })
      
      // 选中日期的记录预览
      if (this.selectedDay > 0) {
        CalendarSelectedRecords({
          selectedYear: this.selectedYear,
          selectedMonth: this.selectedMonth,
          selectedDay: this.selectedDay,
          selectedRecords: this.selectedRecords,
          onRecordsClick: this.onRecordsClick
        })
      }
    }
    .width('100%')
  }
  
  // 星期标题
  @Builder
  WeekdayHeader() {
    Row() {
      ForEach(['日', '一', '二', '三', '四', '五', '六'], (day: string, index: number) => {
        Text(day)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(
            index === 0 || index === 6 ? 
            this.themeColors.primary : 
            this.themeColors.textSecondary
          )
          .width('14.28%')
          .textAlign(TextAlign.Center)
      })
    }
    .width('100%')
    .height(40)
    .padding({ top: 8, bottom: 8 })
  }
  
  // 日历网格
  @Builder
  CalendarGrid() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.calendarDays, (calendarDay: CalendarDay, index: number) => {
        CalendarDayItem({
          calendarDay: calendarDay,
          isCurrentMonth: calendarDay.isCurrentMonth,
          selectedYear: $selectedYear,
          selectedMonth: $selectedMonth,
          selectedDay: $selectedDay,
          onDayClick: (year: number, month: number, day: number) => {
            this.selectedYear = year
            this.selectedMonth = month
            this.selectedDay = day
            this.updateSelectedRecords()
          }
        })
      }, (calendarDay: CalendarDay, index: number) => `${calendarDay.year}-${calendarDay.month}-${calendarDay.day}`)
    }
    .width('100%')
  }
}
