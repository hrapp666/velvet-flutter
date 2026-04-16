// ============================================================================
// AboutScreen · 关于 Velvet
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Vt.s24, Vt.s16, Vt.s24, Vt.s80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 40, height: 40,
                      child: Icon(Icons.arrow_back, color: Vt.gold, size: 18),
                    ),
                  ),
                  const Spacer(),
                  Text('关 于', style: Vt.cnHeading.copyWith(color: Vt.gold)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: Vt.s40),
              Center(
                child: Text('❦',
                    style: Vt.displayLg.copyWith(
                        color: Vt.gold, fontSize: Vt.txl)),
              ),
              const SizedBox(height: Vt.s16),
              Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Vt.statusWaiting, Vt.goldLight, Vt.gold],
                  ).createShader(bounds),
                  child: Text(
                    'VELVET',
                    style: Vt.displayHero.copyWith(
                      color: Colors.white,
                      fontSize: 64,
                      letterSpacing: 8,
                      shadows: const [
                        Shadow(color: Color(0x80C9A961), blurRadius: 40),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Vt.s12),
              Center(
                child: Text(
                  '天  鹅  绒',
                  style: Vt.cnHeading.copyWith(
                    color: Vt.gold, letterSpacing: 8, fontSize: Vt.tmd,
                  ),
                ),
              ),
              const SizedBox(height: Vt.s32),
              Center(
                child: Text(
                  'Touch what was touched.',
                  style: Vt.label.copyWith(
                    color: Vt.gold, fontSize: Vt.tsm,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: Vt.s8),
              Center(
                child: Text(
                  '余 温 · 未 散',
                  style: Vt.cnLabel.copyWith(
                    color: Vt.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: Vt.s48),
              _section('品 牌 故 事', [
                '有些东西，是有温度的。',
                '',
                '一件旧丝绸，衣襟曾贴着夏夜；',
                '一本泛黄的集子，扉页还有她的字迹；',
                '一只瓷盏，盛过某个清晨的粥。',
                '',
                '这些物件，不在意被看见，',
                '只在意 · 被懂。',
                '',
                'Velvet 是一场私下的流转。',
                '给愿意慢下来的人，',
                '给真正 · 懂的人。',
              ]),
              _section('核 心 规 则', [
                '· 上架需完成商家认证',
                '· 平台收取 6% 佣金担保交易',
                '· 订单完成 T+7 释放到卖家提现余额',
                '· 买卖双方互评 · 累计信誉',
              ]),
              _section('联 系', const [
                'hello@velvet.market',
              ], contactEmail: 'hello@velvet.market', context: context),
              const SizedBox(height: Vt.s32),
              Container(
                padding: const EdgeInsets.only(top: Vt.s24),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Vt.borderSubtle)),
                ),
                child: Column(
                  children: [
                    Text('v22 · 2026',
                        style: Vt.label.copyWith(
                          color: Vt.textTertiary,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        )),
                    const SizedBox(height: Vt.s8),
                    Text('私 藏 · 流 转 · 懂 的 人 来',
                        style: Vt.cnLabel.copyWith(
                          color: Vt.gold.withValues(alpha: 0.7),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<String> lines,
      {String? contactEmail, BuildContext? context}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: Vt.s16),
      padding: const EdgeInsets.symmetric(vertical: Vt.s20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Vt.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title,
              style: Vt.cnHeading.copyWith(
                color: Vt.gold,
                shadows: const [Shadow(color: Color(0x33C9A961), blurRadius: 12)],
              )),
          const SizedBox(height: Vt.s16),
          ...lines.map((line) {
            if (line.isEmpty) return const SizedBox(height: Vt.s8);
            final isEmail = contactEmail != null && line == contactEmail;
            if (isEmail) {
              return GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: line));
                  VelvetToast.show(context!, '已复制 $line');
                },
                child: Container(
                  padding: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Vt.gold.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                  child: Text(line,
                      style: Vt.label.copyWith(color: Vt.gold, fontSize: Vt.tsm)),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(line,
                  textAlign: TextAlign.center,
                  style: Vt.cnBody.copyWith(
                    color: Vt.textPrimary.withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic,
                    height: 1.8,
                  )),
            );
          }),
        ],
      ),
    );
  }
}
