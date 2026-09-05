import { hapTasks } from '@ohos/hvigor-ohos-plugin';

// 自定义插件：每次 hvigor 构建时把真实构建日期写入 BuildInfo.ets，
// 供应用「关于」页显示正确 build 日期（而非运行时取当天日期）。
// 通过 postDependencies 挂到 default@PreBuild 之前执行，确保 ArkTS 编译读到最新时间戳。
const writeBuildInfoPlugin = {
  pluginId: 'WriteBuildInfoPlugin',
  apply(node: any): void {
    node.registerTask({
      name: 'WriteBuildInfo',
      postDependencies: ['default@PreBuild'],
      run: (taskContext: any): void => {
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const fs = require('fs');
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const path = require('path');
        const now = new Date();
        const pad = (n: number): string => n.toString().padStart(2, '0');
        const buildDate =
          `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}`;
        const file = path.join(
          taskContext.modulePath, 'src', 'main', 'ets', 'config', 'BuildInfo.ets');
        const content =
          '// 自动生成：每次 hvigor 构建写入真实构建日期（YYYYMMDD），勿手改，勿提交构建产物\n' +
          `export const BUILD_DATE: string = '${buildDate}';\n`;
        fs.writeFileSync(file, content, 'utf8');
      }
    });
  }
};

export default {
  system: hapTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: [writeBuildInfoPlugin] /* Custom plugin to extend the functionality of Hvigor. */
}
