/**
 * 记录数据仓库层
 * 封装 LifeRecord 的 Preferences 持久化访问，消除 store/key 常量散落问题
 *
 * 依赖方向：viewmodel / handler / manager → repository → @kit.ArkData (preferences)
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { LifeRecord } from '../model/RecordModel';
import { Logger } from '../common/utils/Logger'

export class RecordRepository {
  private static readonly STORE_NAME = 'now_page_records';
  private static readonly RECORDS_KEY = 'life_records';
  private static readonly SAMPLE_FLAG_KEY = 'sample_data_initialized';

  /**
   * 从 Preferences 加载全部记录（已反序列化）
   * @returns LifeRecord[]；若存储为空或读取失败，返回 []
   */
  static async getRecords(context: common.Context): Promise<LifeRecord[]> {
    try {
      const prefs = await preferences.getPreferences(context, RecordRepository.STORE_NAME);
      const recordsStr = await prefs.get(RecordRepository.RECORDS_KEY, '') as string;
      if (recordsStr) {
        return JSON.parse(recordsStr) as LifeRecord[];
      }
      return [];
    } catch (error) {
      Logger.error('[RecordRepository] 加载记录失败: ' + JSON.stringify(error));
      return [];
    }
  }

  /**
   * 将记录列表序列化后保存到 Preferences
   * @returns true 保存成功；false 保存失败
   */
  static async saveRecords(context: common.Context, records: LifeRecord[]): Promise<boolean> {
    try {
      const prefs = await preferences.getPreferences(context, RecordRepository.STORE_NAME);
      const recordsStr = JSON.stringify(records);
      await prefs.put(RecordRepository.RECORDS_KEY, recordsStr);
      await prefs.flush();
      return true;
    } catch (error) {
      Logger.error('[RecordRepository] 保存记录失败: ' + JSON.stringify(error));
      return false;
    }
  }

  /**
   * 清空全部记录（写入 '[]'）
   * @returns true 成功；false 失败
   */
  static async clearRecords(context: common.Context): Promise<boolean> {
    try {
      const prefs = await preferences.getPreferences(context, RecordRepository.STORE_NAME);
      await prefs.put(RecordRepository.RECORDS_KEY, '[]');
      await prefs.flush();
      return true;
    } catch (error) {
      Logger.error('[RecordRepository] 清空记录失败: ' + JSON.stringify(error));
      return false;
    }
  }

  // ==================== 示例数据初始化标记 ====================
  // 以「是否已初始化过示例」而非「记录是否为空」判断首次使用：
  // 用户删光记录/导入空备份后重启不应再次生成示例；重置应用会清除标记，从而恢复示例（与首次安装一致）。

  /**
   * 是否已初始化示例数据
   */
  static async isSampleDataInitialized(context: common.Context): Promise<boolean> {
    try {
      const prefs = await preferences.getPreferences(context, RecordRepository.STORE_NAME);
      return await prefs.get(RecordRepository.SAMPLE_FLAG_KEY, false) as boolean;
    } catch (error) {
      Logger.error('[RecordRepository] 读取示例标记失败: ' + JSON.stringify(error));
      return false;
    }
  }

  /**
   * 标记示例数据已初始化（首次安装生成示例后调用）
   */
  static async markSampleDataInitialized(context: common.Context): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, RecordRepository.STORE_NAME);
      await prefs.put(RecordRepository.SAMPLE_FLAG_KEY, true);
      await prefs.flush();
    } catch (error) {
      Logger.error('[RecordRepository] 写入示例标记失败: ' + JSON.stringify(error));
    }
  }

  /**
   * 清除示例数据初始化标记（重置应用时调用，使重启后重新生成示例）
   */
  static async clearSampleDataFlag(context: common.Context): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, RecordRepository.STORE_NAME);
      await prefs.put(RecordRepository.SAMPLE_FLAG_KEY, false);
      await prefs.flush();
    } catch (error) {
      Logger.error('[RecordRepository] 清除示例标记失败: ' + JSON.stringify(error));
    }
  }
}
