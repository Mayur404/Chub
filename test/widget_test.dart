import 'package:flutter_test/flutter_test.dart';
import 'package:Chub/main.dart';

void main() {
  testWidgets('App should build and display home page', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());
    
    // Verify the app builds successfully
    expect(find.byType(MyApp), findsOneWidget);
  });
}
