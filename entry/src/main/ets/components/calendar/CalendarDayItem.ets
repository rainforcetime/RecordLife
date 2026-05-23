// 日历日期项组件：components/calendar/CalendarDayItem.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { CalendarDay } from '../../common/types'
import { CalendarUtils } from './CalendarUtils'

/**
 * 日历日期项组件
 * 显示单个日期及其记录指示器
 */
@Component
export struct CalendarDayItem {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 日历日期数据
  @Prop calendarDay: CalendarDay = {
    date: new Date(),
    year: 0,
    month: 0,
    day: 0,
    isCurrentMonth: false,
    isToday: false,
    recordCount: 0,
    records: []
  }
  
  // 关键属性单独传递，确保状态更新
  @Prop isCurrentMonth: boolean = false
  
  // 选中的日期（使用 @Link 确保状态同步）
  @Link @Watch('onSelectedChange') selectedYear: number
  @Link @Watch('onSelectedChange') selectedMonth: number
  @Link @Watch('onSelectedChange') selectedDay: number
  
  // 是否选中（计算属性）
  @State private isSelected: boolean = false
  
  // 点击回调
  onDayClick?: (year: number, month: number, day: number) => void
  
  // 监听选中日期变化
  onSelectedChange() {
    this.isSelected = this.calendarDay.year === this.selectedYear &&
                      this.calendarDay.month === this.selectedMonth &&
                      this.calendarDay.day === this.selectedDay
  }
  
  aboutToAppear() {
    this.onSelectedChange()
  }
  
  build() {
    // 如果是空白位置（day = 0），显示空占位
    if (this.calendarDay.day === 0) {
      Column()
        .width('14.28%')
        .height(56)
    } else {
      Column() {
        // 日期数字
        Text(this.calendarDay.day.toString())
          .fontSize(16)
          .fontWeight(this.calendarDay.isToday ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(
            this.isSelected ? '#FFFFFF' :
            this.calendarDay.isToday ? this.themeColors.primary : this.themeColors.textPrimary
          )
          .height(24)
        
        // 记录指示器
        if (this.calendarDay.recordCount > 0) {
          this.RecordIndicator()
        } else {
          // 占位，保持高度一致
          Column()
            .height(16)
        }
      }
      .width('14.28%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(
        this.isSelected ? this.themeColors.primary :
        this.calendarDay.isToday ? this.themeColors.primary + '20' : 'transparent'
      )
      .borderRadius(this.isSelected ? 28 : 8)
      .onClick(() => {
        if (this.onDayClick) {
          this.onDayClick(this.calendarDay.year, this.calendarDay.month, this.calendarDay.day)
        }
      })
    }
  }
  
  // 记录指示器
  @Builder
  RecordIndicator() {
    Row() {
      // 检查是否有图片记录
      if (CalendarUtils.hasImageRecords(this.calendarDay.records)) {
        this.ImageIcon()
      }
      
      // 检查是否有标签记录
      if (CalendarUtils.hasTagRecords(this.calendarDay.records)) {
        this.TagIcon()
      }
      
      // 记录数量指示
      if (this.calendarDay.recordCount <= 3) {
        this.DotIndicator()
      } else {
        this.NumberBadge()
      }
    }
    .margin({ top: 2 })
    .height(14)
    .justifyContent(FlexAlign.Center)
  }
  
  // 图片图标
  @Builder
  ImageIcon() {
    Row() {
      SymbolGlyph($r('sys.symbol.camera'))
        .fontSize(8)
        .fontColor(['#FFFFFF'])
    }
    .width(14)
    .height(14)
    .backgroundColor(this.themeColors.primary)
    .borderRadius(7)
    .justifyContent(FlexAlign.Center)
    .margin({ right: 2 })
  }
  
  // 标签图标
  @Builder
  TagIcon() {
    Row() {
      SymbolGlyph($r('sys.symbol.bookmark'))
        .fontSize(8)
        .fontColor(['#FFFFFF'])
    }
    .width(14)
    .height(14)
    .backgroundColor(this.themeColors.success)
    .borderRadius(7)
    .justifyContent(FlexAlign.Center)
    .margin({ right: 2 })
  }
  
  // 点状指示器
  @Builder
  DotIndicator() {
    Row() {
      ForEach(Array(this.calendarDay.recordCount), (_: void, i: number) => {
        Column()
          .width(5)
          .height(5)
          .borderRadius(2.5)
          .backgroundColor(this.themeColors.primary)
          .margin({ right: i < this.calendarDay.recordCount - 1 ? 2 : 0 })
      }, (_: void, i: number) => `dot-${i}`)
    }
    .height(14)
    .justifyContent(FlexAlign.Center)
  }
  
  // 数字徽章
  @Builder
  NumberBadge() {
    Text(`${this.calendarDay.recordCount}`)
      .fontSize(9)
      .fontColor('#FFFFFF')
      .fontWeight(FontWeight.Bold)
      .backgroundColor(this.themeColors.primary)
      .borderRadius(8)
      .padding({ left: 5, right: 5, top: 1, bottom: 1 })
      .height(14)
  }
}
