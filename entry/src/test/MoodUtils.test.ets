// 心情工具纯函数单元测试（更新计划二期：心情标记）
import { describe, it, expect } from '@ohos/hypium';
import { MoodUtils } from '../main/ets/common/utils/MoodUtils';

export default function moodUtilsTest() {
  describe('getMoodEmoji', () => {
    it('happy → 微笑', 0, () => {
      expect(MoodUtils.getMoodEmoji('happy')).assertEqual('😊');
    });

    it('calm → 平静', 0, () => {
      expect(MoodUtils.getMoodEmoji('calm')).assertEqual('😌');
    });

    it('excited → 兴奋', 0, () => {
      expect(MoodUtils.getMoodEmoji('excited')).assertEqual('🤩');
    });

    it('sad → 难过', 0, () => {
      expect(MoodUtils.getMoodEmoji('sad')).assertEqual('😢');
    });

    it('tired → 疲惫', 0, () => {
      expect(MoodUtils.getMoodEmoji('tired')).assertEqual('😴');
    });

    it('未知心情返回空串', 0, () => {
      expect(MoodUtils.getMoodEmoji('angry')).assertEqual('');
      expect(MoodUtils.getMoodEmoji('')).assertEqual('');
    });
  });

  describe('isValidMood', () => {
    it('合法心情返回 true', 0, () => {
      for (const mood of MoodUtils.MOODS) {
        expect(MoodUtils.isValidMood(mood)).assertTrue();
      }
    });

    it('非法心情返回 false', 0, () => {
      expect(MoodUtils.isValidMood('angry')).assertFalse();
      expect(MoodUtils.isValidMood('')).assertFalse();
    });
  });
}
