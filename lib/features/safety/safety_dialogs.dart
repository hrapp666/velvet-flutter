// ============================================================================
// Safety Dialogs · Apple UGC 合规四件套（前端入口）
// ----------------------------------------------------------------------------
// - showReportDialog   举报用户/动态/评论（Apple 1.2）
// - showBlockDialog    拉黑用户（Apple 1.2）
// - showDeleteAccountDialog  注销账号（Apple 5.1.1(v)）
// - showLegalDocument  内置阅读：用户协议 / 隐私政策（注册页跳）
// ----------------------------------------------------------------------------
// 依赖：api_client.dart · design_tokens.dart · velvet_toast.dart
// 后端：POST /api/v1/reports · POST /api/v1/blocks · DELETE /api/v1/users/me
// ============================================================================

import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/feedback/velvet_toast.dart';
import '../auth/presentation/providers/auth_provider.dart';

// ────────────────────────────────────────────────────────────────────────────
// 举报
// ────────────────────────────────────────────────────────────────────────────

enum ReportTargetType { user, moment, comment, chat }

// 后端枚举：SPAM / ADULT / FAKE / HARASSMENT / OTHER
// 显示中文 → 提交英文枚举（key 必须严格匹配后端 ReportController.VALID_REASONS）
const _reportReasons = <(String label, String code)>[
  ('色情低俗', 'ADULT'),
  ('骚扰辱骂', 'HARASSMENT'),
  ('欺诈诱导', 'FAKE'),
  ('垃圾广告', 'SPAM'),
  ('其它', 'OTHER'),
];

