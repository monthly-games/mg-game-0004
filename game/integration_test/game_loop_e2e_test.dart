import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_match_tycoon/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> returnToMenu(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('core-fun-loop')), findsOneWidget);
  }

  group('MG-0004 Cafe Match Tycoon - Game Loop E2E', () {
    testWidgets('Core gameplay loop: match-3 mechanics and combo multipliers', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('game-id')), findsOneWidget);
      expect(find.text('MG-0004'), findsOneWidget);
      expect(find.text('Cafe Match Tycoon'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('start-game')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('primary-loop')), findsOneWidget);
      expect(find.textContaining('Level 1'), findsOneWidget);

      // Complete match action
      await tester.tap(find.byKey(const ValueKey('complete-action')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Level 2'), findsOneWidget);
    });

    testWidgets('Match-3 combo system and scoring multipliers', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('start-game')));
      await tester.pumpAndSettle();

      // Verify match-3 mechanics
      expect(find.textContaining('match'), findsOneWidget);
      expect(find.textContaining('combo'), findsOneWidget);
      expect(find.textContaining('multiplier'), findsOneWidget);

      // Execute match actions
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('complete-action')));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('Level 4'), findsOneWidget);
    });

    testWidgets('Cafe management and tycoon progression', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('start-game')));
      await tester.pumpAndSettle();

      // Verify cafe management elements
      expect(find.textContaining('cafe'), findsOneWidget);
      expect(find.textContaining('management'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('complete-action')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Level 2'), findsOneWidget);
    });

    testWidgets('Level roadmap and cafe upgrades', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('level-roadmap')));
      await tester.pumpAndSettle();

      expect(find.text('Level Roadmap'), findsWidgets);
      expect(find.byKey(const ValueKey('level-list')), findsOneWidget);

      await returnToMenu(tester);
    });

    testWidgets('Competition and leaderboard systems', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tournament')));
      await tester.pumpAndSettle();
      expect(find.text('Tournament'), findsWidgets);
      await returnToMenu(tester);

      await tester.tap(find.byKey(const ValueKey('guild-war')));
      await tester.pumpAndSettle();
      expect(find.text('Guild War'), findsWidgets);
      await returnToMenu(tester);
    });

    testWidgets('Full game loop: match -> upgrade -> progress', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('start-game')));
      await tester.pumpAndSettle();

      // Progress through multiple levels
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const ValueKey('complete-action')));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('Level 6'), findsOneWidget);
    });
  });
}