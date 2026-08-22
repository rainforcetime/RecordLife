/**
 * 心情工具类（更新计划二期：心情标记）
 * mood 值为内部标识（存 LifeRecord.mood），emoji 与名称由显示层映射
 */

export class MoodUtils {
  // 全部心情（顺序即选择器展示顺序）
  static readonly MOODS: string[] = ['happy', 'calm', 'excited', 'sad', 'tired']

  /**
   * 心情 → emoji（未知返回空串）
   */
  static getMoodEmoji(mood: string): string {
    switch (mood) {
      case 'happy':
        return '😊'
      case 'calm':
        return '😌'
      case 'excited':
        return '🤩'
      case 'sad':
        return '😢'
      case 'tired':
        return '😴'
      default:
        return ''
    }
  }

  /**
   * 判断是否为合法心情值
   */
  static isValidMood(mood: string): boolean {
    return MoodUtils.MOODS.includes(mood)
  }
}
