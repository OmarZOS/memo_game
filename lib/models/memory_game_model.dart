import 'dart:async';
import 'dart:math';

class MemoryTile {
  final String content;
  bool isFlipped;
  bool isMatched;
  bool isBomb;

  MemoryTile({
    required this.content,
    this.isFlipped = false,
    this.isMatched = false,
    this.isBomb = false,
  });
}

class MemoryGameModel {
  late List<MemoryTile> tiles;
  MemoryTile? _firstSelectedTile;
  MemoryTile? _secondSelectedTile;
  int? firstSelectedIndex;
  int? secondSelectedIndex;
  int score = 0;
  bool isGameCompleted = false;
  bool bombFound = false; // Flag to indicate bomb was found
  Function? onTilesUpdated; // Callback to notify UI

  void initializeGame() {
    const contents = ['A', 'B', 'C', 'D']; // Reduced to 4 pairs for 3x3 grid
    tiles = (contents + contents)
        .map((content) => MemoryTile(content: content))
        .toList();

    // Add bombs to the grid
    tiles.add(MemoryTile(content: 'BOMB', isBomb: true));

    tiles.shuffle();
    score = 0;
    isGameCompleted = false;
    bombFound = false;
  }

  void flipTile(int index) {
    final tile = tiles[index];
    if (tile.isMatched || tile.isFlipped) return;

    tile.isFlipped = true;

    if (tile.isBomb) {
      _handleBomb();
      return;
    }

    if (_firstSelectedTile == null) {
      _firstSelectedTile = tile;
      firstSelectedIndex = index;
    } else if (_secondSelectedTile == null) {
      _secondSelectedTile = tile;
      secondSelectedIndex = index;
      _checkMatch();
    }
    // Notify UI of tile updates
    onTilesUpdated?.call();
  }

  void _checkMatch() {
    if (_firstSelectedTile != null && _secondSelectedTile != null) {
      final firstTile = _firstSelectedTile;
      final secondTile = _secondSelectedTile;
      final firstIndex = firstSelectedIndex;
      final secondIndex = secondSelectedIndex;

      Timer(const Duration(seconds: 1), () {
        if (firstTile!.content == secondTile!.content) {
          firstTile.isMatched = true;
          secondTile.isMatched = true;
          score += 1; // Increment score for a match
          _checkGameCompletion();
        } else {
          firstTile.isFlipped = false;
          secondTile.isFlipped = false;
        }
        // Reset indices
        firstSelectedIndex = null;
        secondSelectedIndex = null;
        // Notify UI of tile updates
        onTilesUpdated?.call();
      });

      // Reset the selected tiles immediately after processing
      _firstSelectedTile = null;
      _secondSelectedTile = null;
    }
  }

  void _handleBomb() {
    bombFound = true; // Indicate that a bomb was found
    // Notify UI of tile updates
    onTilesUpdated?.call();
  }

  void _checkGameCompletion() {
    isGameCompleted = tiles.every((tile) => tile.isMatched || tile.isBomb);
  }

  void resetGame() {
    initializeGame();
    onTilesUpdated?.call(); // Notify UI of reset
  }
}
