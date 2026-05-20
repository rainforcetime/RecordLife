// 出生日期设置组件
import { BirthDateRow } from './BirthDateRow';
import { TargetAgeRow } from './TargetAgeRow';

@Component
export struct BirthDateSelector {
  @Link birthDate: Date;
  @Link targetAge: number;

  build() {
    Column() {
      // 出生日期行
      BirthDateRow({ birthDate: $birthDate })
      
      // 目标年龄行
      TargetAgeRow({ targetAge: $targetAge })
    }
    .width('100%')
  }
}
