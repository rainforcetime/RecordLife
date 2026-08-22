// 生命里程碑纯函数单元测试（更新计划一期：第几天 / 第几周 / 距下次生日）
import { describe, it, expect } from '@ohos/hypium';
import { TimeUtils } from '../main/ets/common/utils/TimeUtils';

export default function timeUtilsLifeTest() {
  describe('getDayOfLife', () => {
    it('出生当天为第1天', 0, () => {
      expect(TimeUtils.getDayOfLife(TimeUtils.parseDate('2025-01-01'), TimeUtils.parseDate('2025-01-01'))).assertEqual(1);
    });

    it('出生次日为第2天', 0, () => {
      expect(TimeUtils.getDayOfLife(TimeUtils.parseDate('2025-01-01'), TimeUtils.parseDate('2025-01-02'))).assertEqual(2);
    });

    it('平年最后一天为第365天', 0, () => {
      expect(TimeUtils.getDayOfLife(TimeUtils.parseDate('2025-01-01'), TimeUtils.parseDate('2025-12-31'))).assertEqual(365);
    });

    it('跨年累加', 0, () => {
      expect(TimeUtils.getDayOfLife(TimeUtils.parseDate('2024-12-31'), TimeUtils.parseDate('2025-01-01'))).assertEqual(2);
    });

    it('出生日期在未来返回0', 0, () => {
      expect(TimeUtils.getDayOfLife(TimeUtils.parseDate('2025-01-01'), TimeUtils.parseDate('2024-12-31'))).assertEqual(0);
    });
  });

  describe('getWeekOfLife', () => {
    it('第1天为第1周', 0, () => {
      expect(TimeUtils.getWeekOfLife(TimeUtils.parseDate('2025-01-01'), TimeUtils.parseDate('2025-01-01'))).assertEqual(1);
    });

    it('第7天仍为第1周', 0, () => {
      expect(TimeUtils.getWeekOfLife(TimeUtils.parseDate('2025-01-01'), TimeUtils.parseDate('2025-01-07'))).assertEqual(1);
    });

    it('第8天为第2周', 0, () => {
      expect(TimeUtils.getWeekOfLife(TimeUtils.parseDate('2025-01-01'), TimeUtils.parseDate('2025-01-08'))).assertEqual(2);
    });

    it('第365天（平年）为第53周', 0, () => {
      expect(TimeUtils.getWeekOfLife(TimeUtils.parseDate('2025-01-01'), TimeUtils.parseDate('2025-12-31'))).assertEqual(53);
    });

    it('出生日期在未来返回0', 0, () => {
      expect(TimeUtils.getWeekOfLife(TimeUtils.parseDate('2025-01-01'), TimeUtils.parseDate('2024-12-31'))).assertEqual(0);
    });
  });

  describe('getDaysUntilNextBirthday（农历生日）', () => {
    // 1990-06-15 出生 = 农历五月廿三；2025 农历生日 2025-06-18、2026 农历生日 2026-07-07（2026 有闰月）
    it('今天农历生日返回0', 0, () => {
      expect(TimeUtils.getDaysUntilNextBirthday(TimeUtils.parseDate('1990-06-15'), TimeUtils.parseDate('2025-06-18'))).assertEqual(0);
    });

    it('农历生日3天后（阳历生日 6/15 已过，农历 6/18 未到）', 0, () => {
      expect(TimeUtils.getDaysUntilNextBirthday(TimeUtils.parseDate('1990-06-15'), TimeUtils.parseDate('2025-06-15'))).assertEqual(3);
    });

    it('农历生日13天后', 0, () => {
      expect(TimeUtils.getDaysUntilNextBirthday(TimeUtils.parseDate('1990-06-15'), TimeUtils.parseDate('2025-06-05'))).assertEqual(13);
    });

    it('明天农历生日返回1', 0, () => {
      expect(TimeUtils.getDaysUntilNextBirthday(TimeUtils.parseDate('1990-06-15'), TimeUtils.parseDate('2025-06-17'))).assertEqual(1);
    });

    it('跨年：2025-12-31 距 2026 农历生日（07-07）158 天', 0, () => {
      expect(TimeUtils.getDaysUntilNextBirthday(TimeUtils.parseDate('1990-06-15'), TimeUtils.parseDate('2025-12-31'))).assertEqual(158);
    });
  });
}
