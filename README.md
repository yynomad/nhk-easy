# 日语听力 · Flutter Android

项目路径：`/Users/yao/personal/nhk-easy`。

`/Users/yao/personal/AI-news` 是独立的 Python AI 资讯 / Telegram 项目，与此 App 无关。

## 在 Android Studio 中打开

1. 安装 Android Studio 的 Flutter 插件（它会带上 Dart 插件）。
2. 选择 Open，打开本目录；不要只打开 android/ 子目录。
3. 若询问 Flutter SDK，选择 `/Users/yao/develop/flutter`。
4. 在 Device Manager 启动已有的 `EasyListening_API_36` 模拟器。
5. 选择模拟器并运行 `lib/main.dart`。

也可以在终端执行：

```sh
cd /Users/yao/personal/nhk-easy
flutter pub get
flutter emulators --launch EasyListening_API_36
flutter run
```

需要的安卓 SDK 许可请由本人阅读并接受：`flutter doctor --android-licenses`。

## 当前功能

- 蓝色新闻列表、标题和正文振假名开关、文章阅读。
- 隐藏正文的听力模式。
- 播放 / 暂停、进度拖动、后退10秒、0.75 / 1 / 1.25 / 1.5 倍速、单篇循环。
- 收藏文章和保存假名偏好；历史收藏保存完整元数据。
- 切换到后台时暂停播放，离开文章页释放播放器。
- 网络、来源使用确认页、正文缺失、音频缺失等状态。

## 演示与 NHK

默认打开“演示例文”。三篇例文为自编练习，插画为本地绘制；WAV 是使用 macOS Kyoko 生成的合成测试音，每段开头均说明不是 NHK 新闻。演示模式仅用于验证界面和音频操作，不代表 NHK 内容已接入。

“NHK 新闻”尝试读取用户指定的 https://news.web.nhk/news/easy/ 。2026-10-16 实际访问返回 NHK ONE 使用确认页，而非新闻列表。App 会明确提示此状态，保留官网入口；不会绕过确认页，也不会自动把例文冒充真实新闻。

旧页面的 HTML 解析器和音频链接提取已恢复，但当前站点授权流程、真实新闻标题 / 图片 / 正文 / 音频仍需后续适配与验收。当前 App 可用于离线演示，尚不能作为已完成 NHK 实时接入的生产版本。

## 验证与构建

2026-10-16：`flutter analyze` 无问题，13 项测试通过；ARM64 debug APK 构建通过，并已在 Android API36 模拟器上安装和启动。设备测试验证了文章打开、真实合成音频播放 / 进度 / 暂停、隐藏正文、返回列表，未发现崩溃。

设备测试脚本：`python3 tool/smoke_android.py`（需先启动模拟器，默认序列号 emulator-5554）。实际运行截图保存在 `docs/screenshots/`。

```sh
flutter analyze
flutter test
flutter build apk --debug
```

本次已成功构建的 ARM64 测试包位于 `build/app/outputs/flutter-apk/app-debug.apk`。

测试覆盖 URL 来源校验、清理 HTML 并保留 ruby、列表去重、使用确认页、音频缺失、缓存、重定向、收藏持久化、切换来源时的异步竞争、阅读交互、320px 布局及所有演示 WAV 的完整性。

SDK / Gradle 构建文件由本机 Flutter 3.47.7 生成；依赖版本保存在 pubspec.lock 中。默认最低 Android 7.0（API24），compile/target SDK 36。

## 恢复记录

旧聊天中最初写入 Documents/ChatGPT 的源码目录已不存在，常用目录也未找到该 Flutter 工程。本工程于 2026-10-16 根据聊天中的功能、源码设计与保留的界面 Demo 重新恢复，后续使用 Git 跟踪。

## 本机网络说明

首次构建曾因 Maven 依赖 TLS 握手失败以及 NDK 下载中断而失败，已通过本机代理与校验后补装 NDK 完成。没有关闭 TLS 证书校验。

如果后续终端构建再次发生同类问题，确认本机 HTTP 代理 127.0.0.1:7890 正常运行后，可以只对这次命令设置代理：

```sh
JAVA_TOOL_OPTIONS='-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=7890 -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=7890 -Dorg.gradle.workers.max=2 -Dhttp.keepAlive=false' flutter run
```

这组代理参数只适用于当前机器，不应直接用于其他人的环境。
