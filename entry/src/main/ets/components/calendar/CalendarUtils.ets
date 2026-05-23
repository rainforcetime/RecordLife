// 日历工具类：components/calendar/CalendarUtils.ets
import { TimelineData, LifeRecord, CalendarDay } from '../../common/types'

/**
 * 日历工具类
 * 提供日历相关的计算和数据处理方法
 */
export class CalendarUtils {
  /**
   * 构建日历数据（只显示当前月份）
   * @param year 当前年份
   * @param month 当前月份
   * @param timelineData 时间线数据
   * @returns 日历日期数组
   */
  static buildCalendarDays(year: number, month: number, timelineData: TimelineData): CalendarDay[] {
    const days: CalendarDay[] = []
    
    // 获取当月第一天和最后一天
    const firstDay = new Date(year, month - 1, 1)
    const lastDay = new Date(year, month, 0)
    
    console.info(`[CalendarUtils] 构建日历: ${year}年${month}月, 天数: ${lastDay.getDate()}`)
    
    // 获取当月第一天是星期几（0=周日）
    const firstDayOfWeek = firstDay.getDay()
    
    // 今天的日期
    const today = new Date()
    const todayYear = today.getFullYear()
    const todayMonth = today.getMonth() + 1
    const todayDay = today.getDate()
    
    // 构建记录映射（用于快速查找）
    const recordMap = CalendarUtils.buildRecordMap(timelineData)
    
    // 添加前面的空白占位（day = 0 表示空白）
    for (let i = 0; i < firstDayOfWeek; i++) {
      days.push({
        date: new Date(),
        year: 0,
        month: 0,
        day: 0,  // 空白标记
        isCurrentMonth: false,
        isToday: false,
        recordCount: 0,
        records: []
      })
    }
    
    // 添加当月的日期
    for (let day = 1; day <= lastDay.getDate(); day++) {
      const key = `${year}-${month}-${day}`
      const records = recordMap.get(key) || []
      
      days.push({
        date: new Date(year, month - 1, day),
        year: year,
        month: month,
        day: day,
        isCurrentMonth: true,
        isToday: year === todayYear && month === todayMonth && day === todayDay,
        recordCount: records.length,
        records: records
      })
    }
    
    // 添加后面的空白占位，补齐到完整的行
    const remainingDays = (7 - (days.length % 7)) % 7
    for (let i = 0; i < remainingDays; i++) {
      days.push({
        date: new Date(),
        year: 0,
        month: 0,
        day: 0,  // 空白标记
        isCurrentMonth: false,
        isToday: false,
        recordCount: 0,
        records: []
      })
    }
    
    return days
  }
  
  /**
   * 构建记录映射
   * @param timelineData 时间线数据
   * @returns 日期到记录的映射
   */
  static buildRecordMap(timelineData: TimelineData): Map<string, LifeRecord[]> {
    const map = new Map<string, LifeRecord[]>()
    
    for (const yearNode of timelineData.years) {
      for (const monthNode of yearNode.months) {
        for (const dayNode of monthNode.days) {
          const key = `${yearNode.year}-${monthNode.month}-${dayNode.day}`
          map.set(key, dayNode.records)
        }
      }
    }
    
    return map
  }
  
  /**
   * 检查是否有图片记录
   * @param records 记录数组
   * @returns 是否包含图片
   */
  static hasImageRecords(records: LifeRecord[]): boolean {
    return records.some(r => r.imagePaths && r.imagePaths.length > 0)
  }
  
  /**
   * 检查是否有标签记录
   * @param records 记录数组
   * @returns 是否包含标签
   */
  static hasTagRecords(records: LifeRecord[]): boolean {
    return records.some(r => r.tags && r.tags.length > 0)
  }
  
  /**
   * 判断日期是否选中
   * @param calendarDay 日历日期
   * @param selectedYear 选中年份
   * @param selectedMonth 选中月份
   * @param selectedDay 选中日期
   * @returns 是否选中
   */
  static isSelected(calendarDay: CalendarDay, selectedYear: number, selectedMonth: number, selectedDay: number): boolean {
    return calendarDay.year === selectedYear &&
           calendarDay.month === selectedMonth &&
           calendarDay.day === selectedDay
  }
  
  /**
   * 获取星期文本
   * @param year 年份
   * @param month 月份
   * @param day 日期
   * @returns 星期文本
   */
  static getWeekdayText(year: number, month: number, day: number): string {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    const date = new Date(year, month - 1, day)
    return weekdays[date.getDay()]
  }
  
  /**
   * 格式化时间
   * @param timestamp 时间戳
   * @returns 格式化后的时间字符串
   */
  static formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    return `${hours}:${minutes}`
  }
  
  /**
   * 获取日期颜色
   * @param calendarDay 日历日期
   * @param isSelected 是否选中
   * @param textPrimary 主要文本颜色
   * @param textSecondary 次要文本颜色
   * @param textTertiary 第三文本颜色
   * @param primary 主题色
   * @param isCurrentMonth 是否当前月（可选，优先使用）
   * @returns 日期颜色
   */
  static getDayColor(
    calendarDay: CalendarDay,
    isSelected: boolean,
    textPrimary: string,
    textSecondary: string,
    textTertiary: string,
    primary: string,
    isCurrentMonth?: boolean
  ): string {
    // 使用传入的 isCurrentMonth 或 calendarDay.isCurrentMonth
    const currentMonth = isCurrentMonth !== undefined ? isCurrentMonth : calendarDay.isCurrentMonth
    
    // 1. 非当前月份的日期：灰色
    if (!currentMonth) {
      return textTertiary
    }
    
    // 2. 被选中的日期：白色
    if (isSelected) {
      return '#FFFFFF'
    }
    
    // 3. 今天的日期（未被选中）：主题色
    if (calendarDay.isToday) {
      return primary
    }
    
    // 4. 当前月份的普通日期：主要文本色
    return textPrimary
  }
}
