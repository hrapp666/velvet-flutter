# Velvet · App Store 提审 Checklist

> 版本：v0.32.0+32（2026-05-11）
> 7 条主人提的优化点（P1–P7）落地清单 + 提审前必跑命令 + 审核员问答口径。

---

## 一、本轮 7 项交付（@huangji666 quote · 已逐条落地）

### P1 · 用户协议 / 隐私协议 + Support 入口（提审必备）

- [x] `assets/legal/terms.html` + `assets/legal/privacy.html`（中文条款 + Velvet 设计骨架，纯静态，不依赖网络）
- [x] `lib/features/profile/presentation/screens/legal_screen.dart` · webview_flutter v4（WebViewController + WebViewWidget）· `JavaScriptMode.disabled`
- [x] router `/legal/terms` `/legal/privacy` 已注册
- [x] "我的"页底部 "用 户 协 议 / 隐 私 政 策" 编辑器风格菜单
- [x] **Support 入口**："联 系 我 们" 菜单 → `Clipboard.setData('support@velvet.app')` → VelvetToast 提示
- [x] App Store Connect 提审 → App Information → Support URL：`https://velvet.app/support`（域名未上线则填 mailto:support@velvet.app 备审）

### P2 · 多语言切换不生效

- [x] 诊断：291 处硬编码中文 vs 仅 5 处 `AppLocalizations.of(context)` → 切换器即使切到 EN 也几乎无视觉变化
- [x] 务实修：在"我的"页隐藏 _LanguageSection 渲染，删除 3 个相关类（_LanguageSection / _SettingSection / _SettingChip）+ 清理未使用 imports
- [x] 机制保留：`locale_provider.dart` / `app_en.arb` / `app_zh.arb` 不动，下个迭代做完整 ARB 翻译后再放出开关
- [x] App Store 审核口径：本版本为中文优先（main market：CN），后续支持中英双语

### P3 · "我要种草" → "我要发布" 点击报错

- [x] 之前 session 已修：路由 `/publish` 走通，FAB push + 中央 + 浮起按钮双入口均能进 `CreateMomentScreen`
- [x] `create_moment_screen.dart` 保留 X 关闭按钮（双入口需要回退）

### P4 · App Icon 缺失

- [x] `branding/icon_master.png`（1024×1024）+ adaptive `icon_fg.png` / `icon_bg.png`（432×432）
- [x] 设计：Cormorant Garamond V 单字 monogram · 5 档金渐变 · 1px 金线 hairline rule · 径向 ambient 暖炭黑→void 背景
- [x] `pubspec.yaml` 接入 `flutter_launcher_icons: ^0.14.1` · `remove_alpha_ios: true`（App Store 必须不透明）
- [x] iOS Icon-App-*.png 全套生成（含 1024×1024 marketing icon）
- [x] Android mipmap-*dpi + adaptive ic_launcher.xml 全套生成
- [x] `branding/gen_velvet_icon.py` 可复跑

### P5 · 一级页面 nav + 操作完成 Toast

- [x] `profile_screen.dart`：删掉右上角 back arrow（一级 tab 不需要 back）
- [x] `search_screen.dart`：删掉左上角 back arrow（一级 tab 不需要 back）
- [x] `create_moment_screen.dart`：保留 X 关闭（FAB / 中央 + 按钮两个入口需要可取消）
- [x] VelvetToast 已覆盖：复制 / 收藏 / 发布 / 操作成功 / 网络错误 路径

### P6 · iPad 屏占比适配

- [x] `lib/shared/widgets/main_scaffold.dart` · body 与 bottomNavigationBar 都 `Align + ConstrainedBox(maxWidth: 720)`
- [x] iPhone（宽 <720）行为零变化；iPad（宽 >720）内容居中 + 两侧 Vt.bgVoid 留白
- [x] `lib/main.dart` · `setPreferredOrientations` 增加 `DeviceOrientation.portraitDown`（与 iPad Info.plist `portraitUpsideDown` 对齐）
- [x] iOS Info.plist · iPhone：仅 Portrait；iPad：Portrait + PortraitUpsideDown（早前已配）

### P7 · 本 Checklist + Commit

- [x] 本文件 `docs/RELEASE_CHECKLIST.md`
- [x] commit 含 OMC trailer（Confidence / Scope-risk / Rejected / Not-tested）

---

## 二、提审前必跑（Velvet Iron Law 2 · 没有验证不说 done）

