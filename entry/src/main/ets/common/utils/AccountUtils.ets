// 账号页面工具类：common/utils/AccountUtils.ets
import { promptAction, PromptAction } from '@kit.ArkUI'

// 账号页面工具方法类
export class AccountUtils {
  // 主题格式转换：存储格式转显示格式
  static themeToDisplay(theme: string): string {
    switch (theme) {
      case 'light':
        return '浅色模式'
      case 'dark':
        return '深色模式'
      case 'auto':
      default:
        return '跟随系统'
    }
  }

  // 主题格式转换：显示格式转存储格式
  static displayToTheme(display: string): string {
    switch (display) {
      case '浅色模式':
        return 'light'
      case '深色模式':
        return 'dark'
      case '跟随系统':
      default:
        return 'auto'
    }
  }

  // 性别转换：存储格式转显示格式
  static convertGenderToDisplay(gender: string): string {
    switch (gender) {
      case 'male':
        return '男'
      case 'female':
        return '女'
      case 'other':
        return '其他'
      default:
        return '男'
    }
  }

  // 性别转换：显示格式转存储格式
  static convertGenderToStorage(gender: string): string {
    switch (gender) {
      case '男':
        return 'male'
      case '女':
        return 'female'
      case '其他':
        return 'other'
      default:
        return ''
    }
  }

  // 安全显示 Toast 提示
  static showToastSafely(promptAction: PromptAction, message: string, duration: number = 2000) {
    try {
      promptAction.showToast({
        message: message,
        duration: duration
      })
    } catch (error) {
      console.error('显示 Toast 失败: ' + JSON.stringify(error))
    }
  }
}
