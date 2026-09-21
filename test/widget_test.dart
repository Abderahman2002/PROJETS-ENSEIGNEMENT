import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rafiq_al_muallim/app.dart';
import 'package:rafiq_al_muallim/providers/auth_provider.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const RafiqAlMuallimApp(),
      ),
    );

    expect(find.text('رفيق المعلم الموريتاني'), findsOneWidget);
  });
}
