// 数据看板页：pages/DashboardPage.ets（更新计划五期：数据看板 / 生命进度）
import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { ConfigManager } from '../config/ConfigManager'
import { RecordRepository } from '../repository/RecordRepository'
import { LifeRecord } from '../model/RecordModel'
import { StatisticsUtils, LifeStatistics, LifeProgress } from '../model/StatisticsModel'
import { TimeUtils } from '../common/utils/TimeUtils'
import { Logger } from '../common/utils/Logger'

@Entry
@Component
struct DashboardPage {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 统计结果
  @State statistics: LifeStatistics = {
    totalRecords: 0,
    activeDays: 0,
    averagePerDay: 0,
    longestStreak: 0,
    totalCharacters: 0,
    firstRecordDate: '',
    lastRecordDate: ''
  }

  // 生命进度
  @State lifeProgress: LifeProgress = { percent: 0, livedDays: 0, totalDays: 0 }

  // 目标年龄
  @State targetAge: number = 80

  async aboutToAppear() {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const configManager = await ConfigManager.getInstance(context)
      this.targetAge = configManager.getTargetAge()

      // 加载全部记录并统计
      const records: LifeRecord[] = await RecordRepository.getRecords(context)
      this.statistics = StatisticsUtils.calculateStatistics(records)
      this.lifeProgress = StatisticsUtils.getLifeProgress(configManager.getBirthDate(), this.targetAge, TimeUtils.now())
      Logger.info('[DashboardPage] 统计完成: ' + this.statistics.totalRecords + ' 条记录')
    } catch (error) {
      Logger.error('[DashboardPage] 加载统计失败: ' + JSON.stringify(error))
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(22)
          .fontColor([this.themeColors.iconColor])
          .onClick(() => {
            router.back()
          })

        Text($r('app.string.dashboard_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ left: 10 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      Scroll() {
        Column() {
          // 生命进度卡片
          Column() {
            Text($r('app.string.life_progress'))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
              .width('100%')
              .margin({ bottom: 12 })

            Row() {
              // 环形进度
              Stack() {
                Progress({ value: this.lifeProgress.percent, total: 100, type: ProgressType.Ring })
                  .width(110)
                  .height(110)
                  .color(this.themeColors.primary)
                  .backgroundColor(this.themeColors.divider)
                  .style({ strokeWidth: 10 })

                Text(this.lifeProgress.percent.toFixed(1) + '%')
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColors.primary)
              }
              .width(110)
              .height(110)

              Column() {
                Text(this.lifeProgress.livedDays.toLocaleString())
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColors.textPrimary)

                Text($r('app.string.stat_days'))
                  .fontSize(12)
                  .fontColor(this.themeColors.textSecondary)
                  .margin({ top: 2 })

                Text($r('app.string.life_progress_detail', this.targetAge))
                  .fontSize(13)
                  .fontColor(this.themeColors.textSecondary)
                  .margin({ top: 8 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 24 })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.themeColors.cardBackground)
          .borderRadius(16)
          .margin({ bottom: 12 })

          // 数据统计卡片网格
          Row({ space: 10 }) {
            this.StatCard($r('app.string.stat_total_records'), this.statistics.totalRecords.toLocaleString())
            this.StatCard($r('app.string.stat_active_days'), this.statistics.activeDays.toLocaleString())
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row({ space: 10 }) {
            this.StatCard($r('app.string.stat_avg_per_day'), this.statistics.averagePerDay.toFixed(1))
            this.StatCard($r('app.string.stat_longest_streak'), this.statistics.longestStreak.toLocaleString())
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row({ space: 10 }) {
            this.StatCard($r('app.string.stat_total_chars'), this.statistics.totalCharacters.toLocaleString())
            this.StatCard($r('app.string.stat_first_date'), this.statistics.firstRecordDate.length > 0 ? this.statistics.firstRecordDate : '-')
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row({ space: 10 }) {
            this.StatCard($r('app.string.stat_last_date'), this.statistics.lastRecordDate.length > 0 ? this.statistics.lastRecordDate : '-')
            this.StatCard($r('app.string.stat_target_age'), this.targetAge.toLocaleString())
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
  }

  // 统计卡片
  @Builder
  StatCard(label: ResourceStr, value: string) {
    Column() {
      Text(label)
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')

      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .width('100%')
        .margin({ top: 6 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(14)
  }
}
