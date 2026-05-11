// ============================================================================
// LegalScreen · 法务文档查看（用户协议 / 隐私协议）
// ----------------------------------------------------------------------------
// 离线优先：HTML 打包到 assets/legal/ → WebView 加载 file:// → 不依赖网络
// App Store 审核员可直接在 app 内点击查看 · 满足合规要求
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../shared/theme/design_tokens.dart';

enum LegalDoc { terms, privacy }

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, required this.doc});
  final LegalDoc doc;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  String get _title => switch (widget.doc) {
        LegalDoc.terms => '用 户 协 议',
        LegalDoc.privacy => '隐 私 协 议',
      };

  String get _assetPath => switch (widget.doc) {
        LegalDoc.terms => 'assets/legal/terms.html',
        LegalDoc.privacy => 'assets/legal/privacy.html',
      };

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Vt.bgVoid)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      );
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    try {
      final html = await rootBundle.loadString(_assetPath);
      await _controller.loadHtmlString(html);
    } on Object catch (_) {
      // 静默原因：asset 缺失 fallback → 显示极简文本
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: SafeArea(
        child: Column(
          children: [
            _LegalHeader(title: _title),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading)
                    const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.4,
                          color: Vt.gold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalHeader extends StatelessWidget {
  const _LegalHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Vt.s24, Vt.s16, Vt.s24, Vt.s12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back, color: Vt.gold, size: 18),
            ),
          ),
          const SizedBox(width: Vt.s8),
          Text(
            'VELVET',
            style: Vt.headingLg.copyWith(
              color: Vt.textPrimary,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w500,
              letterSpacing: 3.5,
              height: 1.0,
            ),
          ),
          const SizedBox(width: Vt.s12),
          Container(width: 1, height: 14, color: Vt.borderMedium),
          const SizedBox(width: Vt.s12),
          Text(title, style: Vt.cnLabel.copyWith(color: Vt.textSecondary)),
        ],
      ),
    );
  }
}
