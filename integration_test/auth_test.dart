import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_product_app/main.dart';
import 'package:my_product_app/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Signed-out screen and input validation', (tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.signOut();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Register or Sign In'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), 'student');
    await tester.enterText(fields.at(1), '123');
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(
      find.text('Password must be at least 6 characters'),
      findsOneWidget,
    );
    expect(find.text('Profile'), findsNothing);
  });
}
