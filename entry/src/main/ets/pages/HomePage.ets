// 首页：展示用户存活时间
import { ConfigManager } from '../config/ConfigManager';
import { ResourceUtils } from '../common/utils/ResourceUtils'
import { UserConfig } from '../config/UserConfig';
import { TimeUtils } from '../common/utils/TimeUtils';
import { TimeData, DateDifference } from '../common/types';
import { TimeCard } from '../components/record/TimeCard';
import { BirthDateSelector } from '../components/user/BirthDateSelector';
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig';
import { ShareHomeCard } from '../components/share/ShareHomeCard';
import { AccumulatedModeToggle } from '../components/home/AccumulatedModeToggle';
import { ShareUtils } from '../common/utils/ShareUtils';
import { StatisticsUtils } from '../model/StatisticsModel';
import { common } from '@kit.AbilityKit';
import { RefreshManager } from '../common/managers/RefreshManager';
import { Logger } from '../common/utils/Logger'

// 卡片颜色配置接口
interface CardColors {
  cardColor: string;
  valueColor: string;
}

// 首页组件
@Component
export struct HomePage {
  // 主题颜色配置（响应式）
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  @State timeData: TimeData = {
    years: 0,
    months: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  };
  @State @Watch('onBirthDateChanged') birthDate: Date = new Date('1990-01-01T00:00:00Z');
  @State @Watch('onTargetAgeChanged') targetAge: number = 80; // 目标年龄，默认80岁
  @State signature: string = ''; // 签名/座右铭（更新计划一期）
  @State privacyMode: boolean = false; // 隐私模式（更新计划三期）
  @State lifePercent: number = 0; // 生命进度百分比（更新计划五期）
  @State userConfig: UserConfig | null = null;
  @State isAccumulatedMode: boolean = true; // true: 累计模式, false: 非累计模式
  @State isRemainingMode: boolean = false; // true: 剩余模式, false: 已存活模式
  @State showShareDialog: boolean = false; // 控制分享对话框显示
  @State isSharing: boolean = false; // 分享进行中标志
  
  private configManager: ConfigManager | null = null;
  private intervalId: number = -1;
  
  // 判断是否为深色模式
  private isDarkMode(): boolean {
    return this.themeColors.textPrimary === '#FFFFFF'
  }
  
  // 获取已过模式颜色（红色系）
  private getPassedColor(): string {
    return this.themeColors.error
  }
  
  // 获取剩余模式颜色（青色系，深色模式更协调）
  private getRemainingColor(): string {
    return this.themeColors.success
  }
  
  // 获取卡片背景色（适配深色模式）
  private getCardBgColor(lightColor: string): string {
    // 深色模式下使用卡片背景色
    return this.isDarkMode() ? this.themeColors.cardBackground : lightColor
  }
  
  // 获取年卡片颜色
  private getYearCardColors(): CardColors {
    if (this.isRemainingMode) {
      return {
        cardColor: this.getCardBgColor('#E8F5E9'),
        valueColor: this.getRemainingColor()
      }
    } else {
      return {
        cardColor: this.getCardBgColor('#FFE8E8'),
        valueColor: this.getPassedColor()
      }
    }
  }
  
  // 获取月卡片颜色（橙色系）
  private getMonthCardColors(): CardColors {
    return {
      cardColor: this.getCardBgColor('#FFF3E0'),
      valueColor: this.isDarkMode() ? '#FFB74D' : '#FFA726'
    }
  }
  
  // 获取日卡片颜色（绿色系->青色系）
  private getDayCardColors(): CardColors {
    return {
      cardColor: this.getCardBgColor('#E8F5E9'),
      valueColor: this.isDarkMode() ? '#4DD0E1' : '#66BB6A'
    }
  }
  
  // 获取小时卡片颜色（蓝色系）
  private getHourCardColors(): CardColors {
    return {
      cardColor: this.getCardBgColor('#E3F2FD'),
      valueColor: this.isDarkMode() ? '#64B5F6' : '#42A5F5'
    }
  }
  
