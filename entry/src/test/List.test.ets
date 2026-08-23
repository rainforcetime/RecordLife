import localUnitTest from './LocalUnit.test';
import recordModelTest from './RecordModel.test';
import storageServiceTest from './StorageService.test';
import configModelTest from './ConfigModel.test';
import timeUtilsLifeTest from './TimeUtilsLife.test';
import moodUtilsTest from './MoodUtils.test';
import statisticsTest from './StatisticsModel.test';
import themeConfigTest from './ThemeConfig.test';

export default function testsuite() {
  localUnitTest();
  recordModelTest();
  storageServiceTest();
  configModelTest();
  timeUtilsLifeTest();
  moodUtilsTest();
  statisticsTest();
  themeConfigTest();
}
