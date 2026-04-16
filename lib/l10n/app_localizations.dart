// ============================================================================
// Velvet · AppLocalizations (v25 · I1)
// ----------------------------------------------------------------------------
// 手写版本 · API 与 `flutter gen-l10n` 生成物完全兼容
//
// 为什么手写？
//   本次 I1 在 worktree 里交付,这台 machine 暂时没有 flutter CLI,跑不了
//   `flutter gen-l10n`。为了让 i18n 立刻生效（ARB 接入 / locale provider /
//   widget 可以 import 就用）,先手写一份等价的委托 + 类实现。
//
// 主人在 velvet-flutter/ 根目录跑一次 `flutter gen-l10n` 之后,flutter_tools
// 会读取 l10n.yaml + lib/l10n/app_en.arb / app_zh.arb 重新生成这个文件,
// 覆盖这份手写版本。生成后的文件 API 与本文件一致,调用方无需改动。
//
// 非 null getter API 与 `nullable-getter: false` 一致:
//   AppLocalizations.of(context)  //  → AppLocalizations?  (Flutter 标准)
//   使用方式：AppLocalizations.of(context)!.tabAll  或 .of(context) 判空
// ============================================================================

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// 应用级本地化入口 · 对齐 `flutter gen-l10n` 生成的 AppLocalizations 结构。
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = locale;

  final String localeName;

  /// Delegate 入口 · 与 gen-l10n 生成物同名。
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// 必须同时挂上这 4 个 delegate,才能让 Material / Widgets / Cupertino
  /// 的内置 widget（例如 DatePicker / TextField 菜单）跟随 locale。
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// 支持语言 · App 目前只声明 zh + en。扩展时同时加 ARB 与 _lookup。
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 从 context 拿 AppLocalizations · null 表示 delegate 还未挂上。
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // ── Keys (mirror ARB files) ─────────────────────────────────────────

  String get appName;

  String get tabAll;
  String get tabFollow;
  String get tabNearby;
  String get tabRecommend;

  String get retryButton;
  String get loadingLabel;

  String get emptyFeedTitle;
  String get emptyFeedSubtitle;

  String get emptyRecommendTitle;
  String get emptyRecommendSubtitle;

  String get emptyChatTitle;
  String get emptyChatSubtitle;

  String get emptySearchInitialTitle;
  String get emptySearchInitialSubtitle;

  String get emptySearchNoResultTitle;
  String get emptySearchNoResultSubtitle;

  String get emptyOrderBuyerTitle;
  String get emptyOrderBuyerSubtitle;
  String get emptyOrderSellerSubtitle;

  String get emptyFavoritesTitle;
  String get emptyFavoritesSubtitle;

  String get errorGenericTitle;
  String get errorNetworkMessage;

  String get onboardingSkip;
  String get onboardingBegin;
  String get onboardingNext;

  String get themeLight;
  String get themeDark;
  String get themeSystem;
  String get themeSectionTitle;

  String get languageSectionTitle;
  String get languageSystem;
  String get languageEnglish;
  String get languageChinese;

  String get contentViolation;
  String get moderationForbidden;
}

