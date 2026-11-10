// Komponen shared — shell layar (docs/DESIGN.md §3.0)
//
// Semua layar memakai `AppScaffold`: latar dekoratif di belakang Scaffold
// transparan sehingga gradien senja terlihat di seluruh aplikasi.
import 'package:material_ui/material_ui.dart';

import '../tokens/app_sizes.dart';
import 'app_background.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.safeArea = true,
    this.resizeToAvoidBottomInset = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool safeArea;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: safeArea
              ? SafeArea(top: appBar == null, bottom: true, child: body)
              : body,
        ),
      ],
    );
  }
}

/// Kolom konten terpusat dengan lebar maksimum dan gutter halaman.
class AppContent extends StatelessWidget {
  const AppContent({
    super.key,
    required this.child,
    this.maxWidth = AppSizes.contentMaxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