  // 获取分钟卡片颜色（紫色系）
  private getMinuteCardColors(): CardColors {
    return {
      cardColor: this.getCardBgColor('#F3E5F5'),
      valueColor: this.isDarkMode() ? '#BA68C8' : '#AB47BC'
    }
  }
  
  // 获取秒卡片颜色（黄色系）
  private getSecondCardColors(): CardColors {
    return {
      cardColor: this.getCardBgColor('#FFFDE7'),
      valueColor: this.isDarkMode() ? '#FFD54F' : '#FFEE58'
    }
  }

  async aboutToAppear() {
    // 初始化配置管理器
    this.configManager = await ConfigManager.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext);
    this.userConfig = this.configManager.getConfig();
    
    // 加载签名（可选字段，旧配置缺省为空）
    this.signature = this.userConfig?.profile?.signature ?? '';
    
    // 加载隐私模式（更新计划三期）
    this.privacyMode = this.configManager.getPrivacyMode();
    
    // 加载出生日期
    this.birthDate = this.configManager.getBirthDate();
    
    // 加载保存的模式设置
    this.isAccumulatedMode = this.configManager.getIsAccumulatedMode();
    this.isRemainingMode = this.configManager.getIsRemainingMode();

    // 加载目标年龄
    const targetAge = this.configManager.getTargetAge();
    this.targetAge = (targetAge !== undefined && !isNaN(targetAge) && targetAge > 0) ? targetAge : 80;
    
    // 开始计算时间
    this.calculateTime();
    this.intervalId = setInterval(() => {
      this.calculateTime();
    }, 1000);
    
