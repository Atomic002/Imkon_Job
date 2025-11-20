import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ✅ TELEFON RAQAM INPUT FORMATTER (TO'G'RI VERSIYA)
class PhoneNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Faqat raqamlarni olish
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Maksimal 9 ta raqam
    if (digitsOnly.length > 9) {
      digitsOnly = digitsOnly.substring(0, 9);
    }

    // Format: 90 123 45 67
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 5 || i == 7) {
        formatted += ' ';
      }
      formatted += digitsOnly[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ✅ TELEFON RAQAM VALIDATOR
String? validatePhoneNumber(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Ixtiyoriy maydon
  }

  final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

  if (digitsOnly.length != 9) {
    return 'phone_number_must_9_digits'.tr;
  }

  if (!digitsOnly.startsWith('9')) {
    return 'phone_number_must_start_9'.tr;
  }

  return null;
}

// ✅ TELEFON RAQAM INPUT WIDGET
class PhoneNumberTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final ValueChanged<String>? onChanged;

  const PhoneNumberTextField({
    Key? key,
    required this.controller,
    this.label = 'Telefon raqam',
    this.isRequired = false,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                )
              else
                TextSpan(
                  text: ' (${'optional'.tr})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // TextField
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneNumberInputFormatter()],
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: '90 123 45 67',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            prefixText: '+998 ',
            prefixStyle: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: Colors.grey[600],
              size: 22,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorText: validatePhoneNumber(controller.text),
          ),
        ),

        // Yordam matni
        if (!isRequired) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'phone_help_text'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
