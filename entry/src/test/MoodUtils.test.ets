// 心情工具纯函数单元测试（更新计划二期：心情标记 + 自定义心情）
import { describe, it, expect } from '@ohos/hypium';
import { MoodUtils } from '../main/ets/common/utils/MoodUtils';
import { Mood } from '../main/ets/model/RecordModel';

export default function moodUtilsTest() {
  describe('getMoodEmoji', () => {
    it('预置 happy → 微笑', 0, () => {
      expect(MoodUtils.getMoodEmoji('happy')).assertEqual('😊');
    });

    it('预置 calm → 平静', 0, () => {
      expect(MoodUtils.getMoodEmoji('calm')).assertEqual('😌');
    });

    it('预置 excited → 兴奋', 0, () => {
      expect(MoodUtils.getMoodEmoji('excited')).assertEqual('🤩');
    });

    it('预置 sad → 难过', 0, () => {
      expect(MoodUtils.getMoodEmoji('sad')).assertEqual('😢');
    });

    it('预置 tired → 疲惫', 0, () => {
      expect(MoodUtils.getMoodEmoji('tired')).assertEqual('😴');
    });

    it('未知心情返回空串', 0, () => {
      expect(MoodUtils.getMoodEmoji('angry')).assertEqual('');
      expect(MoodUtils.getMoodEmoji('')).assertEqual('');
    });

    it('自定义心情可查到 emoji', 0, () => {
      const custom: Mood[] = [{ id: 'mood_abc', emoji: '🥳' }];
      expect(MoodUtils.getMoodEmoji('mood_abc', custom)).assertEqual('🥳');
    });

    it('自定义心情缺失返回空串', 0, () => {
      const custom: Mood[] = [{ id: 'mood_abc', emoji: '🥳' }];
      expect(MoodUtils.getMoodEmoji('mood_xyz', custom)).assertEqual('');
    });

    it('预置优先于同名自定义', 0, () => {
      const custom: Mood[] = [{ id: 'happy', emoji: '🥳' }];
      expect(MoodUtils.getMoodEmoji('happy', custom)).assertEqual('😊');
    });
  });

  describe('isValidMood', () => {
    it('预置合法心情返回 true', 0, () => {
      for (const mood of MoodUtils.MOODS) {
        expect(MoodUtils.isValidMood(mood)).assertTrue();
      }
    });

    it('自定义心情返回 true', 0, () => {
      const custom: Mood[] = [{ id: 'mood_abc', emoji: '🥳' }];
      expect(MoodUtils.isValidMood('mood_abc', custom)).assertTrue();
    });

    it('非法心情返回 false', 0, () => {
      expect(MoodUtils.isValidMood('angry')).assertFalse();
      expect(MoodUtils.isValidMood('')).assertFalse();
    });
  });

  describe('getAllMoods', () => {
    it('无自定义时仅预置 5 个', 0, () => {
      expect(MoodUtils.getAllMoods().length).assertEqual(5);
    });

    it('含自定义时预置 + 自定义', 0, () => {
      const custom: Mood[] = [{ id: 'mood_abc', emoji: '🥳' }, { id: 'mood_def', emoji: '😱' }];
      const all = MoodUtils.getAllMoods(custom);
      expect(all.length).assertEqual(7);
      expect(all[0].id).assertEqual('happy');
      expect(all[5].id).assertEqual('mood_abc');
      expect(all[6].id).assertEqual('mood_def');
    });
  });

  describe('PRESET_MOOD_EMOJIS', () => {
    it('候选 emoji 池非空且无重复', 0, () => {
      expect(MoodUtils.PRESET_MOOD_EMOJIS.length).assertLarger(10);
      expect(new Set(MoodUtils.PRESET_MOOD_EMOJIS).size).assertEqual(MoodUtils.PRESET_MOOD_EMOJIS.length);
    });
  });
}
