// ============================================================================
// Velvet · Design Token v5 · Editorial Luxury (对齐 H5 styles.css v5)
// ----------------------------------------------------------------------------
// 灵感：TASCHEN / Phaidon / Hermès / Bottega Veneta / Rolls-Royce / 山本耀司
// 原则：纯黑金 · 0 圆角 · 极致留白 · editorial 衬线 · 单列垂直流
//
// 哲学："Touch what was touched." 私藏，流转。
// 视觉锚点：暗金底色 + 黄金箔 + 暖象牙文字 + L 角装饰（替代圆角）
// 字体策略：Cormorant Garamond (display + body) + ZCOOL XiaoWei (中文衬线)
//          + Marcellus SC (accent · 价格 / 徽章)
//
// 单一真相源 — 任何 widget 都必须用 Vt.* 而非硬编码颜色/间距/圆角/阴影
// 圆角铁律：所有元素 0 圆角，仅头像 / 圆形按钮使用 rPill (9999)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Vt {
  Vt._();

  // ==========================================================================
  // 颜色系统
  // ==========================================================================

  // ----- 背景层级（4 层 · H5 v5 暗金底色 Versace/Rolls-Royce/Tom Ford 方向）-----
  // 不是灰黑、不是蓝黑 — 是带暖金底的炽热暗色
  static const Color bgVoid = Color(0xFF050402);        // 极深暖黑 · 微金底（H5 --void）
  static const Color bgPrimary = Color(0xFF0C0A06);     // 深暖棕黑（H5 --char）
  static const Color bgElevated = Color(0xFF16120C);    // 暗金棕（H5 --ink）
  static const Color bgHighest = Color(0xFF1F1A12);     // 浮层 略亮（ink 之上一档）

  // ----- 品牌色（极端克制，仅信号化使用）-----
  /// 黄金箔片 — 唯一品牌色（精选标 / 心动徽章 / 卖家信誉认证 / CTA）
  /// v5 取消酒红，纯黑金 editorial，对齐 Hermès/Tom Ford
  static const Color gold = Color(0xFFC9A961);
  static const Color goldLight = Color(0xFFE8C879);
  static const Color goldDark = Color(0xFF8C7536);

  /// （已废弃 — v5 删除天鹅绒酒红，仍保留常量但全部指向暗金底色，零回归切换）
  /// 后续重构再逐文件改名为 bgPrimary/bgElevated/gold
  static const Color velvet = bgElevated;
  static const Color velvetLight = bgHighest;
  static const Color velvetDark = bgPrimary;

  /// （已废弃 — Velvet 不用樱花粉，那是春水圈的语言）
  /// 重新指向黄金箔色阶，让所有遗留 Vt.sakura 调用自动转为金色，
  /// 后续重构再逐文件改名 — 此举为零回归切换。
  static const Color sakura = gold;
  static const Color sakuraLight = goldLight;
  static const Color sakuraDark = goldDark;

  /// 抹茶绿 — 仅在线 / 订单成功 / 担保中
  static const Color matcha = Color(0xFFC2EF4E);

  /// 警告红 — 退款 / 争议
  static const Color warn = Color(0xFFEF4E5C);

  // ----- 暗金 ambient 沉底（多屏复用：splash/login/register/profile/notification/chat/search）-----
  // v5 改为暖金棕底色 ambient（不再是酒红 → editorial 黑金）
  /// Radial gradient 顶色（暗金棕，比 ink 略暖）
  static const Color bgAmbientTop = Color(0xFF120E08);
  /// Radial gradient 底色（近纯黑暖底）
  static const Color bgAmbientBottom = Color(0xFF050402);
  /// 稍亮一档（moment detail / chat list）
  static const Color bgAmbientSoft = Color(0xFF181308);
  /// 稍暗一档（moment detail 底部）
  static const Color bgAmbientDeep = Color(0xFF080604);

  /// 标准 ambient 2 档（所有全屏 Scaffold 背景）
  static const List<Color> gradientAmbient = [bgAmbientTop, bgAmbientBottom];

  // ----- 纯黑/极深暖底（H5 真相源 register/chat/profile · 多处 radial 用）-----
  // 对照 H5 styles.css line 447/551/3125: radial(#0A0600 0%, #000000 78%~80%)
  /// 纯黑（H5 #000000 · register Scaffold / chat header 底 / profile bottom）
  static const Color bgPureBlack = Color(0xFF000000);
  /// 极深暖底（H5 #0A0600 · register/profile/feed radial 顶档）
  static const Color bgVoidShallow = Color(0xFF0A0600);
  /// 暖琥珀微底（H5 #1A0C02 · chat list / chat detail radial 顶档）
  static const Color bgVoidEmber = Color(0xFF1A0C02);
  /// 暖暗金底（H5 #1C1408 · chat detail logo gradient 顶档 / profile pet）
  static const Color bgVoidWarm = Color(0xFF1C1408);
  /// 冷暗底（H5 #050400 · chat detail logo gradient 底档）
  static const Color bgVoidCool = Color(0xFF050400);

  // ----- VELVET logo shader 6 档金渐变（splash/login/register/profile/feed）-----
  // 对照 H5 styles.css line 480/752 真相源：
  //   linear-gradient(180deg, #FDFAF2 0%, #F0D98A 18%, #E8C879 35%,
  //                            #C9A961 58%, #8C7536 84%, #4A2E0A 100%)
  /// 最亮：象牙白（H5 logo 0% 档）
  static const Color goldIvory = Color(0xFFFDFAF2);
  /// 高光金（H5 logo 18% 档 · 新增）
  static const Color goldHighlight = Color(0xFFF0D98A);
  /// 最暗：深铜金（H5 logo 100% 档）
  static const Color goldDeepest = Color(0xFF4A2E0A);

  /// VELVET logo 专用 6 档金渐变（ShaderMask）— 对齐 H5
  static const List<Color> gradientGoldLogo = [
    goldIvory,
    goldHighlight,
    goldLight,
    gold,
    goldDark,
    goldDeepest,
  ];
  static const List<double> gradientGoldLogoStops = [0.0, 0.18, 0.35, 0.58, 0.84, 1.0];

  /// 4 档金渐变（标题 / 强调文字 shader）
  static const List<Color> gradientGold4 = [goldIvory, goldLight, gold, goldDark];

  /// 自己消息气泡 3 档暗金渐变（chat detail · "me" bubble）
  /// 对照 H5 styles.css line 3530-3534:
  ///   linear-gradient(160deg,
  ///     rgba(70,50,12,.95) 0%, rgba(45,30,6,.98) 50%, rgba(25,16,2,1) 100%)
  static const List<Color> gradientChatBubbleMe = [
    Color(0xF2463208),  // rgba(70,50,12,.95)
    Color(0xFA2D1E06),  // rgba(45,30,6,.98)
    Color(0xFF191002),  // rgba(25,16,2,1)
  ];

  /// Feed/masonry cover 占位色阶（5 档暗金/咖/棕变体 · v5 editorial 黑金）
  static const List<Color> moodCoverVariants = [
    Color(0xFF1F1A12),  // 暖暗金（与 bgHighest 同）
    Color(0xFF261E10),  // 深咖金
    bgElevated,          // 暗金棕
    Color(0xFF2C2410),  // 深咖
    Color(0xFF1A140A),  // 暖暗黑
  ];

  // ----- 状态色（审批 / 订单 / 钱包）-----
  /// 通过 / 成功 / 已支付（薄荷绿）
  static const Color statusSuccess = Color(0xFFB8E6C9);
  /// 拒绝 / 失败 / 退款（灰粉）
  static const Color statusError = Color(0xFFE6A5A5);
  /// 等待 / 审核中（暖象牙）
  static const Color statusWaiting = Color(0xFFF5F1E8);

  // ----- 文本（v13: 全部偏金，editorial luxury 风）-----
  static const Color textPrimary = Color(0xFFF5E6C8);    // 偏金的奶油白
  static const Color textSecondary = Color(0xFFD4B872);  // 淡金
  static const Color textTertiary = Color(0xFF8C7536);   // 深金
  static const Color textDisabled = Color(0xFF4A3F1F);   // 极暗金
  static const Color textPlumDark = Color(0xFF211922);

  // ----- 字面金色（强调用，跟 H5 一致）-----
  static const Color textGold = Color(0xFFC9A961);
  static const Color textGoldLight = Color(0xFFE8C879);
  static const Color textGoldSoft = Color(0xFFF5E6C8);   // 最浅金（输入框文字）

  /// gold 1px 细线（border / divider · alpha 30/100）
  static const Color goldHairline = Color(0x4DC9A961);

  // ----- Light mode tokens (v25 · C2 · Notion warm minimalism) -----
  static const Color bgLightVoid = Color(0xFFFAF6EE);      // 暖奶油白
  static const Color bgLightPrimary = Color(0xFFF5EFE0);   // 象牙
  static const Color bgLightElevated = Color(0xFFEDE4CF);  // 米黄
  static const Color bgLightHighest = Color(0xFFE5D9BC);   // 深象牙

  static const Color textLightPrimary = Color(0xFF1A1410);    // 深咖
  static const Color textLightSecondary = Color(0xFF3A2E1F);
  static const Color textLightTertiary = Color(0xFF6B5A3E);
  static const Color textLightDisabled = Color(0xFF9A8B6C);

  /// Light 边界（10% 深咖 — 替代 dark 的 borderHairline）
  static const Color borderLightHairline = Color(0x1A1A1410);

  // ----- 边界（取代 box-shadow）-----
  static const Color borderHairline = Color(0x14F5E6D3); // 8% 暖白
  static const Color borderSubtle = Color(0x1FF5E6D3);   // 12%
  static const Color borderMedium = Color(0x33F5E6D3);   // 20%
  static const Color borderStrong = Color(0x52F5E6D3);   // 32%

  // ----- 玻璃面板（Sentry 启发：blur 18 + saturate 180%）-----
  static const Color glassFill = Color(0x14F5E6D3);
  static const Color glassBorder = Color(0x1FF5E6D3);
  static const double glassBlur = 18.0;
  static const double glassSaturation = 1.8;   // Sentry: blur(18px) saturate(180%)

  // ==========================================================================
  // 间距（Sanity 12 档 + Pinterest/Sentry 巨型段距）
  // ==========================================================================
  static const double s1 = 1.0;        // hairline (Sanity space-1)
  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s6 = 6.0;        // Sanity space-4 中间档
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;
  static const double s80 = 80.0;
  static const double s96 = 96.0;
  static const double s120 = 120.0;

  // —— v5 兼容别名（profile/orders/feed 残留引用，避免 in-flight rewrite 挂掉）——
  static const double s14 = 14.0;
  static const double s28 = 28.0;
  static const double s56 = 56.0;

  // ==========================================================================
  // 圆角 v5 · Editorial Luxury（TASCHEN/Hermès 共识：0 圆角 + L 角装饰）
  // ⚠️ 所有 r* 全部 0 — 仅 rPill 保留给头像 / 圆形 icon 按钮
  // 所有原 r* 调用点会自动变 0 角（零回归切换 · 后续逐页清理）
  // ==========================================================================
  static const double rXxs = 0.0;
  static const double rXs = 0.0;
  static const double rSm = 0.0;
  static const double rMd = 0.0;
  static const double rLg = 0.0;
  static const double rXl = 0.0;
  static const double rXxl = 0.0;
  static const double rPill = 9999;  // 仅头像 / 圆形 icon 按钮保留

  // ==========================================================================
  // 阴影系统（Sanity 共识：阴影已死，用 ring border + 色阶分层）
  // ==========================================================================

  /// Sanity 风格 ring border（替代 drop shadow 做 elevation）
  /// 用法：作为 BoxDecoration 的 border 替代 box-shadow
  static Border ringBorder = Border.all(color: borderHairline, width: 1);

  /// 仅在浮层用极轻 shadow（Sanity Level 3）
  static List<BoxShadow> shadowFloat = const [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> shadowModal = const [
    BoxShadow(color: Color(0xCC000000), blurRadius: 48, offset: Offset(0, 16)),
  ];

  /// Sentry 风格 inset shadow（按钮触感）
  static List<BoxShadow> shadowInsetButton = const [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  /// 樱花粉"生物发光"— 仅给 CTA 按钮 / 心动通知用
  static List<BoxShadow> glowSakura = const [
    BoxShadow(color: Color(0x66FF4D7E), blurRadius: 32, spreadRadius: -4),
  ];

  /// 黄金光晕 — 仅卖家认证 / 精选徽章
  static List<BoxShadow> glowGold = const [
    BoxShadow(color: Color(0x4DC9A961), blurRadius: 24, spreadRadius: -2),
  ];

  /// 黄金弱阴影 (40% alpha) — 文字 shadow / hairline glow
  static const Color shadowGold40 = Color(0x66C9A961);

  /// 黄金薄阴影 (25% alpha) — 二级 text shadow
  static const Color shadowGold25 = Color(0x40C9A961);

  /// 黄金 hairline 8px blur shadow · 用于 page indicator / divider
  static const BoxShadow shadowGoldHairline = BoxShadow(
    color: shadowGold40,
    blurRadius: 8,
  );

  /// 黄金 12px blur shadow · 用于细线发光
  static const BoxShadow shadowGoldLine = BoxShadow(
    color: shadowGold40,
    blurRadius: 12,
  );

  /// 暗金环境光（v5：原 velvetAmbient 改用金色暗光，editorial 不要紫红）
  static List<BoxShadow> shadowVelvetAmbient = const [
    BoxShadow(
      color: Color(0x33C9A961),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // ==========================================================================
  // 动画
  // ==========================================================================
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration cinematic = Duration(milliseconds: 800);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.elasticOut;
  static const Curve curveCinematic = Cubic(0.22, 1, 0.36, 1); // expo out

  // ==========================================================================
  // 字号标尺 — Perfect Fourth 1.33 ratio (与 H5 同源)
  // ----------------------------------------------------------------------------
  // 基准：16px body = md
  // 向上：md ×1.33 ≈ lg(21) ×1.33 ≈ xl(28) ×1.33 ≈ 2xl(38) ≈ 3xl(54) ≈ 4xl(76) ≈ 5xl(108)
  // 向下：md ÷1.13 ≈ sm(15) ÷1.15 ≈ xs(13) ÷1.08 ≈ 2xs(12)（v6: +1px 全局提升）
  // ==========================================================================
  static const double t2xs = 12.0;   // 最小脚注/版权（v6: +1px 全局提升）
  static const double txs = 13.0;    // label / caption（v6: +1px 全局提升）
  static const double tsm = 15.0;    // body sm / cn body（v6: +1px 全局提升）
  static const double tmd = 17.0;    // body / button（v6: +1px 全局提升）
  static const double tlg = 21.0;    // heading sm / cn heading
  static const double txl = 28.0;    // heading md / price / display sm
  static const double t2xl = 38.0;   // heading lg / display md
  static const double t3xl = 54.0;   // display lg
  static const double t4xl = 76.0;   // display xl
  static const double t5xl = 108.0;  // display hero

  // ==========================================================================
  // 排版（Cinzel display + Manrope sans + Marcellus SC accent）
  // ----------------------------------------------------------------------------
  // 核心理念：
  //   - display 用罗马衬线（Cinzel），制造"奢侈品/古典珠宝盒"感
  //   - heading/body 用 Manrope 单一中粗（500），克制现代
  //   - accent 用 Marcellus SC，用于 logo / 价格 / 品牌词
  //   - 大字号一律负字距 + 0.92-1.05 行高
  //   - 单一字重 500 主导（Lambo / Cursor / Linear 共识）
  // ==========================================================================

  // Cormorant Garamond + Perfect Fourth 1.33 scale
  // 字重统一 w300 (Stripe/Notion feather-light 共识) — 只有 logo/display 保留 w500
  // VELVET logo 风格 — 经典衬线，上下字阶呼吸感强
  static TextStyle get displayHero => GoogleFonts.cormorantGaramond(
        fontSize: t4xl,               // 76 (与 H5 一致)
        fontWeight: FontWeight.w500,
        letterSpacing: 8.0,           // logo 风：字间距宽
        height: 0.96,
        color: textPrimary,
      );

  static TextStyle get displayLg => GoogleFonts.cormorantGaramond(
        fontSize: t3xl,               // 54
        fontWeight: FontWeight.w500,
        letterSpacing: 6.0,
        height: 0.98,
        color: textPrimary,
      );

  static TextStyle get displayMd => GoogleFonts.cormorantGaramond(
        fontSize: t2xl,               // 38
        fontWeight: FontWeight.w300,  // 飘逸版 · light italic 衬线
        fontStyle: FontStyle.italic,
        letterSpacing: 3.0,
        height: 1.02,
        color: textPrimary,
      );

  // 商品价格用 Marcellus（带衬线小型大写感）
  static TextStyle get price => GoogleFonts.marcellusSc(
        fontSize: txl,                // 28
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.0,
        color: gold,
      );

  static TextStyle get priceLg => GoogleFonts.marcellusSc(
        fontSize: t2xl,               // 38
        fontWeight: FontWeight.w400,
        letterSpacing: 0.8,
        height: 1.0,
        color: gold,
      );

  // v13: heading/body 改用 Cormorant Garamond + Noto Serif SC fallback
  // v27: 飘逸版 — 全标题降到 w300 + italic（CormorantGaramond-LightItalic）
  static TextStyle get headingLg => GoogleFonts.cormorantGaramond(
        fontSize: txl,                // 28
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.5,
        height: 1.15,
        color: textPrimary,
      );

  static TextStyle get headingMd => GoogleFonts.cormorantGaramond(
        fontSize: tlg,                // 21
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.4,
        height: 1.2,
        color: textPrimary,
      );

  static TextStyle get headingSm => GoogleFonts.cormorantGaramond(
        fontSize: tmd,                // 16
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.3,
        height: 1.3,
        color: textPrimary,
      );

  static TextStyle get bodyLg => GoogleFonts.cormorantGaramond(
        fontSize: tmd,                // 16
        fontWeight: FontWeight.w300,  // Stripe feather-light
        letterSpacing: 0.2,
        height: 1.6,
        color: textPrimary,
      );

  static TextStyle get bodyMd => GoogleFonts.cormorantGaramond(
        fontSize: tsm,                // 14
        fontWeight: FontWeight.w300,
        letterSpacing: 0.2,
        height: 1.55,
        color: textSecondary,
      );

  static TextStyle get bodySm => GoogleFonts.cormorantGaramond(
        fontSize: txs,                // 12
        fontWeight: FontWeight.w300,
        letterSpacing: 0.3,
        height: 1.5,
        color: textSecondary,
      );

  static TextStyle get label => GoogleFonts.cormorantGaramond(
        fontSize: txs,                // 12
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        letterSpacing: 1.5,
        height: 1.4,
        color: textTertiary,
      );

  static TextStyle get button => GoogleFonts.cormorantGaramond(
        fontSize: tmd,                // 16
        fontWeight: FontWeight.w500,
        letterSpacing: 4.0,
        height: 1.0,
        color: gold,
      );

  static TextStyle get caption => GoogleFonts.cormorantGaramond(
        fontSize: t2xs,               // 11
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        letterSpacing: 2.5,
        height: 1.2,
        color: gold,
      );

  // ==========================================================================
  // 中文专用 TextStyle (ZCOOL XiaoWei 瘦体显示字)
  // 2026-04-29 修复:之前 w200/w300 触发 Android 字形 fallback 系统宋体
  // (回字糊成一团) → 强制 w400 匹配 google_fonts/ZCOOLXiaoWei-Regular.ttf 唯一权重
  // ZCOOL XiaoWei Regular 本身就是设计款瘦体显示字 · 不是普通宋体
  // ==========================================================================
  static TextStyle get cnDisplay => GoogleFonts.zcoolXiaoWei(
        fontSize: tlg,                // 21
        fontWeight: FontWeight.w400,
        letterSpacing: 12.0,
        height: 1.3,
        color: gold,
      );

  static TextStyle get cnHeading => GoogleFonts.zcoolXiaoWei(
        fontSize: tmd,                // 16
        fontWeight: FontWeight.w400,
        letterSpacing: 8.0,
        height: 1.4,
        color: gold,
      );

  static TextStyle get cnBody => GoogleFonts.zcoolXiaoWei(
        fontSize: tsm,                // 14
        fontWeight: FontWeight.w400,
        letterSpacing: 2.0,
        height: 1.95,
        color: textPrimary,
      );

  static TextStyle get cnLabel => GoogleFonts.zcoolXiaoWei(
        fontSize: txs,                // 12
        fontWeight: FontWeight.w400,
        letterSpacing: 7.0,
        height: 1.5,
        color: gold,
      );

  static TextStyle get cnButton => GoogleFonts.zcoolXiaoWei(
        fontSize: tmd,                // 16
        fontWeight: FontWeight.w400,
        letterSpacing: 12.0,
        height: 1.0,
        color: gold,
      );

  static TextStyle get cnCaption => GoogleFonts.zcoolXiaoWei(
        fontSize: txs,                // 12
        fontWeight: FontWeight.w400,
        letterSpacing: 4.0,
        height: 1.6,
        color: textSecondary,
      );

  // ==========================================================================
  // 输入框专用 — Cormorant Garamond 衬线，金色，跟 H5 一致
  // ==========================================================================
  static TextStyle get input => GoogleFonts.cormorantGaramond(
        fontSize: tlg,                // 21
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
        height: 1.2,
        color: textGoldSoft,
      );

  static TextStyle get inputPlaceholder => GoogleFonts.cormorantGaramond(
        fontSize: tmd,                // 16
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.5,
        height: 1.2,
        color: gold.withValues(alpha: 0.35),
      );

  // ==========================================================================
  // 复用 decoration（避免到处重复写）
  // ==========================================================================

  /// 标准卡片（色阶分层 + 1px 边界，无阴影）
  static BoxDecoration cardDecoration = BoxDecoration(
    color: bgElevated,
    borderRadius: BorderRadius.circular(rMd),
    border: Border.all(color: borderHairline, width: 1),
  );

  /// 浮起卡片（用于详情页底部浮卡）
  static BoxDecoration cardElevated = BoxDecoration(
    color: bgHighest,
    borderRadius: BorderRadius.circular(rLg),
    border: Border.all(color: borderSubtle, width: 1),
    boxShadow: shadowFloat,
  );

  /// 玻璃面板（导航栏 / 浮层背景）
  static BoxDecoration glassPanel = BoxDecoration(
    color: glassFill,
    borderRadius: BorderRadius.circular(rLg),
    border: Border.all(color: glassBorder, width: 1),
  );

  /// 樱花粉 CTA 按钮（核心心动按钮）
  static BoxDecoration ctaSakura = BoxDecoration(
    color: sakura,
    borderRadius: BorderRadius.circular(rPill),
    boxShadow: glowSakura,
  );

  /// 黄金强调边框（精选 / 认证）
  static BoxDecoration goldBorder = BoxDecoration(
    color: bgElevated,
    borderRadius: BorderRadius.circular(rMd),
    border: Border.all(color: gold, width: 1),
    boxShadow: glowGold,
  );

  /// 卡片暗角 vignette（电影感，给商品图用）
  static BoxDecoration vignetteOverlay = const BoxDecoration(
    gradient: RadialGradient(
      radius: 1.2,
      colors: [Colors.transparent, Color(0xCC000000)],
      stops: [0.5, 1.0],
    ),
  );

  /// 天鹅绒纹理覆盖层（启动页 / 登录页背景用）
  /// — 通过两层径向渐变模拟丝绒触感
  static BoxDecoration velvetGradient = const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(-0.4, -0.6),
      radius: 1.5,
      colors: [bgHighest, bgPrimary, bgVoid],
      stops: [0.0, 0.4, 1.0],
    ),
  );
}
