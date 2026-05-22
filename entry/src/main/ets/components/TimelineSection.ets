// 时间线区域组件：components/TimelineSection.ets
import { TimelineData, TimelineYear, TimelineMonth, TimelineDay, LifeRecord } from '../common/types'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { RecordCard } from './RecordCard'

@Component
export struct TimelineSection {
  @Prop timelineData: TimelineData = { years: [] }
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 展开状态管理
  @State private expandedYears: Set<number> = new Set()
  @State private expandedMonths: Set<string> = new Set()
  @State private expandedDays: Set<string> = new Set()
  
  // 回调函数
  onEditRecord?: (record: LifeRecord) => void
  onDeleteRecord?: (record: LifeRecord) => void
  
  // 监听 timelineData 变化
  @Watch('onTimelineDataChange')
  @Prop timelineDataVersion: number = 0
  
  // 记录上次的版本号，避免重复初始化
  private lastVersion: number = -1
  
  // 标记是否首次加载
  private isFirstLoad: boolean = true
  
  aboutToAppear() {
    this.initExpandedState()
  }
  
  // 当 timelineData 改变时重新初始化展开状态
  private onTimelineDataChange() {
    console.info('[TimelineSection] timelineDataVersion 改变: ' + this.timelineDataVersion + ', lastVersion: ' + this.lastVersion)
    
    // 只在版本号真正改变时才重新初始化
    if (this.timelineDataVersion !== this.lastVersion) {
      this.lastVersion = this.timelineDataVersion
      this.initExpandedState()
    }
  }
  
  private initExpandedState() {
    if (this.isFirstLoad) {
      // 首次加载：初始化当前年月展开状态
      this.isFirstLoad = false
      const now = new Date()
      const currentYear = now.getFullYear()
      const currentMonth = now.getMonth() + 1
      
      for (const yearNode of this.timelineData.years) {
        if (yearNode.year === currentYear) {
          this.expandedYears.add(yearNode.year)
          for (const monthNode of yearNode.months) {
            if (monthNode.month === currentMonth) {
              this.expandedMonths.add(`${yearNode.year}-${monthNode.month}`)
              break
            }
          }
          break
        }
      }
      console.info('[TimelineSection] 首次加载，初始化当前年月展开状态')
    } else {
      // 刷新时：清理无效节点（数据已删除的）
      this.cleanupInvalidStates()
      console.info('[TimelineSection] 数据刷新，保留用户展开状态并清理无效节点')
    }
    
    // 触发状态更新
    this.expandedYears = new Set(this.expandedYears)
    this.expandedMonths = new Set(this.expandedMonths)
    this.expandedDays = new Set(this.expandedDays)
    
    console.info('[TimelineSection] 展开状态: 年份 ' + this.expandedYears.size + 
      ', 月份 ' + this.expandedMonths.size + ', 日期 ' + this.expandedDays.size)
  }
  
  // 清理无效的展开状态（对应数据已删除）
  private cleanupInvalidStates() {
    // 构建当前有效的年月日集合
    const validYears = new Set<number>()
    const validMonths = new Set<string>()
    const validDays = new Set<string>()
    
    for (const yearNode of this.timelineData.years) {
      validYears.add(yearNode.year)
      for (const monthNode of yearNode.months) {
        validMonths.add(`${yearNode.year}-${monthNode.month}`)
        for (const dayNode of monthNode.days) {
          validDays.add(`${yearNode.year}-${monthNode.month}-${dayNode.day}`)
        }
      }
    }
    
    // 过滤掉无效的展开状态
    const oldYearCount = this.expandedYears.size
    const oldMonthCount = this.expandedMonths.size
    const oldDayCount = this.expandedDays.size
    
    this.expandedYears = new Set(Array.from(this.expandedYears).filter(y => validYears.has(y)))
    this.expandedMonths = new Set(Array.from(this.expandedMonths).filter(m => validMonths.has(m)))
    this.expandedDays = new Set(Array.from(this.expandedDays).filter(d => validDays.has(d)))
    
    // 日志记录清理情况
    if (oldYearCount !== this.expandedYears.size || 
        oldMonthCount !== this.expandedMonths.size || 
        oldDayCount !== this.expandedDays.size) {
      console.info('[TimelineSection] 清理无效节点: 年份 ' + (oldYearCount - this.expandedYears.size) + 
        ', 月份 ' + (oldMonthCount - this.expandedMonths.size) + 
        ', 日期 ' + (oldDayCount - this.expandedDays.size))
    }
  }
  
