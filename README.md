# Velvet Flutter · 一套代码 · Web / Android / iOS

> 约会 + 二手寄售双形态社区的前端。
> Touch what was touched. 私藏，流转。

---

## 技术栈

| 层 | 选型 | 版本 |
|---|---|---|
| 框架 | Flutter | 3.5+ / Dart 3.5+ |
| 状态管理 | Riverpod | ^2.5.1 |
| 路由 | go_router | ^14.6.2 |
| 网络 | Dio | ^5.7.0 |
| 安全存储 | flutter_secure_storage | ^9.2.2 |
| 实时 | web_socket_channel | ^3.0.1 |
| 图片 | cached_network_image / image_picker / photo_view | latest |
| 字体 | google_fonts（**仅本地 bundle，CDN 关闭**） | ^6.2.1 |
| Pinterest 网格 | flutter_staggered_grid_view | ^0.7.0 |
| 地理 | geolocator（同城 / 附近） | ^13.0.2 |
| Apple 登录 | sign_in_with_apple（iOS 上架必须） | ^6.1.4 |
| 传感器 | sensors_plus（splash 3D tilt） | ^6.1.0 |

---

## 快速开始

```bash
# 1. 装 Flutter 3.5+ + Dart 3.5+
flutter --version

# 2. 拉依赖
cd velvet-flutter
flutter pub get

# 3. 跑 web（默认连黄哥的生产 API）
flutter run -d chrome

# 4. 跑 Android 模拟器
flutter run -d emulator-5554

# 5. 打 release APK（连你自己的后端）
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.your-domain.com
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

---

## API 后端切换

默认连 `https://api.rvqu4vaz.work`（AWS ap-east-1 正式后端），见 `lib/core/api/api_client.dart:18`：

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.rvqu4vaz.work',
);
```

切到你的后端：

```bash
# 方式 A · 编译时注入（推荐）
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.your-domain.com

# 方式 B · 改默认值后 commit
# 直接编辑 lib/core/api/api_client.dart 第 20 行的 defaultValue
```

---

## 目录结构

```
velvet-flutter/lib/
├── main.dart                    # 应用入口（ProviderScope + Material）
├── core/
│   ├── router.dart              # GoRouter 全局路由表
│   ├── api/api_client.dart      # Dio 单例 · API_BASE_URL 配置
│   ├── deep_link_handler.dart   # 微信 / 支付宝回跳
│   └── constants/prefs_keys.dart
├── features/                    # 按业务领域分模块
│   ├── auth/                    # 注册 / 登录 / Apple Sign-In
│   ├── moment/                  # 动态 feed / 详情 / 创建 / 收藏 / 同城
│   ├── chat/                    # 私信 + WebSocket
│   ├── order/                   # 订单
│   ├── merchant/                # 商家入驻
│   ├── payment/                 # 支付 sheet
│   ├── notification/            # 通知
│   ├── profile/                 # 个人主页 / 编辑 / 关于
│   └── admin/                   # 后台
├── shared/
│   ├── theme/                   # design_tokens.dart（v25 视觉系统）
│   ├── widgets/                 # 通用组件
│   └── ...
└── l10n/                        # 国际化（zh / en）
```

每个 feature 内部分层：

```
features/<name>/
├── data/
│   ├── models/                  # JSON DTO + freezed
│   ├── repositories/            # 抽象接口 + impl
│   └── services/                # WebSocket / 第三方 SDK
└── presentation/
    ├── screens/                 # 页面
    ├── widgets/                 # 子组件
    └── providers/               # Riverpod
```

---

## 设计系统（v25 · `lib/shared/theme/design_tokens.dart`）

**Iron Laws**：
- 只用 `Vt.*`，禁止 `Color(0xFF...)` / `EdgeInsets.all(13)` / 自创圆角
- 字号走 Perfect Fourth 1.33 标尺（`Vt.t2xs` 11px → `Vt.t5xl` 108px）
- 圆角白名单：`rXxs(3) rXs(5) rSm(8) rMd(12) rLg(16) rXl(20) rXxl(28) rPill(9999)`，禁止 13~99998
- 间距走 4px 网格：`s1 s2 s4 s6 s8 s12 s16 s20 s24 s32 s40 s48 s64 s80 s96 s120`
- 单 accent 金色（`Vt.gold` / `goldLight` / `goldDark`），樱花粉已废弃自动指向 gold
- 字体三栈：Cormorant Garamond + Noto Serif SC + Marcellus SC（**全部本地 bundle，禁用 google fonts CDN**）

---

## Null Safety / 异常约定

- ❌ `!` bang 操作符 → 用局部变量提升 / 模式匹配 / `??`
- ❌ 裸 `catch (e)` → 必须 `on DioException catch (e)` / `on Object catch (e)`
- 每个 `catch (_)` 必须有 `// 静默原因：...` 注释
- async 后用 `if (mounted)` / `if (context.mounted)`

---

## 提交前检查

```bash
flutter analyze                                       # 0 error 0 warning
flutter test                                          # 全绿
grep -rn "Color(0xFF" lib/features                    # 0 hit
grep -rn "Navigator\.push" lib                        # 0 hit（用 context.push）
grep -rn "catch (_)" lib | grep -v "// 静默原因"      # 0 hit
```

---

## 打包发布

### Android APK / AAB

```bash
# APK（侧载 / 测试）
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.your-domain.com

# AAB（Google Play 上架）
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.your-domain.com \
  --obfuscate --split-debug-info=./debug-info/
```

签名配置：`android/app/build.gradle` 的 `signingConfigs`，密钥放 `android/key.properties`（已 gitignore）。

### iOS IPA

```bash
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.your-domain.com \
  --export-options-plist=ios/ExportOptions.plist
```

需要：
- Apple Developer 账号
- Bundle ID `com.hrapp.velvet`（与后端 `APPLE_BUNDLE_ID` 一致）
- Apple Sign-In capability 已开

---

## 常见问题

| 问题 | 解决 |
|---|---|
| Web 字体破相 | `GoogleFonts.config.allowRuntimeFetching = false`（main.dart 已配），字体必须本地 bundle |
| WebSocket 不重连 | 见 `lib/features/chat/data/services/chat_socket.dart`，token 拒绝时不要无限重连 |
| 切 tab 数据 reset | Provider 加 `ref.keepAlive()`（见 `feed_screen.dart` 的 `feedProvider`） |
| Flutter web 部署后中文 grep 不到 | dart2js 把中文转 unicode escape，要 `\uXXXX` hex 正则查 |
| Android release crash | 检查 `--obfuscate --split-debug-info=` 参数 + 上传 mapping 给 sentry |

---

## License

私有 / 商业项目（Velvet by 黄哥团队）
