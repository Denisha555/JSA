import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/model/reward_model.dart';

class Reward extends StatefulWidget {
  final RewardModel currentReward;

  const Reward({super.key, required this.currentReward});

  @override
  State<Reward> createState() => _RewardState();
}

class _RewardState extends State<Reward> {
  late RewardModel currentReward;

  @override
  void initState() {
    super.initState();
    currentReward = widget.currentReward;
  }

  @override
  void didUpdateWidget(covariant Reward oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentReward.currentHours !=
        widget.currentReward.currentHours) {
      setState(() {
        currentReward = widget.currentReward;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (currentReward.currentHours / currentReward.requiredHours)
        .clamp(0.0, 1.0);

    final isRewardAvailable1 = currentReward.currentHours >= 10;
    final isRewardAvailable2 = currentReward.currentHours >= 20;

    final nextStageHours = ((currentReward.currentHours / 10).floor() + 1) * 10;
    final hoursToNext = (nextStageHours - currentReward.currentHours).clamp(
      0,
      double.infinity,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Reward Progress',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar with markers
          _buildProgressBar(progress, isRewardAvailable1, isRewardAvailable2),
          const SizedBox(height: 16),

          // Progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentReward.currentHours.toDouble()} h played',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${hoursToNext.toDouble()} h left',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    double progress,
    bool isRewardAvailable1,
    bool isRewardAvailable2,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const markerSize = 32.0;
        final barWidth = constraints.maxWidth;
        final firstMarkerPos = (barWidth * 0.5) - (markerSize / 2);
        final secondMarkerPos = barWidth - markerSize;

        return SizedBox(
          height: 40,
          child: Stack(
            children: [
              // Background bar
              Positioned(
                left: 0,
                right: 0,
                top: 16,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Progress bar with animation
              Positioned(
                left: 0,
                top: 16,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: barWidth * progress,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // First reward marker (10 hours)
              Positioned(
                left: firstMarkerPos,
                top: 4,
                child: _buildRewardMarker(
                  isAvailable: isRewardAvailable1,
                  rewardText: '1 jam gratis',
                  hoursRequired: '10 jam',
                ),
              ),

              // Second reward marker (20 hours)
              Positioned(
                left: secondMarkerPos,
                top: 4,
                child: _buildRewardMarker(
                  isAvailable: isRewardAvailable2,
                  rewardText: '2 jam gratis',
                  hoursRequired: '20 jam',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardMarker({
    required bool isAvailable,
    required String rewardText,
    required String hoursRequired,
  }) {
    return GestureDetector(
      onTap:
          isAvailable
              ? () => _showRewardDialog(rewardText)
              : () => _showRewardRequirementDialog(hoursRequired),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color:
              isAvailable ? Colors.amber : Colors.white.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow:
              isAvailable
                  ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        child: Icon(
          isAvailable ? Icons.card_giftcard : Icons.lock,
          color: isAvailable ? Colors.white : Colors.grey[600],
          size: 18,
        ),
      ),
    );
  }

  void _showRewardDialog(String rewardText) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('🎉 Selamat!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kamu mendapatkan $rewardText!'),
                const SizedBox(height: 12),
                const Text(
                  'Catatan: Reward ini dapat digunakan pada booking selanjutnya dengan konfirmasi admin.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showRewardRequirementDialog(String hoursRequired) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reward Terkunci'),
            content: Text(
              'Mainkan hingga $hoursRequired untuk membuka reward ini.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }
}
