/**
 * 通知服务（service 层，更新计划四期：每日提醒通知）
 * 请求通知授权 + 通过 reminderAgentManager 发布/取消每日定时提醒（系统级，无需应用常驻后台）
 */
import { reminderAgentManager } from '@kit.ReminderAgentKit'
import { notificationManager } from '@kit.NotificationKit'
import { common } from '@kit.AbilityKit'
import { Logger } from '../common/utils/Logger'

export class NotificationService {
  // 请求通知授权（首次弹系统授权框）
  static async requestNotificationPermission(context: common.UIAbilityContext): Promise<boolean> {
    try {
      await notificationManager.requestEnableNotification(context)
      return true
    } catch (error) {
      Logger.error('[NotificationService] 请求通知授权失败: ' + JSON.stringify(error))
      return false
    }
  }

  // 发布每日提醒（每日固定时间重复）
  static async publishDailyReminder(context: common.UIAbilityContext, hour: number, minute: number): Promise<boolean> {
    try {
      const rm = context.resourceManager
      const reminder: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        title: rm.getStringByNameSync('app_name'),
        content: rm.getStringByNameSync('daily_reminder_content'),
        hour: hour,
        minute: minute,
        daysOfWeek: [],       // 空 = 每日重复
        repeatMonths: [],
        repeatDays: [],
        wantAgent: {
          pkgName: context.abilityInfo.bundleName,
          abilityName: 'EntryAbility'
        },
        notificationId: 11001
      }
      await reminderAgentManager.publishReminder(reminder)
      Logger.info('[NotificationService] 每日提醒已发布: ' + hour + ':' + minute)
      return true
    } catch (error) {
      Logger.error('[NotificationService] 发布每日提醒失败: ' + JSON.stringify(error))
      return false
    }
  }

  // 取消全部提醒
  static async cancelAllReminders(): Promise<boolean> {
    try {
      await reminderAgentManager.cancelAllReminders()
      return true
    } catch (error) {
      Logger.error('[NotificationService] 取消提醒失败: ' + JSON.stringify(error))
      return false
    }
  }
}
