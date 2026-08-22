// 标签领域模型

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
  { id: 'sport', name: '运动', color: '#FF69B4', icon: '⚽' },
  { id: 'hobby', name: '爱好', color: '#00BCD4', icon: '🎨' },
  { id: 'friend', name: '社交', color: '#FF9800', icon: '👥' },
  { id: 'other', name: '其他', color: '#607D8B', icon: '📌' },
];

// 获取所有标签（预设 + 用户自定义）
export function getAllTags(customTags?: Tag[]): Tag[] {
  if (customTags && customTags.length > 0) {
    return [...DEFAULT_TAGS, ...customTags];
  }
  return DEFAULT_TAGS;
}

// 根据ID获取标签名称
export function getTagNameById(tagId: string, customTags?: Tag[]): string {
  const allTags = getAllTags(customTags);
  const tag = allTags.find(t => t.id === tagId);
  return tag ? tag.name : tagId;
}

// 根据ID获取标签
export function getTagById(tagId: string, customTags?: Tag[]): Tag | undefined {
  const allTags = getAllTags(customTags);
  return allTags.find(t => t.id === tagId);
}
