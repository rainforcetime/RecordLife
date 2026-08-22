/**
 * 时间工具类 - 统一使用UTC+8时区
 * 所有时间计算和显示都基于北京时间（UTC+8）
 */

// UTC+8时区偏移量（毫秒）
const TIMEZONE_OFFSET_MS = 8 * 60 * 60 * 1000;

// 一天的毫秒数
const DAY_MS = 24 * 60 * 60 * 1000;

// 日期差值接口
export interface DateDifference {
  years: number;
  months: number;
  days: number;
}

export class TimeUtils {
  /**
   * 获取当前时间
   * @returns Date对象（不修改时间戳，保持标准UTC时间戳）
   */
  static now(): Date {
    return new Date();
  }

  /**
   * 获取UTC+8时区的年份
   */
  static getFullYear(date: Date): number {
    // UTC时间+8小时得到北京时间
    const beijingTime = new Date(date.getTime() + TIMEZONE_OFFSET_MS);
    return beijingTime.getUTCFullYear();
  }

  /**
   * 获取UTC+8时区的月份（0-11）
   */
  static getMonth(date: Date): number {
    const beijingTime = new Date(date.getTime() + TIMEZONE_OFFSET_MS);
    return beijingTime.getUTCMonth();
  }

  /**
   * 获取UTC+8时区的日期（1-31）
   */
  static getDate(date: Date): number {
    const beijingTime = new Date(date.getTime() + TIMEZONE_OFFSET_MS);
    return beijingTime.getUTCDate();
  }

  /**
   * 获取UTC+8时区的小时（0-23）
   */
  static getHours(date: Date): number {
    const beijingTime = new Date(date.getTime() + TIMEZONE_OFFSET_MS);
    return beijingTime.getUTCHours();
  }

  /**
   * 获取UTC+8时区的分钟（0-59）
   */
  static getMinutes(date: Date): number {
    const beijingTime = new Date(date.getTime() + TIMEZONE_OFFSET_MS);
    return beijingTime.getUTCMinutes();
  }

  /**
   * 获取UTC+8时区的秒数（0-59）
   */
  static getSeconds(date: Date): number {
    const beijingTime = new Date(date.getTime() + TIMEZONE_OFFSET_MS);
    return beijingTime.getUTCSeconds();
  }

  /**
   * 设置UTC+8时区的年份
   */
  static setFullYear(date: Date, year: number): void {
    // 先转换为北京时间，设置年份，再转回UTC时间戳
    const beijingTime = new Date(date.getTime() + TIMEZONE_OFFSET_MS);
    beijingTime.setUTCFullYear(year);
    date.setTime(beijingTime.getTime() - TIMEZONE_OFFSET_MS);
  }

