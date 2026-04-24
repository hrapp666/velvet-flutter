// ============================================================================
// MomentCard · Pinterest masonry 卡片
// ----------------------------------------------------------------------------
// 视觉策略：
//   - 12px 圆角（Pinterest 经典）
//   - 顶部色块占位（实际接 cached_network_image）
//   - 下方 vignette 渐变让文字浮起
//   - 价格用 Marcellus SC 衬线 + 金色（Vt.price）
//   - 卖家头像 + 名字 + 心动数
//   - 同城角标 + 心动数显示
//   - hover/press scale 0.97（轻微反馈）
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
  final String sellerName;
  final String sellerAvatar;
  final int priceCents;
  final int likeCount;
  final double coverHeight;
  final Color coverColor;
  final String location;
  final VoidCallback onTap;

  // 真接 API 后新增
  final String? imageUrl;
  final bool liked;
  final VoidCallback? onLike;

  /// 同城 / 附近模式下显示的距离标签（如 "1.2km"），为 null 时不显示
  final String? distanceLabel;

  const MomentCard({
    super.key,
    required this.momentId,
    required this.title,
    required this.sellerName,
    required this.sellerAvatar,
    required this.priceCents,
    required this.likeCount,
    required this.coverHeight,
    required this.coverColor,
    required this.location,
    required this.onTap,
    this.imageUrl,
    this.liked = false,
    this.onLike,
    this.distanceLabel,
  });

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticService.instance.light());
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: Vt.fast,
        child: Container(
          decoration: BoxDecoration(
            color: Vt.bgElevated,
            borderRadius: BorderRadius.circular(Vt.rMd),
            border: Border.all(color: Vt.borderHairline, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Vt.rMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 封面 · Hero tag = moment-cover-${momentId} ───
                Stack(
                  children: [
                    Builder(builder: (_) {
                      final imageUrl = widget.imageUrl;
                      final hasImage = imageUrl != null && imageUrl.isNotEmpty;
                      return Hero(
                        tag: 'moment-cover-${widget.momentId}',
                        // flightShuttleBuilder 默认 · 系统 MaterialRectArcTween
                        child: SizedBox(
                          height: widget.coverHeight,
                          width: double.infinity,
                          child: hasImage
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _placeholderBg(),
                                  errorWidget: (_, __, ___) => _placeholderBg(),
                                )
                              : _placeholderBg(),
                        ),
                      );
                    }),

                    // 暗角 vignette
                    Positioned.fill(child: DecoratedBox(decoration: Vt.vignetteOverlay)),

                    // 同城角标 (location 文字)
                    if (widget.location.isNotEmpty)
                      Positioned(
                        bottom: Vt.s8,
                        left: Vt.s8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Vt.bgVoid.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(Vt.rXs),
                            border: Border.all(color: Vt.borderHairline),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on,
                                  size: 10, color: Vt.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                widget.location,
                                style: Vt.label.copyWith(fontSize: Vt.t2xs),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 距离徽章（同城模式专用 · 金色边框）
                    if (widget.distanceLabel != null)
                      Positioned(
                        top: Vt.s8,
                        right: Vt.s8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Vt.bgVoid.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(Vt.rXs),
                            border: Border.all(
                              color: Vt.gold.withValues(alpha: 0.6),
                              width: 0.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Vt.gold.withValues(alpha: 0.18),
                                blurRadius: 8,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me_rounded,
                                  size: 9, color: Vt.gold),
                              const SizedBox(width: 3),
                              Text(
                                widget.distanceLabel!,
                                style: Vt.label.copyWith(
                                  color: Vt.gold,
                                  fontSize: Vt.t2xs,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // ─── 文字区 ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Vt.s12, Vt.s12, Vt.s12, Vt.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Vt.bodyMd.copyWith(
                          color: Vt.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Vt.s8),

                      // 价格（Marcellus SC + 金色）
                      Text(
                        '¥ ${(widget.priceCents / 100).toStringAsFixed(0)}',
                        style: Vt.price.copyWith(fontSize: Vt.tlg),
                      ),

                      const SizedBox(height: Vt.s12),

                      // 卖家信息行
                      Row(
                        children: [
                          // 头像
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Vt.borderSubtle,
                                width: 1,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Vt.velvet.withValues(alpha: 0.6),
                                  Vt.velvetDark,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.sellerName,
                              style: Vt.bodySm.copyWith(
                                color: Vt.textSecondary,
                                fontSize: Vt.t2xs,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // 心动数（可点击 — 黄金箔 / SpringTap 弹性反馈）
                          SpringTap(
                            onTap: widget.onLike,
                            pressedScale: 0.82, // 小 icon 按压要明显
                            glow: widget.liked, // 已点亮时有 burst
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(Vt.s4),
                              child: Icon(
                                widget.liked
                                    ? Icons.favorite
                                    : Icons.favorite_border_rounded,
                                size: 12,
                                color: widget.liked ? Vt.gold : Vt.textTertiary,
                                shadows: widget.liked
                                    ? [
                                        Shadow(
                                          color: Vt.gold.withValues(alpha: 0.6),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            '${widget.likeCount}',
                            style: Vt.label.copyWith(
                              color: Vt.textSecondary,
                              fontSize: Vt.t2xs,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.2,
          colors: [
            widget.coverColor,
            widget.coverColor.withValues(alpha: 0.7),
            Vt.bgVoid,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Vt.gold.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.diamond_outlined,
            color: Vt.gold.withValues(alpha: 0.6),
            size: 24,
          ),
        ),
      ),
    );
  }
}
