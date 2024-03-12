import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'dart:math';
import '../utils/chess_utils.dart';

// Main Chess Game Screen
class ChessGameScreen extends StatefulWidget {
  final bool isSinglePlayer;
  final PlayerColor playerColor;

  const ChessGameScreen({
    Key? key, 
    required this.isSinglePlayer, 
    required this.playerColor,
  }) : super(key: key);

  @override
  _ChessGameScreenState createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  final ChessBoardController _controller = ChessBoardController();
  String _previousFen = "";
  String _gameStatus = "";
  bool _gameOver = false;
  late PlayerColor _currentTurn = PlayerColor.white; // White starts
  
  List<String> _capturedWhite = []; // Captured pieces for White
  List<String> _capturedBlack = []; // Captured pieces for Black
  List<String> _moves = []; // List of moves played

  // Random number generator for computer moves
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onBoardChange);
    _previousFen = _controller.getFen();
    
    // If single player and computer's turn is first (player chose black)
    if (widget.isSinglePlayer && widget.playerColor == PlayerColor.black) {
      // Allow the board to initialize first
      Future.delayed(const Duration(milliseconds: 500), () {
        _makeComputerMove();
      });
    }
  }

  void _onBoardChange() {
    setState(() {
      String currentFen = _controller.getFen();
      if (currentFen != _previousFen) {
        _updateCapturedPieces(_previousFen, currentFen);
        _previousFen = currentFen;
        
        // Toggle current turn
        _currentTurn = _currentTurn == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
        
        // After each valid move, check for game end conditions
        _checkGameStatus();
        
        // In single player mode, make computer move if it's computer's turn
        if (widget.isSinglePlayer && !_gameOver && _currentTurn != widget.playerColor) {
          // Add a small delay to make it feel more natural
          Future.delayed(const Duration(milliseconds: 500), () {
            _makeComputerMove();
          });
        }
      }
    });
  }

  void _makeComputerMove() {
    try {
      // Get possible moves using the controller's method
      final moves = _controller.getPossibleMoves();
      print("Available moves: ${moves.length}");
      
      if (moves.isNotEmpty) {
        // Randomly select a move
        final randomIndex = _random.nextInt(moves.length);
        final randomMove = moves[randomIndex];
        
        print("Computer selected move: ${randomMove.from} to ${randomMove.to}");
        
        // Convert indices to algebraic notation
        final from = squareToNotation(randomMove.from);
        final to = squareToNotation(randomMove.to);
        
        print("Move in notation: $from to $to");
        
        // Make the move using the controller
        _controller.makeMove(from: from, to: to);
        
        // Manually update state after a short delay
        Future.delayed(Duration(milliseconds: 100), () {
          final newFen = _controller.getFen();
          if (newFen != _previousFen) {
            setState(() {
              _updateCapturedPieces(_previousFen, newFen);
              _previousFen = newFen;
              _currentTurn = _currentTurn == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
            });
          }
        });
      } else {
        print("No moves available for computer");
        _showGameOverDialog("Game over - no moves available");
      }
    } catch (e) {
      print("Error making computer move: $e");
    }
  }

  void _checkGameStatus() {
    // For simplicity, just check if kings are missing
    if (!_previousFen.contains('K')) {
      _showGameOverDialog("White king captured! Black wins");
    } else if (!_previousFen.contains('k')) {
      _showGameOverDialog("Black king captured! White wins");
    }
    
    // Also check for a potential draw condition after many moves
    if (_moves.length > 20 && _capturedWhite.isEmpty && _capturedBlack.isEmpty) {
      _showPossibleDrawDialog();
    }
  }

  void _showPossibleDrawDialog() {
    if (!_gameOver) {
      _gameOver = true;
      _gameStatus = "Possible Draw";
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: const Text("Game Status", 
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text("Many moves without captures. Possible draw?",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _gameOver = false;
                    _gameStatus = "";
                  });
                },
                child: const Text("Continue Game"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetGame();
                },
                child: const Text("New Game"),
              ),
            ],
          );
        },
      );
    }
  }

  void _resetGame() {
    setState(() {
      _controller.resetBoard();
      _capturedWhite.clear();
      _capturedBlack.clear();
      _moves.clear();
      _previousFen = _controller.getFen();
      _gameStatus = "";
      _gameOver = false;
      _currentTurn = PlayerColor.white; // Reset turn to white
      
      // If single player and computer plays first
      if (widget.isSinglePlayer && widget.playerColor == PlayerColor.black) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _makeComputerMove();
        });
      }
    });
  }

  void _updateCapturedPieces(String previousFen, String currentFen) {
    Map<String, int> previousPieces = countPieces(previousFen);
    Map<String, int> currentPieces = countPieces(currentFen);
    
    // Check which pieces were captured
    previousPieces.forEach((piece, count) {
      int currentCount = currentPieces[piece] ?? 0;
      if (currentCount < count) {
        // A piece was captured
        int capturedCount = count - currentCount;
        for (int i = 0; i < capturedCount; i++) {
          if (piece.toUpperCase() == piece) {
            // Black captured White piece
            _capturedWhite.add(piece);
          } else {
            // White captured Black piece
            _capturedBlack.add(piece);
          }
        }
      }
    });
    
    // Add to move history
    _moves.add(currentFen);
  }

  void _showGameOverDialog(String message) {
    if (!_gameOver) {
      _gameOver = true;
      _gameStatus = message;
      
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: const Text("Game Over", 
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(message,
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetGame();
                  },
                  child: const Text("New Game"),
                ),
                TextButton(
                  onPressed: () {
                    // Return to menu
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text("Main Menu"),
                ),
              ],
            );
          },
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onBoardChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.isSinglePlayer 
            ? "Single Player - ${widget.playerColor == PlayerColor.white ? 'White' : 'Black'}"
            : "Chess Game - Multiplayer",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.black,
                  title: const Text('Return to Menu?', style: TextStyle(color: Colors.white)),
                  content: const Text('Current game progress will be lost.', style: TextStyle(color: Colors.white)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('Return'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildCapturedPiecesRow(_capturedWhite, "Captured by Black"),
          const SizedBox(height: 10),
          // Current turn indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Text(
              widget.isSinglePlayer
                  ? _currentTurn == widget.playerColor
                      ? "Your Turn"
                      : "Computer's Turn"
                  : _currentTurn == PlayerColor.white
                      ? "White's Turn"
                      : "Black's Turn",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Game status indicator
          if (_gameStatus.isNotEmpty && !_gameOver)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Text(
                _gameStatus,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: ChessBoard(
                  controller: _controller,
                  boardColor: BoardColor.green,
                  boardOrientation: widget.playerColor, // Set board orientation based on player color
                  enableUserMoves: !widget.isSinglePlayer || _currentTurn == widget.playerColor, // Disable moves when it's computer's turn
                  onMove: () {
                    // We use onMove as a backup to the listener
                    setState(() {
                      String currentFen = _controller.getFen();
                      if (currentFen != _previousFen) {
                        _updateCapturedPieces(_previousFen, currentFen);
                        _previousFen = currentFen;
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildCapturedPiecesRow(_capturedBlack, "Captured by White"),
          const SizedBox(height: 20),
          // Styled reset button
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
            child: const Text(
              "Reset Game",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCapturedPiecesRow(List<String> pieces, String label) {
    return Column(
      children: [
        // Styled label
        Text(
          label, 
          style: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        // Container for captured pieces
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: pieces.isEmpty 
              ? [
                  Text(
                    "None",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ]
              : pieces.map((piece) => 
                  Text(
                    pieceIcons[piece]!, 
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                ).toList(),
          ),
        ),
      ],
    );
  }
}