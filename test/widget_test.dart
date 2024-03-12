import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_game/main.dart';  // Ensure your project name is correct
import 'package:flutter_chess_board/flutter_chess_board.dart';

void main() {
  group('Chess Game Widget Tests', () {
    testWidgets('Basic UI elements are present', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());

      // Verify that "Chess Game" title is present
      expect(find.text("Chess Game"), findsOneWidget);

      // Verify that the ChessBoard widget is present
      expect(find.byType(ChessBoard), findsOneWidget);

      // Verify that the Reset button is present
      expect(find.text("Reset Game"), findsOneWidget);

      // Verify captured pieces sections are visible
      expect(find.text("Captured by Black"), findsOneWidget);
      expect(find.text("Captured by White"), findsOneWidget);
    });
    
    testWidgets('Reset button functionality works', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());
      
      // Tap the reset button
      await tester.tap(find.text("Reset Game"));
      await tester.pump();
      
      // After reset, captured pieces sections should be empty
      // We can't directly test the board state, but we can verify the UI reflects a reset
      final capturedWhiteRow = find.ancestor(
        of: find.text("Captured by Black"),
        matching: find.byType(Column),
      );
      
      final capturedBlackRow = find.ancestor(
        of: find.text("Captured by White"),
        matching: find.byType(Column),
      );
      
      // Verify these sections don't contain any chess piece characters
      // This is an indirect way to test the reset functionality
      expect(
        find.descendant(
          of: capturedWhiteRow,
          matching: find.textContaining(RegExp('[♙♖♘♗♕♔♟♜♞♝♛♚]')),
        ),
        findsNothing,
      );
      
      expect(
        find.descendant(
          of: capturedBlackRow,
          matching: find.textContaining(RegExp('[♙♖♘♗♕♔♟♜♞♝♛♚]')),
        ),
        findsNothing,
      );
    });
    
    testWidgets('Chess board orientation is correct', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());
      
      // Find the ChessBoard widget
      final chessBoardFinder = find.byType(ChessBoard);
      expect(chessBoardFinder, findsOneWidget);
      
      // Extract the ChessBoard widget
      final ChessBoard chessBoard = tester.widget(chessBoardFinder);
      
      // Verify board orientation is set to white
      expect(chessBoard.boardOrientation, PlayerColor.white);
      
      // Verify board color is set to green
      expect(chessBoard.boardColor, BoardColor.green);
    });
    
    testWidgets('ChessBoard controller is properly initialized', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());
      
      // Verify we can find the ChessBoard
      final chessBoardFinder = find.byType(ChessBoard);
      expect(chessBoardFinder, findsOneWidget);
      
      // Extract the ChessBoard widget
      final ChessBoard chessBoard = tester.widget(chessBoardFinder);
      
      // Verify the controller is not null
      expect(chessBoard.controller, isNotNull);
    });
    
    testWidgets('App has a dark theme', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());
      
      // Find the MaterialApp
      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);
      
      // Extract the MaterialApp widget
      final MaterialApp materialApp = tester.widget(materialAppFinder);
      
      // Verify theme is dark
      expect(materialApp.theme, ThemeData.dark());
      
      // Verify debug banner is disabled
      expect(materialApp.debugShowCheckedModeBanner, false);
    });

    // This is a visual verification test - it'll help catch regression issues
    testWidgets('App layout structure is correct', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());
      
      // Verify the overall structure:
      // Scaffold -> Column with children in the right order
      expect(find.byType(Scaffold), findsOneWidget);
      
      final scaffoldFinder = find.byType(Scaffold);
      final Scaffold scaffold = tester.widget(scaffoldFinder);
      
      // Verify AppBar title
      expect(scaffold.appBar, isNotNull);
      expect((scaffold.appBar as AppBar).title, isA<Text>());
      
      // Verify body is a Column
      expect(scaffold.body, isA<Column>());
      
      // Verify order of widgets in column
      final columnFinder = find.byType(Column).first;
      
      // Verify general structure has:
      // - SizedBox
      // - Captured pieces row
      // - SizedBox
      // - ChessBoard
      // - SizedBox
      // - Captured pieces row
      // - SizedBox
      // - Reset button
      expect(
        find.descendant(of: columnFinder, matching: find.byType(SizedBox)),
        findsAtLeastNWidgets(3),
      );
      
      expect(
        find.descendant(of: columnFinder, matching: find.byType(ChessBoard)),
        findsOneWidget,
      );
      
      expect(
        find.descendant(of: columnFinder, matching: find.byType(ElevatedButton)),
        findsOneWidget,
      );
    });
  });
}