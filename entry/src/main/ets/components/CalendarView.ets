// 日历视图组件：components/CalendarView.ets
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { TimelineData, LifeRecord } from '../common/types'

// 日历日期数据
interface CalendarDay {
  date: Date           // 日期对象
  year: number         // 年份
  month: number        // 月份（1-12）
  day: number          // 日期（1-31）
  isCurrentMonth: boolean  // 是否当前月份
  isToday: boolean     // 是否今天
  recordCount: number  // 当天记录数量
  records: LifeRecord[]  // 当天的记录
}

@Component
export struct CalendarView {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 时间线数据
  @Prop timelineData: TimelineData = { years: [] }
  
  // 当前显示的年月
  @State private currentYear: number = 0
  @State private currentMonth: number = 0
  
  // 选中的日期
  @State private selectedYear: number = 0
  @State private selectedMonth: number = 0
  @State private selectedDay: number = 0
  
  // 日历数据
  @State private calendarDays: CalendarDay[] = []
  
  // 记录点击回调
  onRecordsClick?: (records: LifeRecord[], dateStr: string) => void
  
  aboutToAppear() {
    const now = new Date()
    this.currentYear = now.getFullYear()
    this.currentMonth = now.getMonth() + 1
    this.selectedYear = this.currentYear
    this.selectedMonth = this.currentMonth
    this.selectedDay = now.getDate()
    
    this.buildCalendarDays()
  }
  
  // 构建日历数据
  private buildCalendarDays() {
    const days: CalendarDay[] = []
    
    // 获取当月第一天和最后一天
    const firstDay = new Date(this.currentYear, this.currentMonth - 1, 1)
    const lastDay = new Date(this.currentYear, this.currentMonth, 0)
    
    // 获取当月第一天是星期几（0=周日）
    const firstDayOfWeek = firstDay.getDay()
    
    // 获取上个月的天数
    const prevMonthLastDay = new Date(this.currentYear, this.currentMonth - 1, 0).getDate()
    
    // 今天的日期
    const today = new Date()
    const todayYear = today.getFullYear()
    const todayMonth = today.getMonth() + 1
    const todayDay = today.getDate()
    
    // 构建记录映射（用于快速查找）
    const recordMap = this.buildRecordMap()
    
    // 添加上个月的日期
    for (let i = firstDayOfWeek - 1; i >= 0; i--) {
      const day = prevMonthLastDay - i
      const prevMonth = this.currentMonth - 1 === 0 ? 12 : this.currentMonth - 1
      const prevYear = this.currentMonth - 1 === 0 ? this.currentYear - 1 : this.currentYear
      
      const key = `${prevYear}-${prevMonth}-${day}`
      const records = recordMap.get(key) || []
      
      days.push({
        date: new Date(prevYear, prevMonth - 1, day),
        year: prevYear,
        month: prevMonth,
        day: day,
        isCurrentMonth: false,
        isToday: false,
        recordCount: records.length,
        records: records
      })
    }
    
    // 添加当月的日期
    for (let day = 1; day <= lastDay.getDate(); day++) {
      const key = `${this.currentYear}-${this.currentMonth}-${day}`
      const records = recordMap.get(key) || []
      
      days.push({
        date: new Date(this.currentYear, this.currentMonth - 1, day),
        year: this.currentYear,
        month: this.currentMonth,
        day: day,
        isCurrentMonth: true,
        isToday: this.currentYear === todayYear && this.currentMonth === todayMonth && day === todayDay,
        recordCount: records.length,
        records: records
      })
    }
    
    // 添加下个月的日期（补齐6行）
    const remainingDays = 42 - days.length  // 6行 x 7列 = 42
    for (let day = 1; day <= remainingDays; day++) {
      const nextMonth = this.currentMonth + 1 === 13 ? 1 : this.currentMonth + 1
      const nextYear = this.currentMonth + 1 === 13 ? this.currentYear + 1 : this.currentYear
      
      const key = `${nextYear}-${nextMonth}-${day}`
      const records = recordMap.get(key) || []
      
      days.push({
        date: new Date(nextYear, nextMonth - 1, day),
        year: nextYear,
        month: nextMonth,
        day: day,
        isCurrentMonth: false,
        isToday: false,
        recordCount: records.length,
        records: records
      })
    }
    
    this.calendarDays = days
  }
  
  // 构建记录映射
  private buildRecordMap(): Map<string, LifeRecord[]> {
    const map = new Map<string, LifeRecord[]>()
    
    for (const yearNode of this.timelineData.years) {
      for (const monthNode of yearNode.months) {
        for (const dayNode of monthNode.days) {
          const key = `${yearNode.year}-${monthNode.month}-${dayNode.day}`
          map.set(key, dayNode.records)
        }
      }
    }
    
    return map
  }
  
  build() {
    Column() {
      // 月份导航
      this.MonthNavigator()
      
      // 星期标题
      this.WeekdayHeader()
      
      // 日历网格
      this.CalendarGrid()
      
      // 选中日期的记录预览
      if (this.selectedDay > 0) {
        this.SelectedDateRecords()
      }
    }
    .width('100%')
  }
  