```bash
cd /root/velvet/velvet-flutter

# 1. 静态分析 · 0 error 0 warning（pre-existing unused_import 除外）
flutter analyze

# 2. 设计 token 红线
grep -rn "Color(0xFF" lib/features                 # 0 hit 期望
grep -rn "Navigator\.push" lib                     # 0 hit（用 context.push）
grep -rn "catch (_)" lib | grep -v "// 静默原因"   # 0 hit
grep -rn "!\." lib --include="*.dart" | grep -v "//"  # 排查残留 bang

# 3. 构建（在 macOS 上）
flutter build ios --release --no-codesign        # iOS 构建产物
flutter build apk --release --obfuscate \
  --split-debug-info=./debug-info/                 # Android release with obfuscation

# 4. 跑端到端（在 macOS Simulator 上）
bash scripts/take-appstore-shots.sh 6.7 zhHans   # 6.7 寸中文
bash scripts/take-appstore-shots.sh 6.5 zhHans
bash scripts/take-appstore-shots.sh ipad zhHans  # iPad 适配验证

# 5. icon 校验
ls -la ios/Runner/Assets.xcassets/AppIcon.appiconset/  # 17 PNG + Contents.json
ls -la android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png  # 192×192
```

---

## 三、App Store Connect 字段（提审填空）

| 字段 | 填写 |
|------|------|
| Bundle ID | com.velvet.app（按 Xcode 项目实际填） |
| 版本号 | 0.32.0 |
| Build | 32 |
| 类别 | Social Networking（主）/ Lifestyle（副） |
| 年龄分级 | 17+（含轻度社交、用户生成内容） |
| Support URL | https://velvet.app/support（域名未上线则填 mailto:support@velvet.app） |
| Marketing URL | https://velvet.app（可选） |
| Privacy Policy URL | https://velvet.app/privacy 或随包内 `/legal/privacy` |
| Copyright | © 2026 Velvet |
| App Tracking | 不使用 IDFA（无第三方 ATT 弹窗） |
| In-App Purchase | v26 起纯分享模式 · 不含 IAP（pubspec 已注释 in_app_purchase）|

### 隐私清单（App Privacy）

| 数据类型 | 收集？ | 用途 | 关联用户？ |
|---------|--------|------|-----------|
| 邮箱 | Yes | 账号 | Yes |
| 用户内容（照片、文字） | Yes | App Functionality | Yes |
| 设备 ID | Yes | App Functionality（推送 token） | No |
| 粗略位置 | Yes（geolocator）| App Functionality（同城 / 附近） | No |

---

## 四、Apple 审核员常问 & 标准回答

| 问题 | 回答 |
|------|------|
| Q: Support link 怎么联系到你们？ | A: 在「我的 → 联系我们」点击可复制 support@velvet.app；同时 App Store Connect 配置了 Support URL。 |
| Q: 用户协议 / 隐私协议在哪？ | A: 「我的」页底部「用户协议」「隐私政策」打开内置 WebView 显示 `assets/legal/*.html`，离线可用。 |
| Q: 多语言支持？ | A: 当前版本中文优先（主市场 CN），架构已就位（ARB + l10n），下版本释放英文 UI 开关。 |
| Q: 是否含 IAP / 订阅？ | A: 不含。v26 起纯分享模式，所有功能免费。 |
| Q: 是否使用 IDFA / ATT？ | A: 不使用。未集成 AdServices / AppTrackingTransparency。 |
| Q: iPad 支持？ | A: 支持。Portrait + PortraitUpsideDown。内容居中 maxWidth 720，两侧 bgVoid 留白。 |

---

## 五、未覆盖 / Known Limitations

- ⚠️ `lib/main.dart:18` 有 1 个 pre-existing `unused_import: light_theme.dart`，不影响功能。后续清理。
- ⚠️ P2 多语言开关本版本隐藏，不是"全量翻译完成"。文案 ARB 完整化在下版本。
- ⚠️ Support URL `https://velvet.app/support` 需要主人在域名上线后挂一个静态页；过审时可临时用 mailto。
- ⚠️ branding/ 下的 PNG 是设计源文件，已 commit；如需更换品牌色，编辑 `branding/gen_velvet_icon.py` 后 `flutter pub run flutter_launcher_icons`。

---

**提审前最后一步**：在 macOS Xcode 打开 `ios/Runner.xcworkspace` → Archive → Distribute App → App Store Connect → Upload。等 TestFlight 处理完后提交审核。