/// 打开举报对话框。target 必填，result 返回是否成功提交。
Future<bool> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required ReportTargetType targetType,
  required int targetId,
}) async {
  final picked = await showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => const _ReportDialog(),
  );
  if (picked == null || !context.mounted) return false;

  try {
    final api = ref.read(apiClientProvider);
    await api.dio.post('/api/v1/reports', data: {
      'targetType': targetType.name.toUpperCase(),
      'targetId': targetId,
      'reason': picked,
    });
    if (context.mounted) {
      VelvetToast.show(context, '举报已受理 · 24 小时内处理');
    }
    return true;
  } on DioException catch (e) {
    if (context.mounted) {
      VelvetToast.show(context, '举报失败：${e.message ?? '网络异常'}', isError: true);
    }
    return false;
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Vt.rLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(Vt.s24),
            decoration: BoxDecoration(
              color: Vt.bgElevated.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(Vt.rLg),
              border: Border.all(
                color: Vt.gold.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '举   报',
                  textAlign: TextAlign.center,
                  style: Vt.cnHeading.copyWith(
                    fontSize: Vt.tlg,
                    letterSpacing: 8,
                    color: Vt.gold,
                  ),
                ),
                const SizedBox(height: Vt.s8),
                Text(
                  '我们会在 24 小时内人工审核',
                  textAlign: TextAlign.center,
                  style: Vt.bodySm.copyWith(
                    color: Vt.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: Vt.s20),
                ..._reportReasons.map((r) {
                  final (label, code) = r;
                  final selected = _reason == code;
                  return _ReasonRow(
                    text: label,
                    selected: selected,
                    onTap: () => setState(() => _reason = code),
                  );
                }),
                const SizedBox(height: Vt.s20),
                Row(
                  children: [
                    Expanded(
                      child: _DialogBtn(
                        label: '取  消',
                        ghost: true,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: Vt.s12),
                    Expanded(
                      child: _DialogBtn(
                        label: '提  交',
                        onTap: _reason == null
                            ? null
                            : () => Navigator.of(context).pop(_reason),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _ReasonRow({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Vt.gold.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? Vt.gold.withValues(alpha: 0.28)
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? Vt.gold
                      : Vt.gold.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: selected
                  ? const Center(
                      child:
                          Icon(Icons.check, size: 10, color: Vt.gold),
                    )
                  : null,
            ),
            const SizedBox(width: Vt.s16),
            Text(
              text,
              style: Vt.cnBody.copyWith(
                fontSize: Vt.tsm,
                color: selected ? Vt.gold : Vt.textSecondary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 拉黑
// ────────────────────────────────────────────────────────────────────────────

Future<bool> showBlockDialog(
  BuildContext context,
  WidgetRef ref, {
  required int userId,
  String? nickname,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => _ConfirmDialog(
      title: '拉 黑',
      body: nickname == null
          ? '拉黑后，对方不会再出现在你的动态和消息里。'
          : '拉黑 $nickname 后，对方不会再出现在你的动态和消息里。',
      confirmLabel: '确  认  拉  黑',
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  try {
    final api = ref.read(apiClientProvider);
    await api.dio.post('/api/v1/blocks', data: {
      'targetUserId': userId,
    });
    if (context.mounted) {
      VelvetToast.show(context, '已拉黑');
    }
    return true;
  } on DioException catch (e) {
    if (context.mounted) {
      VelvetToast.show(context, '拉黑失败：${e.message ?? '网络异常'}', isError: true);
    }
    return false;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 注销账号
// ────────────────────────────────────────────────────────────────────────────

/// 弹出二次确认对话框。返回 true 表示确认并成功提交注销请求。
Future<bool> showDeleteAccountDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder: (_) => const _DeleteAccountDialog(),
  );
  if (confirmed != true || !context.mounted) return false;

  try {
    final api = ref.read(apiClientProvider);
    await api.dio.delete('/api/v1/users/me', data: {
      'confirmation': 'DELETE_MY_ACCOUNT',
    });
    return true;
  } on DioException catch (e) {
    if (context.mounted) {
      VelvetToast.show(context, '注销失败：${e.message ?? '网络异常'}', isError: true);
    }
    return false;
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _ctrl = TextEditingController();
  bool _typed = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Vt.rLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(Vt.s24),
            decoration: BoxDecoration(
              color: Vt.bgElevated.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(Vt.rLg),
              border: Border.all(
                color: Vt.statusError.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '注  销  账  号',
                  textAlign: TextAlign.center,
                  style: Vt.cnHeading.copyWith(
                    fontSize: Vt.tlg,
                    letterSpacing: 8,
                    color: Vt.statusError,
                  ),
                ),
                const SizedBox(height: Vt.s16),
                Text(
                  '此操作不可撤销。\n'
                  '你的动态、评论、订单、收藏将被清空，\n'
                  '个人资料会被匿名化。',
                  textAlign: TextAlign.center,
                  style: Vt.cnBody.copyWith(
                    fontSize: Vt.tsm,
                    color: Vt.textSecondary,
                    letterSpacing: 1.5,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: Vt.s20),
                Text(
                  '请输入  DELETE_MY_ACCOUNT  确认',
                  textAlign: TextAlign.center,
                  style: Vt.caption.copyWith(
                    color: Vt.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: Vt.s12),
                TextField(
                  controller: _ctrl,
                  textAlign: TextAlign.center,
                  style: Vt.input.copyWith(
                    color: Vt.statusError,
                    letterSpacing: 1.5,
                  ),
                  cursorColor: Vt.statusError,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Vt.statusError.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Vt.statusError, width: 1),
                    ),
                  ),
                  onChanged: (v) {
                    final ok = v.trim() == 'DELETE_MY_ACCOUNT';
                    if (ok != _typed) setState(() => _typed = ok);
                  },
                ),
                const SizedBox(height: Vt.s24),
                Row(
                  children: [
                    Expanded(
                      child: _DialogBtn(
                        label: '取  消',
                        ghost: true,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: Vt.s12),
                    Expanded(
                      child: _DialogBtn(
                        label: '永  久  注  销',
                        danger: true,
                        onTap: _typed
                            ? () => Navigator.of(context).pop(true)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 法律条款阅读器（用户协议 / 隐私政策）
// ────────────────────────────────────────────────────────────────────────────

enum LegalDoc { terms, privacy }

Future<void> showLegalDocument(
  BuildContext context,
  LegalDoc doc,
) async {
  final (title, body) = switch (doc) {
    LegalDoc.terms => ('用  户  协  议', _termsText),
    LegalDoc.privacy => ('隐  私  政  策', _privacyText),
  };
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder: (_) => _LegalDialog(title: title, body: body),
  );
}

class _LegalDialog extends StatelessWidget {
  final String title;
  final String body;
  const _LegalDialog({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Vt.rLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: BoxConstraints(maxHeight: size.height * 0.8),
            padding: const EdgeInsets.all(Vt.s20),
            decoration: BoxDecoration(
              color: Vt.bgElevated.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(Vt.rLg),
              border: Border.all(
                color: Vt.gold.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Vt.cnHeading.copyWith(
                    fontSize: Vt.tlg,
                    letterSpacing: 8,
                    color: Vt.gold,
                  ),
                ),
                const SizedBox(height: Vt.s16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      body,
                      style: Vt.cnBody.copyWith(
                        fontSize: Vt.tsm,
                        color: Vt.textSecondary,
                        height: 1.9,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Vt.s16),
                _DialogBtn(
                  label: '我  已  知  悉',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 公共按钮
// ────────────────────────────────────────────────────────────────────────────

class _DialogBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool ghost;
  final bool danger;
  const _DialogBtn({
    required this.label,
    required this.onTap,
    this.ghost = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final color = danger ? Vt.statusError : Vt.gold;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.35 : 1,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ghost
                ? Colors.transparent
                : color.withValues(alpha: 0.14),
            border: Border.all(
              color: ghost ? color.withValues(alpha: 0.35) : color,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: Vt.label.copyWith(
              color: color,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Vt.rLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(Vt.s24),
            decoration: BoxDecoration(
              color: Vt.bgElevated.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(Vt.rLg),
              border: Border.all(
                color: Vt.gold.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Vt.cnHeading.copyWith(
                    fontSize: Vt.tlg,
                    letterSpacing: 8,
                    color: Vt.gold,
                  ),
                ),
                const SizedBox(height: Vt.s16),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Vt.cnBody.copyWith(
                    fontSize: Vt.tsm,
                    color: Vt.textSecondary,
                    letterSpacing: 1.5,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: Vt.s24),
                Row(
                  children: [
                    Expanded(
                      child: _DialogBtn(
                        label: '取  消',
                        ghost: true,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: Vt.s12),
                    Expanded(
                      child: _DialogBtn(
                        label: confirmLabel,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 法律文本（同步于 VPS 部署的 /legal/terms.html 和 /legal/privacy.html）
// ────────────────────────────────────────────────────────────────────────────

const _termsText = '''
一、服务说明

Velvet（以下简称"本服务"）是一款内容分享与 C2C 二手物品交易社交应用。本协议由你（以下简称"用户"）与本服务运营方之间订立，自你注册或使用本服务时生效。

二、用户行为规范

1. 你承诺不发布、不传播以下内容：
   · 违反中华人民共和国法律法规、所在地区法律的内容
   · 色情、低俗、暴力、恐怖、血腥内容
   · 人身攻击、骚扰、诽谤、歧视性言论
   · 侵犯他人知识产权、肖像权、隐私权的内容
   · 欺诈、虚假宣传、误导性信息
   · 其它不适宜在社交平台传播的内容

2. 你发布的内容必须为你本人原创或你已获得合法授权。

3. 你不得利用本服务从事违法犯罪活动。

三、内容审核

本服务对用户发布内容保持零容忍的违规处理态度：
· 所有用户可对内容进行举报
· 我们将在 24 小时内人工审核举报内容
· 经核实违规的内容将被删除，情节严重者账号将被封禁
· 涉嫌犯罪的，我们将依法配合司法机关

四、知识产权

你对自己发布的内容保留所有权，同时授权本服务在服务范围内对该内容进行存储、展示、传播。

五、账号管理

· 你可随时在"我的 > 注销账号"中永久注销账号
· 注销后你的动态、评论、订单记录将被清空，个人资料匿名化处理
· 注销操作不可撤销

六、免责声明

本服务仅提供技术平台。用户之间发生的交易、纠纷、损失，由当事人自行处理与承担。本服务作为平台方将在力所能及范围内协助协调。

七、协议修改

本服务有权根据业务调整修改本协议，修改后将在 App 内公告。继续使用本服务视为接受修改后的协议。

八、联系方式

如有疑问，请邮件联系：support@velvet.app

（最后更新：2026 年 4 月）
''';

const _privacyText = '''
一、我们收集的信息

1. 你主动提供的：
   · 账号信息：用户名、密码（bcrypt 加密存储）、手机号或邮箱
   · 个人资料：昵称、头像、个人简介、封面图
   · 你发布的内容：动态文字、图片、评论、私信
   · 交易信息：订单、收货地址、支付流水号

2. 我们自动收集的：
   · 设备信息：设备型号、操作系统版本（仅用于崩溃诊断）
   · 使用数据：登录时间、页面浏览（仅用于服务改进）

3. 经你授权后收集的：
   · 相机、相册：仅在你主动上传照片时访问
   · 麦克风：仅在你主动录制语音时访问
   · 粗略位置：仅在你主动使用"同城"功能时访问

二、我们不收集的信息

我们明确不收集以下信息：
· 精确 GPS 定位
· 通讯录
· 短信内容
· 设备剪贴板
· 跨 App 追踪标识符（IDFA / Android Ad ID）

三、我们如何使用你的信息

· 提供核心服务（登录、发布、聊天、交易）
· 改进产品（匿名统计）
· 遵守法律法规（配合执法调查）

四、我们不做的事

· 我们不向第三方出售你的个人信息
· 我们不进行跨 App / 跨网站追踪
· 我们不使用你的内容训练第三方 AI 模型

五、数据存储与安全

· 你的数据存储在位于德国和新加坡的自托管服务器上
· 密码使用 bcrypt 单向加密
· 传输使用 HTTPS / TLS
· 敏感数据使用 AES 加密存储

六、你的权利

· 访问：在"我的 > 导出数据"中下载你的全部数据副本
· 更正：在"编辑资料"中修改个人信息
· 删除：在"注销账号"中永久删除你的账号和关联数据
· 举报：对任何内容发起举报，我们将在 24 小时内处理

七、儿童隐私

本服务不面向 14 岁以下儿童。如我们发现未经监护人同意收集了儿童信息，将立即删除。

八、隐私政策修改

本政策有实质性修改时，我们将在 App 内以显著方式通知你。

九、联系我们

隐私相关问题请邮件至：privacy@velvet.app

（最后更新：2026 年 4 月）
''';
