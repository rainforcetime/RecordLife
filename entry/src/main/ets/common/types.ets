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

// ==================== 标签类型定义 ====================

// 标签接口
export interface Tag {
  id: string;           // 标签唯一标识
  name: string;         // 标签名称
  color: string;        // 标签颜色（十六进制）
  icon?: string;        // 标签图标（可选，emoji）
}

// 预设标签列表
export const DEFAULT_TAGS: Tag[] = [
  { id: 'work', name: '工作', color: '#4A90D9', icon: '💼' },
  { id: 'life', name: '生活', color: '#67C23A', icon: '🏠' },
  { id: 'travel', name: '旅行', color: '#E6A23C', icon: '✈️' },
  { id: 'food', name: '美食', color: '#F56C6C', icon: '🍜' },
  { id: 'health', name: '健康', color: '#909399', icon: '💪' },
  { id: 'study', name: '学习', color: '#9B59B6', icon: '📚' },
  { id: 'entertainment', name: '娱乐', color: '#FF69B4', icon: '🎮' },
  { id: 'family', name: '家庭', color: '#00BCD4', icon: '👨‍👩‍👧‍👦' }
];

// ==================== NowPage 类型定义 ====================

// 生活记录条目（统一类型，图片为可选项）
export interface LifeRecord {
  id: string;                    // 唯一标识
  timestamp: number;             // 时间戳（毫秒）
  content: string;               // 文字内容（可为空）
  imagePaths?: string[];         // 图片路径数组（可选，最多9张）
  tags?: string[];               // 标签ID数组（可选）
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

// ==================== 图片相关类型定义 ====================

// 图片信息接口
export interface ImageInfo {
  path: string;                  // 图片路径
  uri: string;                   // 图片URI
}
