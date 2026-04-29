// ============================================================================
// SearchScreen · 搜 索 · v5 Editorial Luxury
// ----------------------------------------------------------------------------
// H5 真相源:
//   - styles.css L3130 .search-header (glassmorphism · gold border-bottom)
//   - styles.css L3151 .search-input (44h · gold-04 bg · focus gold glow)
//   - styles.css L3275 .search-empty (huge "懂 的 人" gold gradient)
//   - styles.css L3185 .search-hot-tags + .hot-chip (gold border · padding 8/20)
//   - styles.css L3298 .search-row (72x96 thumb · gold border · serif title + price)
// ============================================================================

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/motion/scroll_reveal.dart';
import '../../../../shared/widgets/skeleton/search_skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/moment_model.dart';

/// H5 同款 hot-chip 词云
const _hotChips = [
  '真 丝', '故 事 款', '面 交', '香 薰', '孤 品',
  '九 成 新', '同 城', '手 工', '古 着', '私 藏',
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<MomentModel> _results = [];
  bool _loading = false;
  String? _error;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final trimmed = q.trim();
      if (trimmed.isNotEmpty) {
        unawaited(_doSearch(trimmed));
      } else {
        setState(() {
          _results = [];
          _lastQuery = '';
          _error = null;
        });
      }
    });
  }

  void _onChipTap(String label) {
    final q = label.replaceAll(' ', '');
    unawaited(HapticService.instance.light());
    _ctrl.text = q;
    _ctrl.selection =
        TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
    unawaited(_doSearch(q));
  }

  Future<void> _doSearch(String q) async {
    setState(() {
      _loading = true;
      _error = null;
      _lastQuery = q;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.get<dynamic>(
        '/api/v1/search/public/moments',
        queryParameters: {'q': q, 'page': 0, 'size': 30},
      );
      final data = res.data as Map<String, dynamic>;
      final content = (data['content'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _results = content
            .map((e) => MomentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? '搜索失败';
        _loading = false;
      });
    } on Object catch (_) {
      // 静默原因：解析/类型异常时不能让 UI 卡在 loading,给错误态可重试
      if (!mounted) return;
      setState(() {
        _error = '搜索失败';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.4,
            colors: Vt.gradientAmbient,
          ),
        ),
        child: Column(
          children: [
            // ─── Header + 搜索框 (search-header) ───
            Container(
              padding: EdgeInsets.fromLTRB(
                  Vt.s20, padding.top + Vt.s16, Vt.s20, Vt.s16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Vt.gold.withValues(alpha: 0.18),
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Vt.gold,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: Vt.s16),
                      decoration: BoxDecoration(
                        color: Vt.gold.withValues(alpha: 0.04),
                        border: Border.all(
                          color: Vt.gold.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          onChanged: _onChanged,
                          style: Vt.bodyLg.copyWith(
                            color: Vt.textGoldSoft,
                            letterSpacing: 0.5,
                          ),
                          cursorColor: Vt.gold,
                          decoration: InputDecoration(
                            hintText: '寻 找 一 件 好 物…',
                            hintStyle: Vt.inputPlaceholder.copyWith(
                              color: Vt.gold.withValues(alpha: 0.4),
                              letterSpacing: 4,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── 结果区 ───
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SearchSkeleton();
    }
    if (_error != null) {
      return _ErrorEmpty(message: _error!);
    }
    if (_lastQuery.isEmpty) {
      return _SearchHomeEmpty(onChipTap: _onChipTap);
    }
    if (_results.isEmpty) {
      return const _NoResultEmpty();
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: Vt.s12),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Vt.s24),
        child: Container(
          height: 1,
          color: Vt.gold.withValues(alpha: 0.08),
        ),
      ),
      itemBuilder: (context, i) {
        final m = _results[i];
        return ScrollReveal(
          // 搜索结果 · 快速 stagger 40ms
          delay: Duration(milliseconds: (i * 40).clamp(0, 300)),
          duration: const Duration(milliseconds: 400),
          fromOffsetY: 18,
          child: _ResultTile(moment: m),
        );
      },
    );
  }
}

// ============================================================================
// 空 / 词云首屏 · 大字 "懂 的 人" gold gradient + hot-chip cloud
// ============================================================================
class _SearchHomeEmpty extends StatelessWidget {
  final ValueChanged<String> onChipTap;
  const _SearchHomeEmpty({required this.onChipTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(Vt.s32, Vt.s96, Vt.s32, Vt.s40),
      child: Column(
        children: [
          // 顶部 hairline gold 56×1
          Container(
            width: 56,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Vt.gold.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Vt.gold.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: Vt.s24),
          // 大字 cn display gold gradient
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Vt.goldIvory, Vt.gold],
            ).createShader(rect),
            child: Text(
              '懂 的 人',
              style: Vt.cnDisplay.copyWith(
                color: Colors.white,
                fontSize: Vt.txl,
                letterSpacing: 18,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: Vt.s8),
          Text(
            'WHO  KNOWS',
            style: Vt.label.copyWith(
              color: Vt.gold.withValues(alpha: 0.6),
              letterSpacing: 6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: Vt.s16),
          Text(
            '真 丝 · 丝 袜 · 私 房 · 陪 伴 ……',
            style: Vt.bodySm.copyWith(
              color: Vt.textTertiary,
              letterSpacing: 3,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Vt.s40),
          // hot-chip cloud
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Vt.s12,
            runSpacing: Vt.s12,
            children: _hotChips
                .map((c) => _HotChip(label: c, onTap: () => onChipTap(c)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HotChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HotChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Vt.gold.withValues(alpha: 0.06),
          border: Border.all(
            color: Vt.gold.withValues(alpha: 0.30),
          ),
        ),
        child: Text(
          label,
          style: Vt.cnLabel.copyWith(
            color: Vt.gold,
            fontSize: Vt.tsm,
            letterSpacing: 2,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _NoResultEmpty extends StatelessWidget {
  const _NoResultEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Vt.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Vt.gold.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: Vt.s24),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Vt.goldIvory, Vt.gold],
              ).createShader(rect),
              child: Text(
                '— 此 物 尚 未 出 现 —',
                style: Vt.cnHeading.copyWith(
                  color: Colors.white,
                  fontSize: Vt.tlg,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: Vt.s12),
            Text(
              '换 一 个 词 · 再 试',
              style: Vt.bodySm.copyWith(
                color: Vt.textTertiary,
                letterSpacing: 2,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorEmpty extends StatelessWidget {
  final String message;
  const _ErrorEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Vt.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 32, color: Vt.gold.withValues(alpha: 0.6)),
            const SizedBox(height: Vt.s16),
            Text(
              '— 暂 时 找 不 到 —',
              style: Vt.cnHeading.copyWith(
                fontSize: Vt.tsm,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: Vt.s8),
            Text(
              message,
              style: Vt.bodySm.copyWith(color: Vt.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _ResultTile · 72×96 thumb (4/3 aspect-ish 0 圆角 gold 边) + 衬线 title + price
// ============================================================================
class _ResultTile extends StatelessWidget {
  final MomentModel moment;
  const _ResultTile({required this.moment});

  @override
  Widget build(BuildContext context) {
    final cover = moment.mediaUrls.isNotEmpty ? moment.mediaUrls.first : null;
    final price = (moment.itemPriceCents ?? 0) / 100;

    return GestureDetector(
      onTap: () => context.push('/moment/${moment.id}'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: Vt.s24, vertical: Vt.s16),
        child: Row(
          children: [
            // 缩略图 72×96 · 0 圆角 · gold 边
            Container(
              width: 72,
              height: 96,
              decoration: BoxDecoration(
                color: Vt.bgVoid,
                border: Border.all(
                  color: Vt.gold.withValues(alpha: 0.30),
                ),
              ),
              child: cover != null
                  ? CachedNetworkImage(
                      imageUrl: cover,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: Vt.s16),

            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moment.title?.isNotEmpty == true
                        ? moment.title!
                        : '无 题',
                    style: Vt.headingMd.copyWith(
                      color: Vt.textGoldSoft,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    moment.userNickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Vt.label.copyWith(
                      color: Vt.gold.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (moment.hasItem && moment.itemPriceCents != null) ...[
                    const SizedBox(height: Vt.s8),
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: Vt.gradientGold4,
                      ).createShader(rect),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: '¥ ',
                            style: Vt.price.copyWith(
                              fontSize: Vt.tsm,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: price.toStringAsFixed(0),
                            style: Vt.price.copyWith(
                              fontSize: Vt.txl,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 1,
                              height: 1,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Text(
        'V',
        style: Vt.displayMd.copyWith(
          fontSize: Vt.t2xl,
          fontWeight: FontWeight.w500,
          color: Vt.gold.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
