import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../utils/theme.dart';

class PhoneNumberInput extends StatefulWidget {
  final Function(String) onChanged;
  final String? initialCountryCode;
  final String? initialPhoneNumber;
  const PhoneNumberInput({
    Key? key,
    required this.onChanged,
    this.initialCountryCode,
    this.initialPhoneNumber,
  }) : super(key: key);

  @override
  State<PhoneNumberInput> createState() => _PhoneNumberInputState();
}

class _PhoneNumberInputState extends State<PhoneNumberInput> {
  String selectedCountryCode = '+62';
  String selectedCountryISOCode = 'ID'; // ISO code untuk Indonesia
  String phoneNumber = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialCountryCode != null) {
      selectedCountryCode = widget.initialCountryCode!;
    }
    if (widget.initialPhoneNumber != null) {
      phoneNumber = widget.initialPhoneNumber!;
    }
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          selectedCountryCode = '+${country.phoneCode}';
          selectedCountryISOCode = country.countryCode;
        });
        widget.onChanged(
          '$selectedCountryCode${phoneNumber.replaceAll(RegExp(r'^0+'), '')}',
        );
      },
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
        inputDecoration: InputDecoration(
          labelText: 'Cari negara',
          hintText: 'Ketik nama negara',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryOrange, width: 2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _showCountryPicker,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$selectedCountryISOCode ($selectedCountryCode)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: AppColors.primaryOrange),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.primaryOrange,
          ),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.phone,
              controller: TextEditingController(text: phoneNumber)
                ..selection = TextSelection.collapsed(offset: phoneNumber.length),
              decoration: const InputDecoration(
                hintText: 'Nomor Telepon',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) {
                phoneNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
                widget.onChanged(
                  '$selectedCountryCode${phoneNumber.replaceAll(RegExp(r'^0+'), '')}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}