<div align="center">

<img src="assets/logo.png" width="128" height="128" alt="AnimeRecord Logo" style="border-radius: 28px;" />

# 看番记录 (AnimeRecord)

**优雅、轻量、本地优先的跨平台个人追番记录客户端**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-brightgreen.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 项目简�?
**看番记录 (AnimeRecord)** 是一款专为追番爱好者打造的高颜值、无广告、纯净的跨平台个人追番记录客户端�?
应用基于 **Flutter 3** �?**Dart 3** 开发，采用 **Local-First (本地优先)** 架构。用户数据默认全量保存在本地设备中，同时支持通过 **GitHub Secret Gist** 实现安全便捷的跨端双向加密同步，无需依赖任何第三方中心化服务器或外部账号体系�?
本项目完整复刻并增强�?Web 经典版追番记录器的全部功能与交互，并针对移动端及触控设备进行了全方位的交互体验优化�?
---

## 功能特�?
### 追番维度全面管理
- **5 种追番状�?*：想�?(`want_to_watch`)、在�?(`watching`)、已�?(`watched`)、搁�?(`on_hold`)、抛�?(`dropped`)，具备专属视觉状态标识�?- **周日程追�?*：支持周一至周日按星期几快速筛选当日更新番剧�?- **放送与评分**：支持记录“连载中 / 已完结”�? �?10 分个人评分、总集数、观看进度与最后更新日期�?- **自定义备注与标签**：随时随地记录观后感、吐槽或自定义分类标签�?
### 便捷交互与智能流�?- **一键快捷追�?*：卡片右侧快捷按键直接递增当前集数进度，无需进入详情编辑弹窗�?- **智能状态流�?*：当在看进度达到全集时，系统自动提示流转为“已看”状态�?- **实时统计看板**：顶部聚合显示番剧总数、在看数、已看数、想看数以及总体追番完成率�?- **灵活排序与拖拽重�?*：支持按最后更新时间、评分、进度降序排列；在默认排序模式下支持长按拖拽卡片自由调整追番优先级�?- **即时检�?*：支持番剧名称与备注关键字即时过滤，支持一键清空搜索词�?
### GitHub Secret Gist 双向云同�?- **零服务端依赖**：仅需个人 GitHub Token，自动创建和管理私有加密 Gist 文件�?- **分布式冲突消�?*：采用基于更新时间戳的三方合并策略，多设备间无缝同步最新变动�?- **墓碑机制 (Tombstone Tracking)**：持久化记录已删除条�?ID，避免无服务端架构下“已删除数据被另一台设备重新复活”的问题�?- **防悬崖跌落保�?*：智能感知远端空数据或异常大范围删除，防止误删或意外覆盖本地已有数据�?
### 本地数据安全备份
- **一键导�?JSON**：随时导出标准格式的追番数据备份文件�?- **灵活导入恢复**：支持“智能合并去重”与“完全覆盖导入”双模式，内置标准导入模板下载�?
### 视觉与主题设�?- **日系蔷薇配色**：以日系蔷薇粉（`#EC5F7A`）为主色调，状态色彩鲜明和谐�?- **深浅主题适配**：内置经过细腻对比度调校的浅�?(Light) 与深�?(Dark) 主题，支持一键切换并持久化保存�?
---

## 下载与安�?
### 方式一：直接下载安装包
前往 [Releases 页面](../../releases) 下载最新的 Android 正式版安装包（`app-release.apk`）直接安装即可�?
### 方式二：从源码编译构�?如需自行编译或在 Windows 桌面端运行，请参考下方步骤�?
---

## 源码编译与运�?
### 环境要求
- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.3.0
- Dart SDK >= 3.3.0
- Android Studio / Android SDK (构建 Android �?
- Visual Studio C++ 工具�?(构建 Windows 桌面�?

### 编译步骤

1. **克隆本仓�?*
   ```bash
   git clone https://github.com/aclguh/AnimeRecord.git
   cd AnimeRecord
   ```

2. **拉取依赖**
   ```bash
   flutter pub get
   ```

3. **运行代码检查与测试**
   ```bash
   flutter analyze
   flutter test
   ```

4. **调试运行**
   ```bash
   # 连接手机或启动模拟器后执�?   flutter run
   ```

5. **构建正式发布�?(Release)**
   ```bash
   # 构建 Android APK
   flutter build apk --release
   # 输出文件位于：build/app/outputs/flutter-apk/app-release.apk

   # 构建 Windows 桌面�?   flutter build windows --release
   ```

---

## GitHub Gist 云同步配置指�?
为实现手机与电脑等多端追番数据无缝同步，可按如下步骤配置 GitHub Gist�?
1. **获取 GitHub Personal Access Token**�?   - 访问 GitHub -> **Settings** -> **Developer Settings** -> **Personal Access Tokens** -> **Tokens (classic)**�?   - 点击 **Generate new token (classic)**�?   - Note 填写 `AnimeRecord`，在权限勾选列表中**仅需勾�?`gist`** 权限�?   - 点击底部生成，复制生成的 Token（形�?`ghp_xxxx`）�?
2. **在应用中绑定**�?   - 打开应用右上�?**设置** 按钮�?   - 在“云端同�?(GitHub Gist)”中粘贴您的 Token�?   - **Gist ID 首次可留�?*，直接点�?**测试连接**，系统将自动在您�?GitHub 中创建名�?`anime-record-data.json` 的专属私�?Gist 并自动回�?ID�?   - 点击 **保存设置**，后续点击“立即同步”即可完成多端合流�?
---

## 架构与技术栈

| 模块 | 技术选型 / 实现方式 |
| :--- | :--- |
| **开发语言与框�?* | Flutter 3.x, Dart 3.x |
| **状态管�?* | `ChangeNotifier` + `ListenableBuilder` 极简响应式架�?|
| **本地持久�?* | `shared_preferences` (结合 Tombstones 软删除跟�? |
| **网络请求** | `http` RESTful 规范请求 GitHub API |
| **拖拽排序** | `reorderables` 弹性流式卡片重�?|
| **文件读写** | `file_picker` 跨平台文件选择与保�?|
| **代码规范与质�?* | `flutter_lints`, Effective Dart 严格类型推导 |

更深入的设计考量、跨盘编译异常处理及协作流程，请参阅 [AGENTS.md](AGENTS.md)�?
---

## 开源许可证

本项目采�?[MIT 许可证](LICENSE) 开源。欢迎自由使用、学习与二次分发�?
