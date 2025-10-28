// lib/Screens/home/simple_location_picker.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SimpleLocationPicker extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final Function(double lat, double lng) onLocationPicked;

  const SimpleLocationPicker({
    Key? key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onLocationPicked,
  }) : super(key: key);

  @override
  State<SimpleLocationPicker> createState() => _SimpleLocationPickerState();
}

class _SimpleLocationPickerState extends State<SimpleLocationPicker> {
  late TextEditingController latController;
  late TextEditingController lngController;

  @override
  void initState() {
    super.initState();
    latController = TextEditingController(
      text: widget.initialLatitude.toStringAsFixed(6),
    );
    lngController = TextEditingController(
      text: widget.initialLongitude.toStringAsFixed(6),
    );
  }

  @override
  void dispose() {
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }

  void _confirmLocation() {
    try {
      final lat = double.parse(latController.text);
      final lng = double.parse(lngController.text);

      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        Get.snackbar(
          'Xato',
          'Noto\'g\'ri koordinatalar',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      widget.onLocationPicked(lat, lng);
      Navigator.pop(context);
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Iltimos to\'g\'ri raqam kiriting',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        title: const Text('Lokatsiyani kiriting'),
        actions: [
          TextButton.icon(
            onPressed: _confirmLocation,
            icon: const Icon(Icons.check, color: Colors.green),
            label: const Text(
              'Yuborish',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hozirgi lokatsiyangiz avtomatik aniqlandi. Kerak bo\'lsa tahrirlashingiz mumkin.',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Latitude input
            const Text(
              'Kenglik (Latitude)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                hintText: '40.5261305',
                prefixIcon: const Icon(Icons.straighten),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: '-90 dan 90 gacha',
              ),
            ),

            const SizedBox(height: 20),

            // Longitude input
            const Text(
              'Uzunlik (Longitude)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                hintText: '70.9281139',
                prefixIcon: const Icon(Icons.straighten_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: '-180 dan 180 gacha',
              ),
            ),

            const SizedBox(height: 32),

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Maslahat:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Google Maps dan koordinata olish uchun:\n'
                    '1. Google Maps ochib, joyni bosing\n'
                    '2. Pastdan chiqadigan oynada koordinatani ko\'ring\n'
                    '3. Koordinatani bosib nusxalang',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
