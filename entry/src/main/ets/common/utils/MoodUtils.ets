/**
 * 心情工具类（更新计划二期：心情标记 + 自定义心情）
 * LifeRecord.mood 存心情 id（预置或自定义）；emoji 由本工具映射
 */
import { Mood } from '../../model/RecordModel'

export class MoodUtils {
  // 预置心情（不可删除/编辑）
  static readonly PRESET_MOODS: Mood[] = [
    { id: 'happy', emoji: '😊' },
    { id: 'calm', emoji: '😌' },
    { id: 'excited', emoji: '🤩' },
    { id: 'sad', emoji: '😢' },
    { id: 'tired', emoji: '😴' }
  ]

  // 预置心情 id 列表（兼容旧调用）
  static readonly MOODS: string[] = MoodUtils.PRESET_MOODS.map(m => m.id)

  // 自定义心情候选 emoji 池（个性化管理页心情管理选择，3.0.4 扩充至 ~80 个）
  static readonly PRESET_MOOD_EMOJIS: string[] = [
    // 笑脸/开心
    '😀', '😄', '😁', '😆', '😊', '😌', '🙂', '😉',
    '😍', '🥰', '😘', '🤗', '🤩', '🥳', '😎', '🤓',
    '😇', '🥹', '😏', '😜', '🤪', '😝', '🤭', '🫢',
    // 中性/无语
    '😐', '😑', '😶', '🫥', '😒', '🙄', '😬', '🤔',
    // 难过/生气
    '😢', '😭', '🥺', '😞', '😟', '😣', '😩', '😤',
    '😠', '😡', '🤬', '😖', '😫', '🥱', '😴', '😪',
    // 惊讶/害怕/不适
    '😮', '😲', '😳', '🥴', '😵', '🤯', '🤢', '🤮',
    '🤧', '😷', '🤕', '🥶', '🥵', '🤤', '😱', '🫠',
    // 动物/自然
    '🐶', '🐱', '🐰', '🦊', '🐼', '🐯', '🐸', '🐵',
    '🐷', '🐧', '🐤', '🦋', '🌸', '🌙', '🌈',
    // 物品/符号
    '❤️', '💔', '💕', '✨', '🎉', '🎂', '☕', '🍰',
    '🎮', '🎵', '🎧', '📚', '💪', '👍', '👏', '🙏',
    '💯', '🔥', '💤', '⚡', '💡'
  ]

  /**
   * 心情 id → emoji（预置优先，再查自定义；未知返回空串）
   * @param moodId 心情 id
   * @param customMoods 自定义心情列表（可选）
   */
  static getMoodEmoji(moodId: string, customMoods?: Mood[]): string {
    for (const mood of MoodUtils.PRESET_MOODS) {
      if (mood.id === moodId) {
        return mood.emoji
      }
    }
    if (customMoods) {
      for (const mood of customMoods) {
        if (mood.id === moodId) {
          return mood.emoji
        }
      }
    }
    return ''
  }

  /**
   * 判断是否为合法心情 id（预置或自定义）
   */
  static isValidMood(moodId: string, customMoods?: Mood[]): boolean {
    return MoodUtils.getMoodEmoji(moodId, customMoods).length > 0
  }

  /**
   * 全部心情（预置 + 自定义），用于选择器/筛选栏
   */
  static getAllMoods(customMoods?: Mood[]): Mood[] {
    const result: Mood[] = [...MoodUtils.PRESET_MOODS]
    if (customMoods) {
      for (const mood of customMoods) {
        result.push(mood)
      }
    }
    return result
  }
}
