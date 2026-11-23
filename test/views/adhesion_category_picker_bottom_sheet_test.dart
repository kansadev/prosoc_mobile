import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/views/screens/at/widgets/adhesion_category_picker_bottom_sheet.dart';

void main() {
  testWidgets('affiche les trois parcours et renvoie la catégorie choisie', (
    tester,
  ) async {
    late Future<String?> selection;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                selection = AdhesionCategoryPickerBottomSheet.show(context);
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Particulier'), findsOneWidget);
    expect(find.text('Structure'), findsOneWidget);
    expect(find.text('Entreprise'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('adhesion-category-STRUCTURE')));
    await tester.pumpAndSettle();

    expect(await selection, 'STRUCTURE');
  });
}
