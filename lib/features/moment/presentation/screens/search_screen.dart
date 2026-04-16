// ============================================================================
// SearchScreen · 搜索 moments
// ============================================================================

import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/empty_state/empty_state.dart';
import '../../../../shared/widgets/motion/scroll_reveal.dart';
import '../../../../shared/widgets/skeleton/search_skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/moment_model.dart';

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
    Future.delayed(const Duration(milliseconds: 200), () {
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
      if (q.trim().isNotEmpty) _doSearch(q.trim());
      else setState(() {
        _results = [];
        _lastQuery = '';
        _error = null;
      });
    });
  }

  Future<void> _doSearch(String q) async {
    setState(() {
      _loading = true;
      _error = null;
      _lastQuery = q;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.get(
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
            // ─── Header + 搜索框 ───
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
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Vt.gold,
                        size: 18,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: Vt.s16),
                      decoration: BoxDecoration(
                        color: Vt.gold.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(Vt.rXs),
                        border: Border.all(
                          color: Vt.gold.withValues(alpha: 0.3),
                        ),
                      ),
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
                          hintStyle: GoogleFonts.cormorantGaramond(
                            fontSize: Vt.tmd,
                            color: Vt.gold.withValues(alpha: 0.4),
                            fontStyle: FontStyle.italic,
                            letterSpacing: 4,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: Vt.s12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── 结果区 ───
            Expanded(
              child: _buildBody(),
            ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Vt.s32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 32, color: Vt.gold.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(
                '— 暂 时 找 不 到 —',
                style: Vt.cnHeading.copyWith(
                  fontSize: Vt.tsm,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Vt.bodySm.copyWith(color: Vt.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_lastQuery.isEmpty) {
      return const EmptyState(
        title: '懂 的 人 · 自 然 知 道 找 什 么',
        subtitle: '试试  真丝  古董  夜里  ……',
      );
    }
    if (_results.isEmpty) {
      return const EmptyState(
        title: '— 此 物 尚 未 出 现 —',
        subtitle: '换一个词 · 再试',
      );
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
          // 搜索结果 · 快速 stagger 40ms · 让结果"一个一个冒出"感
          delay: Duration(milliseconds: (i * 40).clamp(0, 300)),
          duration: const Duration(milliseconds: 400),
          fromOffsetY: 18,
          child: _ResultTile(moment: m),
        );
      },
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: Vt.s24, vertical: Vt.s16),
        child: Row(
          children: [
            // 缩略图
            Container(
              width: 72,
              height: 96,
              decoration: BoxDecoration(
                color: Vt.bgPrimary,
                border: Border.all(
                  color: Vt.gold.withValues(alpha: 0.3),
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
            const SizedBox(width: 16),

            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moment.title?.isNotEmpty == true
                        ? moment.title!
                        : '无 题',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: Vt.textGoldSoft,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    moment.userNickname,
                    style: Vt.label.copyWith(
                      color: Vt.gold.withValues(alpha: 0.7),
                      letterSpacing: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (moment.hasItem && moment.itemPriceCents != null)
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '¥ ',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: Vt.tsm,
                            color: Vt.gold,
                          ),
                        ),
                        TextSpan(
                          text: price.toStringAsFixed(0),
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Vt.gold,
                            letterSpacing: 1,
                          ),
                        ),
                      ]),
                    ),
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
        style: GoogleFonts.cormorantGaramond(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          color: Vt.gold.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
