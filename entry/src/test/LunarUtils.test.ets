// 农历工具单元测试（更新计划五期：农历生日）
import { describe, it, expect } from '@ohos/hypium';
import { LunarUtils } from '../main/ets/common/utils/LunarUtils';
import { TimeUtils } from '../main/ets/common/utils/TimeUtils';

export default function lunarUtilsTest() {
  describe('solarToLunar', () => {
    it('2024 春节 = 正月初一', 0, () => {
      const l = LunarUtils.solarToLunar(TimeUtils.parseDate('2024-02-10'));
      expect(l.year).assertEqual(2024);
      expect(l.month).assertEqual(1);
      expect(l.day).assertEqual(1);
      expect(l.isLeapMonth).assertFalse();
    });

    it('2025 春节 = 正月初一', 0, () => {
      const l = LunarUtils.solarToLunar(TimeUtils.parseDate('2025-01-29'));
      expect(l.month).assertEqual(1);
      expect(l.day).assertEqual(1);
    });

    it('2023-03-22 = 闰二月初一', 0, () => {
      const l = LunarUtils.solarToLunar(TimeUtils.parseDate('2023-03-22'));
      expect(l.year).assertEqual(2023);
      expect(l.month).assertEqual(2);
      expect(l.day).assertEqual(1);
      expect(l.isLeapMonth).assertTrue();
    });

    it('1990-06-15 = 农历五月廿三', 0, () => {
      const l = LunarUtils.solarToLunar(TimeUtils.parseDate('1990-06-15'));
      expect(l.year).assertEqual(1990);
      expect(l.month).assertEqual(5);
      expect(l.day).assertEqual(23);
    });
  });

  describe('lunarToSolar', () => {
    it('正月初一 → 2024-02-10', 0, () => {
      const d = LunarUtils.lunarToSolar(2024, 1, 1, false);
      expect(TimeUtils.formatDate(d)).assertEqual('2024-02-10');
    });

    it('闰二月初二 → 2023-03-23', 0, () => {
      const d = LunarUtils.lunarToSolar(2023, 2, 2, true);
      expect(TimeUtils.formatDate(d)).assertEqual('2023-03-23');
    });

    it('无闰年闰月按普通月（2025 闰二月 → 二月初二）', 0, () => {
      const d = LunarUtils.lunarToSolar(2025, 2, 2, true);
      expect(TimeUtils.formatDate(d)).assertEqual('2025-03-01');
    });

    it('回转一致：1990-06-15 ↔ 农历五月廿三', 0, () => {
      const l = LunarUtils.solarToLunar(TimeUtils.parseDate('1990-06-15'));
      const d = LunarUtils.lunarToSolar(l.year, l.month, l.day, l.isLeapMonth);
      expect(TimeUtils.formatDate(d)).assertEqual('1990-06-15');
    });
  });

  describe('农历生日', () => {
    it('1990-06-15 出生（农历五月廿三）2025 年生日 = 2025-06-18', 0, () => {
      const d = LunarUtils.getLunarBirthdayInYear(TimeUtils.parseDate('1990-06-15'), 2025);
      expect(TimeUtils.formatDate(d)).assertEqual('2025-06-18');
    });

    it('下次农历生日：2025-06-15 距今 3 天（2025-06-18）', 0, () => {
      const d = LunarUtils.getNextLunarBirthday(TimeUtils.parseDate('1990-06-15'), TimeUtils.parseDate('2025-06-15'));
      expect(TimeUtils.formatDate(d)).assertEqual('2025-06-18');
    });

    it('农历生日当天返回当天', 0, () => {
      const d = LunarUtils.getNextLunarBirthday(TimeUtils.parseDate('1990-06-15'), TimeUtils.parseDate('2025-06-18'));
      expect(TimeUtils.formatDate(d)).assertEqual('2025-06-18');
    });
  });
}
