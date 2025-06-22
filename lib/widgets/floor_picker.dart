import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class FloorPickerButton extends StatelessWidget {
  final int selectedFloor;
  final int numberOfFloors; // Assuming a maximum of 10 floors
  final ValueChanged<int> onFloorSelected;

  const FloorPickerButton({
    super.key,
    required this.numberOfFloors,
    required this.selectedFloor,
    required this.onFloorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _showFloorPicker(context);
      },
      child: Text('Select Floor: $selectedFloor'),
    );
  }

  void _showFloorPicker(BuildContext context) {
    int tempSelected = selectedFloor;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              // Toolbar with Done button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('Done'),
                    onPressed: () {
                      Navigator.pop(context);
                      onFloorSelected(tempSelected);
                    },
                  ),
                ],
              ),

              // Scroll picker
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                  FixedExtentScrollController(initialItem: selectedFloor - 1),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    tempSelected = index + 1;
                  },
                  children: List.generate(numberOfFloors, (index) {
                    final floor = index + 1;
                    return Center(child: Text('Floor $floor'));
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