  /**
   * 格式化日期为 YYYY-MM-DD 格式（UTC+8时区）
   */
  static formatDate(date: Date): string {
    const beijingTime = new Date(date.getTime() + TIMEZONE_OFFSET_MS);
    const year = beijingTime.getUTCFullYear();
    const month = (beijingTime.getUTCMonth() + 1).toString().padStart(2, '0');
    const day = beijingTime.getUTCDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 解析日期字符串为Date对象（按UTC+8时区解析）
   * @param dateStr 格式：YYYY-MM-DD
   * @returns Date对象（内部存储UTC时间戳，表示北京时间的0点）
   */
  static parseDate(dateStr: string): Date {
    // 将日期字符串解析为UTC时间，然后减去8小时偏移，使其表示UTC+8时区的0点
    const utcDate = new Date(dateStr + 'T00:00:00Z');
    return new Date(utcDate.getTime() - TIMEZONE_OFFSET_MS);
  }

  /**
   * 计算两个日期之间的年月日差（基于UTC+8时区）
   */
  static getDateDifference(startDate: Date, endDate: Date): DateDifference {
    // 转换为北京时间进行计算
    const beijingStart = new Date(startDate.getTime() + TIMEZONE_OFFSET_MS);
    const beijingEnd = new Date(endDate.getTime() + TIMEZONE_OFFSET_MS);
    
    let years = beijingEnd.getUTCFullYear() - beijingStart.getUTCFullYear();
    let months = beijingEnd.getUTCMonth() - beijingStart.getUTCMonth();
    let days = beijingEnd.getUTCDate() - beijingStart.getUTCDate();

    // 处理负数天数
    if (days < 0) {
      // 获取endDate上个月的天数
      const lastDayOfPrevMonth = new Date(Date.UTC(beijingEnd.getUTCFullYear(), beijingEnd.getUTCMonth(), 0)).getUTCDate();
      days += lastDayOfPrevMonth;
      months--;
    }

    // 处理负数月份
    if (months < 0) {
      years--;
      months += 12;
    }

    // 如果开始日期大于结束日期
    if (years < 0) {
      years = 0;
      months = 0;
      days = 0;
    }

    const result: DateDifference = {
      years: years,
      months: months,
      days: days
    };
    return result;
  }

  /**
   * 获取指定年月的最后一天
   */
  static getLastDayOfMonth(year: number, month: number): number {
    return new Date(Date.UTC(year, month + 1, 0)).getUTCDate();
  }

  // ==================== 生命里程碑计算（纯函数，可单测；更新计划一期） ====================

  /**
   * 生命中第几天（出生日当天 = 第 1 天；未出生返回 0）
   * @param birthDate 出生日期（取北京时间当天 0 点归一化）
   * @param now 基准时刻，缺省为当前时间
   */
  static getDayOfLife(birthDate: Date, now?: Date): number {
    const today = TimeUtils.parseDate(TimeUtils.formatDate(now ?? TimeUtils.now()));
    const birth = TimeUtils.parseDate(TimeUtils.formatDate(birthDate));
    const diffMs = today.getTime() - birth.getTime();
    if (diffMs < 0) {
      return 0;
    }
    return Math.floor(diffMs / DAY_MS) + 1;
  }

  /**
   * 生命中第几周（第 1 天起算第 1 周；未出生返回 0）
   * @param birthDate 出生日期
   * @param now 基准时刻，缺省为当前时间
   */
  static getWeekOfLife(birthDate: Date, now?: Date): number {
    const dayOfLife = TimeUtils.getDayOfLife(birthDate, now);
    if (dayOfLife <= 0) {
      return 0;
    }
    return Math.ceil(dayOfLife / 7);
  }

  /**
   * 距下次生日的天数（今天生日返回 0；未设置/出生日期在未来时按正常算法返回，调用方自行处理）
   * @param birthDate 出生日期
   * @param now 基准时刻，缺省为当前时间
   * @returns 0~366
   */
  static getDaysUntilNextBirthday(birthDate: Date, now?: Date): number {
    const today = TimeUtils.parseDate(TimeUtils.formatDate(now ?? TimeUtils.now()));
    const birth = TimeUtils.parseDate(TimeUtils.formatDate(birthDate));

    // 取北京时间年月日分量（UTC+8 一致性）
    const beijing = new Date(birth.getTime() + TIMEZONE_OFFSET_MS);
    const birthMonth = beijing.getUTCMonth(); // 0-11
    const birthDay = beijing.getUTCDate();    // 1-31

    // 当前年份（北京时间）；注意生日「今年」按当前年份计算，而非出生年份
    const todayBeijing = new Date(today.getTime() + TIMEZONE_OFFSET_MS);
    const currentYear = todayBeijing.getUTCFullYear();

    // 今年生日（北京时间 0 点）；2/29 在平年由 Date.UTC 溢出自动滚到 3/1
    const thisYearBirthday = Date.UTC(currentYear, birthMonth, birthDay) - TIMEZONE_OFFSET_MS;
    let nextBirthday = thisYearBirthday;
    if (thisYearBirthday < today.getTime()) {
      // 今年生日已过（含昨天），取明年
      nextBirthday = Date.UTC(currentYear + 1, birthMonth, birthDay) - TIMEZONE_OFFSET_MS;
    }
    return Math.round((nextBirthday - today.getTime()) / DAY_MS);
  }
}
