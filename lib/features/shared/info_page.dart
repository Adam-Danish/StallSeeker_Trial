import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tablet ? 24 : 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 720,
                maxHeight: 900,
              ),
              child: SizedBox.expand(
                child: Material(
                  color: Colors.white,
                  elevation: tablet ? 4 : 0,
                  shadowColor: const Color(0x18000000),
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      ),
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: AppColors.textDark,
                          ),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              tablet ? 32 : 20,
                              12,
                              tablet ? 32 : 20,
                              28,
                            ),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: -.3,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ...children,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
