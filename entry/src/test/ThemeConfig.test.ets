import { describe, it, expect } from '@ohos/hypium'
import { ThemeConfig, DEFAULT_THEME_COLOR, LightTheme, DarkTheme } from '../main/ets/config/ThemeConfig'
import { ColorUtils } from '../main/ets/common/ColorUtils'

export default function themeConfigTest() {
  describe('ThemeConfig.getColors', () => {
    it('无主色时返回模式默认色板', 0, () => {
      expect(ThemeConfig.getColors(false).primary).assertEqual(LightTheme.primary);
      expect(ThemeConfig.getColors(true).primary).assertEqual(DarkTheme.primary);
    });

    it('浅色模式自定义主色生效', 0, () => {
      const colors = ThemeConfig.getColors(false, '#07C160');
      expect(colors.primary).assertEqual('#07C160');
    });

    it('深色模式自定义主色自动调亮20%', 0, () => {
      const colors = ThemeConfig.getColors(true, '#07C160');
      // 0x07 + (0xFF-0x07)*0.2 → round(56.6)=57=0x39; 0xC1+...→0xCD; 0x60+...→0x80
      expect(colors.primary).assertEqual('#39CD80');
    });

    it('无效主色回退模式默认', 0, () => {
      expect(ThemeConfig.getColors(false, 'red').primary).assertEqual(LightTheme.primary);
      expect(ThemeConfig.getColors(false, '#FFF').primary).assertEqual(LightTheme.primary);
    });
  });

  describe('ColorUtils 调色', () => {
    it('lighten 向白靠拢', 0, () => {
      // 0x00→round(127.5)=128=0x80; 0x7D→190=0xBE; 0xFF 不变
      expect(ColorUtils.lighten('#007DFF', 0.5)).assertEqual('#80BEFF');
    });

    it('darken 向黑靠拢', 0, () => {
      expect(ColorUtils.darken('#007DFF', 0.5)).assertEqual('#003F80');
    });

    it('越界钳制', 0, () => {
      expect(ColorUtils.lighten('#FFFFFF', 0.5)).assertEqual('#FFFFFF');
      expect(ColorUtils.darken('#000000', 0.5)).assertEqual('#000000');
    });
  });
}
