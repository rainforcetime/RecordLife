/**
 * 引导页数据仓库（repository 层，更新计划四期：首装引导标记）
 * 独立 store（app_meta），不涉及业务数据，不影响备份
 */
import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { Logger } from '../common/utils/Logger'

export class GuideRepository {
  private static readonly STORE_NAME = 'app_meta'
  private static readonly GUIDE_KEY = 'has_seen_guide'

  // 是否已看过引导页（未看过返回 false → 首次安装）
  static async hasSeenGuide(context: common.Context): Promise<boolean> {
    try {
      const prefs = await preferences.getPreferences(context, GuideRepository.STORE_NAME)
      return await prefs.get(GuideRepository.GUIDE_KEY, false) as boolean
    } catch (error) {
      Logger.error('[GuideRepository] 读取引导标记失败: ' + JSON.stringify(error))
      return false
    }
  }

  // 标记已看过引导页
  static async markGuideSeen(context: common.Context): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, GuideRepository.STORE_NAME)
      await prefs.put(GuideRepository.GUIDE_KEY, true)
      await prefs.flush()
    } catch (error) {
      Logger.error('[GuideRepository] 写入引导标记失败: ' + JSON.stringify(error))
    }
  }

  // 清除引导标记（重置应用时调用，使重置后重新展示引导）
  static async clearGuideFlag(context: common.Context): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, GuideRepository.STORE_NAME)
      await prefs.put(GuideRepository.GUIDE_KEY, false)
      await prefs.flush()
    } catch (error) {
      Logger.error('[GuideRepository] 清除引导标记失败: ' + JSON.stringify(error))
    }
  }
}
