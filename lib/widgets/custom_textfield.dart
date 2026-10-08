// widgets/custom_textfield.dart
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'PhoneNumberInput.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? initialValue;
  final bool isRequired;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.initialValue,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Text Field
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          readOnly: readOnly,
          textInputAction: textInputAction,
          focusNode: focusNode,
          autofocus: autofocus,
          initialValue: initialValue,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryOrange,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
        ),
      ],
    );
  }
}

// Specialized TextField variants
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final bool isRequired;
  final bool enabled;

  const EmailTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.isRequired = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: 'Email',
      hintText: 'Masukkan email Anda',
      keyboardType: TextInputType.emailAddress,
      prefixIcon: const Icon(Icons.email),
      enabled: enabled,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Email harus diisi';
        }
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(
            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
          );
          if (!emailRegex.hasMatch(value)) {
            return 'Format email tidak valid';
          }
        }
        return null;
      },
      onChanged: onChanged,
      isRequired: isRequired,
    );
  }
}

class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final bool isRequired;
  final bool showVisibilityToggle;

  const PasswordTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.isRequired = true,
    this.showVisibilityToggle = true,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      label: 'Password',
      hintText: 'Masukkan password Anda',
      obscureText: _obscureText,
      enabled: true,
      keyboardType: TextInputType.visiblePassword,
      prefixIcon: const Icon(Icons.lock),
      suffixIcon: widget.showVisibilityToggle
          ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            )
          : null,
      validator: (value) {
        if (widget.isRequired && (value == null || value.isEmpty)) {
          return 'Password harus diisi';
        }
        if (value != null && value.isNotEmpty && value.length < 6) {
          return 'Password minimal 6 karakter';
        }
        return null;
      },
      onChanged: widget.onChanged,
      isRequired: widget.isRequired,
    );
  }
}

class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final bool isRequired;
  final bool enabled;

  const PhoneTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.isRequired = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return PhoneNumberInput(
      onChanged: onChanged ?? (value) {},
      // Untuk validasi, bisa tambahkan parameter tambahan jika perlu
    );
  }
}

class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String hintText;
  final bool enabled;

  const SearchTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Cari restoran atau menu...',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: '',
      hintText: hintText,
      enabled: enabled,
      prefixIcon: const Icon(Icons.search, color: Colors.grey),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
