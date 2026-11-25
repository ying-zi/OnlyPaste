# OnlyPaste

OnlyPaste 是一个纯键盘剪贴板工具。键盘扩展会在打开时读取当前纯文本剪贴板，并保存到键盘自己的本地列表；点一条即可插入当前输入框。主 App 只提供启用说明，不保存数据。

## 键盘用法

1. 安装后前往“设置 → 通用 → 键盘 → 键盘 → 添加新键盘”，添加 OnlyPaste。
2. 点进 OnlyPaste，开启“允许完全访问”。
3. 在其他 App 复制文字，回到输入框并切换到 OnlyPaste。当前剪贴板会自动收录到列表。
4. 点列表中的记录即可上屏；向左滑动可删除。
5. 工具栏右侧的键盘按钮切换到下一个键盘，“换行”按钮插入换行符。

键盘不提供加号、分类、文件夹或库存池；所有记录在一个列表里，最多保留 200 条。升级时，旧版文件夹和库存池中仍存在的内容会合并迁移到该列表，列表为空时会显示操作提示。

## iOS 限制与隐私

- 读取系统剪贴板需要用户开启“允许完全访问”。
- iOS 不允许第三方键盘在后台读取或恢复系统的完整历史剪贴板。本应用只在键盘可用时收录当前剪贴板；安装前没有保存过的系统剪贴板内容无法找回。
- 目前仅收录纯文本，不支持把图片直接插入任意输入框。
- 数据只存储在键盘扩展自己的容器中，不联网、不使用 App Group。卸载应用会删除本地数据。

## 编译

需要 macOS 和 Xcode 26 或更高版本。打开 `OnlyPaste.xcodeproj`，选择 `OnlyPaste` scheme 和目标设备后构建。

默认 Bundle ID 为 `ltd.lone.OnlyPaste` 和 `ltd.lone.OnlyPaste.keyboard`。使用自己的开发团队时，可在两个 Target 的 Signing & Capabilities 中设置一对具有前缀关系的 Bundle ID。项目不需要 App Group。

## GitHub Actions

- `.github/workflows/build.yml`：在 push / pull request 时编译验证。
- `.github/workflows/release.yml`：推送 `v` 开头的 tag 后构建并发布未签名 IPA；安装前需要使用签名工具签名。

## 目录

```text
OnlyPaste/
├── OnlyPaste/                 主 App 空壳和启用引导
├── OnlyPaste/Shared/          数据模型与键盘本地存储
├── OnlyPasteKeyboard/         UIKit 键盘扩展
└── OnlyPaste.xcodeproj/
```