    // 注册全局刷新回调：当其他页面修改出生日期时同步更新
    RefreshManager.getInstance().register('HomePage', () => {
      Logger.info('[HomePage] 收到全局刷新通知，重新加载出生日期')
      if (this.configManager) {
        const newBirthDate = this.configManager.getBirthDate()
        if (newBirthDate.getTime() !== this.birthDate.getTime()) {
          this.birthDate = newBirthDate
        }
        // 同步刷新签名（我的页保存后）
        this.signature = this.configManager.getConfig()?.profile?.signature ?? ''
        // 同步刷新隐私模式（我的页切换后）
        this.privacyMode = this.configManager.getPrivacyMode()
      }
    })
  }

  aboutToDisappear() {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
    }
    // 注销刷新回调
    RefreshManager.getInstance().unregister('HomePage')
  }

  // 计算两个日期之间的精确年、月、日差（使用UTC+8时区）
  private getDateDifference(startDate: Date, endDate: Date): DateDifference {
    return TimeUtils.getDateDifference(startDate, endDate);
  }

  // 计算数值的显示权重（基于数值位数）
  private getValueWeight(value: number): number {
    const digitCount = value.toString().length;
    // 基硈权重1.0，每增加一位增加0.15权重
    return 1.0 + (digitCount - 1) * 0.15;
  }
  
  // 处理分享操作
  private handleShare() {
    Logger.info('[HomePage] 分享按钮被点击');
    this.showShareDialog = true;
  }

  // 出生日期变更时立即重新计算时间
  private onBirthDateChanged(): void {
    this.calculateTime();
  }

  // 目标年龄变更时立即重新计算时间
  private onTargetAgeChanged(): void {
    this.calculateTime();
  }

  // 计算存活时间（使用UTC+8时区）
  private calculateTime() {
    const now = TimeUtils.now();
    
    // 生命进度（更新计划五期）
    this.lifePercent = StatisticsUtils.getLifeProgress(this.birthDate, this.targetAge, now).percent;
    
    if (this.isRemainingMode) {
      // 剩余模式：计算距离目标年龄的剩余时间
      this.calculateRemainingTime(now);
    } else {
      // 已存活模式：计算已经存活的时间
      this.calculateLivedTime(now);
    }
  }

  // 计算已存活时间
  private calculateLivedTime(now: Date) {
    const diff = now.getTime() - this.birthDate.getTime();

    if (diff < 0) {
      // 出生日期在未来，显示0
      this.timeData = {
        years: 0,
        months: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0
      };
      return;
    }

    // 计算总秒数、总分钟数、总小时数、总天数
    const totalSeconds = Math.floor(diff / 1000);
    const totalMinutes = Math.floor(totalSeconds / 60);
    const totalHours = Math.floor(totalMinutes / 60);
    const totalDays = Math.floor(totalHours / 24);

    // 计算精确的年、月、日差
    const dateDiff = this.getDateDifference(this.birthDate, now);
    const years = dateDiff.years;
    const months = dateDiff.months;
    const days = dateDiff.days;
    
    // 计算总月数（年*12 + 月）
    const totalMonths = years * 12 + months;

    if (this.isAccumulatedMode) {
      // 累计模式：所有时间单位都是累计值
      this.timeData = {
        years,
        months: totalMonths, // 显示总月数
        days: totalDays,     // 显示总天数
        hours: totalHours,
        minutes: totalMinutes,
        seconds: totalSeconds
      };
    } else {
      // 非累计模式：年月日显示精确差值，时分秒显示当前时间（UTC+8时区）
      this.timeData = {
        years,
        months: months, // 显示剩余月数
        days: days,     // 显示剩余天数
        hours: TimeUtils.getHours(now),        // UTC+8时区当前小时
        minutes: TimeUtils.getMinutes(now),    // UTC+8时区当前分钟
        seconds: TimeUtils.getSeconds(now)     // UTC+8时区当前秒数
      };
    }
  }

  // 计算剩余时间（使用UTC+8时区）
  private calculateRemainingTime(now: Date) {
    // 防护：确保 targetAge 有效
    const targetAge = (this.targetAge !== undefined && !isNaN(this.targetAge) && this.targetAge > 0) ? this.targetAge : 80;

    // 计算目标日期（出生日期 + 目标年龄），使用UTC+8时区
    const targetDate = new Date(this.birthDate);
    TimeUtils.setFullYear(targetDate, TimeUtils.getFullYear(this.birthDate) + targetAge);

    const diff = targetDate.getTime() - now.getTime();

    if (diff < 0) {
      // 已超过目标年龄，显示0
      this.timeData = {
        years: 0,
        months: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0
      };
      return;
    }

    // 计算总秒数、总分钟数、总小时数、总天数
    const totalSeconds = Math.floor(diff / 1000);
    const totalMinutes = Math.floor(totalSeconds / 60);
    const totalHours = Math.floor(totalMinutes / 60);
    const totalDays = Math.floor(totalHours / 24);

    // 计算精确的年、月、日差
    const dateDiff = this.getDateDifference(now, targetDate);
    const years = dateDiff.years;
    const months = dateDiff.months;
    const days = dateDiff.days;
    
    // 计算总月数（年*12 + 月）
    const totalMonths = years * 12 + months;

    if (this.isAccumulatedMode) {
      // 累计模式：所有时间单位都是累计值
      this.timeData = {
        years,
        months: totalMonths, // 显示总月数
        days: totalDays,     // 显示总天数
        hours: totalHours,
        minutes: totalMinutes,
        seconds: totalSeconds
      };
    } else {
      // 非累计模式：年月日显示精确差值，时分秒显示剩余时间
      // 计算当前时间到目标时间的时分秒
      this.timeData = {
        years,
        months: months, // 显示剩余月数
        days: days,     // 显示剩余天数
        hours: Math.floor((diff % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000)),
        minutes: Math.floor((diff % (60 * 60 * 1000)) / (60 * 1000)),
        seconds: Math.floor((diff % (60 * 1000)) / 1000)
      };
    }
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          // 标题区域
          Column() {
            // 标题行：应用名 + 生命进度环形（同一行）
            Row() {
              Column() {
                Text($r('app.string.app_name'))
                  .fontSize(32)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColors.textPrimary)
                  .letterSpacing(2)

                Text($r('app.string.app_desc'))
                  .fontSize(14)
                  .fontColor(this.themeColors.textSecondary)
                  .margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              // 生命进度环形（更新计划五期）
              Stack() {
                Progress({ value: this.lifePercent, total: 100, type: ProgressType.Ring })
                  .width(64)
                  .height(64)
                  .color(this.themeColors.primary)
                  .backgroundColor(this.themeColors.divider)
                  .style({ strokeWidth: 7 })

                Text(this.lifePercent.toFixed(1) + '%')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColors.primary)
              }
              .width(64)
              .height(64)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 签名/座右铭（有值才展示，更新计划一期）
            if (this.signature && this.signature.length > 0) {
              Text(this.signature)
                .fontSize(15)
                .fontColor(this.themeColors.primary)
                .fontStyle(FontStyle.Italic)
                .margin({ top: 8 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 32, bottom: 20 })

        // 出生日期设置组件（隐私模式开启时遮罩，更新计划三期）
        if (this.privacyMode) {
          Column() {
            Text('🔒')
              .fontSize(32)
            Text($r('app.string.privacy_mode_on'))
              .fontSize(14)
              .fontColor(this.themeColors.textSecondary)
              .margin({ top: 8 })
          }
          .width('100%')
          .padding({ top: 28, bottom: 28 })
          .backgroundColor(this.themeColors.cardBackground)
          .borderRadius(16)
        } else {
          BirthDateSelector({ birthDate: $birthDate, targetAge: $targetAge, themeColors: this.themeColors })
        }

        // 时间卡片组（弹性布局，自动换行）
        Column() {
          // 标题
          Row() {
            if (this.isRemainingMode) {
              Text() {
                Span('⏳ ')
                Span($r('app.string.remaining_mode'))
              }
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.textPrimary)
            } else {
              Text() {
                Span('⏱️ ')
                Span($r('app.string.already_alive'))
              }
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.textPrimary)
            }
            
            // 分享按钮
            Button({ type: ButtonType.Circle }) {
              Text('📤')
                .fontSize(16)
            }
            .width(32)
            .height(32)
            .backgroundColor(this.themeColors.background)
            .onClick(() => {
              Logger.info('[HomePage] 分享按钮被点击');
              this.handleShare();
            })
            .margin({ left: 8 })
            
            Blank()
            
            // 主模式切换栏（已存活/剩余）
            Row() {
              Text($r('app.string.already_alive'))
                .fontSize(12)
                .fontColor(!this.isRemainingMode ? '#FFFFFF' : this.themeColors.textSecondary)
                .fontWeight(!this.isRemainingMode ? FontWeight.Medium : FontWeight.Normal)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(!this.isRemainingMode ? this.getPassedColor() : 'transparent')
                .borderRadius(12)
                .onClick(async () => {
                  if (this.isRemainingMode) {
                    this.isRemainingMode = false;
                    // 保存设置
                    if (this.configManager) {
                      await this.configManager.setIsRemainingMode(false);
                    }
                    this.calculateTime();
                  }
                })
              
              Text($r('app.string.remaining_mode'))
                .fontSize(12)
                .fontColor(this.isRemainingMode ? '#FFFFFF' : this.themeColors.textSecondary)
                .fontWeight(this.isRemainingMode ? FontWeight.Medium : FontWeight.Normal)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(this.isRemainingMode ? this.getRemainingColor() : 'transparent')
                .borderRadius(12)
                .onClick(async () => {
                  if (!this.isRemainingMode) {
                    this.isRemainingMode = true;
                    // 保存设置
                    if (this.configManager) {
                      await this.configManager.setIsRemainingMode(true);
                    }
                    this.calculateTime();
                  }
                })
            }
            .backgroundColor(this.themeColors.background)
            .borderRadius(16)
            .padding(2)
          }
          .width('100%')
          .margin({ bottom: 12 })

          // 累计模式切换栏（P5 抽为独立组件）
          AccumulatedModeToggle({
            isAccumulatedMode: $isAccumulatedMode,
            isRemainingMode: this.isRemainingMode,
            onModeChange: () => {
              this.saveModeSettings()
              this.calculateTime()
            }
          })

          // 时间卡片布局
          Column() {
            // 第一行：年月日（根据数值长度自适应宽度）
            Row() {
              Column() {
                TimeCard({
                  value: this.timeData.years,
                  label: $r('app.string.years'),
                  description: this.isRemainingMode ? $r('app.string.remaining_years') : $r('app.string.current_years'),
                  cardColor: this.getYearCardColors().cardColor,
                  valueColor: this.getYearCardColors().valueColor,
                  valueFontSize: 28
                })
              }
              .layoutWeight(this.getValueWeight(this.timeData.years))
              .margin({ right: 8 })

              Column() {
                TimeCard({
                  value: this.timeData.months,
                  label: $r('app.string.months'),
                  description: this.isAccumulatedMode ? 
                    (this.isRemainingMode ? $r('app.string.remaining_total_months') : $r('app.string.current_months')) : 
                    (this.isRemainingMode ? $r('app.string.remaining_months') : $r('app.string.non_accumulated_months')),
                  cardColor: this.getMonthCardColors().cardColor,
                  valueColor: this.getMonthCardColors().valueColor,
                  valueFontSize: 28
                })
              }
              .layoutWeight(this.getValueWeight(this.timeData.months))
              .margin({ right: 8 })

              Column() {
                TimeCard({
                  value: this.timeData.days,
                  label: $r('app.string.days'),
                  description: this.isAccumulatedMode ? 
                    (this.isRemainingMode ? $r('app.string.remaining_total_days') : $r('app.string.current_days')) : 
                    (this.isRemainingMode ? $r('app.string.remaining_days') : $r('app.string.non_accumulated_days')),
                  cardColor: this.getDayCardColors().cardColor,
                  valueColor: this.getDayCardColors().valueColor,
                  valueFontSize: 28
                })
              }
              .layoutWeight(this.getValueWeight(this.timeData.days))
            }
            .width('100%')
            .margin({ bottom: 12 })

            // 第二行：时
            Row() {
              Column() {
                TimeCard({
                  value: this.timeData.hours,
                  label: $r('app.string.hours'),
                  description: this.isAccumulatedMode ? 
                    (this.isRemainingMode ? $r('app.string.remaining_total_hours') : $r('app.string.accumulated_hours')) : 
                    (this.isRemainingMode ? $r('app.string.remaining_hours_short') : $r('app.string.current_hours_short')),
                  cardColor: this.getHourCardColors().cardColor,
                  valueColor: this.getHourCardColors().valueColor
                })
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 12 })

            // 第三行：分
            Row() {
              Column() {
                TimeCard({
                  value: this.timeData.minutes,
                  label: $r('app.string.minutes'),
                  description: this.isAccumulatedMode ? 
                    (this.isRemainingMode ? $r('app.string.remaining_total_minutes') : $r('app.string.accumulated_minutes')) : 
                    (this.isRemainingMode ? $r('app.string.remaining_minutes_short') : $r('app.string.current_minutes_short')),
                  cardColor: this.getMinuteCardColors().cardColor,
                  valueColor: this.getMinuteCardColors().valueColor
                })
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 12 })

            // 第四行：秒
            Row() {
              Column() {
                TimeCard({
                  value: this.timeData.seconds,
                  label: $r('app.string.seconds'),
                  description: this.isAccumulatedMode ? 
                    (this.isRemainingMode ? $r('app.string.remaining_total_seconds') : $r('app.string.accumulated_seconds')) : 
                    (this.isRemainingMode ? $r('app.string.remaining_seconds') : $r('app.string.current_seconds_short')),
                  cardColor: this.getSecondCardColors().cardColor,
                  valueColor: this.getSecondCardColors().valueColor
                })
              }
              .layoutWeight(1)
            }
            .width('100%')
          }
          .width('100%')
          }
          .width('100%')
          .padding(20)
          .margin({ top: 16 })
          .backgroundColor(this.themeColors.cardBackground)
          .borderRadius(16)
          .shadow({
            radius: 12,
            color: this.themeColors.shadow,
            offsetX: 0,
            offsetY: 4
          })
        }
        .width('100%')
        .backgroundColor(this.themeColors.background)
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.background)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    
    // 分享弹窗
    if (this.showShareDialog) {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          if (!this.isSharing) {
            this.showShareDialog = false;
          }
        })
        .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
      
      // 弹窗内容
      Column() {
        // 分享卡片预览区域
        Scroll() {
          Column() {
            ShareHomeCard({
              birthDate: this.birthDate,
              targetAge: this.targetAge,
              timeData: this.timeData,
              isRemainingMode: this.isRemainingMode,
              isAccumulatedMode: this.isAccumulatedMode
            })
              .id('share-home-card')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 16, bottom: 16 })
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .constraintSize({ maxHeight: '60%' })
        
        // 操作按钮
        Row({ space: 12 }) {
          Button($r('app.string.cancel'))
            .layoutWeight(1)
            .height(44)
            .fontSize(16)
            .fontColor(this.themeColors.textSecondary)
            .backgroundColor(this.themeColors.cardBackground)
            .borderRadius(22)
            .enabled(!this.isSharing)
            .onClick(() => {
              this.showShareDialog = false;
            })
          
          Button(this.isSharing ? $r('app.string.sharing_in_progress') : $r('app.string.share'))
            .layoutWeight(1)
            .height(44)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(this.isSharing ? this.themeColors.textSecondary : this.getPassedColor())
            .borderRadius(22)
            .enabled(!this.isSharing)
            .onClick(() => {
              this.doShare();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      }
      .width('90%')
      .backgroundColor(this.themeColors.cardBackground)
      .borderRadius(4)
      .shadow({
        radius: 20,
        color: 'rgba(0, 0, 0, 0.3)',
        offsetX: 0,
        offsetY: 10
      })
      .position({ x: '5%', y: '50%' })
      .translate({ y: '-50%' })
      .transition(
        TransitionEffect.OPACITY
          .combine(TransitionEffect.scale({ x: 0.8, y: 0.8 }))
          .animation({ duration: 300, curve: Curve.EaseOut })
      )
    }
  }
  .width('100%')
  .height('100%')
  }
  
  // 保存累计/剩余模式设置（AccumulatedModeToggle 回调，P5；两值幂等写入）
  private async saveModeSettings() {
    if (this.configManager) {
      await this.configManager.setIsAccumulatedMode(this.isAccumulatedMode)
      await this.configManager.setIsRemainingMode(this.isRemainingMode)
    }
  }

  // 执行分享
  private async doShare() {
    if (this.isSharing) {
      return;
    }
    
    this.isSharing = true;
    Logger.info('[HomePage] 开始分享');
    
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      // 执行分享
      const rm = context.resourceManager;
      const success = await ShareUtils.shareComponent(
        this.getUIContext(),
        'share-home-card',
        context,
        ResourceUtils.getString(rm, 'share_title'),
        ResourceUtils.getString(rm, 'share_description')
      );
      
      if (success) {
        Logger.info('[HomePage] 分享成功');
        setTimeout(() => {
          this.showShareDialog = false;
          this.isSharing = false;
        }, 500);
      } else {
        Logger.error('[HomePage] 分享失败');
        this.isSharing = false;
      }
    } catch (error) {
      Logger.error('[HomePage] 分享异常: ' + JSON.stringify(error));
      this.isSharing = false;
    }
  }
}
