// 占位文件：每次 hvigor 构建时由 entry/hvigorfile.ts 的 WriteBuildInfo 任务覆盖为真实构建日期。
// 仓库内保留此占位仅为保证未构建前可编译；构建产物的日期变化勿提交。
export const BUILD_DATE: string = '19700101';
