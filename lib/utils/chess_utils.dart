// Convert a square index to chess notation (e.g., 0 -> a8, 63 -> h1)
String squareToNotation(int square) {
  int file = square % 8;
  int rank = 7 - (square ~/ 8);
  
  String fileStr = String.fromCharCode('a'.codeUnitAt(0) + file);
  String rankStr = (rank + 1).toString();
  
  return fileStr + rankStr;
}

// Count pieces in FEN string
Map<String, int> countPieces(String fen) {
  // Get just the piece placement part of the FEN
  String piecePlacement = fen.split(' ')[0];
  
  // Create a map to count each type of piece
  Map<String, int> pieceCounts = {};
  
  // Process the FEN string
  for (String char in piecePlacement.split('')) {
    // Skip slashes (row separators)
    if (char == '/') continue;
    
    // If it's a digit, it represents empty squares
    if (RegExp(r'[1-8]').hasMatch(char)) continue;
    
    // Otherwise it's a piece
    pieceCounts[char] = (pieceCounts[char] ?? 0) + 1;
  }
  
  return pieceCounts;
}

// Map of piece icons
final Map<String, String> pieceIcons = {
  'p': '♙', 'r': '♖', 'n': '♘', 'b': '♗', 'q': '♕', 'k': '♔', // White pieces
  'P': '♟', 'R': '♜', 'N': '♞', 'B': '♝', 'Q': '♛', 'K': '♚', // Black pieces
};