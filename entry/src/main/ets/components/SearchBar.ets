// 搜索栏组件：components/SearchBar.ets
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'

@Component
export struct SearchBar {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 双向绑定搜索关键词
  @Link searchText: string
  // 是否显示搜索框
  @Link isSearching: boolean
  
  // 占位符文本
  @Prop placeholder: string = '搜索记录...'
  
  build() {
    Row() {
      if (this.isSearching) {
        // 搜索模式：显示输入框
        Row() {
          // 搜索图标
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(18)
            .fontColor([this.themeColors.textSecondary])
            .margin({ left: 12, right: 8 })
          
          // 输入框
          TextInput({ text: $$this.searchText, placeholder: this.placeholder })
            .layoutWeight(1)
            .height(40)
            .backgroundColor('transparent')
            .placeholderColor(this.themeColors.textSecondary)
            .placeholderFont({ size: 14 })
            .fontColor(this.themeColors.textPrimary)
            .fontSize(14)
            .caretColor(this.themeColors.primary)
          
          // 清除按钮
          if (this.searchText.length > 0) {
            SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
              .fontSize(18)
              .fontColor([this.themeColors.textSecondary])
              .margin({ right: 8 })
              .onClick(() => {
                this.searchText = ''
              })
          }
          
          // 取消按钮
          Text('取消')
            .fontSize(14)
            .fontColor(this.themeColors.primary)
            .margin({ right: 12 })
            .onClick(() => {
              this.searchText = ''
              this.isSearching = false
            })
        }
        .width('100%')
        .height(44)
        .backgroundColor(this.themeColors.cardBackground)
        .borderRadius(22)
        .shadow({
          radius: 8,
          color: this.themeColors.shadow,
          offsetX: 0,
          offsetY: 2
        })
      } else {
        // 正常模式：显示搜索按钮
        Row() {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(20)
            .fontColor([this.themeColors.textSecondary])
          
          Text(this.placeholder)
            .fontSize(14)
            .fontColor(this.themeColors.textSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(44)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.themeColors.cardBackground)
        .borderRadius(22)
        .onClick(() => {
          this.isSearching = true
        })
      }
    }
    .width('100%')
  }
}
