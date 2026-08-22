/**
 * 用户配置仓库层
 * 封装 UserConfig 的 Preferences 持久化访问
 *
 * 仅负责原始字符串的读写；JSON 解析 / 校验 / metadata 更新等业务逻辑
 * 仍由 ConfigManager 负责。
 *
 * 依赖方向：config/ConfigManager → repository → @kit.ArkData (preferences)
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from '../common/utils/Logger'

export class ConfigRepository {
  private static readonly STORE_NAME = 'record_life_config';
  private static readonly CONFIG_KEY = 'user_config';

  /**
   * 从 Preferences 读取配置 JSON 字符串
   * @returns 配置字符串；若存储为空或读取失败，返回 ''
   */
  static async getConfigString(context: common.Context): Promise<string> {
    try {
      const prefs = await preferences.getPreferences(context, ConfigRepository.STORE_NAME);
      return await prefs.get(ConfigRepository.CONFIG_KEY, '') as string;
    } catch (error) {
      Logger.error('[ConfigRepository] 加载配置失败: ' + JSON.stringify(error));
      return '';
    }
  }

  /**
   * 将配置 JSON 字符串保存到 Preferences
   * @returns true 保存成功；false 保存失败
   */
  static async saveConfigString(context: common.Context, configStr: string): Promise<boolean> {
    try {
      const prefs = await preferences.getPreferences(context, ConfigRepository.STORE_NAME);
      await prefs.put(ConfigRepository.CONFIG_KEY, configStr);
      await prefs.flush();
      return true;
    } catch (error) {
      Logger.error('[ConfigRepository] 保存配置失败: ' + JSON.stringify(error));
      return false;
    }
  }
}
