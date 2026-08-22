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
}
