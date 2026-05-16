import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_tile.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.build(AppThemes.unishare),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders icon and uppercase label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MoreDrawerTile(
          label: 'SAVED',
          icon: Icons.bookmark_outline,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('SAVED'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
  });

  testWidgets('tapping the tile fires onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _wrap(
        MoreDrawerTile(
          label: 'SAVED',
          icon: Icons.bookmark_outline,
          onTap: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.byType(MoreDrawerTile));
    await tester.pump();

    expect(tapped, 1);
  });
}