  // 月份导航
  @Builder
  MonthNavigator() {
    Row() {
      // 上一月
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(20)
        .fontColor([this.themeColors.textSecondary])
        .onClick(() => {
          if (this.currentMonth === 1) {
            this.currentMonth = 12
            this.currentYear--
          } else {
            this.currentMonth--
          }
          this.buildCalendarDays()
        })
      
      // 当前年月
      Text(`${this.currentYear}年${this.currentMonth}月`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      // 下一月
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([this.themeColors.textSecondary])
        .onClick(() => {
          if (this.currentMonth === 12) {
            this.currentMonth = 1
            this.currentYear++
          } else {
            this.currentMonth++
          }
          this.buildCalendarDays()
        })
      
      // 今天按钮
      Text('今天')
        .fontSize(14)
        .fontColor(this.themeColors.primary)
        .margin({ left: 12 })
        .onClick(() => {
          const now = new Date()
          this.currentYear = now.getFullYear()
          this.currentMonth = now.getMonth() + 1
          this.selectedYear = this.currentYear
          this.selectedMonth = this.currentMonth
          this.selectedDay = now.getDate()
          this.buildCalendarDays()
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
  }
  
  // 星期标题
  @Builder
  WeekdayHeader() {
    Row() {
      ForEach(['日', '一', '二', '三', '四', '五', '六'], (day: string, index: number) => {
        Text(day)
          .fontSize(14)
          .fontColor(index === 0 || index === 6 ? this.themeColors.textSecondary : this.themeColors.textPrimary)
          .width('14.28%')
          .textAlign(TextAlign.Center)
      })
    }
    .width('100%')
    .height(36)
  }
  
  // 日历网格
  @Builder
  CalendarGrid() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.calendarDays, (calendarDay: CalendarDay, index: number) => {
        this.CalendarDayItem(calendarDay)
      }, (calendarDay: CalendarDay, index: number) => `day-${index}`)
    }
    .width('100%')
  }
  
  // 单个日期项
  @Builder
  CalendarDayItem(calendarDay: CalendarDay) {
    Column() {
      // 日期数字
      Text(calendarDay.day.toString())
        .fontSize(16)
        .fontWeight(calendarDay.isToday ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(
          !calendarDay.isCurrentMonth ? this.themeColors.textTertiary :
          calendarDay.isToday ? this.themeColors.primary :
          this.themeColors.textPrimary
        )
      
      // 记录指示点
      if (calendarDay.recordCount > 0) {
        Row() {
          ForEach(Array(Math.min(calendarDay.recordCount, 3)), (_: void, i: number) => {
            Column()
              .width(4)
              .height(4)
              .borderRadius(2)
              .backgroundColor(this.themeColors.primary)
              .margin({ right: i < Math.min(calendarDay.recordCount, 3) - 1 ? 2 : 0 })
          }, (_: void, i: number) => `dot-${i}`)
        }
        .margin({ top: 2 })
      }
    }
    .width('14.28%')
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(
      this.isSelected(calendarDay) ? this.themeColors.primaryLight + '30' :
      calendarDay.isToday ? this.themeColors.primaryLight + '15' :
      'transparent'
    )
    .borderRadius(8)
    .onClick(() => {
      this.selectedYear = calendarDay.year
      this.selectedMonth = calendarDay.month
      this.selectedDay = calendarDay.day
    })
  }
  
  // 判断是否选中
  private isSelected(calendarDay: CalendarDay): boolean {
    return calendarDay.year === this.selectedYear &&
           calendarDay.month === this.selectedMonth &&
           calendarDay.day === this.selectedDay
  }
  
  // 获取选中日期的记录
  private getSelectedRecords(): LifeRecord[] {
    const day = this.calendarDays.find(d => 
      d.year === this.selectedYear && d.month === this.selectedMonth && d.day === this.selectedDay
    )
    return day?.records || []
  }
  
  // 选中日期的记录预览
  @Builder
  SelectedDateRecords() {
    Column() {
      // 分隔线
      Divider()
        .color(this.themeColors.divider)
        .margin({ top: 16, bottom: 12 })
      
      // 日期标题
      Row() {
        Text(`${this.selectedMonth}月${this.selectedDay}日`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.textPrimary)
        
        Blank()
        
        Text(`${this.getSelectedRecords().length} 条记录`)
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 记录预览
      if (this.getSelectedRecords().length > 0) {
        Column() {
          ForEach(this.getSelectedRecords().slice(0, 3), (record: LifeRecord, index: number) => {
            Row() {
              Text(record.content.length > 50 ? record.content.substring(0, 50) + '...' : record.content)
                .fontSize(14)
                .fontColor(this.themeColors.textPrimary)
                .layoutWeight(1)
                .lineHeight(20)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(this.themeColors.cardBackground)
            .borderRadius(8)
            .margin({ bottom: index < Math.min(this.getSelectedRecords().length, 3) - 1 ? 8 : 0 })
          }, (record: LifeRecord) => record.id)
          
          if (this.getSelectedRecords().length > 3) {
            Text(`还有 ${this.getSelectedRecords().length - 3} 条记录...`)
              .fontSize(12)
              .fontColor(this.themeColors.textSecondary)
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          }
        }
        .width('100%')
        
        // 查看全部按钮
        Button('查看全部记录')
          .width('100%')
          .height(36)
          .backgroundColor(this.themeColors.primary)
          .fontColor('#FFFFFF')
          .fontSize(14)
          .borderRadius(8)
          .margin({ top: 12 })
          .onClick(() => {
            if (this.onRecordsClick) {
              const dateStr = `${this.selectedYear}年${this.selectedMonth}月${this.selectedDay}日`
              this.onRecordsClick(this.getSelectedRecords(), dateStr)
            }
          })
      } else {
        Text('这一天没有记录')
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(20)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }
}
