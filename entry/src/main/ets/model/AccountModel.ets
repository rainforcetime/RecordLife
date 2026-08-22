// 账号页面 UI 模型（View DTO）
// 与 model/UserConfigModel.ets 中的持久化模型区分，避免命名冲突

// 账号页面用户信息（UI 层）
// 注意：birthday 对应持久化层的 birthDate，hasCustomAvatar 为 UI 派生字段
export interface AccountProfile {
  name: string;
  birthday: string;
  gender: string;
  avatar: string;
  hasCustomAvatar: boolean;
}

// 主题设置（UI 层）
export interface ThemeSettings {
  currentTheme: string;
}

// 账号页面数据统计（UI 层）
// 注意：dataVersion 为 string（持久化层为 number），storageSize 为 UI 派生字段
export interface AccountDataStatistics {
  usageDays: number;
  dataVersion: string;
  lastActiveTime: string;
  storageSize: string;
}

// 头像信息（内部使用）
export interface AvatarInfo {
  avatar: string;
  hasCustomAvatar: boolean;
}
