import localUnitTest from './LocalUnit.test';
import recordModelTest from './RecordModel.test';
import storageServiceTest from './StorageService.test';
import configModelTest from './ConfigModel.test';
import timeUtilsLifeTest from './TimeUtilsLife.test';

export default function testsuite() {
  localUnitTest();
  recordModelTest();
  storageServiceTest();
  configModelTest();
  timeUtilsLifeTest();
}
