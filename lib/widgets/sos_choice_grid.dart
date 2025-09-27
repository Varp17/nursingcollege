import 'package:flutter/material.dart';

class SosChoiceGrid extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelected;

  const SosChoiceGrid({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.5,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        final isSelected = selected == item;

        return GestureDetector(
          onTap: () => onSelected(item),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Text(
              item,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
