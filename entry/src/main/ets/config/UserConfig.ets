/**
 * 用户配置模型
 * 扩展性良好的配置结构，支持后续备份功能
 */

import { TimeUtils } from '../common/utils/TimeUtils';

// 云备份配置
export interface CloudBackupConfig {
  enabled: boolean;
  provider: string; // 'huawei' | 'custom'
  syncInterval: number;
}

// 用户基本信息
export interface UserProfile {
  name: string;
  birthDate: string;
  gender: string; // 'male' | 'female' | 'other' | ''
  avatar: string;
}

// 应用设置
export interface AppSettings {
  theme: string; // 'light' | 'dark' | 'auto'
  language: string; // 'zh-CN' | 'en-US'
  showTimeDetails: boolean;
  enableNotifications: boolean;
  timeFormat: string; // 'standard' | 'compact'
  // HomePage 模式设置
  isAccumulatedMode: boolean; // true: 累计模式, false: 非累计模式
  isRemainingMode: boolean; // true: 剩余模式, false: 已存活模式
}

// 备份配置
export interface BackupConfig {
  autoBackup: boolean;
  backupFrequency: number;
  lastBackupTime: string;
  backupPath: string;
  cloudBackup: CloudBackupConfig | null;
}

// 数据统计
export interface DataStatistics {
  usageDays: number;
  lastActiveTime: string;
  dataVersion: number;
}

// 元数据
export interface ConfigMetadata {
  createdAt: string;
  updatedAt: string;
  deviceId: string;
}

// 应用信息（运行时只读，由AppInfoManager管理）
export interface AppInfo {
  appName: string;
  appVersion: string;
  buildNumber: string;
  developer: string;
  website: string;
  description: string;
}

// 完整的用户配置（不再包含appInfo，由AppInfoManager单独管理）
export interface UserConfig {
  version: string;
  profile: UserProfile;
  settings: AppSettings;
  backup: BackupConfig;
  statistics: DataStatistics;
  metadata: ConfigMetadata;
}

// 默认配置工厂函数（异步版本）
export async function createDefaultConfig(): Promise<UserConfig> {
  const now = new Date().toISOString();
  
  const profile: UserProfile = {
    name: '',
    birthDate: '1990-01-01',
    gender: '',
    avatar: ''
  };
  
  const settings: AppSettings = {
    theme: 'light',
    language: 'zh-CN',
    showTimeDetails: true,
    enableNotifications: false,
    timeFormat: 'standard',
    isAccumulatedMode: true,  // 默认累计模式
    isRemainingMode: false    // 默认已存活模式
  };
  
  const backup: BackupConfig = {
    autoBackup: false,
    backupFrequency: 7,
    lastBackupTime: '',
    backupPath: '',
    cloudBackup: null
  };
  
  const statistics: DataStatistics = {
    usageDays: 0,
    lastActiveTime: now,
    dataVersion: 1
  };
  
  const metadata: ConfigMetadata = {
    createdAt: now,
    updatedAt: now,
    deviceId: ''
  };
  
  const config: UserConfig = {
    version: '1.0.0',
    profile: profile,
    settings: settings,
    backup: backup,
    statistics: statistics,
    metadata: metadata
  };
  
  return config;
}

// 默认配置工厂函数（同步版本，用于紧急情况）
export function createDefaultConfigSync(): UserConfig {
  const now = new Date().toISOString();
  
  const profile: UserProfile = {
    name: '',
    birthDate: '1990-01-01',
    gender: '',
    avatar: ''
  };
  
  const settings: AppSettings = {
    theme: 'light',
    language: 'zh-CN',
    showTimeDetails: true,
    enableNotifications: false,
    timeFormat: 'standard',
    isAccumulatedMode: true,  // 默认累计模式
    isRemainingMode: false    // 默认已存活模式
  };
  
  const backup: BackupConfig = {
    autoBackup: false,
    backupFrequency: 7,
    lastBackupTime: '',
    backupPath: '',
    cloudBackup: null
  };
  
  const statistics: DataStatistics = {
    usageDays: 0,
    lastActiveTime: now,
    dataVersion: 1
  };
  
  const metadata: ConfigMetadata = {
    createdAt: now,
    updatedAt: now,
    deviceId: ''
  };
  
  const config: UserConfig = {
    version: '1.0.0',
    profile: profile,
    settings: settings,
    backup: backup,
    statistics: statistics,
    metadata: metadata
  };
  
  return config;
}

// 配置验证函数
export function validateConfig(config: UserConfig): boolean {
  // 验证出生日期格式
  const birthDateRegex = /^\d{4}-\d{2}-\d{2}$/;
  if (!birthDateRegex.test(config.profile.birthDate)) {
    return false;
  }

  // 验证出生日期是否合理（使用UTC+8时区）
  const birthDate = TimeUtils.parseDate(config.profile.birthDate);
  const now = TimeUtils.now();
  if (birthDate.getTime() > now.getTime() || TimeUtils.getFullYear(birthDate) < 1900) {
    return false;
  }

  // 验证备份频率
  if (config.backup.backupFrequency < 1 || config.backup.backupFrequency > 365) {
    return false;
  }

  return true;
}
