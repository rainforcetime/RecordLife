// 月份导航组件：components/calendar/CalendarMonthNavigator.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

/**
 * 月份导航组件
 * 用于切换月份和快速跳转到今天
 */
@Component
export struct CalendarMonthNavigator {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 当前年份和月份
  @Link currentYear: number
  @Link currentMonth: number
  
  // 选中的日期（用于"今天"按钮）
  @Link selectedYear: number
  @Link selectedMonth: number
  @Link selectedDay: number
  
  // 月份变化回调
  onMonthChange?: () => void
  
  build() {
    Row() {
      // 上一月按钮
      this.PrevMonthButton()
      
      // 当前年月显示
      this.CurrentYearMonth()
      
      // 下一月按钮
      this.NextMonthButton()
      
      // 今天按钮
      this.TodayButton()
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
  }
  
  // 上一月按钮
  @Builder
  PrevMonthButton() {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(18)
        .fontColor([this.themeColors.textSecondary])
    }
    .width(36)
    .height(36)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(18)
    .shadow({
      radius: 4,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 1
    })
    .onClick(() => {
      if (this.currentMonth === 1) {
        this.currentMonth = 12
        this.currentYear--
      } else {
        this.currentMonth--
      }
      if (this.onMonthChange) {
        this.onMonthChange()
      }
    })
  }
  
  // 当前年月显示
  @Builder
  CurrentYearMonth() {
    Column() {
      Text(`${this.currentYear}年`)
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
        .height(18)
      
      Text(`${this.currentMonth}月`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .height(28)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
  
  // 下一月按钮
  @Builder
  NextMonthButton() {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontColor([this.themeColors.textSecondary])
    }
    .width(36)
    .height(36)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(18)
    .shadow({
      radius: 4,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 1
    })
    .onClick(() => {
      if (this.currentMonth === 12) {
        this.currentMonth = 1
        this.currentYear++
      } else {
        this.currentMonth++
      }
      if (this.onMonthChange) {
        this.onMonthChange()
      }
    })
  }
  
  // 今天按钮
  @Builder
  TodayButton() {
    Row() {
      SymbolGlyph($r('sys.symbol.calendar'))
        .fontSize(16)
        .fontColor([this.themeColors.primary])
        .margin({ right: 4 })
      
      Text('今天')
        .fontSize(14)
        .fontColor(this.themeColors.primary)
        .fontWeight(FontWeight.Medium)
    }
    .height(36)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.themeColors.primary + '15')
    .borderRadius(18)
    .margin({ left: 12 })
    .onClick(() => {
      const now = new Date()
      this.currentYear = now.getFullYear()
      this.currentMonth = now.getMonth() + 1
      this.selectedYear = this.currentYear
      this.selectedMonth = this.currentMonth
      this.selectedDay = now.getDate()
      if (this.onMonthChange) {
        this.onMonthChange()
      }
    })
  }
}
