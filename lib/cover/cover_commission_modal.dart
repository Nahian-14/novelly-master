import 'package:flutter/material.dart';

class CoverCommissionModal extends StatefulWidget {
  const CoverCommissionModal({
    super.key,
    required this.artistName,
    this.artistAccountId = '',
  });

  final String artistName;
  final String artistAccountId;

  @override
  State<CoverCommissionModal> createState() => _CoverCommissionModalState();
}

class _CoverCommissionModalState extends State<CoverCommissionModal> {
  int _currentStep = 0;
  bool _isCustomArt = true;
  String _formatOption = 'E-book & Print Jacket';
  String _deliverySpeed = 'Standard (5 Days)';
  final _titleController = TextEditingController();
  final _conceptController = TextEditingController();

  int get _calculatedPrice {
    int basePrice = _isCustomArt ? 5000 : 1500;
    if (_formatOption == 'E-book & Print Jacket') basePrice += 1000;
    if (_formatOption == 'Hardcover Collector Edition') basePrice += 1800;
    if (_deliverySpeed == 'Express Rush (48 Hours)') basePrice += 1200;
    return basePrice;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryInk = Color(0xFF173B43);
    const accentGold = Color(0xFFC89543);
    const paperBg = Color(0xFFF4F0E7);

    return Dialog(
      backgroundColor: paperBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.palette_outlined, color: accentGold, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Commission Cover Art',
                          style: TextStyle(
                            color: primaryInk,
                            fontFamily: 'Georgia',
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'With ${widget.artistName}',
                          style: const TextStyle(
                            color: Color(0xFF777873),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: primaryInk),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),
              // Step Progress Bar
              Row(
                children: List.generate(4, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isActive ? accentGold : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(),
                ),
              ),
              const SizedBox(height: 12),
              // Price estimation footer banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryInk,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Total',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          'Real-Time Quote',
                          style: TextStyle(
                            color: accentGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '৳$_calculatedPrice',
                      style: const TextStyle(
                        color: accentGold,
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryInk,
                          side: const BorderSide(color: primaryInk),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < 3) {
                          setState(() => _currentStep++);
                        } else {
                          _submitCommission();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryInk,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_currentStep == 3 ? 'Submit Request 🚀' : 'Next Step ➔'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1: Choose Artwork Type',
              style: TextStyle(
                color: Color(0xFF173B43),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildSelectableCard(
              title: 'Custom Illustrated Cover',
              subtitle: 'Unique bespoke illustration crafted specifically for your manuscript concept & vision.',
              price: 'From ৳5,000',
              selected: _isCustomArt,
              onTap: () => setState(() => _isCustomArt = true),
            ),
            const SizedBox(height: 12),
            _buildSelectableCard(
              title: 'Premade Cover Design',
              subtitle: 'Select from available portfolio templates customized with your title & author typography.',
              price: 'From ৳1,500',
              selected: !_isCustomArt,
              onTap: () => setState(() => _isCustomArt = false),
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2: Format & Dimensions',
              style: TextStyle(
                color: Color(0xFF173B43),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              'E-book Standard (Digital Only)',
              'E-book & Print Jacket',
              'Hardcover Collector Edition',
            ].map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSelectableCard(
                  title: opt,
                  subtitle: opt.contains('Hardcover')
                      ? 'Includes front, back, spine & dust jacket flap dimensions.'
                      : opt.contains('Jacket')
                          ? 'Includes front cover, spine, and back cover layouts.'
                          : 'High-resolution RGB file optimized for Kindle & e-readers.',
                  price: opt.contains('Hardcover')
                      ? '+৳1,800'
                      : opt.contains('Jacket')
                          ? '+৳1,000'
                          : 'Included',
                  selected: _formatOption == opt,
                  onTap: () => setState(() => _formatOption = opt),
                ),
              ),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 3: Manuscript Concept & Notes',
              style: TextStyle(
                color: Color(0xFF173B43),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Book Title',
                hintText: 'e.g., Rain over Old Dhaka',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _conceptController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Visual Concept & Synopsis',
                hintText: 'Describe key themes, colors, mood, or specific elements (e.g. monsoon rain, vintage calligraphy).',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );

      case 3:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 4: Delivery Speed',
              style: TextStyle(
                color: Color(0xFF173B43),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              'Standard (5 Days)',
              'Express Rush (48 Hours)',
            ].map(
              (speed) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSelectableCard(
                  title: speed,
                  subtitle: speed.contains('Rush')
                      ? 'Priority queue with initial drafts within 24 hours.'
                      : 'Standard delivery with up to 3 revision cycles.',
                  price: speed.contains('Rush') ? '+৳1,200' : 'Included',
                  selected: _deliverySpeed == speed,
                  onTap: () => setState(() => _deliverySpeed = speed),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildSelectableCard({
    required String title,
    required String subtitle,
    required String price,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFE9E4D8).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFC89543) : const Color(0xFFDDD5C7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? const Color(0xFFC89543) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF173B43),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF777873),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              price,
              style: TextStyle(
                color: selected ? const Color(0xFFC89543) : const Color(0xFF173B43),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitCommission() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Commission request submitted to ${widget.artistName}! Total: ৳$_calculatedPrice',
        ),
        backgroundColor: const Color(0xFF173B43),
      ),
    );
  }
}
