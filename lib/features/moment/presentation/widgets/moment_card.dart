// ============================================================================
// MomentCard · Editorial 单列卡（v5 对齐 H5 .editorial-card）
// ----------------------------------------------------------------------------
// H5 真相源: styles.css L1429 .editorial-card
//   - padding 56/32/64 · border-bottom hairline gold
//   - 巨型罗马数字水印 watermark (180px, italic, gold gradient text)
//   - meta-row · italic gold · "N° 001 · 北京 · 4 月 27 日"
//   - cover aspect 4/5 · 0 圆角 · inset hairline gold
//   - title clamp(34,44) Cormorant w500 · -0.6px tracking
//   - lead italic w300 · drop cap 首字母放大金色
//   - price clamp(48,60) 4 档金色 ShaderMask · ¥ + 数字
//   - footer-row · hairline border-top · seller + heart-btn
//   - 0 圆角 · 全页面无 BorderRadius
// ----------------------------------------------------------------------------
// 字段保留（被 feed_screen / favorites 复用）:
//   momentId / title / sellerName / sellerAvatar / priceCents / likeCount
//   coverHeight (废弃 · 改 4/5 aspect) / coverColor / location / onTap
//   imageUrl / liked / onLike / distanceLabel
// ============================================================================

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';

class MomentCard extends StatefulWidget {
  final int momentId;
  final String title;
  final String content;
  final String sellerName;
  final String sellerAvatar;
  final int priceCents;
  final int likeCount;
  final int indexInFeed; // 0-based · 用于 N° 001 罗马数字水印
  final Color coverColor;
  final String location;
  final DateTime? createdAt;
  final VoidCallback onTap;

  /// 真接 API 后新增
  final String? imageUrl;
  final bool liked;
  final VoidCallback? onLike;

  /// 同城 / 附近模式下显示的距离标签（如 "1.2km"），为 null 时不显示
  final String? distanceLabel;

