// 出生日期设置组件
import { BirthDateRow } from './BirthDateRow';
import { TargetAgeRow } from './TargetAgeRow';
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig';

@Component
export struct BirthDateSelector {
  @Link birthDate: Date;
  @Link targetAge: number;
  
  // 主题颜色配置
  @Prop themeColors: ThemeColors = ThemeConfig.getColors(false)

  build() {
    Column() {
      // 出生日期行
      BirthDateRow({ birthDate: $birthDate, themeColors: this.themeColors })
      
      // 目标年龄行
      TargetAgeRow({ targetAge: $targetAge, themeColors: this.themeColors })
    }
    .width('100%')
  }
}
