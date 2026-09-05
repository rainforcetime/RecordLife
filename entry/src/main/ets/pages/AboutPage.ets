// 关于应用页（AboutAppDialog 升级为完整页面，按业内标准：头部/版本/统计/链接/版权）
import { common } from '@kit.AbilityKit'
import { Logger } from '../common/utils/Logger'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { AppInfoManager } from '../config/AppInfoConfig'
import { ConfigManager } from '../config/ConfigManager'
import { RecordRepository } from '../repository/RecordRepository'
import { StorageService } from '../service/StorageService'
import { BusinessError } from '@kit.BasicServicesKit'

@Entry
@Component
struct AboutPage {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 应用信息（AppInfoManager 提供）
  @State private appName: string = ''
  @State private appVersion: string = ''
  @State private buildNumber: string = ''
  @State private appDesc: string = ''

  // 使用统计
  @State private usageDays: number = 0
  @State private recordCount: number = 0

  // 信息弹层（隐私/许可共用单 bindSheet，避免多 bindSheet 覆盖）
  @State private showInfoSheet: boolean = false
  @State private infoMode: string = 'privacy' // 'privacy' | 'license'

  private context: common.UIAbilityContext | null = null

  // 链接
  private readonly REPO_URL: string = 'https://github.com/rainforcetime/RecordLife'
  private readonly RELEASES_URL: string = 'https://github.com/rainforcetime/RecordLife/releases'
  private readonly ISSUES_URL: string = 'https://github.com/rainforcetime/RecordLife/issues'

  async aboutToAppear() {
    try {
      this.context = this.getUIContext().getHostContext() as common.UIAbilityContext
    } catch (e) {
      Logger.error('[AboutPage] 获取 context 失败: ' + JSON.stringify(e))
    }
    // 应用信息
    try {
      const info = await AppInfoManager.getInstance(this.context ?? undefined)
      this.appName = info.getAppName()
      this.appVersion = info.getAppVersion()
      this.buildNumber = info.getBuildNumber()
      this.appDesc = info.getDescription()
    } catch (e) {
      Logger.error('[AboutPage] 加载应用信息失败: ' + JSON.stringify(e))
    }
    // 已使用天数
    try {
      const configManager = await ConfigManager.getInstance(this.context ?? undefined)
      const createdAt = configManager.getConfig()?.metadata?.createdAt
      if (createdAt) {
        this.usageDays = StorageService.calcUsageDays(createdAt)
      }
    } catch (e) {
      Logger.error('[AboutPage] 加载使用天数失败: ' + JSON.stringify(e))
    }
    // 记录总数
    try {
      if (this.context) {
        const records = await RecordRepository.getRecords(this.context)
        this.recordCount = records.length
      }
    } catch (e) {
      Logger.error('[AboutPage] 加载记录数失败: ' + JSON.stringify(e))
    }
  }

  // 打开外链
  private openLink(url: string): void {
    const ctx = this.context
    if (!ctx) {
      return
    }
    ctx.openLink(url, { appLinkingOnly: false }).catch((error: BusinessError) => {
      Logger.error('[AboutPage] 打开链接失败: ' + JSON.stringify(error))
    })
  }

  // 打开信息弹层（隐私/许可）
  private openInfoSheet(mode: string): void {
    this.infoMode = mode
    this.showInfoSheet = true
  }