  const MomentCard({
    super.key,
    required this.momentId,
    required this.title,
    required this.content,
    required this.sellerName,
    required this.sellerAvatar,
    required this.priceCents,
    required this.likeCount,
    required this.indexInFeed,
    required this.coverColor,
    required this.location,
    required this.onTap,
    this.createdAt,
    this.imageUrl,
    this.liked = false,
    this.onLike,
    this.distanceLabel,
  });

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard> {
  static const _romanNumerals = [
    'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
    'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX',
  ];

  String _formatPubDate(DateTime? d) {
    if (d == null) return '';
    return '${d.month} 月 ${d.day} 日';
  }

  @override
  Widget build(BuildContext context) {
    final hasPrice = widget.priceCents > 0;
    final price = widget.priceCents / 100;
    final roman = _romanNumerals[widget.indexInFeed % _romanNumerals.length];

    return GestureDetector(
      onTap: () {
        unawaited(HapticService.instance.light());
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        // editorial 单列 · padding 48/32/64 (s56 不存在 · 用 s48)
        padding: const EdgeInsets.fromLTRB(Vt.s32, Vt.s48, Vt.s32, Vt.s64),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Vt.borderHairline, width: 0.5),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // ─── 巨型罗马数字水印 (右上溢出) ───
            Positioned(
              top: -8,
              right: -16,
              child: IgnorePointer(
                child: ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Vt.gold.withValues(alpha: 0.10),
                      Vt.gold.withValues(alpha: 0.0),
                    ],
                  ).createShader(rect),
                  child: Text(
                    roman,
                    style: TextStyle(
                      fontFamily: Vt.displayMd.fontFamily,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                      fontSize: 160,
                      height: 0.8,
                      letterSpacing: -6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // ─── 顶部 hairline 装饰 ───
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Vt.gold.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Vt.gold.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── 主内容 ───
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── meta-row · italic gold · N° 001 · 地点 · 日期 ──
                _MetaRow(
                  index: widget.indexInFeed + 1,
                  location: widget.location.isNotEmpty
                      ? widget.location
                      : '未 知',
                  date: _formatPubDate(widget.createdAt),
                  distanceLabel: widget.distanceLabel,
                ),
                const SizedBox(height: Vt.s24),

                // ── 封面 4/5 aspect · 0 圆角 · inset hairline ──
                _Cover(
                  momentId: widget.momentId,
                  imageUrl: widget.imageUrl,
                  coverColor: widget.coverColor,
                ),
                const SizedBox(height: Vt.s40),

                // ── 巨型 title · Cormorant w500 ──
                Text(
                  widget.title.isNotEmpty ? widget.title : '无 题',
                  style: Vt.displayMd.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.6,
                    height: 1.06,
                    color: Vt.textPrimary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Vt.s24),

                // ── lead · italic w300 · 描述 ──
                if (widget.content.isNotEmpty) ...[
                  Text(
                    widget.content,
                    style: Vt.bodyMd.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                      fontSize: Vt.tmd,
                      height: 1.85,
                      letterSpacing: 0.4,
                      color: Vt.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Vt.s32),
                ],

                // ── 巨型 price · 4 档金色 ShaderMask ──
                if (hasPrice) ...[
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Vt.goldIvory,
                        Vt.goldHighlight,
                        Vt.gold,
                        Vt.goldDark,
                      ],
                      stops: [0.0, 0.22, 0.6, 1.0],
                    ).createShader(rect),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '¥ ',
                          style: Vt.price.copyWith(
                            fontSize: Vt.tmd,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: price.toStringAsFixed(0),
                          style: Vt.price.copyWith(
                            fontSize: 56,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -1,
                            height: 1,
                            color: Colors.white,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: Vt.s32),
                ],

                // ── footer-row · hairline border-top · seller + heart ──
                Container(
                  padding: const EdgeInsets.only(top: Vt.s24),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Vt.borderSubtle, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURATED BY',
                              style: Vt.label.copyWith(
                                fontStyle: FontStyle.italic,
                                fontSize: Vt.t2xs,
                                letterSpacing: 1.5,
                                color: Vt.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.sellerName,
                              style: Vt.bodySm.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Vt.textPrimary,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // heart-btn
                      SpringTap(
                        onTap: widget.onLike,
                        pressedScale: 0.85,
                        glow: widget.liked,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Vt.s4,
                            vertical: Vt.s8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.liked
                                    ? Icons.favorite
                                    : Icons.favorite_border_rounded,
                                size: 14,
                                color: widget.liked
                                    ? Vt.gold
                                    : Vt.textTertiary,
                                shadows: widget.liked
                                    ? [
                                        Shadow(
                                          color: Vt.gold.withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.likeCount}',
                                style: Vt.label.copyWith(
                                  fontSize: Vt.txs,
                                  color: widget.liked
                                      ? Vt.gold
                                      : Vt.textTertiary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ─── 底部 hairline 居中 32px 渐变线 ───
            Positioned(
              bottom: -1,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 32,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Vt.gold.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _MetaRow · italic gold · N° 001 · 地点 · 日期 · [距离]
// ============================================================================
class _MetaRow extends StatelessWidget {
  final int index;
  final String location;
  final String date;
  final String? distanceLabel;
  const _MetaRow({
    required this.index,
    required this.location,
    required this.date,
    this.distanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Vt.gold,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Vt.gold.withValues(alpha: 0.6), blurRadius: 6),
        ],
      ),
    );
    return Row(
      children: [
        // N° 001 编号徽章 · border 1px gold-30
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: Vt.gold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            'N° ${index.toString().padLeft(3, '0')}',
            style: Vt.label.copyWith(
              fontSize: Vt.txs,
              fontWeight: FontWeight.w500,
              color: Vt.gold,
              letterSpacing: 2,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 16),
        dot,
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            location,
            style: Vt.label.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: Vt.txs,
              color: Vt.gold.withValues(alpha: 0.82),
              letterSpacing: 3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (date.isNotEmpty) ...[
          const SizedBox(width: 16),
          dot,
          const SizedBox(width: 16),
          Text(
            date,
            style: Vt.label.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: Vt.txs,
              color: Vt.gold.withValues(alpha: 0.82),
              letterSpacing: 3,
            ),
          ),
        ],
        if (distanceLabel != null) ...[
          const Spacer(),
          // 距离徽章 · 金色描边
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Vt.bgVoid.withValues(alpha: 0.78),
              border: Border.all(
                color: Vt.gold.withValues(alpha: 0.6),
                width: 0.6,
              ),
            ),
            child: Text(
              '⌖ $distanceLabel',
              style: Vt.label.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: Vt.t2xs,
                color: Vt.gold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// _Cover · Hero + 4/5 aspect + inset hairline + vignette
// ============================================================================
class _Cover extends StatelessWidget {
  final int momentId;
  final String? imageUrl;
  final Color coverColor;
  const _Cover({
    required this.momentId,
    required this.imageUrl,
    required this.coverColor,
  });

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.6),
          radius: 1.2,
          colors: [
            coverColor,
            coverColor.withValues(alpha: 0.6),
            Vt.bgVoid,
          ],
        ),
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Vt.goldLight, Vt.goldDark],
          ).createShader(rect),
          child: Text(
            'V',
            style: Vt.displayHero.copyWith(
              fontSize: 72,
              fontWeight: FontWeight.w500,
              letterSpacing: 6,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImg = url != null && url.isNotEmpty;
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 黑底封面
          ColoredBox(
            color: Vt.bgVoid,
            child: Hero(
              tag: 'moment-cover-$momentId',
              child: hasImg
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          // 顶部 + 底部双 vignette
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 0.8, 1.0],
                  colors: [
                    Vt.bgVoid.withValues(alpha: 0.25),
                    Colors.transparent,
                    Colors.transparent,
                    Vt.bgVoid.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
          // inset hairline gold
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Vt.gold.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
