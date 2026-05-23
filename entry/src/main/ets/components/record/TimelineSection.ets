// 时间线区域组件：components/TimelineSection.ets
import { TimelineData, TimelineYear, TimelineMonth, TimelineDay, LifeRecord } from '../../common/types'
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { RecordCard } from './RecordCard'
import { ColorUtils } from '../../common/ColorUtils'

// 日期分组数据结构
interface DateGroup {
  year: number
  month: number
  day: number
  dateStr: string      // 格式化后的日期字符串（如"今天"、"昨天"、"5月20日"）
  records: LifeRecord[]
}

@Component
export struct TimelineSection {
  @Prop timelineData: TimelineData = { years: [] }
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 搜索关键词（用于过滤和高亮）
  @Prop searchKeyword: string = ''
  // 搜索关键词版本号（用于强制刷新）
  @Watch('onSearchKeywordChange')
  @Prop searchKeywordVersion: number = 0
  
  // 回调函数
  onEditRecord?: (record: LifeRecord) => void
  onDeleteRecord?: (record: LifeRecord) => void
  
  // 监听 timelineData 变化
  @Watch('onTimelineDataChange')
  @Prop timelineDataVersion: number = 0
  
  // 扁平化的日期分组数据
  @State private dateGroups: DateGroup[] = []
  
  aboutToAppear() {
    this.buildDateGroups()
  }
  
  // 当 timelineData 改变时重新构建数据
  private onTimelineDataChange() {
    console.info('[TimelineSection] timelineDataVersion 改变: ' + this.timelineDataVersion)
    this.buildDateGroups()
  }
  
  // 当搜索关键词改变时重新构建数据
  private onSearchKeywordChange() {
    console.info('[TimelineSection] searchKeyword 改变: ' + this.searchKeyword)
    this.buildDateGroups()
  }
  
  // 匹配记录（搜索内容和标签）
  private matchRecord(record: LifeRecord, keyword: string): boolean {
    const lowerKeyword = keyword.toLowerCase()
    
    // 1. 搜索文字内容
    if (record.content.toLowerCase().includes(lowerKeyword)) {
      return true
    }
    
    // 2. 搜索标签名称
    if (record.tags && record.tags.length > 0) {
      for (const tagId of record.tags) {
        // 根据标签ID获取标签名称
        const tagName = this.getTagNameById(tagId)
        if (tagName && tagName.toLowerCase().includes(lowerKeyword)) {
          return true
        }
      }
    }
    
    return false
  }
  
  // 根据标签ID获取标签名称
  private getTagNameById(tagId: string): string | null {
    // 标签ID到名称的映射
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
  
  // 构建扁平化的日期分组数据
  private buildDateGroups() {
    const groups: DateGroup[] = []
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    
    // 遍历所有年月日，收集记录
    for (const yearNode of this.timelineData.years) {
      for (const monthNode of yearNode.months) {
        for (const dayNode of monthNode.days) {
          // 过滤记录（如果有搜索关键词）
          let filteredRecords = dayNode.records
          if (this.searchKeyword.length > 0) {
            filteredRecords = dayNode.records.filter(record => 
              this.matchRecord(record, this.searchKeyword)
            )
          }
          
          if (filteredRecords.length > 0) {
            // 计算日期描述
            const recordDate = new Date(yearNode.year, monthNode.month - 1, dayNode.day)
            const diffDays = Math.floor((today.getTime() - recordDate.getTime()) / (1000 * 60 * 60 * 24))
            
            let dateStr = ''
            if (diffDays === 0) {
              dateStr = '今天'
            } else if (diffDays === 1) {
              dateStr = '昨天'
            } else if (diffDays === 2) {
              dateStr = '前天'
            } else if (diffDays < 7) {
              dateStr = `${diffDays}天前`
            } else {
              dateStr = `${monthNode.month}月${dayNode.day}日`
            }
            
            groups.push({
              year: yearNode.year,
              month: monthNode.month,
              day: dayNode.day,
              dateStr: dateStr,
              records: filteredRecords
            })
          }
        }
      }
    }
    
    // 按日期倒序排列（最新的在前）
    groups.sort((a, b) => {
      const dateA = new Date(a.year, a.month - 1, a.day)
      const dateB = new Date(b.year, b.month - 1, b.day)
      return dateB.getTime() - dateA.getTime()
    })
    
    this.dateGroups = groups
    console.info('[TimelineSection] 构建日期分组完成，共 ' + groups.length + ' 个日期组')
  }
  
  build() {
    Column() {
      if (this.dateGroups.length === 0) {
        // 空状态
        this.EmptyState()
      } else {
        // 时间线内容
        ForEach(this.dateGroups, (group: DateGroup, groupIndex: number) => {
          this.DateGroupBuilder(group, groupIndex)
        }, (group: DateGroup) => `${this.timelineDataVersion}-${group.year}-${group.month}-${group.day}`)
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
        Text(this.searchKeyword.length > 0 ? '🔍' : '📝')
          .fontSize(48)
      }
      .width(100)
      .height(100)
      .borderRadius(50)
      .backgroundColor(ColorUtils.primaryUltraLight(this.themeColors.primary))
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 24 })
      
      if (this.searchKeyword.length > 0) {
        // 搜索无结果
        Text('没有找到相关记录')
          .fontSize(20)
          .fontColor(this.themeColors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 8 })
        
        Text(`没有包含"${this.searchKeyword}"的记录`)
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
          .textAlign(TextAlign.Center)
          .lineHeight(22)
      } else {
        // 无记录
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
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 40, right: 40 })
  }
  
  // 日期分组构建器
  @Builder
  DateGroupBuilder(group: DateGroup, groupIndex: number) {
    Column() {
      // 日期分隔线
      this.DateDividerBuilder(group)
      
      // 该日期下的所有记录
      ForEach(group.records, (record: LifeRecord, recordIndex: number) => {
        RecordCard({
          record: record,
          showDate: false,  // 不显示日期，因为已经在分隔线显示了
          searchKeyword: this.searchKeyword,  // 传递搜索关键词
          onEdit: this.onEditRecord,
          onDelete: this.onDeleteRecord
        })
        .margin({ top: recordIndex > 0 ? 12 : 8 })
      }, (record: LifeRecord) => `${this.timelineDataVersion}-${record.id}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: groupIndex > 0 ? 20 : 0 })
  }
  
  // 日期分隔线
  @Builder
  DateDividerBuilder(group: DateGroup) {
    Row() {
      // 左侧装饰线
      Column()
        .width(3)
        .height(20)
        .linearGradient({
          angle: 90,
          colors: [[this.themeColors.primary, 0], [this.themeColors.primaryLight, 1]]
        })
        .borderRadius(1.5)
      
      // 日期文字
      Text(group.dateStr)
        .fontSize(16)
        .fontColor(this.themeColors.textPrimary)
        .fontWeight(FontWeight.Medium)
        .margin({ left: 10 })
      
      // 完整日期（小字）
      Text(`· ${group.month}月${group.day}日`)
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
        .margin({ left: 6 })
      
      Blank()
      
      // 记录数量徽章
      if (group.records.length > 1) {
        Row() {
          Text(`${group.records.length} 条`)
            .fontSize(12)
            .fontColor(this.themeColors.primary)
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor(ColorUtils.primaryExtraLight(this.themeColors.primary))
        .borderRadius(12)
      }
    }
    .width('100%')
    .height(32)
    .alignItems(VerticalAlign.Center)
  }
}
