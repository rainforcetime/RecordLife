/**
 * 颜色工具类
 * 用于处理颜色转换和透明度计算
 */

export class ColorUtils {
  /**
   * 将十六进制颜色转换为带透明度的颜色
   * @param hexColor 十六进制颜色，如 '#007DFF'
   * @param alpha 透明度，范围 0-255（如 20 表示约 8% 透明度）
   * @returns rgba 格式的颜色字符串
   */
  static withAlpha(hexColor: string, alpha: number): string {
    // 移除 # 前缀
    const hex = hexColor.replace('#', '')
    
    // 解析 RGB 值
    const r = parseInt(hex.substring(0, 2), 16)
    const g = parseInt(hex.substring(2, 4), 16)
    const b = parseInt(hex.substring(4, 6), 16)
    
    // 计算透明度（0-1）
    const a = alpha / 255
    
    return `rgba(${r}, ${g}, ${b}, ${a.toFixed(3)})`
  }
  
  /**
   * 获取主题色的浅色背景（约 12.5% 透明度）
   * 常用于按钮、徽章等元素的背景
   */
  static primaryLight(hexColor: string): string {
    return ColorUtils.withAlpha(hexColor, 32) // 32/255 ≈ 12.5%
  }
  
  /**
   * 获取主题色的极浅背景（约 8% 透明度）
   * 常用于按钮、徽章等元素的背景
   */
  static primaryExtraLight(hexColor: string): string {
    return ColorUtils.withAlpha(hexColor, 20) // 20/255 ≈ 8%
  }
  
  /**
   * 获取主题色的超浅背景（约 6% 透明度）
   * 常用于图标背景等
   */
  static primaryUltraLight(hexColor: string): string {
    return ColorUtils.withAlpha(hexColor, 15) // 15/255 ≈ 6%
  }

  /**
   * 调亮颜色（向白色靠拢）
   * @param hexColor 十六进制颜色，如 '#007DFF'
   * @param ratio 调亮比例 0-1（如 0.2 = 调亮 20%）
   * @returns 调亮后的 hex 颜色
   */
  static lighten(hexColor: string, ratio: number): string {
    return ColorUtils.adjustBrightness(hexColor, ratio)
  }

  /**
   * 调暗颜色（向黑色靠拢）
   * @param hexColor 十六进制颜色
   * @param ratio 调暗比例 0-1（如 0.2 = 调暗 20%）
   * @returns 调暗后的 hex 颜色
   */
  static darken(hexColor: string, ratio: number): string {
    return ColorUtils.adjustBrightness(hexColor, -ratio)
  }

  // 亮度调整实现（正 ratio 调亮、负 ratio 调暗）
  private static adjustBrightness(hexColor: string, ratio: number): string {
    const hex = hexColor.replace('#', '')
    const r = parseInt(hex.substring(0, 2), 16)
    const g = parseInt(hex.substring(2, 4), 16)
    const b = parseInt(hex.substring(4, 6), 16)

    const lr = ratio >= 0 ? Math.round(r + (255 - r) * ratio) : Math.round(r * (1 + ratio))
    const lg = ratio >= 0 ? Math.round(g + (255 - g) * ratio) : Math.round(g * (1 + ratio))
    const lb = ratio >= 0 ? Math.round(b + (255 - b) * ratio) : Math.round(b * (1 + ratio))

    const toHex = (v: number): string => {
      const clamped = v < 0 ? 0 : (v > 255 ? 255 : v)
      return clamped.toString(16).padStart(2, '0')
    }
    return '#' + toHex(lr) + toHex(lg) + toHex(lb)
  }
}
