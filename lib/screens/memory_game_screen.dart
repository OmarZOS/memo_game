import 'package:flutter/material.dart';
import '../models/memory_game_model.dart';
import 'dart:math' as math;
import 'dart:async';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with TickerProviderStateMixin {
  late MemoryGameModel _gameModel;
  final Map<int, AnimationController> _controllers = {};
  final Map<int, Animation<double>> _animations = {};

  @override
  void initState() {
    super.initState();
    _gameModel = MemoryGameModel();
    _gameModel.onTilesUpdated = _refreshUI; // Set callback for tile updates
    _gameModel.initializeGame();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Dispose existing controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _animations.clear();

    // Create new controllers for each tile
    for (var i = 0; i < _gameModel.tiles.length; i++) {
      _controllers[i] = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _animations[i] = Tween<double>(
        begin: 0,
        end: math.pi,
      ).animate(_controllers[i]!);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _refreshUI() {
    setState(() {});
    if (_gameModel.bombFound) {
      Future.delayed(
        const Duration(seconds: 1),
        _showBombDialog,
      ); // Add latency for bomb effect
    }
  }

  void _onTileTap(int index) {
    if (_gameModel.firstSelectedIndex != null &&
        _gameModel.secondSelectedIndex != null) {
      return;
    }

    // Start the animation first
    _controllers[index]?.forward().then((_) {
      // Update the game state after animation starts
      _gameModel.flipTile(index);
    });

    // Handle second tile
    if (_gameModel.firstSelectedIndex != null &&
        _gameModel.firstSelectedIndex != index) {
      Timer(const Duration(milliseconds: 100), () {
        if (!mounted) return;

        final firstIndex = _gameModel.firstSelectedIndex;
        final secondIndex = _gameModel.secondSelectedIndex;

        if (firstIndex != null && secondIndex != null) {
          final firstTile = _gameModel.tiles[firstIndex];
          final secondTile = _gameModel.tiles[secondIndex];

          if (!firstTile.isMatched && !secondTile.isMatched) {
            _controllers[firstIndex]?.reverse();
            _controllers[secondIndex]?.reverse();
          }
        }
      });
    }
  }

  void _resetGame() {
    _gameModel.resetGame();
    _initializeAnimations();
  }

  void _showBombDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent clicking away
      builder: (context) => AlertDialog(
        title: Center(child: const Text('Bomb Found!')),
        content: const Text('A bomb was found! The game will reset.'),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTileColor(MemoryTile tile) {
    if (tile.isFlipped || tile.isMatched) {
      return Colors.white; // White for flipped/matched cards
    } else {
      return Colors.grey.shade300; // Gentle grey for card back
    }
  }

  Widget _buildTile(MemoryTile tile, int index) {
    return GestureDetector(
      onTap: () => _onTileTap(index),
      child: AnimatedBuilder(
        animation: _animations[index] ?? kAlwaysDismissedAnimation,
        builder: (context, child) {
          final rotation = _animations[index]?.value ?? 0.0;
          final isBack = rotation > math.pi / 2;
          final showContent = rotation > math.pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotation),
            alignment: Alignment.center,
            child: Card(
              color: _getTileColor(tile),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: BorderSide(color: Colors.grey.shade400, width: 2.0),
              ),
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: showContent ? 1.0 : 0.0,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..rotateY(isBack ? math.pi : 0),
                    alignment: Alignment.center,
                    child: tile.isFlipped || tile.isMatched
                        ? _buildTileContent(tile)
                        : SizedBox(
                            width: 40,
                            height: 40,
                            // child: Image.asset(
                            //   'assets/card_background.png',
                            //   fit: BoxFit.contain,
                            // ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Memory Game')),
        backgroundColor: Colors.green.shade200, // Set AppBar background color
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 8.0,
            ),
            child: Text(
              'Score: ${_gameModel.score}',
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(
                16.0,
              ), // Add more padding around the grid
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 columns for 3x3 grid
                ),
                itemCount: _gameModel.tiles.length,
                itemBuilder: (context, index) =>
                    _buildTile(_gameModel.tiles[index], index),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(
              16.0,
            ), // Add more padding around the reset button
            child: ElevatedButton(
              onPressed: _resetGame,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(), // Make the button circular
                padding: const EdgeInsets.all(24.0), // Increase button size
                backgroundColor: Colors.green.shade400, // Button color
              ),
              child: const Icon(
                Icons.refresh, // Use refresh icon
                size: 32.0, // Larger icon size
                color: Colors.white, // Icon color
              ),
            ),
          ),
          if (_gameModel.isGameCompleted)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Congratulations! You completed the game!',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTileContent(MemoryTile tile) {
    if (tile.isMatched) {
      return const Icon(Icons.check, color: Colors.green, size: 24.0);
    } else if (tile.isBomb) {
      return const Icon(Icons.grass, color: Color.fromARGB(255, 134, 121, 4), size: 24.0);
    } else {
      return Text(
        tile.content,
        style: const TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    }
  }
}
