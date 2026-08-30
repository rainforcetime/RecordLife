// 桌面卡片 FormExtensionAbility：提供「快速记录」卡片
import { FormExtensionAbility, formBindingData } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    // 卡片无动态数据，返回空绑定即可
    return formBindingData.createFormBindingData({});
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN, 'testTag', 'onRemoveForm, formId: %{public}s', formId);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', 'EntryFormAbility onDestroy');
  }
}