  build() {
    Column() {
      if (this.timelineData.years.length === 0) {
        // 空状态
        this.EmptyState()
      } else {
        // 时间线内容
        // 使用版本号+年份作为 key，确保数据变化时强制刷新
        ForEach(this.timelineData.years, (yearNode: TimelineYear, yearIndex: number) => {
          this.YearNodeBuilder(yearNode, yearIndex)
        }, (yearNode: TimelineYear) => `${this.timelineDataVersion}-${yearNode.year}`)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }
  
  // 空状态
  @Builder
  EmptyState() {
    Column() {
      // 图标背景
      Column() {
        Text('📝')
          .fontSize(48)
      }
      .width(100)
      .height(100)
      .borderRadius(50)
      .backgroundColor(this.themeColors.primaryLight + '20')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 24 })
      
      Text('还没有记录')
        .fontSize(20)
        .fontColor(this.themeColors.textPrimary)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 8 })
      
      Text('点击右下角的按钮开始记录你的生活')
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
        .textAlign(TextAlign.Center)
        .lineHeight(22)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 40, right: 40 })
  }
  
  // 年份节点
  @Builder
  YearNodeBuilder(yearNode: TimelineYear, yearIndex: number) {
    Column() {
      // 年份标题行
      Row() {
        // 时间线圆环和连接线
        Column() {
          // 上方连接线（第一年没有）
          if (yearIndex > 0) {
            Line()
              .width(2)
              .height(24)
              .backgroundColor(this.themeColors.primary)
          }
          
          // 年份圆环
          Column() {
            Circle()
              .width(18)
              .height(18)
              .fill(this.themeColors.cardBackground)
              .stroke(this.themeColors.primary)
              .strokeWidth(3)
          }
          .width(24)
          .height(24)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          
          // 下方连接线
          Line()
            .width(2)
            .height(this.isYearExpanded(yearNode.year) ? 24 : 16)
            .backgroundColor(this.themeColors.primary)
        }
        .width(24)
        .alignItems(HorizontalAlign.Center)
        
        // 年份标题
        Row() {
          Text(yearNode.year + '年')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeColors.textPrimary)
          
          // 条目数量徽章
          Text(this.getYearRecordCount(yearNode).toString())
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor(this.themeColors.primary)
            .borderRadius(12)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .margin({ left: 10 })
        }
        .margin({ left: 12 })
        
        // Blank()
        
        // 展开/折叠图标
        Image(this.isYearExpanded(yearNode.year) ? $r('sys.media.ohos_ic_public_arrow_down') : $r('sys.media.ohos_ic_public_arrow_right'))
          .width(20)
          .height(20)
          .fillColor(this.themeColors.iconColor)
          .margin({ left: 4 })
      }
      .width('100%')
      .height(yearIndex === 0 ? 56 : 64)
      .onClick(() => {
        this.toggleYear(yearNode.year)
      })
      
      // 月份列表（展开时显示）
      if (this.isYearExpanded(yearNode.year)) {
        Column() {
          ForEach(yearNode.months, (monthNode: TimelineMonth, monthIndex: number) => {
            this.MonthNodeBuilder(yearNode, monthNode, monthIndex)
          }, (monthNode: TimelineMonth) => `${this.timelineDataVersion}-${yearNode.year}-${monthNode.month}`)
        }
        .width('100%')
        .margin({ left: 12 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  // 月份节点
  @Builder
  MonthNodeBuilder(yearNode: TimelineYear, monthNode: TimelineMonth, monthIndex: number) {
    Column() {
      // 月份标题行
      Row() {
        // 时间线圆环和连接线
        Column() {
          // 上方连接线
          Line()
            .width(2)
            .height(20)
            .backgroundColor(this.themeColors.primaryLight)
          
          // 月份圆环
          Column() {
            Circle()
              .width(14)
              .height(14)
              .fill(this.themeColors.cardBackground)
              .stroke(this.themeColors.primaryLight)
              .strokeWidth(2.5)
          }
          .width(18)
          .height(18)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          
          // 下方连接线
          Line()
            .width(2)
            .height(this.isMonthExpanded(yearNode.year, monthNode.month) ? 20 : 12)
            .backgroundColor(this.themeColors.primaryLight)
        }
        .width(18)
        .alignItems(HorizontalAlign.Center)
        
        // 月份标题
        Row() {
          Text(monthNode.month + '月')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeColors.textPrimary)
          
          // 条目数量徽章
          Text(this.getMonthRecordCount(monthNode).toString())
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor(this.themeColors.primaryLight)
            .borderRadius(10)
            .padding({ left: 7, right: 7, top: 1, bottom: 1 })
            .margin({ left: 8 })
        }
        .margin({ left: 12 })
        
        // Blank()
        
        // 展开/折叠图标
        Image(this.isMonthExpanded(yearNode.year, monthNode.month) ? $r('sys.media.ohos_ic_public_arrow_down') : $r('sys.media.ohos_ic_public_arrow_right'))
          .width(18)
          .height(18)
          .fillColor(this.themeColors.iconColor)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(48)
      .onClick(() => {
        this.toggleMonth(yearNode.year, monthNode.month)
      })
      
      // 日期列表（展开时显示）
      if (this.isMonthExpanded(yearNode.year, monthNode.month)) {
        Column() {
          ForEach(monthNode.days, (dayNode: TimelineDay, dayIndex: number) => {
            this.DayNodeBuilder(yearNode, monthNode, dayNode, dayIndex)
          }, (dayNode: TimelineDay) => `${this.timelineDataVersion}-${yearNode.year}-${monthNode.month}-${dayNode.day}`)
        }
        .width('100%')
        .margin({ left: 10 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  // 日期节点
  @Builder
  DayNodeBuilder(yearNode: TimelineYear, monthNode: TimelineMonth, dayNode: TimelineDay, dayIndex: number) {
    Column() {
      // 日期标题行
      Row() {
        // 时间线圆环和连接线
        Column() {
          // 上方连接线
          Line()
            .width(2)
            .height(16)
            .backgroundColor(this.themeColors.info)
          
          // 日期圆环
          Column() {
            Circle()
              .width(10)
              .height(10)
              .fill(this.themeColors.info)
          }
          .width(14)
          .height(14)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          
          // 下方连接线
          Line()
            .width(2)
            .height(this.isDayExpanded(yearNode.year, monthNode.month, dayNode.day) ? 16 : 10)
            .backgroundColor(this.themeColors.info)
        }
        .width(14)
        .alignItems(HorizontalAlign.Center)
        
        // 日期标题
        Row() {
          Text(dayNode.day + '日')
            .fontSize(15)
            .fontColor(this.themeColors.textPrimary)
            .fontWeight(FontWeight.Medium)
          
          // 条目数量徽章
          Text(dayNode.records.length.toString())
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor(this.themeColors.info)
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
        .margin({ left: 10 })
        
        // Blank()
        
        // 展开/折叠图标
        Image(this.isDayExpanded(yearNode.year, monthNode.month, dayNode.day) ? $r('sys.media.ohos_ic_public_arrow_down') : $r('sys.media.ohos_ic_public_arrow_right'))
          .width(16)
          .height(16)
          .fillColor(this.themeColors.iconColor)
          .margin({ left: 20 })
      }
      .width('100%')
      .height(40)
      .onClick(() => {
        this.toggleDay(yearNode.year, monthNode.month, dayNode.day)
      })
      
      // 记录列表（展开时显示）
      if (this.isDayExpanded(yearNode.year, monthNode.month, dayNode.day)) {
        Column() {
          ForEach(dayNode.records, (record: LifeRecord, recordIndex: number) => {
            Row() {
              // 连接线
              Column() {
                Line()
                  .width(2)
                  .height(12)
                  .backgroundColor(this.themeColors.divider)
              }
              .width(10)
              .flexShrink(0)
              
              // 记录卡片
              RecordCard({
                record: record,
                onEdit: this.onEditRecord,
                onDelete: this.onDeleteRecord
              })
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ top: recordIndex > 0 ? 10 : 0 })
          }, (record: LifeRecord) => `${this.timelineDataVersion}-${record.id}`)
        }
        .width('100%')
        .margin({ left: 6, right: 0 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  // 年份展开状态
  private isYearExpanded(year: number): boolean {
    return this.expandedYears.has(year)
  }
  
  // 月份展开状态
  private isMonthExpanded(year: number, month: number): boolean {
    return this.expandedMonths.has(`${year}-${month}`)
  }
  
  // 日期展开状态
  private isDayExpanded(year: number, month: number, day: number): boolean {
    return this.expandedDays.has(`${year}-${month}-${day}`)
  }
  
  // 切换年份展开
  private toggleYear(year: number) {
    if (this.expandedYears.has(year)) {
      this.expandedYears.delete(year)
    } else {
      this.expandedYears.add(year)
    }
    // 触发状态更新
    this.expandedYears = new Set(this.expandedYears)
  }
  
  // 切换月份展开
  private toggleMonth(year: number, month: number) {
    const key = `${year}-${month}`
    if (this.expandedMonths.has(key)) {
      this.expandedMonths.delete(key)
    } else {
      this.expandedMonths.add(key)
    }
    this.expandedMonths = new Set(this.expandedMonths)
  }
  
  // 切换日期展开
  private toggleDay(year: number, month: number, day: number) {
    const key = `${year}-${month}-${day}`
    if (this.expandedDays.has(key)) {
      this.expandedDays.delete(key)
    } else {
      this.expandedDays.add(key)
    }
    this.expandedDays = new Set(this.expandedDays)
  }
  
  // 获取年份记录数量
  private getYearRecordCount(yearNode: TimelineYear): number {
    let count = 0
    for (const monthNode of yearNode.months) {
      count += this.getMonthRecordCount(monthNode)
    }
    return count
  }
  
  // 获取月份记录数量
  private getMonthRecordCount(monthNode: TimelineMonth): number {
    let count = 0
    for (const dayNode of monthNode.days) {
      count += dayNode.records.length
    }
    return count
  }
}
