import 'package:flutter_test/flutter_test.dart';
import 'package:graph_anonymization_app/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const NetGUCApp());
    expect(find.text('NetGUC'), findsOneWidget);
  });
}
