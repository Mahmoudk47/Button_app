import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:confetti/confetti.dart';

void main() {
  runApp(const ButtonManagerApp());
}

class ButtonManagerApp extends StatelessWidget {
  const ButtonManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Button Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ButtonManagerHome(),
    );
  }
}

class ButtonManagerHome extends StatefulWidget {
  const ButtonManagerHome({super.key});

  @override
  State<ButtonManagerHome> createState() => _ButtonManagerHomeState();
}

class _ButtonManagerHomeState extends State<ButtonManagerHome> {
  List<ButtonData> buttons = [];
  List<ButtonData> originalButtons = [];
  bool hasUnsavedChanges = false;
  final confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    _loadButtons();
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final buttonsJson = prefs.getStringList('buttons') ?? [];
    setState(() {
      buttons =
          buttonsJson
              .map((json) => ButtonData.fromJson(jsonDecode(json)))
              .toList();
      originalButtons = List.from(buttons);
    });
  }

  Future<void> _saveButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final buttonsJson =
        buttons.map((button) => jsonEncode(button.toJson())).toList();
    await prefs.setStringList('buttons', buttonsJson);
    setState(() {
      originalButtons = List.from(buttons);
      hasUnsavedChanges = false;
    });
  }

  void _addButton(ButtonData button) {
    setState(() {
      buttons.add(button);
      hasUnsavedChanges = true;
    });
  }

  void _updateButton(int index, ButtonData button) {
    setState(() {
      buttons[index] = button;
      hasUnsavedChanges = true;
    });
  }

  void _deleteButton(int index) {
    setState(() {
      buttons.removeAt(index);
      hasUnsavedChanges = true;
    });
  }

  void _decrementCount(int index) {
    if (buttons[index].count > 0) {
      setState(() {
        buttons[index].count--;
        hasUnsavedChanges = true;
      });

      if (buttons[index].count == 0) {
        confettiController.play();
      }
    }
  }

  int get totalCount => buttons.fold(0, (sum, button) => sum + button.count);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Card(
                margin: const EdgeInsets.all(16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Total Counter Card
                      TotalCounterCard(totalCount: totalCount),
                      const SizedBox(height: 24.0),

                      // Button Grid
                      Expanded(
                        child:
                            buttons.isEmpty
                                ? const EmptyStateWidget()
                                : ButtonGrid(
                                  buttons: buttons,
                                  onButtonPressed: _decrementCount,
                                  onButtonLongPressed: _showEditDialog,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Confetti effect
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
              ],
            ),
          ),

          // Save Changes Button
          if (hasUnsavedChanges)
            Positioned(
              bottom: 80.0,
              left: 0,
              right: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: _saveButtons,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => ButtonDialog(
            onSave: (button) {
              _addButton(button);
              Navigator.of(context).pop();
            },
          ),
    );
  }

  void _showEditDialog(int index) {
    showDialog(
      context: context,
      builder:
          (context) => ButtonDialog(
            initialButton: buttons[index],
            onSave: (button) {
              _updateButton(index, button);
              Navigator.of(context).pop();
            },
            onDelete: () {
              _deleteButton(index);
              Navigator.of(context).pop();
            },
          ),
    );
  }
}

// Widget for displaying the total count
class TotalCounterCard extends StatelessWidget {
  final int totalCount;

  const TotalCounterCard({super.key, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Total Count',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8.0),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: totalCount + 1, end: totalCount),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 36.0,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for displaying the empty state
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 64.0, color: Colors.grey[400]),
          const SizedBox(height: 16.0),
          Text(
            'No buttons yet',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Create your first button by tapping the + button below',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Widget for displaying the grid of buttons
class ButtonGrid extends StatelessWidget {
  final List<ButtonData> buttons;
  final Function(int) onButtonPressed;
  final Function(int) onButtonLongPressed;

  const ButtonGrid({
    super.key,
    required this.buttons,
    required this.onButtonPressed,
    required this.onButtonLongPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine number of columns based on width
        int crossAxisCount;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4; // Large screens
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3; // Medium screens
        } else {
          crossAxisCount = 2; // Small screens
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.2,
          ),
          itemCount: buttons.length,
          itemBuilder: (context, index) {
            return CustomButton(
              button: buttons[index],
              onPressed: () => onButtonPressed(index),
              onLongPress: () => onButtonLongPressed(index),
            );
          },
        );
      },
    );
  }
}

