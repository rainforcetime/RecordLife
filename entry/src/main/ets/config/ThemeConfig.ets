/**
 * 主题颜色配置
 * 定义浅色模式和深色模式的颜色配置
 * 遵循 HarmonyOS 设计规范，易于维护和扩展
 */

import { ConfigurationConstant } from '@kit.AbilityKit'
import { ColorUtils } from '../common/ColorUtils'

// 默认主题主色（用户未自定义时，主题配色功能）
export const DEFAULT_THEME_COLOR: string = '#007DFF'

// 主题颜色接口
export interface ThemeColors {
  // 背景色
  background: string;           // 页面背景色
  cardBackground: string;       // 卡片背景色
  divider: string;              // 分隔线颜色
  
  // 文本色
  textPrimary: string;          // 主要文本色（标题、重要信息）
  textSecondary: string;        // 次要文本色（描述、辅助信息）
  textTertiary: string;         // 第三级文本色（提示、禁用状态）
  
  // 主题色
  primary: string;              // 主题色（按钮、强调元素）
  primaryLight: string;         // 主题色浅色版本
  primaryDark: string;          // 主题色深色版本
  
  // 功能色
  success: string;              // 成功色
  warning: string;              // 警告色
  error: string;                // 错误色
  info: string;                 // 信息色
  
  // 边框和阴影
  border: string;               // 边框颜色
  shadow: string;               // 阴影颜色
  
  // 特殊元素
  avatarBorder: string;         // 头像边框色
  iconColor: string;            // 图标颜色
  overlay: string;              // 遮罩层颜色
}

// 浅色模式配色方案
export const LightTheme: ThemeColors = {
  // 背景色
  background: '#F5F5F5',
  cardBackground: '#FFFFFF',
  divider: '#E5E5E5',
  
  // 文本色
  textPrimary: '#000000',
  textSecondary: '#666666',
  textTertiary: '#707070',   // 对比度达标：白底≈5.2:1、#F5F5F5≈4.7:1（≥4.5），仍弱于 textSecondary
  
  // 主题色
  primary: '#007DFF',
  primaryLight: '#4DA3FF',
  primaryDark: '#0057B8',
  
  // 功能色
  success: '#00C853',
  warning: '#FF9800',
  error: '#FF4444',
  info: '#2196F3',
  
  // 边框和阴影
  border: '#E0E0E0',
  shadow: 'rgba(0, 0, 0, 0.1)',
  
  // 特殊元素
  avatarBorder: '#E0E0E0',
  iconColor: '#666666',
  overlay: 'rgba(0, 0, 0, 0.4)'
}

// 深色模式配色方案
export const DarkTheme: ThemeColors = {
  // 背景色
  background: '#1A1A1A',
  cardBackground: '#2D2D2D',
  divider: '#3D3D3D',
  
  // 文本色
  textPrimary: '#FFFFFF',
  textSecondary: '#B3B3B3',
  textTertiary: '#9E9E9E',   // 对比度达标：cardBackground #2D2D2D≈5.1:1（≥4.5），仍弱于 textSecondary
  
  // 主题色
  primary: '#4DA3FF',
  primaryLight: '#80BFFF',
  primaryDark: '#007DFF',
  
  // 功能色
  success: '#26C6DA',      // 青色（深色模式更协调）
  warning: '#FFB74D',
  error: '#FF6B6B',
  info: '#64B5F6',
  
  // 边框和阴影
  border: '#4D4D4D',
  shadow: 'rgba(0, 0, 0, 0.3)',
  
  // 特殊元素
  avatarBorder: '#4D4D4D',
  iconColor: '#B3B3B3',
  overlay: 'rgba(0, 0, 0, 0.6)'
}

// 主题类型
export type ThemeMode = 'light' | 'dark' | 'auto'

// 主题配置类（提供便捷访问方法）
export class ThemeConfig {
  // 获取当前主题颜色（支持自定义主色，主题配色功能）
  // 深色模式下主色自动调亮 20% 保证对比度
  static getColors(isDark: boolean, primaryColor?: string): ThemeColors {
    const base = isDark ? DarkTheme : LightTheme
    if (!primaryColor || primaryColor.length !== 7) {
      return base
    }
    const effectivePrimary = isDark ? ColorUtils.lighten(primaryColor, 0.2) : primaryColor
    // ArkTS 不支持对象展开（arkts-no-spread），显式构造
    const colors: ThemeColors = {
      background: base.background,
      cardBackground: base.cardBackground,
      divider: base.divider,
      textPrimary: base.textPrimary,
      textSecondary: base.textSecondary,
      textTertiary: base.textTertiary,
      primary: effectivePrimary,
      primaryLight: ColorUtils.lighten(effectivePrimary, 0.25),
      primaryDark: ColorUtils.darken(effectivePrimary, 0.25),
      success: base.success,
      warning: base.warning,
      error: base.error,
      info: base.info,
      border: base.border,
      shadow: base.shadow,
      avatarBorder: base.avatarBorder,
      iconColor: base.iconColor,
      overlay: base.overlay
    }
    return colors
  }
  
  // 判断是否为深色模式
  static isDarkMode(theme: ThemeMode, systemColorMode?: ConfigurationConstant.ColorMode): boolean {
    if (theme === 'dark') {
      return true
    } else if (theme === 'light') {
      return false
    } else {
      // auto 模式：跟随系统
      // ConfigurationConstant.ColorMode: 0=NOT_SET, 1=LIGHT, 2=DARK
      return systemColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
    }
  }
  
}
