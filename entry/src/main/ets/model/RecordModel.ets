// 记录领域模型
import { TimeUtils } from '../common/utils/TimeUtils'

// 记录接口
export interface LifeRecord {
  id: string;               // 记录唯一标识
  timestamp: number;        // 记录时间戳（创建时间，毫秒）
  content: string;          // 记录内容
  updatedAt?: number;       // 最后修改时间戳（毫秒，可选；编辑保存时更新，未编辑过则无）
  imagePaths?: string[];    // 图片路径数组（可选）
  imageCloudKeys?: string[]; // 云端原图 key 数组（可选，与 imagePaths 一一对应；图片存储优化 M3）
  tags?: string[];          // 标签ID数组（可选）
  isPinned?: boolean;       // 是否置顶（可选）
  mood?: string;            // 心情（可选，更新计划二期：心情 id，预置或自定义）
}

// 心情（更新计划二期：自定义心情）
export interface Mood {
  id: string;               // 心情唯一标识（预置为 'happy' 等；自定义为 'mood_xxx'）
  emoji: string;            // 心情 emoji
}

// 图片信息接口
export interface ImageInfo {
  path: string;             // 图片路径
  uri?: string;             // 图片 URI（可选）
  thumbnailPath?: string;   // 缩略图路径（可选）
}

// ==================== 时间线数据结构 ====================

// 时间线日数据
export interface TimelineDay {
  day: number;
  records: LifeRecord[];
  isExpanded: boolean;
}

// 时间线月数据
export interface TimelineMonth {
  month: number;
  days: TimelineDay[];
  isExpanded: boolean;
}

// 时间线年数据
export interface TimelineYear {
  year: number;
  months: TimelineMonth[];
  isExpanded: boolean;
}

// 时间线数据
export interface TimelineData {
  years: TimelineYear[];
}

// ==================== 时间线构建（纯函数，可单测） ====================

// 构建时间线数据（按年/月/日分组，降序排列，当前年月默认展开）
// 自 NowViewModel.buildTimeline 下沉（P4），纯函数无副作用，可直接单测
export function buildTimelineData(records: LifeRecord[], now: Date): TimelineData {
  const currentYear = TimeUtils.getFullYear(now);
  const currentMonth = TimeUtils.getMonth(now) + 1;  // 0-11 → 1-12，与分组月份（date.getMonth()+1）对齐；修复 off-by-one：当前月展开原本永不生效

  // 按年月日分组
  const yearMap = new Map<number, Map<number, Map<number, LifeRecord[]>>>();

  for (const record of records) {
    const date = new Date(record.timestamp);
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();

    if (!yearMap.has(year)) {
      yearMap.set(year, new Map<number, Map<number, LifeRecord[]>>());
    }

    const monthMap = yearMap.get(year)!;
    if (!monthMap.has(month)) {
      monthMap.set(month, new Map<number, LifeRecord[]>());
    }

    const dayMap = monthMap.get(month)!;
    if (!dayMap.has(day)) {
      dayMap.set(day, []);
    }

    dayMap.get(day)!.push(record);
  }

  // 构建时间线结构
  const years: TimelineYear[] = [];
  const sortedYears = Array.from(yearMap.keys()).sort((a, b) => b - a); // 降序

  for (const year of sortedYears) {
    const monthMap = yearMap.get(year)!;
    const months: TimelineMonth[] = [];
    const sortedMonths = Array.from(monthMap.keys()).sort((a, b) => b - a);

    for (const month of sortedMonths) {
      const dayMap = monthMap.get(month)!;
      const days: TimelineDay[] = [];
      const sortedDays = Array.from(dayMap.keys()).sort((a, b) => b - a);

      for (const day of sortedDays) {
        const dayRecords = dayMap.get(day)!;
        days.push({
          day: day,
          records: dayRecords,
          isExpanded: false // 默认折叠
        });
      }

      months.push({
        month: month,
        days: days,
        isExpanded: false // 默认折叠
      });
    }

    years.push({
      year: year,
      months: months,
      isExpanded: year === currentYear // 当前年份默认展开
    });
  }

  // 如果有当前年份，展开当前月份
  if (years.length > 0 && years[0].year === currentYear) {
    const currentYearNode = years[0];
    for (const monthNode of currentYearNode.months) {
      if (monthNode.month === currentMonth) {
        monthNode.isExpanded = true;
        break;
      }
    }
  }

  return { years: years };
}

// ==================== 日历数据结构 ====================

// 日历日数据
export interface CalendarDay {
  date: Date;               // 日期对象
  year: number;             // 年
  month: number;            // 月
  day: number;              // 日
  isCurrentMonth: boolean;  // 是否当前月
  isToday: boolean;         // 是否今天
  recordCount: number;      // 记录数量
  records: LifeRecord[];    // 当日记录
}
