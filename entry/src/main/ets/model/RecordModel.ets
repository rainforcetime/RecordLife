// 记录领域模型

// 记录接口
export interface LifeRecord {
  id: string;               // 记录唯一标识
  timestamp: number;        // 记录时间戳
  content: string;          // 记录内容
  imagePaths?: string[];    // 图片路径数组（可选）
  tags?: string[];          // 标签ID数组（可选）
  isPinned?: boolean;       // 是否置顶（可选）
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
