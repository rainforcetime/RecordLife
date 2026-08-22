/**
 * 农历工具类（common/utils/LunarUtils.ets）
 * 公历 ↔ 农历转换（查表法，1900-2100）+ 农历生日相关
 * 纯函数，可单测；数据表为标准农历信息（高位闰月天数/闰月，低位各月大小）
 * 注意：自包含 UTC+8 处理，不依赖 TimeUtils（避免与 TimeUtils 的循环依赖导致未初始化）
 */

// UTC+8 偏移（毫秒）
const TZ_OFFSET_MS = 8 * 60 * 60 * 1000
// 一天的毫秒数
const DAY_MS = 24 * 60 * 60 * 1000

// 解析 YYYY-MM-DD 为 UTC+8 0 点
function parseUtc8Date(dateStr: string): Date {
  const utc = new Date(dateStr + 'T00:00:00Z')
  return new Date(utc.getTime() - TZ_OFFSET_MS)
}

// 格式化 Date 为 YYYY-MM-DD（UTC+8）
function formatUtc8Date(date: Date): string {
  const b = new Date(date.getTime() + TZ_OFFSET_MS)
  const y = b.getUTCFullYear()
  const m = (b.getUTCMonth() + 1).toString().padStart(2, '0')
  const d = b.getUTCDate().toString().padStart(2, '0')
  return y + '-' + m + '-' + d
}

// 获取 UTC+8 年份
function getUtc8Year(date: Date): number {
  return new Date(date.getTime() + TZ_OFFSET_MS).getUTCFullYear()
}

// 农历日期
export interface LunarDate {
  year: number;       // 农历年
  month: number;      // 农历月（1-12）
  day: number;        // 农历日（1-30）
  isLeapMonth: boolean; // 是否闰月
}

// 农历数据表（1900-2100）
// 二进制：第 17 位为闰月天数（1=30 天），4-16 位为闰月月份（0=无闰月），1-12 位为各月大小（1=大月 30 天）
const LUNAR_INFO: number[] = [
  0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, //1900-1909
  0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, //1910-1919
  0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, //1920-1929
  0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, //1930-1939
  0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, //1940-1949
  0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, //1950-1959
  0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, //1960-1969
  0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6, //1970-1979
  0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570, //1980-1989
  0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x055c0, 0x0ab60, 0x096d5, 0x092e0, //1990-1999
  0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, //2000-2009
  0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, //2010-2019
  0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, //2020-2029
  0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, //2030-2039
  0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, //2040-2049
  0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0, //2050-2059
  0x0a2e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4, //2060-2069
  0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, //2070-2079
  0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160, //2080-2089
  0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252, //2090-2099
  0x0d520 //2100
]

// 基准：1900-01-31（UTC+8）= 农历 1900 年正月初一
const BASE_DATE_MS = parseUtc8Date('1900-01-31').getTime()

export class LunarUtils {
  // 该农历年闰月月份（0 = 无闰月）
  private static leapMonth(year: number): number {
    return LUNAR_INFO[year - 1900] & 0xf
  }

  // 该农历年闰月天数（0 = 无闰月）
  private static leapDays(year: number): number {
    if (LunarUtils.leapMonth(year) === 0) {
      return 0
    }
    return (LUNAR_INFO[year - 1900] & 0x10000) ? 30 : 29
  }

  // 该农历年某月天数
  private static monthDays(year: number, month: number): number {
    return (LUNAR_INFO[year - 1900] & (0x10000 >> month)) ? 30 : 29
  }

  // 该农历年总天数
  private static lunarYearDays(year: number): number {
    let sum = 348
    for (let i = 0x8000; i > 0x8; i >>= 1) {
      if (LUNAR_INFO[year - 1900] & i) {
        sum++
      }
    }
    return sum + LunarUtils.leapDays(year)
  }

  /**
   * 公历转农历
   */
  static solarToLunar(date: Date): LunarDate {
    const normalized = parseUtc8Date(formatUtc8Date(date))
    const offset = Math.round((normalized.getTime() - BASE_DATE_MS) / DAY_MS)

    // 累减各农历年天数，定位农历年
    let rest = offset
    let year = 1900
    while (year < 2101 && rest >= LunarUtils.lunarYearDays(year)) {
      rest -= LunarUtils.lunarYearDays(year)
      year++
    }

    const leap = LunarUtils.leapMonth(year)
    let isLeap = false
    let month = 1
    let days = 0
    for (;;) {
      days = LunarUtils.monthDays(year, month)
      if (rest < days) {
        break
      }
      rest -= days
      if (month === leap) {
        const leapDayCount = LunarUtils.leapDays(year)
        if (rest < leapDayCount) {
          isLeap = true
          days = leapDayCount
          break
        }
        rest -= leapDayCount
      }
      month++
    }

    return {
      year: year,
      month: month,
      day: rest + 1,
      isLeapMonth: isLeap
    }
  }

  /**
   * 农历转公历（返回 UTC+8 0 点）
   * 说明：若 isLeapMonth 但目标年无对应闰月，按普通月计算
   */
  static lunarToSolar(lunarYear: number, lunarMonth: number, lunarDay: number, isLeapMonth: boolean): Date {
    let offset = 0
    for (let i = 1900; i < lunarYear; i++) {
      offset += LunarUtils.lunarYearDays(i)
    }
    const leap = LunarUtils.leapMonth(lunarYear)
    for (let i = 1; i < lunarMonth; i++) {
      offset += LunarUtils.monthDays(lunarYear, i)
      if (i === leap) {
        offset += LunarUtils.leapDays(lunarYear)
      }
    }
    if (isLeapMonth) {
      offset += LunarUtils.monthDays(lunarYear, lunarMonth)
    }
    offset += lunarDay - 1
    return new Date(BASE_DATE_MS + offset * DAY_MS)
  }

  /**
   * 指定公历年份中该农历生日的公历日期（闰月生日在无闰年份按普通月）
   */
  static getLunarBirthdayInYear(birthSolar: Date, year: number): Date {
    const lunar = LunarUtils.solarToLunar(birthSolar)
    return LunarUtils.lunarToSolar(year, lunar.month, lunar.day, lunar.isLeapMonth)
  }

  /**
   * 下次农历生日的公历日期（今天生日返回今天）
   */
  static getNextLunarBirthday(birthSolar: Date, now: Date): Date {
    const today = parseUtc8Date(formatUtc8Date(now))
    const currentYear = getUtc8Year(today)
    let birthday = LunarUtils.getLunarBirthdayInYear(birthSolar, currentYear)
    if (birthday.getTime() < today.getTime()) {
      birthday = LunarUtils.getLunarBirthdayInYear(birthSolar, currentYear + 1)
    }
    return birthday
  }
}
