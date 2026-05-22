// 时间数据接口
export interface TimeData {
  years: number;
  months: number;
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
}

// 日期差值接口
export interface DateDifference {
  years: number;
  months: number;
  days: number;
}

// ==================== NowPage 类型定义 ====================

// 生活记录类型
export type RecordType = 'image' | 'text';

// 生活记录条目
export interface LifeRecord {
  id: string;                    // 唯一标识
  timestamp: number;             // 时间戳（毫秒）
  type: RecordType;              // 类型
  content: string;               // 文字内容或图片路径
  description?: string;          // 图片描述（可选）
}

// 时间线日期节点
export interface TimelineDay {
  day: number;                   // 日期（1-31）
  records: LifeRecord[];         // 该日的记录列表
  isExpanded: boolean;           // 是否展开
}

// 时间线月份节点
export interface TimelineMonth {
  month: number;                 // 月份（1-12）
  days: TimelineDay[];           // 该月的日期列表
  isExpanded: boolean;           // 是否展开
}

// 时间线年份节点
export interface TimelineYear {
  year: number;                  // 年份
  months: TimelineMonth[];       // 该年的月份列表
  isExpanded: boolean;           // 是否展开
}

// 时间线数据
export interface TimelineData {
  years: TimelineYear[];         // 年份列表
}
