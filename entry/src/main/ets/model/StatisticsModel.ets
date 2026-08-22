/**
 * 生命与数据统计纯函数（model 层，更新计划五期：数据看板 / 生命进度）
 * 全部为纯函数（无 IO、无状态），可直接单测
 */
import { LifeRecord } from './RecordModel'
import { TimeUtils } from '../common/utils/TimeUtils'

// 一天的毫秒数
const DAY_MS = 24 * 60 * 60 * 1000

// 数据看板统计结果
export interface LifeStatistics {
  totalRecords: number;      // 记录总数
  activeDays: number;        // 活跃天数（有记录的不同日期数）
  averagePerDay: number;     // 日均记录数（保留 1 位小数）
  longestStreak: number;     // 最长连续记录天数
  totalCharacters: number;   // 累计记录字数
  firstRecordDate: string;   // 最早记录日期（YYYY-MM-DD，UTC+8；无记录为 ''）
  lastRecordDate: string;    // 最近记录日期（YYYY-MM-DD，UTC+8；无记录为 ''）
}

// 生命进度结果
export interface LifeProgress {
  percent: number;      // 已活进度百分比（0-100，保留 1 位）
  livedDays: number;    // 已活天数
  totalDays: number;    // 目标年龄总天数
}

// 已度过时间明细（更新计划五期）
export interface LifeBreakdown {
  years: number;        // 已活整年
  months: number;       // 年内的整月（0-11）
  days: number;         // 剩余天数
}

// 生命里程碑（更新计划五期）
export interface LifeMilestone {
  type: string;         // 'days_10000' | 'age_18' | 'age_50' | 'half_target' | 'target'（UI 层映射资源文案）
  daysFromBirth: number; // 距出生天数
  reached: boolean;     // 是否已达成
  daysLeft: number;     // 未来=距达成天数（正）；已达成=0
  date: string;         // 达成日期（YYYY-MM-DD，UTC+8）
}

export class StatisticsUtils {
  /**
   * 计算数据看板统计（records 应为全部记录）
   */
  static calculateStatistics(records: LifeRecord[]): LifeStatistics {
    const totalRecords = records.length
    const daySet = new Set<string>()
    let totalCharacters = 0
    let minDate = ''
    let maxDate = ''

    for (const record of records) {
      const dateStr = TimeUtils.formatDate(new Date(record.timestamp))
      daySet.add(dateStr)
      totalCharacters += record.content.length
      if (minDate.length === 0 || dateStr < minDate) {
        minDate = dateStr
      }
      if (maxDate.length === 0 || dateStr > maxDate) {
        maxDate = dateStr
      }
    }

    const activeDays = daySet.size
    const averagePerDay = totalRecords > 0 ? Math.round((totalRecords / activeDays) * 10) / 10 : 0

    return {
      totalRecords: totalRecords,
      activeDays: activeDays,
      averagePerDay: averagePerDay,
      longestStreak: StatisticsUtils.getLongestStreak(records),
      totalCharacters: totalCharacters,
      firstRecordDate: minDate,
      lastRecordDate: maxDate
    }
  }

  /**
   * 最长连续记录天数（按 UTC+8 日期）
   */
  static getLongestStreak(records: LifeRecord[]): number {
    if (records.length === 0) {
      return 0
    }
    const daySet = new Set<string>()
    for (const record of records) {
      daySet.add(TimeUtils.formatDate(new Date(record.timestamp)))
    }
    const sortedDays = Array.from(daySet).sort()
    let maxStreak = 1
    let current = 1
    for (let i = 1; i < sortedDays.length; i++) {
      const prev = TimeUtils.parseDate(sortedDays[i - 1]).getTime()
      const curr = TimeUtils.parseDate(sortedDays[i]).getTime()
      if (curr - prev === DAY_MS) {
        current++
        if (current > maxStreak) {
          maxStreak = current
        }
      } else {
        current = 1
      }
    }
    return maxStreak
  }

  /**
   * 生命进度（已活 / 目标年龄比例）
   * @param birthDate 出生日期（UTC+8 0 点）
   * @param targetAge 目标年龄（>0）
   * @param now 基准时刻，缺省为当前时间
   */
  static getLifeProgress(birthDate: Date, targetAge: number, now?: Date): LifeProgress {
    const safeTarget = targetAge > 0 ? targetAge : 80
    const livedDays = TimeUtils.getDayOfLife(birthDate, now)
    const totalDays = safeTarget * 365
    const percent = totalDays > 0 ? Math.round((livedDays / totalDays) * 1000) / 10 : 0
    return {
      percent: percent,
      livedDays: livedDays,
      totalDays: totalDays
    }
  }

  /**
   * 已度过时间明细（年月日，UTC+8）
   */
  static getLifeBreakdown(birthDate: Date, now?: Date): LifeBreakdown {
    const diff = TimeUtils.getDateDifference(birthDate, now ?? TimeUtils.now())
    return {
      years: diff.years,
      months: diff.months,
      days: diff.days
    }
  }

  /**
   * 生命里程碑列表（按距出生天数升序；type 供 UI 层映射文案）
   * 里程碑：1 万天 / 18 岁 / 50 岁 / 目标年龄一半 / 目标年龄
   */
  static getLifeMilestones(birthDate: Date, targetAge: number, now?: Date): LifeMilestone[] {
    const safeTarget = targetAge > 0 ? targetAge : 80
    const livedDays = TimeUtils.getDayOfLife(birthDate, now)
    const base = birthDate.getTime()

    const candidates: Array<[string, number]> = [
      ['days_10000', 10000],
      ['age_18', 18 * 365],
      ['age_50', 50 * 365],
      ['half_target', Math.floor(safeTarget / 2) * 365],
      ['target', safeTarget * 365]
    ]

    const milestones: LifeMilestone[] = []
    for (const [type, daysFromBirth] of candidates) {
      // 达成日期 = 出生 + daysFromBirth 天（UTC+8）
      const date = TimeUtils.formatDate(new Date(base + daysFromBirth * DAY_MS))
      const reached = livedDays >= daysFromBirth
      milestones.push({
        type: type,
        daysFromBirth: daysFromBirth,
        reached: reached,
        daysLeft: reached ? 0 : daysFromBirth - livedDays,
        date: date
      })
    }
    return milestones
  }
}
