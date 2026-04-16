# Golden Screenshot Baseline

## 用法

### 首次生成 baseline
```bash
flutter test --update-goldens test/golden/
```

### 视觉回归检查
```bash
flutter test test/golden/
```

失败会生成 `test/golden/failures/` 带 diff 图。

## 当前覆盖（v25 · J5 首批）

| 文件 | golden | 说明 |
|------|--------|------|
| velvet_glyph_golden_test.dart | velvet_glyph_96.png | VelvetGlyph size=96 纯 CustomPaint |
| feed_skeleton_golden_test.dart | feed_skeleton.png | FeedSkeleton 6-card masonry shimmer |

## 原则

- baseline 图必须 git 跟踪（`.png` 不加 `.gitignore`）
- 任何视觉故意改动必须手动 `--update-goldens` 并 review diff
- 失败不等于 bug：可能是故意设计改动，必须 review 后决定 accept / revert
- baseline 只在真 flutter 环境生成（需要 skia renderer）

## 已知限制（J5 暂缓）

涉及 `Vt.label` / `Vt.bodyMd` 等 GoogleFonts 文本的 golden 暂时不能在 test 环境
跑通（google_fonts 在 headless test 里既不能走网络也不能走 asset）。

已删除的 3 个 golden 文件（等 bundled font 方案落地后再开）：

- `retry_chip_golden_test.dart` · RetryChip 带文本
- `empty_state_golden_test.dart` · EmptyState 带 title/subtitle
- `error_state_golden_test.dart` · ErrorState 带文本

解决方案候选（后续一 PR 专项）：
1. 下载 Cormorant/Marcellus/ZCool TTF 到 `assets/fonts/google_fonts/`，在 pubspec
   的 `flutter.fonts.family=CormorantGaramond` 注册（google_fonts 包会自动发现
   assets 里的字体文件，不再走网络）
2. 或 test 环境覆盖 `Vt.*` text style 为 `TextStyle(fontFamily: null)`