// Widget for displaying a custom button
class CustomButton extends StatelessWidget {
  final ButtonData button;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;

  const CustomButton({
    super.key,
    required this.button,
    required this.onPressed,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Material(
        color: button.color,
        borderRadius: BorderRadius.circular(12.0),
        elevation: 2.0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  button.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '${button.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Dialog for creating/editing buttons
class ButtonDialog extends StatefulWidget {
  final ButtonData? initialButton;
  final Function(ButtonData) onSave;
  final VoidCallback? onDelete;

  const ButtonDialog({
    super.key,
    this.initialButton,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<ButtonDialog> createState() => _ButtonDialogState();
}

class _ButtonDialogState extends State<ButtonDialog> {
  late TextEditingController labelController;
  late TextEditingController countController;
  late Color selectedColor;
  bool useCustomColor = false;
  final List<Color> standardColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    final initialButton = widget.initialButton;
    labelController = TextEditingController(text: initialButton?.label ?? '');
    countController = TextEditingController(
      text: initialButton?.count.toString() ?? '0',
    );
    selectedColor = initialButton?.color ?? Colors.blue;

    // Check if the initial color is one of the standard colors
    useCustomColor = !standardColors.contains(selectedColor);
  }

  @override
  void dispose() {
    labelController.dispose();
    countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialButton != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Button' : 'Create New Button'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label field
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Enter button label',
              ),
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16.0),

            // Count field
            TextField(
              controller: countController,
              decoration: const InputDecoration(
                labelText: 'Count',
                hintText: 'Enter initial count',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24.0),

            // Color selection
            Row(
              children: [
                const Text('Use custom color:'),
                const SizedBox(width: 8.0),
                Switch(
                  value: useCustomColor,
                  onChanged: (value) {
                    setState(() {
                      useCustomColor = value;
                      if (!useCustomColor &&
                          !standardColors.contains(selectedColor)) {
                        selectedColor = standardColors.first;
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Standard color swatches
            if (!useCustomColor)
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children:
                    standardColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  selectedColor == color
                                      ? Colors.white
                                      : Colors.transparent,
                              width: 3.0,
                            ),
                            boxShadow: [
                              if (selectedColor == color)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4.0,
                                  spreadRadius: 1.0,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),

            // Custom color picker
            if (useCustomColor)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a custom color:'),
                  const SizedBox(height: 8.0),
                  Container(
                    height: 50.0,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  // Simple color slider for demonstration
                  // In a real app, you would use a proper color picker
                  Slider(
                    value: HSVColor.fromColor(selectedColor).hue,
                    min: 0,
                    max: 360,
                    divisions: 360,
                    onChanged: (value) {
                      setState(() {
                        final hsv = HSVColor.fromColor(selectedColor);
                        selectedColor = hsv.withHue(value).toColor();
                      });
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        // Delete button (only for editing)
        if (isEditing && widget.onDelete != null)
          TextButton(
            onPressed: widget.onDelete,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        const Spacer(),
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        // Save button
        ElevatedButton(
          onPressed: () {
            // Validate input
            final label = labelController.text.trim();
            if (label.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a label')),
              );
              return;
            }

            final countText = countController.text.trim();
            final count = int.tryParse(countText) ?? 0;
            if (count < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Count cannot be negative')),
              );
              return;
            }

            // Create button data and save
            final button = ButtonData(
              label: label,
              count: count,
              color: selectedColor,
            );
            widget.onSave(button);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Data class for button
class ButtonData {
  String label;
  int count;
  Color color;

  ButtonData({required this.label, required this.count, required this.color});

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {'label': label, 'count': count, 'color': color.value};
  }

  // Create from JSON
  factory ButtonData.fromJson(Map<String, dynamic> json) {
    return ButtonData(
      label: json['label'] as String,
      count: json['count'] as int,
      color: Color(json['color'] as int),
    );
  }

  // Create a copy with optional new values
  ButtonData copyWith({String? label, int? count, Color? color}) {
    return ButtonData(
      label: label ?? this.label,
      count: count ?? this.count,
      color: color ?? this.color,
    );
  }
}
