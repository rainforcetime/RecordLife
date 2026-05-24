// 时间线区域组件：components/TimelineSection.ets
import { TimelineData, TimelineYear, TimelineMonth, TimelineDay, LifeRecord, getTagNameById, Tag } from '../../common/types'
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { RecordCard } from './RecordCard'
import { ColorUtils } from '../../common/ColorUtils'
import { ConfigManager } from '../../config/ConfigManager'

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
  
  // 标签筛选
  @Prop filterTagIds: string[] = []
  @Watch('onFilterTagIdsChange')
  @Prop filterTagIdsVersion: number = 0

  // 回调函数
  onEditRecord?: (record: LifeRecord) => void
  onDeleteRecord?: (record: LifeRecord) => void
  onTogglePin?: (record: LifeRecord) => void

  // 监听 timelineData 变化
  @Watch('onTimelineDataChange')
  @Prop timelineDataVersion: number = 0
  
  // 扁平化的日期分组数据
  @State private dateGroups: DateGroup[] = []

  // 收藏的记录
  @State private pinnedRecords: LifeRecord[] = []

  // 自定义标签（用于标签名称查找）
  @State private customTags: Tag[] = []

  // ConfigManager
  private configManager: ConfigManager | null = null
  
  async aboutToAppear() {
    try {
      this.configManager = await ConfigManager.getInstance()
      this.customTags = this.configManager.getCustomTags()
    } catch (error) {
      console.error('[TimelineSection] 初始化失败: ' + JSON.stringify(error))
    }
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

  // 当标签筛选改变时重新构建数据
  private onFilterTagIdsChange() {
    console.info('[TimelineSection] filterTagIds 改变: ' + JSON.stringify(this.filterTagIds))
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
        // 根据标签ID获取标签名称（支持自定义标签）
        const tagName = getTagNameById(tagId, this.customTags)
        if (tagName && tagName.toLowerCase().includes(lowerKeyword)) {
          return true
        }
      }
    }
    
    return false
  }

  // 判断记录是否匹配任一筛选标签
  private matchesAnyFilterTag(record: LifeRecord): boolean {
    if (!record.tags || record.tags.length === 0) {
      return false
    }
    for (const tagId of record.tags) {
      if (this.filterTagIds.includes(tagId)) {
        return true
      }
    }
    return false
  }

  // 构建扁平化的日期分组数据
  private buildDateGroups() {
    const groups: DateGroup[] = []
    const pinned: LifeRecord[] = []
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())

    // 遍历所有年月日，收集记录
    for (const yearNode of this.timelineData.years) {
      for (const monthNode of yearNode.months) {
        for (const dayNode of monthNode.days) {
          // 过滤记录（搜索关键词）
          let filteredRecords = dayNode.records
          if (this.searchKeyword.length > 0) {
            filteredRecords = dayNode.records.filter(record =>
              this.matchRecord(record, this.searchKeyword)
            )
          }

          // 过滤记录（标签筛选）
          if (this.filterTagIds.length > 0) {
            filteredRecords = filteredRecords.filter(record =>
              this.matchesAnyFilterTag(record)
            )
          }

          // 分离收藏记录
          if (this.searchKeyword.length === 0) {
            for (const record of filteredRecords) {
              if (record.isPinned) {
                pinned.push(record)
              }
            }
          }

          // 从常规时间线中排除收藏记录
          const nonPinnedRecords = filteredRecords.filter(r => !r.isPinned)

          if (nonPinnedRecords.length > 0) {
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
              // 非本年显示年份，本年只显示月日
              if (yearNode.year !== now.getFullYear()) {
                dateStr = `${yearNode.year}年${monthNode.month}月${dayNode.day}日`
              } else {
                dateStr = `${monthNode.month}月${dayNode.day}日`
              }
            }

            groups.push({
              year: yearNode.year,
              month: monthNode.month,
              day: dayNode.day,
              dateStr: dateStr,
              records: nonPinnedRecords
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

    // 收藏记录也按时间倒序排列
    pinned.sort((a, b) => b.timestamp - a.timestamp)

    this.dateGroups = groups
    this.pinnedRecords = pinned
    console.info('[TimelineSection] 构建日期分组完成，共 ' + groups.length + ' 个日期组，收藏记录: ' + pinned.length)
  }
  
  build() {
    Column() {
      // 收藏记录专区
      if (this.pinnedRecords.length > 0) {
        this.PinnedSection()
      }

      if (this.dateGroups.length === 0) {
        // 只有没有任何记录（含收藏）才显示空状态
        if (this.pinnedRecords.length === 0) {
          this.EmptyState()
        }
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
  
  // 收藏记录专区
  @Builder
  PinnedSection() {
    Column() {
      // 收藏专区标题
      Row({ space: 6 }) {
        SymbolGlyph($r('sys.symbol.pin_fill'))
          .fontSize(18)
          .fontColor([this.themeColors.primary])
        Text('收藏')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.primary)

        // 收藏数量
        Row() {
          Text(`${this.pinnedRecords.length}`)
            .fontSize(12)
            .fontColor(this.themeColors.primary)
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .backgroundColor(ColorUtils.primaryExtraLight(this.themeColors.primary))
        .borderRadius(10)
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 收藏记录卡片（每张独立，无日期分隔线）
      ForEach(this.pinnedRecords, (record: LifeRecord, index: number) => {
        RecordCard({
          record: record,
          showDate: true,  // 收藏区显示完整日期
          searchKeyword: this.searchKeyword,
          onEdit: this.onEditRecord,
          onDelete: this.onDeleteRecord,
          onTogglePin: this.onTogglePin
        })
        .margin({ top: index > 0 ? 12 : 0 })
      }, (record: LifeRecord) => `pinned-${this.timelineDataVersion}-${record.id}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 4, bottom: 16 })
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
          onDelete: this.onDeleteRecord,
          onTogglePin: this.onTogglePin
        })
        .margin({ top: recordIndex > 0 ? 12 : 8 })
      }, (record: LifeRecord) => `${this.timelineDataVersion}-${record.id}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: groupIndex > 0 ? 20 : 0 })
    .id(`date-${group.year}-${group.month}-${group.day}`)  // 添加 id 用于滚动定位
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
