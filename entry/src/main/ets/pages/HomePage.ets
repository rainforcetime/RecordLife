// 首页：展示用户存活时间
import { ConfigManager } from '../config/ConfigManager';
import { UserConfig } from '../config/UserConfig';
import { TimeUtils } from '../common/utils/TimeUtils';
import { TimeData, DateDifference } from '../common/types';
import { TimeCard } from '../components/record/TimeCard';
import { BirthDateSelector } from '../components/user/BirthDateSelector';
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig';

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
  @State birthDate: Date = new Date('1990-01-01T00:00:00Z');
  @State targetAge: number = 80; // 目标年龄，默认80岁
  @State userConfig: UserConfig | null = null;
  @State isAccumulatedMode: boolean = true; // true: 累计模式, false: 非累计模式
  @State isRemainingMode: boolean = false; // true: 剩余模式, false: 已存活模式
  
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
    this.configManager = await ConfigManager.getInstance();
    this.userConfig = this.configManager.getConfig();
    
    // 加载出生日期
    this.birthDate = this.configManager.getBirthDate();
    
    // 加载保存的模式设置
    this.isAccumulatedMode = this.configManager.getIsAccumulatedMode();
    this.isRemainingMode = this.configManager.getIsRemainingMode();
    
    // 开始计算时间
    this.calculateTime();
    this.intervalId = setInterval(() => {
      this.calculateTime();
    }, 1000);
  }

  aboutToDisappear() {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
    }
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

  // 计算存活时间（使用UTC+8时区）
  private calculateTime() {
    const now = TimeUtils.now();
    
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
    // 计算目标日期（出生日期 + 目标年龄），使用UTC+8时区
    const targetDate = new Date(this.birthDate);
    TimeUtils.setFullYear(targetDate, TimeUtils.getFullYear(this.birthDate) + this.targetAge);

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
    Scroll() {
      Column() {
        // 标题区域
        Column() {
          Text('活着')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeColors.textPrimary)
            .letterSpacing(2)

          Text('记录生命的每一刻')
            .fontSize(14)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 6 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 32, bottom: 20 })

        // 出生日期设置组件
        BirthDateSelector({ birthDate: $birthDate, targetAge: $targetAge, themeColors: this.themeColors })

        // 时间卡片组（弹性布局，自动换行）
        Column() {
          // 标题
          Row() {
            Text(this.isRemainingMode ? '⏳ 剩余时间' : '⏱️ 存活时间')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textPrimary)
            
            Blank()
            
            // 主模式切换栏（已存活/剩余）
            Row() {
              Text('已存活')
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
              
              Text('剩余')
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

          // 累计模式切换栏
          Row() {
            Text(this.isRemainingMode ? '剩余计算方式' : '存活计算方式')
              .fontSize(14)
              .fontColor(this.themeColors.textSecondary)
            
            Blank()
            
            Row() {
              Text('累计模式')
                .fontSize(12)
                .fontColor(this.isAccumulatedMode ? '#FFFFFF' : this.themeColors.textSecondary)
                .fontWeight(this.isAccumulatedMode ? FontWeight.Medium : FontWeight.Normal)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(this.isAccumulatedMode ? (this.isRemainingMode ? this.getRemainingColor() : this.getPassedColor()) : 'transparent')
                .borderRadius(12)
                .onClick(async () => {
                  if (!this.isAccumulatedMode) {
                    this.isAccumulatedMode = true;
                    // 保存设置
                    if (this.configManager) {
                      await this.configManager.setIsAccumulatedMode(true);
                    }
                    this.calculateTime();
                  }
                })
              
              Text('非累计模式')
                .fontSize(12)
                .fontColor(!this.isAccumulatedMode ? '#FFFFFF' : this.themeColors.textSecondary)
                .fontWeight(!this.isAccumulatedMode ? FontWeight.Medium : FontWeight.Normal)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(!this.isAccumulatedMode ? (this.isRemainingMode ? this.getRemainingColor() : this.getPassedColor()) : 'transparent')
                .borderRadius(12)
                .onClick(async () => {
                  if (this.isAccumulatedMode) {
                    this.isAccumulatedMode = false;
                    // 保存设置
                    if (this.configManager) {
                      await this.configManager.setIsAccumulatedMode(false);
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
          .margin({ bottom: 16 })

          // 时间卡片布局
          Column() {
            // 第一行：年月日（根据数值长度自适应宽度）
            Row() {
              Column() {
                TimeCard({
                  value: this.timeData.years,
                  label: '年',
                  description: this.isRemainingMode ? '剩余年数' : '已经存活',
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
                  label: '月',
                  description: this.isAccumulatedMode ? 
                    (this.isRemainingMode ? '剩余总月数' : '累计月数') : 
                    (this.isRemainingMode ? '剩余月数' : '当前月数'),
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
                  label: '日',
                  description: this.isAccumulatedMode ? 
                    (this.isRemainingMode ? '剩余总天数' : '累计天数') : 
                    (this.isRemainingMode ? '剩余天数' : '当前天数'),
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
                  label: '小时',
                  description: this.isAccumulatedMode ? 
                    (this.isRemainingMode ? '剩余总小时数' : '累计小时数') : 
                    (this.isRemainingMode ? '剩余小时' : '当前小时'),
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
                  label: '分钟',
                  description: this.isAccumulatedMode ? 
                    (this.isRemainingMode ? '剩余总分钟数' : '累计分钟数') : 
                    (this.isRemainingMode ? '剩余分钟' : '当前分钟'),
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
                  label: '秒',
                  description: this.isAccumulatedMode ? 
                    (this.isRemainingMode ? '剩余总秒数' : '累计秒数') : 
                    (this.isRemainingMode ? '剩余秒数' : '当前秒数'),
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
  }
}