  build() {
    Column() {
      // 标题栏：返回 + 标题
      Row() {
        Column() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([this.themeColors.textPrimary])
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.getUIContext().getRouter().back()
        })

        Text($r('app.string.about_app'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 8, right: 16 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          // ① 应用头部
          Column() {
            Image($r('app.media.startIcon'))
              .width(84)
              .height(84)
              .borderRadius(18)
              .margin({ top: 16, bottom: 12 })

            Text(this.appName)
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textPrimary)

            Text(this.appDesc)
              .fontSize(13)
              .fontColor(this.themeColors.textSecondary)
              .margin({ top: 4 })
              .textAlign(TextAlign.Center)

            // 版本 + Build 日期
            Row() {
              Text($r('app.string.version_value', this.appVersion))
                .fontSize(13)
                .fontColor(this.themeColors.textSecondary)
              Text(' · Build ' + this.buildNumber)
                .fontSize(13)
                .fontColor(this.themeColors.textTertiary)
                .margin({ left: 6 })
            }
            .margin({ top: 10 })
          }
          .width('100%')
          .padding({ bottom: 18 })
          .alignItems(HorizontalAlign.Center)

          // ② 使用统计卡
          Row() {
            Column() {
              Text($r('app.string.usage_days', this.usageDays))
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.primary)
              Text($r('app.string.usage_label'))
                .fontSize(12)
                .fontColor(this.themeColors.textTertiary)
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            Divider()
              .vertical(true)
              .height(32)
              .color(this.themeColors.divider)

            Column() {
              Text($r('app.string.record_count_simple', this.recordCount))
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.primary)
              Text($r('app.string.about_records_label'))
                .fontSize(12)
                .fontColor(this.themeColors.textTertiary)
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })
          .backgroundColor(this.themeColors.cardBackground)
          .borderRadius(14)
          .margin({ bottom: 12 })

          // ③ 链接列表卡
          Column() {
            this.LinkRow('📄', '#E3F2FD', $r('app.string.about_update_log'), () => {
              this.openLink(this.RELEASES_URL)
            })
            Divider().color(this.themeColors.divider).margin({ left: 56 })

            this.LinkRow('💻', '#E8F5E9', $r('app.string.about_source'), () => {
              this.openLink(this.REPO_URL)
            })
            Divider().color(this.themeColors.divider).margin({ left: 56 })

            this.LinkRow('💬', '#FFF3E0', $r('app.string.about_feedback'), () => {
              this.openLink(this.ISSUES_URL)
            })
            Divider().color(this.themeColors.divider).margin({ left: 56 })

            this.LinkRow('🔒', '#EDE7F6', $r('app.string.about_privacy'), () => {
              this.openInfoSheet('privacy')
            })
            Divider().color(this.themeColors.divider).margin({ left: 56 })

            this.LinkRow('📜', '#FCE4EC', $r('app.string.about_license'), () => {
              this.openInfoSheet('license')
            })
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })
          .backgroundColor(this.themeColors.cardBackground)
          .borderRadius(14)
          .margin({ bottom: 20 })

          // ④ 版权
          Text($r('app.string.about_copyright'))
            .fontSize(12)
            .fontColor(this.themeColors.textTertiary)
            .margin({ bottom: 24 })
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      // 隐私/许可信息共用弹层（单 bindSheet，避免同节点覆盖）
      .bindSheet($$this.showInfoSheet, this.InfoSheetBuilder(), {
        height: '60%',
        backgroundColor: this.themeColors.cardBackground,
        dragBar: true,
        showClose: false
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
  }

  // 链接行
  @Builder
  LinkRow(icon: string, iconBg: string, label: Resource, onClick: () => void) {
    Row() {
      Text(icon)
        .fontSize(22)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .backgroundColor(iconBg)
        .borderRadius(18)

      Text(label)
        .fontSize(15)
        .fontColor(this.themeColors.textPrimary)
        .margin({ left: 12 })
        .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontColor([this.themeColors.textTertiary])
    }
    .width('100%')
    .padding({ left: 14, right: 16, top: 13, bottom: 13 })
    .onClick(() => {
      onClick()
    })
  }

  // 隐私/许可信息弹层
  @Builder
  InfoSheetBuilder() {
    Column() {
      Row() {
        Text(this.infoMode === 'privacy' ? $r('app.string.privacy_title') : $r('app.string.license_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
        Blank()
        Text('✕')
          .fontSize(20)
          .fontColor(this.themeColors.textSecondary)
          .onClick(() => {
            this.showInfoSheet = false
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 8 })

      Scroll() {
        Text(this.infoMode === 'privacy' ? $r('app.string.privacy_body') : $r('app.string.license_body'))
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
          .lineHeight(22)
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.cardBackground)
  }
}
