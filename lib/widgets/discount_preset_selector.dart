// widgets/discount_preset_selector.dart
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class DiscountPresetSelector extends StatefulWidget {
  final String selectedPreset;
  final double discountPercent;
  final Function(String preset, double percent) onChanged;

  const DiscountPresetSelector({
    super.key,
    required this.selectedPreset,
    required this.discountPercent,
    required this.onChanged,
  });

  @override
  State<DiscountPresetSelector> createState() => _DiscountPresetSelectorState();
}

class _DiscountPresetSelectorState extends State<DiscountPresetSelector> {
  late TextEditingController _customController;
  final List<String> _presets = ['5', '10', '15', '20', '25', '30', '50', 'custom'];

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController(
      text: widget.selectedPreset == 'custom' && widget.discountPercent > 0
          ? widget.discountPercent.toInt().toString()
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant DiscountPresetSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPreset == 'custom' &&
        _customController.text != widget.discountPercent.toInt().toString()) {
      _customController.text =
          widget.discountPercent > 0 ? widget.discountPercent.toInt().toString() : '';
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _onPresetTapped(String preset) {
    if (preset == 'custom') {
      final customVal = double.tryParse(_customController.text) ?? 0.0;
      widget.onChanged('custom', customVal);
    } else {
      final val = double.parse(preset);
      widget.onChanged(preset, val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Besaran Diskon',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((preset) {
            final isSelected = widget.selectedPreset == preset;
            final label = preset == 'custom' ? 'Custom' : '$preset%';

            return ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryOrange,
              backgroundColor: Colors.grey.shade100,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryOrange : Colors.grey.shade300,
                ),
              ),
              onSelected: (_) => _onPresetTapped(preset),
            );
          }).toList(),
        ),
        if (widget.selectedPreset == 'custom') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Masukkan persentase diskon (1-99)',
              suffixText: '%',
              suffixStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryOrange,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              widget.onChanged('custom', parsed.clamp(0.0, 99.0));
            },
          ),
        ],
      ],
    );
  }
}
