// 标签显示工具：common/utils/TagDisplayUtils.ets
// 预设标签（DEFAULT_TAGS）显示名国际化：id → 资源 key 映射；自定义标签保留数据 name
import { resourceManager } from '@kit.LocalizationKit'
import { ResourceUtils } from './ResourceUtils'
import { Tag, getAllTags, getTagNameById } from '../types'

// 预设标签 id → 资源 key 映射
const PRESET_TAG_RES_KEYS: Map<string, string> = new Map([
  ['work', 'tag_name_work'],
  ['life', 'tag_name_life'],
  ['travel', 'tag_name_travel'],
  ['food', 'tag_name_food'],
  ['health', 'tag_name_health'],
  ['study', 'tag_name_study'],
  ['sport', 'tag_name_sport'],
  ['hobby', 'tag_name_hobby'],
  ['friend', 'tag_name_friend'],
  ['other', 'tag_name_other']
])

// 构建显示用标签列表（预设名国际化，自定义标签保留数据 name）
export function buildDisplayTags(customTags: Tag[] | undefined, rm: resourceManager.ResourceManager | null): Tag[] {
  return getAllTags(customTags).map(tag => {
    const resKey = PRESET_TAG_RES_KEYS.get(tag.id)
    if (resKey && rm) {
      return {
        id: tag.id,
        name: ResourceUtils.getString(rm, resKey),
        color: tag.color,
        icon: tag.icon
      }
    }
    return tag
  })
}

// 获取标签显示名（预设读资源，自定义/未知回退 getTagNameById）
export function getDisplayTagName(tagId: string, customTags: Tag[] | undefined, rm: resourceManager.ResourceManager | null): string {
  const resKey = PRESET_TAG_RES_KEYS.get(tagId)
  if (resKey && rm) {
    return ResourceUtils.getString(rm, resKey)
  }
  return getTagNameById(tagId, customTags)
}
