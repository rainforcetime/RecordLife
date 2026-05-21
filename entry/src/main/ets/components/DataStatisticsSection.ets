// 数据统计区域组件：components/DataStatisticsSection.ets
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'

// 数据统计信息模型
export interface DataStatisticsInfo {
  usageDays: number
  dataVersion: string
  lastActiveTime: string
}

@Component
export struct DataStatisticsSection {
  // 主题颜色配置
  @Prop themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 数据统计信息
  @Prop statisticsInfo: DataStatisticsInfo = {
    usageDays: 0,
    dataVersion: 'v1.0.0',
    lastActiveTime: ''
  }

  build() {
    Column() {
      // 区域标题
      Row() {
        Text('数据统计')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
      }
      .width('100%')
      .padding({ left: 4, bottom: 12 })

      // 统计卡片网格
      Row() {
        // 使用天数卡片
        this.StatisticCard(
          $r('sys.symbol.calendar'),
          '已使用',
          `${this.statisticsInfo.usageDays}天`,
          this.themeColors.primary
        )

        // 数据版本卡片
        this.StatisticCard(
          $r('sys.symbol.info_circle'),
          '数据版本',
          this.statisticsInfo.dataVersion,
          this.themeColors.success
        )
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 10 })

      Row() {
        // 最后活跃时间卡片
        this.StatisticCard(
          $r('sys.symbol.clock'),
          '最后活跃',
          this.statisticsInfo.lastActiveTime,
          this.themeColors.info
        )

        // 占位卡片（保持对称）
        this.StatisticCard(
          $r('sys.symbol.externaldrive'),
          '存储空间',
          '计算中...',
          this.themeColors.warning
        )
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
    .margin({ left: 16, right: 16, bottom: 16 })
    .padding(16)
    .shadow({
      radius: 12,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 4
    })
  }

  // 统计卡片子组件
  @Builder
  StatisticCard(icon: Resource, label: string, value: string, color: string) {
    Column() {
      // 图标
      Column() {
        SymbolGlyph(icon)
          .fontSize(20)
          .fontColor([color])
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(color + '15')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 8 })

      // 标签
      Text(label)
        .fontSize(12)
        .fontColor(this.themeColors.textSecondary)
        .margin({ bottom: 4 })

      // 数值
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
    }
    .width('48%')
    .padding(12)
    .backgroundColor(this.themeColors.background)
    .borderRadius(12)
  }
}
