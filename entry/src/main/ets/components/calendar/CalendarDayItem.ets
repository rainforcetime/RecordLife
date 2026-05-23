// 日历日期项组件：components/calendar/CalendarDayItem.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { CalendarDay } from '../../common/types'
import { CalendarUtils } from './CalendarUtils'
import { ColorUtils } from '../../common/ColorUtils'

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
  
  // 判断是否为深色模式
  private isDarkMode(): boolean {
    console.log('[CalendarDayItem]', this.themeColors.textPrimary);
    console.log(this.themeColors.textPrimary);
    return this.themeColors.textPrimary === '#FFFFFF'
  }
  
  // 获取选中背景色（适配深色模式）
  private getSelectedBgColor(): string {
    // 深色模式使用更高的透明度
    const alpha = this.isDarkMode() ? 64 : 38 // 25% vs 15%
    return ColorUtils.withAlpha(this.themeColors.primary, alpha)
  }
  
  // 获取今天背景色（更浅，与选中区分）
  private getTodayBgColor(): string {
    // 今天使用更浅的背景，与选中状态区分
    const alpha = this.isDarkMode() ? 30 : 20 // 12% vs 8%
    return ColorUtils.withAlpha(this.themeColors.primary, alpha)
  }
  
  build() {
    // 如果是空白位置（day = 0），显示空占位
    if (this.calendarDay.day === 0) {
      Column()
        .width('14.28%')
        .height(56)
    } else {
      Column() {
        // 日期数字（带选中框）
        Column() {
          Text(this.calendarDay.day.toString())
            .fontSize(16)
            .fontWeight(this.calendarDay.isToday || this.isSelected ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(
              this.calendarDay.isToday ? this.themeColors.primary :
              this.isSelected ? this.themeColors.primary : this.themeColors.textPrimary
            )
        }
        .width(32)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(
          this.isSelected ? this.getSelectedBgColor() :
          this.calendarDay.isToday ? this.getTodayBgColor() : 'transparent'
        )
        .borderRadius(8)
        .border({
          width: this.isSelected ? 2 : (this.calendarDay.isToday ? 1 : 0),
          color: this.themeColors.primary,
          style: this.isSelected ? BorderStyle.Solid : (this.calendarDay.isToday ? BorderStyle.Dashed : BorderStyle.Solid)
        })
        
        // 记录小点标识（紧贴选中框下方）
        if (this.calendarDay.recordCount > 0) {
          Column()
            .width(4)
            .height(4)
            .borderRadius(2)
            .backgroundColor(this.themeColors.primary)
            .margin({ top: 2 })
        } else {
          // 无记录时占位
          Column()
            .height(6)
        }
        
        // 记录类型指示器（相机、书签等）
        if (this.calendarDay.recordCount > 0) {
          this.RecordIndicator()
        } else {
          // 占位，保持高度一致
          Column()
            .height(14)
        }
      }
      .width('14.28%')
      .height(56)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 2 })
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