// ============================================================================
// Delegate
// ============================================================================

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // 只看 languageCode,countryCode 忽略(zh-CN / zh-TW 都落到 zh,en-US /
    // en-GB 都落到 en)。
    return <String>{'en', 'zh'}.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(_lookup(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations _lookup(Locale locale) {
  return switch (locale.languageCode) {
    'zh' => _AppLocalizationsZh(),
    _ => _AppLocalizationsEn(),
  };
}

// ============================================================================
// English · keep aligned with lib/l10n/app_en.arb
// ============================================================================

class _AppLocalizationsEn extends AppLocalizations {
  _AppLocalizationsEn() : super('en');

  @override
  String get appName => 'Velvet';

  @override
  String get tabAll => 'ALL';
  @override
  String get tabFollow => 'FOLLOW';
  @override
  String get tabNearby => 'NEARBY';
  @override
  String get tabRecommend => 'FOR YOU';

  @override
  String get retryButton => 'RETRY';
  @override
  String get loadingLabel => 'LOADING';

  @override
  String get emptyFeedTitle => '— NO STORIES YET —';
  @override
  String get emptyFeedSubtitle => 'Tap + below to hang your first';

  @override
  String get emptyRecommendTitle => '— NO TASTE MATCH YET —';
  @override
  String get emptyRecommendSubtitle =>
      'Tap more hearts, let time find your match';

  @override
  String get emptyChatTitle => '— NO WHISPERS YET —';
  @override
  String get emptyChatSubtitle => 'The right ones will find you';

  @override
  String get emptySearchInitialTitle => 'What are you looking for';
  @override
  String get emptySearchInitialSubtitle => 'Try silk  vintage  night ...';

  @override
  String get emptySearchNoResultTitle => '— NOT HERE YET —';
  @override
  String get emptySearchNoResultSubtitle => 'Try another word';

  @override
  String get emptyOrderBuyerTitle => '— NO ORDERS —';
  @override
  String get emptyOrderBuyerSubtitle =>
      'Browse around, find something that moves you';
  @override
  String get emptyOrderSellerSubtitle =>
      'No trades yet, good things find their people';

  @override
  String get emptyFavoritesTitle => '— NO SAVES YET —';
  @override
  String get emptyFavoritesSubtitle => 'tap heart to keep what moves you';

  @override
  String get errorGenericTitle => '— NOT FOUND —';
  @override
  String get errorNetworkMessage => 'Network error, please try again';

  @override
  String get onboardingSkip => 'SKIP';
  @override
  String get onboardingBegin => 'BEGIN';
  @override
  String get onboardingNext => 'NEXT';

  @override
  String get themeLight => 'LIGHT';
  @override
  String get themeDark => 'DARK';
  @override
  String get themeSystem => 'SYSTEM';
  @override
  String get themeSectionTitle => 'APPEARANCE';

  @override
  String get languageSectionTitle => 'LANGUAGE';
  @override
  String get languageSystem => 'SYSTEM';
  @override
  String get languageEnglish => 'ENGLISH';
  @override
  String get languageChinese => '中 文';

  @override
  String get contentViolation => 'Content contains inappropriate information';
  @override
  String get moderationForbidden => 'Forbidden content';
}

// ============================================================================
// 中文 · keep aligned with lib/l10n/app_zh.arb
// Velvet editorial 调性 · 空格分隔单字
// ============================================================================

class _AppLocalizationsZh extends AppLocalizations {
  _AppLocalizationsZh() : super('zh');

  @override
  String get appName => 'Velvet';

  @override
  String get tabAll => '全 部';
  @override
  String get tabFollow => '关 注';
  @override
  String get tabNearby => '同 城';
  @override
  String get tabRecommend => '推 荐';

  @override
  String get retryButton => '重 试';
  @override
  String get loadingLabel => '加 载 中';

  @override
  String get emptyFeedTitle => '— 还 没 有 故 事 —';
  @override
  String get emptyFeedSubtitle => '点底部 + 来挂第一件';

  @override
  String get emptyRecommendTitle => '— 还 没 懂 你 的 品 味 —';
  @override
  String get emptyRecommendSubtitle => '多点几个心动，让时间帮你找知己';

  @override
  String get emptyChatTitle => '— 还 没 有 私 语 —';
  @override
  String get emptyChatSubtitle => '懂的人 · 自然会来找你';

  @override
  String get emptySearchInitialTitle => '懂 的 人 · 自 然 知 道 找 什 么';
  @override
  String get emptySearchInitialSubtitle => '试试  真丝  古董  夜里  ……';

  @override
  String get emptySearchNoResultTitle => '— 此 物 尚 未 出 现 —';
  @override
  String get emptySearchNoResultSubtitle => '换一个词 · 再试';

  @override
  String get emptyOrderBuyerTitle => '— 暂 无 订 单 —';
  @override
  String get emptyOrderBuyerSubtitle => '逛 逛 看 · 或 许 有 心 动 的';
  @override
  String get emptyOrderSellerSubtitle => '还 没 有 成 交 · 好 物 自 会 遇 见 人';

  @override
  String get emptyFavoritesTitle => '— 还 没 有 收 藏 —';
  @override
  String get emptyFavoritesSubtitle => '心动的 · 按一下 ♡ 留下来';

  @override
  String get errorGenericTitle => '— 暂 时 找 不 到 —';
  @override
  String get errorNetworkMessage => '网络开小差 · 稍等再试';

  @override
  String get onboardingSkip => '跳 过';
  @override
  String get onboardingBegin => '开 始';
  @override
  String get onboardingNext => '下 一 页';

  @override
  String get themeLight => '明 亮';
  @override
  String get themeDark => '暗 黑';
  @override
  String get themeSystem => '跟 随';
  @override
  String get themeSectionTitle => '外 观';

  @override
  String get languageSectionTitle => '语 言';
  @override
  String get languageSystem => '跟 随';
  @override
  String get languageEnglish => 'ENGLISH';
  @override
  String get languageChinese => '中 文';

  @override
  String get contentViolation => '内容包含不恰当的信息';
  @override
  String get moderationForbidden => '内容无法发布';
}
