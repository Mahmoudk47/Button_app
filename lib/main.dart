import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Button Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ButtonManagerHome(title: 'Button Management Interface'),
    );
  }
}

class ButtonData {
  String label;
  int count;
  Color color;
  String id;

  ButtonData({
    required this.label,
    required this.count,
    required this.color,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'count': count, 'color': color.value};
  }

  factory ButtonData.fromJson(Map<String, dynamic> json) {
    return ButtonData(
      id: json['id'],
      label: json['label'],
      count: json['count'],
      color: Color(json['color']),
    );
  }
}

class ButtonManagerHome extends StatefulWidget {
  const ButtonManagerHome({super.key, required this.title});

  final String title;

  @override
  State<ButtonManagerHome> createState() => _ButtonManagerHomeState();
}

class _ButtonManagerHomeState extends State<ButtonManagerHome> {
  List<ButtonData> buttons = [];
  int totalCount = 0;
  late SharedPreferences prefs;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadButtons();
  }

  Future<void> _loadButtons() async {
    prefs = await SharedPreferences.getInstance();
    final buttonsList = prefs.getStringList('buttons') ?? [];

    if (buttonsList.isNotEmpty) {
      setState(() {
        buttons =
            buttonsList
                .map(
                  (buttonJson) => ButtonData.fromJson(json.decode(buttonJson)),
                )
                .toList();
        _updateTotalCount();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveButtons() async {
    final buttonsList =
        buttons.map((button) => json.encode(button.toJson())).toList();
    await prefs.setStringList('buttons', buttonsList);
  }

  void _updateTotalCount() {
    setState(() {
      totalCount = buttons.fold(0, (sum, button) => sum + button.count);
    });
  }

  void _decrementButtonCount(int index) {
    if (buttons[index].count > 0) {
      setState(() {
        buttons[index].count--;
        _updateTotalCount();
      });
      _saveButtons();
    }
  }

  void _addButton(ButtonData newButton) {
    setState(() {
      buttons.add(newButton);
      _updateTotalCount();
    });
    _saveButtons();
  }

  void _editButton(int index, ButtonData updatedButton) {
    setState(() {
      buttons[index] = updatedButton;
      _updateTotalCount();
    });
    _saveButtons();
  }

  void _deleteButton(int index) {
    setState(() {
      buttons.removeAt(index);
      _updateTotalCount();
    });
    _saveButtons();
  }

  void _showButtonDialog({ButtonData? buttonData, int? index}) {
    final isEditing = buttonData != null;
    final TextEditingController labelController = TextEditingController(
      text: isEditing ? buttonData.label : '',
    );
    final TextEditingController countController = TextEditingController(
      text: isEditing ? buttonData.count.toString() : '10',
    );

    Color selectedColor = isEditing ? buttonData.color : Colors.blue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Button' : 'Add New Button'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Button Label',
                        hintText: 'Enter a label for the button',
                      ),
                    ),
                    TextField(
                      controller: countController,
                      decoration: const InputDecoration(
                        labelText: 'Count',
                        hintText: 'Enter initial count',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Color:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildColorOption(Colors.blue, selectedColor, (color) {
                          setState(() => selectedColor = color);
                        }),
                        _buildColorOption(Colors.red, selectedColor, (color) {
                          setState(() => selectedColor = color);
                        }),
                        _buildColorOption(Colors.green, selectedColor, (color) {
                          setState(() => selectedColor = color);
                        }),
                        _buildColorOption(Colors.yellow, selectedColor, (
                          color,
                        ) {
                          setState(() => selectedColor = color);
                        }),
                        _buildColorOption(Colors.purple, selectedColor, (
                          color,
                        ) {
                          setState(() => selectedColor = color);
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteButton(index!);
                    },
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final label = labelController.text.trim();
                    final countText = countController.text.trim();

                    if (label.isEmpty || countText.isEmpty) {
                      return;
                    }

                    final count = int.tryParse(countText) ?? 0;

                    final newButtonData = ButtonData(
                      label: label,
                      count: count,
                      color: selectedColor,
                      id: isEditing ? buttonData.id : null,
                    );

                    if (isEditing) {
                      _editButton(index!, newButtonData);
                    } else {
                      _addButton(newButtonData);
                    }

                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorOption(
    Color color,
    Color selectedColor,
    Function(Color) onSelect,
  ) {
    final isSelected = color.value == selectedColor.value;

    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Total Count: ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$totalCount',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        buttons.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.touch_app,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No buttons yet',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tap the + button to add your first button',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _showButtonDialog(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Button'),
                                  ),
                                ],
                              ),
                            )
                            : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 200,
                                    childAspectRatio: 1,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: buttons.length,
                              itemBuilder: (context, index) {
                                return CounterButton(
                                  buttonData: buttons[index],
                                  onPressed: () => _decrementButtonCount(index),
                                  onLongPress:
                                      () => _showButtonDialog(
                                        buttonData: buttons[index],
                                        index: index,
                                      ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showButtonDialog,
        tooltip: 'Add Button',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CounterButton extends StatefulWidget {
  final ButtonData buttonData;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;

  const CounterButton({
    super.key,
    required this.buttonData,
    required this.onPressed,
    required this.onLongPress,
  });

  @override
  State<CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<CounterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;
  bool _showGlow = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.buttonData.count > 0) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      widget.onPressed();

      if (widget.buttonData.count == 1) {
        // This will be 0 after the onPressed callback
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            _showGlow = true;
          });
          _confettiController.play();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.buttonData.count == 0;

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: widget.buttonData.color.withOpacity(
                      isCompleted ? 0.7 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow:
                        _showGlow
                            ? [
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                            : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.buttonData.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.buttonData.count}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: pi / 2,
                    maxBlastForce: 5,
                    minBlastForce: 1,
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    gravity: 0.1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
