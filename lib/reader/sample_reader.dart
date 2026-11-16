import 'package:flutter/material.dart';

class SampleReaderScreen extends StatefulWidget {
  const SampleReaderScreen({
    super.key,
    required this.title,
    required this.author,
    this.sampleContent,
  });

  final String title;
  final String author;
  final String? sampleContent;

  @override
  State<SampleReaderScreen> createState() => _SampleReaderScreenState();
}

class _SampleReaderScreenState extends State<SampleReaderScreen> {
  double _fontSize = 17.0;
  double _lineHeight = 1.6;
  Color _paperColor = const Color(0xFFF4F0E7);
  Color _textColor = const Color(0xFF173B43);
  String _fontFamily = 'Georgia';

  final List<Map<String, dynamic>> _paperTints = [
    {
      'name': 'Paper Cream',
      'bg': const Color(0xFFF4F0E7),
      'text': const Color(0xFF173B43),
    },
    {
      'name': 'Warm Sepia',
      'bg': const Color(0xFFFBF0D9),
      'text': const Color(0xFF5F4B32),
    },
    {
      'name': 'Midnight Ink',
      'bg': const Color(0xFF0D1F23),
      'text': const Color(0xFFE2F1F3),
    },
    {
      'name': 'Dark Slate',
      'bg': const Color(0xFF1A2830),
      'text': const Color(0xFFE8F2F8),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final sampleText = widget.sampleContent ?? _getSampleTextForBook(widget.title);
    final wordCount = sampleText.split(RegExp(r'\s+')).length;
    final estimatedMinutes = (wordCount / 200).ceil();

    return Scaffold(
      backgroundColor: _paperColor,
      appBar: AppBar(
        backgroundColor: _paperColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: _textColor,
                fontFamily: 'Georgia',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'by ${widget.author}',
              style: TextStyle(
                color: _textColor.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.text_format_rounded, color: _textColor, size: 24),
            tooltip: 'Typography Options',
            onPressed: _showTypographySheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: _textColor.withValues(alpha: 0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories_outlined, color: _textColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Chapter 1 Teaser • ~$estimatedMinutes min read ($wordCount words)',
                    style: TextStyle(
                      color: _textColor.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          '— CHAPTER I —',
                          style: TextStyle(
                            color: _textColor.withValues(alpha: 0.5),
                            letterSpacing: 2,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        sampleText,
                        style: TextStyle(
                          color: _textColor,
                          fontFamily: _fontFamily,
                          fontSize: _fontSize,
                          height: _lineHeight,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Divider(color: _textColor.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'End of Sample Teaser',
                          style: TextStyle(
                            color: _textColor.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTypographySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _paperColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      Text(
                        'Typography & Theme',
                        style: TextStyle(
                          color: _textColor,
                          fontFamily: 'Georgia',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: _textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Font Size: ${_fontSize.toInt()}pt',
                      style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                  Slider(
                    value: _fontSize,
                    min: 14.0,
                    max: 26.0,
                    divisions: 6,
                    activeColor: const Color(0xFFC89543),
                    onChanged: (val) {
                      setState(() => _fontSize = val);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Line Height: ${_lineHeight.toStringAsFixed(1)}',
                      style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                  Slider(
                    value: _lineHeight,
                    min: 1.2,
                    max: 2.2,
                    divisions: 5,
                    activeColor: const Color(0xFFC89543),
                    onChanged: (val) {
                      setState(() => _lineHeight = val);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Paper Tint',
                      style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _paperTints.map((tint) {
                      final isSelected = _paperColor == tint['bg'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _paperColor = tint['bg'] as Color;
                            _textColor = tint['text'] as Color;
                          });
                          setSheetState(() {});
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tint['bg'] as Color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFC89543)
                                  : Colors.grey.withValues(alpha: 0.4),
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  String _getSampleTextForBook(String title) {
    if (title.contains('Nondito Noroke')) {
      return 'The rain fell softly over Old Dhaka, whispering secrets across the ancient terracotta roofs. '
          'In our small courtyard, the fragrance of wet earth mingled with fresh jasmine tea.\n\n'
          'Kholil looked up from his writing desk, his hand pausing over the manuscript. "Stories are not made of grand gestures," he murmured gently. "They are woven from the quiet heartbeats we tend to forget."';
    } else if (title.contains('Misir Ali')) {
      return 'Misir Ali adjusted his spectacles and took a slow sip of cold water. Outside, the night was still, interrupted only by the rustle of dry neem leaves.\n\n'
          '"Every riddle has a logical spine," Misir Ali stated calmly. "What people call supernatural is often just human psychology waiting for a clear-eyed observer."';
    } else {
      return 'The morning sun rose over the banks of the Buriganga River, casting golden reflections across the wooden rowboats. '
          'Every story begins with a choice—to look closely at the light, or to listen to the shadows whispering beneath the tide.\n\n'
          'As the city awakened into a symphony of brass bells, street callers, and rain clouds, a new journey unfolded for those who dare to read between the lines.';
    }
  }
}
