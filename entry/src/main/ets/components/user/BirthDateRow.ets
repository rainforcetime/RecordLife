// 出生日期选择组件
import { ConfigManager } from '../../config/ConfigManager';
import { ResourceUtils } from '../../common/utils/ResourceUtils'
import { TimeUtils } from '../../common/utils/TimeUtils';
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig';
import { common } from '@kit.AbilityKit';

@Component
export struct BirthDateRow {
  @Link birthDate: Date;
  @State showDatePicker: boolean = false;
  
  // 主题颜色配置
  @Prop themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  private configManager: ConfigManager | null = null;

  aboutToAppear() {
    ConfigManager.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext).then(manager => {
      this.configManager = manager;
    });
  }

  // 格式化日期显示（使用UTC+8时区，国际化）
  private formatDate(date: Date): string {
    const rm = this.getUIContext().getHostContext()?.resourceManager
    if (!rm) {
      return '';
    }
    return ResourceUtils.getString(rm, 'date_ymd_full', TimeUtils.getFullYear(date), TimeUtils.getMonth(date) + 1, TimeUtils.getDate(date));
  }

  build() {
    Row() {
      Text($r('app.string.birth_date_label'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.textPrimary)

      Blank()

      // 日期显示
      Text(this.formatDate(this.birthDate))
        .fontSize(15)
        .fontColor(this.themeColors.error)
        .margin({ right: 12 })

      // 编辑按钮
      Button({ type: ButtonType.Circle }) {
        Text('✏️')
          .fontSize(16)
      }
      .width(36)
      .height(36)
      .backgroundColor(this.themeColors.background)
      .onClick(() => {
        this.showDatePicker = true;
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 2
    })
    .bindSheet($$this.showDatePicker, this.DatePickerSheet(), {
      height: 400,
      backgroundColor: this.themeColors.cardBackground,
      dragBar: true
    })
  }

  // 日期选择器弹窗
  @Builder
  DatePickerSheet() {
    Column() {
      Text($r('app.string.select_birth_date'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ top: 20, bottom: 20 })

      DatePicker({
        selected: this.birthDate
      })
        .lunar(false)
        .onDateChange((value: Date) => {
          this.birthDate = value;
          
          // 保存到配置（使用UTC+8时区）
          if (this.configManager) {
            const dateStr = TimeUtils.formatDate(value);
            this.configManager.setBirthDate(dateStr);
          }
        })

      Button($r('app.string.confirm'))
        .width('80%')
        .height(44)
        .backgroundColor(this.themeColors.error)
        .fontColor(Color.White)
        .margin({ top: 20 })
        .onClick(() => {
          this.showDatePicker = false;
        })
    }
    .width('100%')
    .padding(16)
  }
}
