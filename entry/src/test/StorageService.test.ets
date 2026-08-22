// StorageService 纯函数单元测试（P6 可测试性提升）
import { describe, it, expect } from '@ohos/hypium';
import { StorageService } from '../main/ets/service/StorageService';

export default function storageServiceTest() {
  describe('StorageService.formatStorageSize', () => {
    it('B 单位边界', 0, () => {
      expect(StorageService.formatStorageSize(0)).assertEqual('0B');
      expect(StorageService.formatStorageSize(1023)).assertEqual('1023B');
    });

    it('KB 单位换算', 0, () => {
      expect(StorageService.formatStorageSize(1024)).assertEqual('1.0KB');
      expect(StorageService.formatStorageSize(1536)).assertEqual('1.5KB');
    });

    it('MB 单位换算', 0, () => {
      expect(StorageService.formatStorageSize(1024 * 1024)).assertEqual('1.0MB');
      expect(StorageService.formatStorageSize(2.5 * 1024 * 1024)).assertEqual('2.5MB');
    });

    it('GB 单位换算', 0, () => {
      expect(StorageService.formatStorageSize(1024 * 1024 * 1024)).assertEqual('1.0GB');
    });
  });

  describe('StorageService.calcUsageDays', () => {
    it('当前时刻创建为 0 天', 0, () => {
      expect(StorageService.calcUsageDays(new Date().toISOString())).assertEqual(0);
    });

    it('很久以前创建天数大于 0', 0, () => {
      const days = StorageService.calcUsageDays('2000-01-01T00:00:00.000Z');
      expect(days).assertLarger(0);
    });

    it('未来时间返回 0', 0, () => {
      const future = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
      expect(StorageService.calcUsageDays(future)).assertEqual(0);
    });
  });
}
