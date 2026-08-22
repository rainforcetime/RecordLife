// buildTimelineData 单元测试（P6 可测试性提升）
import { describe, it, expect } from '@ohos/hypium';
import { buildTimelineData, LifeRecord } from '../main/ets/model/RecordModel';
import { TimeUtils } from '../main/ets/common/utils/TimeUtils';

export default function recordModelTest() {
  describe('buildTimelineData', () => {
    it('空记录返回空时间线', 0, () => {
      const result = buildTimelineData([], TimeUtils.parseDate('2026-06-15'));
      expect(result.years.length).assertEqual(0);
    });

    it('按年/月/日分组且降序排列', 0, () => {
      const records: LifeRecord[] = [
        { id: 'r1', timestamp: TimeUtils.parseDate('2026-03-10').getTime(), content: 'a' },
        { id: 'r2', timestamp: TimeUtils.parseDate('2026-01-05').getTime(), content: 'b' },
        { id: 'r3', timestamp: TimeUtils.parseDate('2025-07-20').getTime(), content: 'c' },
        { id: 'r4', timestamp: TimeUtils.parseDate('2025-07-15').getTime(), content: 'd' }
      ];
      const result = buildTimelineData(records, TimeUtils.parseDate('2026-06-15'));

      // 年份降序
      expect(result.years.length).assertEqual(2);
      expect(result.years[0].year).assertEqual(2026);
      expect(result.years[1].year).assertEqual(2025);

      // 2026 年月份降序
      const year2026 = result.years[0];
      expect(year2026.months.length).assertEqual(2);
      expect(year2026.months[0].month).assertEqual(3);
      expect(year2026.months[1].month).assertEqual(1);

      // 2025 年 7 月日降序
      const year2025 = result.years[1];
      expect(year2025.months.length).assertEqual(1);
      expect(year2025.months[0].month).assertEqual(7);
      expect(year2025.months[0].days.length).assertEqual(2);
      expect(year2025.months[0].days[0].day).assertEqual(20);
      expect(year2025.months[0].days[1].day).assertEqual(15);
    });

    it('同一天多条记录归入同一日', 0, () => {
      const ts = TimeUtils.parseDate('2026-03-10').getTime();
      const records: LifeRecord[] = [
        { id: 'a', timestamp: ts, content: 'a' },
        { id: 'b', timestamp: ts, content: 'b' },
        { id: 'c', timestamp: ts, content: 'c' }
      ];
      const result = buildTimelineData(records, TimeUtils.parseDate('2026-06-15'));
      expect(result.years.length).assertEqual(1);
      expect(result.years[0].months[0].days[0].records.length).assertEqual(3);
    });

    it('当前年份与当前月份默认展开，其余折叠', 0, () => {
      const records: LifeRecord[] = [
        { id: 'a', timestamp: TimeUtils.parseDate('2026-03-10').getTime(), content: 'a' },
        { id: 'b', timestamp: TimeUtils.parseDate('2025-07-20').getTime(), content: 'b' }
      ];
      const result = buildTimelineData(records, TimeUtils.parseDate('2026-03-15'));

      // 当前年展开
      expect(result.years[0].year).assertEqual(2026);
      expect(result.years[0].isExpanded).assertTrue();
      // 当前月展开
      expect(result.years[0].months[0].month).assertEqual(3);
      expect(result.years[0].months[0].isExpanded).assertTrue();
      // 非当前年不展开
      expect(result.years[1].isExpanded).assertFalse();
    });
  });
}
