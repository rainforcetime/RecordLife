// 统计纯函数单元测试（更新计划五期：数据看板 / 生命进度）
import { describe, it, expect } from '@ohos/hypium';
import { StatisticsUtils } from '../main/ets/model/StatisticsModel';
import { LifeRecord } from '../main/ets/model/RecordModel';
import { TimeUtils } from '../main/ets/common/utils/TimeUtils';

function record(day: number, content: string = '内容'): LifeRecord {
  return { id: 'r' + day, timestamp: TimeUtils.parseDate('2025-01-' + day).getTime(), content: content };
}

export default function statisticsTest() {
  describe('calculateStatistics', () => {
    it('空记录全为 0', 0, () => {
      const s = StatisticsUtils.calculateStatistics([]);
      expect(s.totalRecords).assertEqual(0);
      expect(s.activeDays).assertEqual(0);
      expect(s.longestStreak).assertEqual(0);
      expect(s.totalCharacters).assertEqual(0);
      expect(s.firstRecordDate).assertEqual('');
    });

    it('多天多条统计正确', 0, () => {
      const records: LifeRecord[] = [
        record(1, '一二三'),
        record(1, '四五六七八九'),
        record(2, '十'),
        record(5, '十一十二')
      ];
      const s = StatisticsUtils.calculateStatistics(records);
      expect(s.totalRecords).assertEqual(4);
      expect(s.activeDays).assertEqual(3);
      expect(s.averagePerDay).assertEqual(1.3);  // 4/3=1.333 → 1.3
      expect(s.totalCharacters).assertEqual(3 + 6 + 1 + 4);
      expect(s.firstRecordDate).assertEqual('2025-01-01');
      expect(s.lastRecordDate).assertEqual('2025-01-05');
    });
  });

  describe('getLongestStreak', () => {
    it('空记录返回 0', 0, () => {
      expect(StatisticsUtils.getLongestStreak([])).assertEqual(0);
    });

    it('连续 3 天', 0, () => {
      const records: LifeRecord[] = [record(1), record(2), record(3), record(10)];
      expect(StatisticsUtils.getLongestStreak(records)).assertEqual(3);
    });

    it('跨月连续', 0, () => {
      const records: LifeRecord[] = [
        { id: 'a', timestamp: TimeUtils.parseDate('2025-01-31').getTime(), content: '' },
        { id: 'b', timestamp: TimeUtils.parseDate('2025-02-01').getTime(), content: '' },
        { id: 'c', timestamp: TimeUtils.parseDate('2025-02-02').getTime(), content: '' }
      ];
      expect(StatisticsUtils.getLongestStreak(records)).assertEqual(3);
    });

    it('同一天多条不重复计数', 0, () => {
      const records: LifeRecord[] = [record(1), record(1), record(2)];
      expect(StatisticsUtils.getLongestStreak(records)).assertEqual(2);
    });
  });

  describe('getLifeProgress', () => {
    it('出生当天进度极小', 0, () => {
      const birth = TimeUtils.parseDate('2025-01-01');
      const p = StatisticsUtils.getLifeProgress(birth, 80, TimeUtils.parseDate('2025-01-01'));
      expect(p.livedDays).assertEqual(1);
      expect(p.totalDays).assertEqual(80 * 365);
      expect(p.percent).assertEqual(0);
    });

    it('1 岁（366 天）进度 = 1/80', 0, () => {
      const birth = TimeUtils.parseDate('2024-01-01');
      const p = StatisticsUtils.getLifeProgress(birth, 80, TimeUtils.parseDate('2025-01-01'));
      expect(p.livedDays).assertEqual(367);  // 2024 闰年 366 天 + 出生日当天
      expect(p.percent).assertEqual(1.3);    // 367/(80*365)=0.01257 → 1.3
    });

    it('targetAge 非法回退 80', 0, () => {
      const birth = TimeUtils.parseDate('2024-01-01');
      const p = StatisticsUtils.getLifeProgress(birth, 0, TimeUtils.parseDate('2025-01-01'));
      expect(p.totalDays).assertEqual(80 * 365);
    });
  });

  describe('getLifeMilestones', () => {
    it('已达成与未来里程碑正确（农历年龄里程碑）', 0, () => {
      const birth = TimeUtils.parseDate('1990-06-15');
      const ms = StatisticsUtils.getLifeMilestones(birth, 80, TimeUtils.parseDate('2025-06-15'));
      expect(ms.length).assertEqual(11);
      // 升序：第 1000 天最早，目标年龄最后（农历版实际日期）
      expect(ms[0].type).assertEqual('days_1000');
      expect(ms[0].reached).assertTrue();
      expect(ms[0].date).assertEqual('1993-03-11');
      expect(ms[10].type).assertEqual('target');
      expect(ms[10].reached).assertFalse();
      expect(ms[10].date).assertEqual('2070-05-26');
      // 18 岁农历生日（1990 农历五月廿三 → 2008 年同日）
      expect(ms[1].type).assertEqual('age_18');
      expect(ms[1].date).assertEqual('2008-06-10');
    });

    it('公历日历法：18 岁 = 2008-06-15（阳历生日）', 0, () => {
      const birth = TimeUtils.parseDate('1990-06-15');
      const ms = StatisticsUtils.getLifeMilestones(birth, 80, TimeUtils.parseDate('2025-06-15'), 'solar');
      const age18 = ms.find(m => m.type === 'age_18');
      expect(age18 !== undefined).assertTrue();
      expect(age18!.date).assertEqual('2008-06-15');
    });

    it('出生当天全部未达成', 0, () => {
      const birth = TimeUtils.parseDate('2025-01-01');
      const ms = StatisticsUtils.getLifeMilestones(birth, 80, TimeUtils.parseDate('2025-01-01'));
      for (const m of ms) {
        expect(m.reached).assertFalse();
        expect(m.daysLeft).assertEqual(m.daysFromBirth - 1);
      }
    });
  });

  describe('getLifeBreakdown', () => {
    it('同一天为 0 年 0 月 0 天', 0, () => {
      const b = StatisticsUtils.getLifeBreakdown(TimeUtils.parseDate('2025-01-01'), TimeUtils.parseDate('2025-01-01'));
      expect(b.years).assertEqual(0);
      expect(b.months).assertEqual(0);
      expect(b.days).assertEqual(0);
    });

    it('整年生日为整年', 0, () => {
      const b = StatisticsUtils.getLifeBreakdown(TimeUtils.parseDate('1990-06-15'), TimeUtils.parseDate('2025-06-15'));
      expect(b.years).assertEqual(35);
      expect(b.months).assertEqual(0);
      expect(b.days).assertEqual(0);
    });
  });
}
