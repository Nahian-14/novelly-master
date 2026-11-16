import 'package:flutter/material.dart';

class BoiMelaBannerWidget extends StatelessWidget {
  const BoiMelaBannerWidget({
    super.key,
    this.onStallTap,
    this.onEventTap,
  });

  final ValueChanged<String>? onStallTap;
  final VoidCallback? onEventTap;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFE5AE4D);
    const deepInk = Color(0xFF12343B);

    final stalls = [
      {'name': 'Prothoma', 'stall': '#402'},
      {'name': 'Sheba', 'stall': '#115'},
      {'name': 'Batighar', 'stall': '#204'},
      {'name': 'Anyaprokash', 'stall': '#310'},
      {'name': 'UPL', 'stall': '#501'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deepInk, Color(0xFF1A4650), Color(0xFF0F2C32)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.auto_stories_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, color: deepInk, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'EKUSHEY BOI MELA 2025',
                            style: TextStyle(
                              color: deepInk,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onEventTap,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_note_rounded, color: gold, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Events ➔',
                            style: TextStyle(
                              color: gold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Explore Official Boi Mela Stalls & Releases',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Georgia',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Browse publisher pavilions & signing schedules at Suhrawardy Udyan.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: stalls.map((stall) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.storefront_rounded, size: 14, color: gold),
                          label: Text('${stall['name']} ${stall['stall']}'),
                          labelStyle: const TextStyle(
                            color: deepInk,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          onPressed: () => onStallTap?.call(stall['name']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
