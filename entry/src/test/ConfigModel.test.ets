// 配置校验与时间工具单元测试（P6 可测试性提升）
import { describe, it, expect } from '@ohos/hypium';
import { createDefaultConfigSync, validateConfig } from '../main/ets/model/UserConfigModel';
import { TimeUtils } from '../main/ets/common/utils/TimeUtils';

export default function configModelTest() {
  describe('validateConfig', () => {
    it('默认配置有效', 0, () => {
      const config = createDefaultConfigSync();
      expect(validateConfig(config)).assertTrue();
    });

    it('出生日期格式错误无效', 0, () => {
      const config = createDefaultConfigSync();
      config.profile.birthDate = '2026/06/15';
      expect(validateConfig(config)).assertFalse();
    });

    it('未来出生日期无效', 0, () => {
      const config = createDefaultConfigSync();
      config.profile.birthDate = '2999-01-01';
      expect(validateConfig(config)).assertFalse();
    });

    it('年份早于 1900 无效', 0, () => {
      const config = createDefaultConfigSync();
      config.profile.birthDate = '1800-01-01';
      expect(validateConfig(config)).assertFalse();
    });

    it('备份频率越界无效', 0, () => {
      const config = createDefaultConfigSync();
      config.backup.backupFrequency = 0;
      expect(validateConfig(config)).assertFalse();
      config.backup.backupFrequency = 366;
      expect(validateConfig(config)).assertFalse();
    });

    it('合法自定义配置有效', 0, () => {
      const config = createDefaultConfigSync();
      config.profile.birthDate = '1990-06-15';
      config.backup.backupFrequency = 30;
      expect(validateConfig(config)).assertTrue();
    });
  });

  describe('TimeUtils（UTC+8）', () => {
    it('formatDate / parseDate 往返一致', 0, () => {
      expect(TimeUtils.formatDate(TimeUtils.parseDate('2026-06-15'))).assertEqual('2026-06-15');
    });

    it('parseDate 分量正确', 0, () => {
      const d = TimeUtils.parseDate('2026-06-15');
      expect(TimeUtils.getFullYear(d)).assertEqual(2026);
      expect(TimeUtils.getMonth(d)).assertEqual(5);
      expect(TimeUtils.getDate(d)).assertEqual(15);
    });
  });
}
