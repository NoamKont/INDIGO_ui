import 'package:flutter/material.dart';

class BottomSearchBar extends StatelessWidget {
  final List<String> allSuggestions;
  final void Function(String)? onSuggestionSelected;

  const BottomSearchBar({
    super.key,
    required this.allSuggestions,
    this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _buildSearchContainer(context),
    );
  }

  Widget _buildSearchContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _containerDecoration(),
      child: Row(
        children: [
          Expanded(child: _buildAutocompleteField()),
          const SizedBox(width: 12),
          _buildMicButton(),
        ],
      ),
    );
  }

  BoxDecoration _containerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildAutocompleteField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return const Iterable<String>.empty();
        return allSuggestions.where(
              (s) => s.toLowerCase().contains(value.text.toLowerCase()),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration.collapsed(
            hintText: 'Where do you want to go?',
          ),
        );
      },
      onSelected: onSuggestionSelected ??
              (selection) {
            debugPrint('Selected: $selection');
          },
    );
  }

  Widget _buildMicButton() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.pin_drop_outlined, color: Colors.white),
    );
  }
}
