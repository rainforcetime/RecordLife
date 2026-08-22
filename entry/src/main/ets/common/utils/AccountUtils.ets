// 账号页面工具类：common/utils/AccountUtils.ets
import { promptAction, PromptAction } from '@kit.ArkUI'
import { ResourceUtils } from './ResourceUtils'
import { resourceManager } from '@kit.LocalizationKit'
import { Logger } from './Logger'

// 账号页面工具方法类
export class AccountUtils {
  // 主题格式转换：存储格式转显示格式（显示文本国际化，需传 resourceManager）
  static themeToDisplay(theme: string, rm: resourceManager.ResourceManager | null): string {
    if (!rm) {
      return ''
    }
    switch (theme) {
      case 'light':
        return ResourceUtils.getString(rm, 'light_mode')
      case 'dark':
        return ResourceUtils.getString(rm, 'dark_mode')
      case 'auto':
      default:
        return ResourceUtils.getString(rm, 'follow_system')
    }
  }

  // 主题格式转换：显示格式转存储格式（按当前语言资源值反向匹配）
  static displayToTheme(display: string, rm: resourceManager.ResourceManager | null): string {
    if (!rm) {
      return 'auto'
    }
    if (display === ResourceUtils.getString(rm, 'light_mode')) {
      return 'light'
    }
    if (display === ResourceUtils.getString(rm, 'dark_mode')) {
      return 'dark'
    }
    return 'auto'
  }

  // 字体大小格式转换：存储格式转显示格式（国际化，需传 resourceManager；更新计划一期）
  static fontSizeToDisplay(fontSize: string, rm: resourceManager.ResourceManager | null): string {
    if (!rm) {
      return 'medium'
    }
    switch (fontSize) {
      case 'small':
        return ResourceUtils.getString(rm, 'font_size_small')
      case 'large':
        return ResourceUtils.getString(rm, 'font_size_large')
      case 'medium':
      default:
        return ResourceUtils.getString(rm, 'font_size_medium')
    }
  }

  // 字体大小格式转换：显示格式转存储格式（按当前语言资源值反向匹配；更新计划一期）
  static displayToFontSize(display: string, rm: resourceManager.ResourceManager | null): string {
    if (!rm) {
      return 'medium'
    }
    if (display === ResourceUtils.getString(rm, 'font_size_small')) {
      return 'small'
    }
    if (display === ResourceUtils.getString(rm, 'font_size_large')) {
      return 'large'
    }
    return 'medium'
  }

  // 性别转换：存储格式转显示格式
  static convertGenderToDisplay(gender: string, rm: resourceManager.ResourceManager | null): string {    if (!rm) {
      return ''
    }
    switch (gender) {
      case 'male':
        return ResourceUtils.getString(rm, 'male')
      case 'female':
        return ResourceUtils.getString(rm, 'female')
      case 'other':
        return ResourceUtils.getString(rm, 'gender_other')
      default:
        return ResourceUtils.getString(rm, 'male')
    }
  }

  // 性别转换：显示格式转存储格式（按当前语言资源值反向匹配）
  static convertGenderToStorage(gender: string, rm: resourceManager.ResourceManager | null): string {
    if (!rm) {
      return ''
    }
    if (gender === ResourceUtils.getString(rm, 'male')) {
      return 'male'
    }
    if (gender === ResourceUtils.getString(rm, 'female')) {
      return 'female'
    }
    if (gender === ResourceUtils.getString(rm, 'gender_other')) {
      return 'other'
    }
    return ''
  }

  // 安全显示 Toast 提示
  static showToastSafely(promptAction: PromptAction, message: ResourceStr, duration: number = 2000) {
    try {
      promptAction.showToast({
        message: message,
        duration: duration
      })
    } catch (error) {
      Logger.error('显示 Toast 失败: ' + JSON.stringify(error))
    }
  }
}
