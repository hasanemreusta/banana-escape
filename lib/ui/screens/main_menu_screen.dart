import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/config/app_copy.dart';
import 'package:banana_escape/models/game_profile.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/services/app_services.dart';
import 'package:banana_escape/ui/screens/gameplay_screen.dart';
import 'package:banana_escape/ui/widgets/banana_preview.dart';
import 'package:banana_escape/ui/widgets/daily_reward_card.dart';
import 'package:banana_escape/ui/widgets/menu_stat_chip.dart';
import 'package:banana_escape/ui/widgets/mission_card.dart';
import 'package:banana_escape/ui/widgets/skin_preview_card.dart';
import 'package:flutter/material.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({
    super.key,
    required this.services,
  });

  final AppServices services;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  GameProfile get profile => widget.services.profile;

  @override
  void initState() {
    super.initState();
    widget.services.audio.playMenuMusic();
  }

  Future<void> _toggleSound() async {
    await widget.services.audio.playButton();
    final updated = profile.copyWith(soundOn: !profile.soundOn);
    await widget.services.saveProfile(updated);
    if (updated.soundOn) {
      await widget.services.audio.playMenuMusic();
    } else {
      await widget.services.audio.stopMusic();
    }
    setState(() {});
  }

  Future<void> _startGame() async {
    await widget.services.audio.playButton();
    await widget.services.audio.stopMusic();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameplayScreen(services: widget.services),
      ),
    );
    await widget.services.audio.playMenuMusic();
    setState(() {});
  }

  Future<void> _claimDailyReward() async {
    await widget.services.audio.playButton();
    final now = DateTime.now();
    final current = profile;
    if (!current.canClaimDailyReward(now)) {
      return;
    }
    final reward = current.dailyRewardState.pendingReward(now);
    await widget.services.saveProfile(current.claimDailyReward(now));
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily bunch collected: +$reward coins'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSkinAction(BananaSkin skin) async {
    await widget.services.audio.playButton();
    final current = profile;
    String message;

    if (skin.id == current.equippedSkinId) {
      message = '${skin.name} already equipped.';
    } else if (skin.isOwned(current.ownedSkinIds)) {
      await widget.services.saveProfile(current.equipSkin(skin.id));
      message = '${skin.name} equipped.';
    } else if (current.canUnlockSkin(skin)) {
      await widget.services.saveProfile(current.unlockSkin(skin));
      message = '${skin.name} unlocked and equipped.';
    } else {
      final missing = skin.cost - current.totalCoins;
      message = 'Need $missing more coins for ${skin.name}.';
    }

    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final equippedSkin = BananaSkins.byId(profile.equippedSkinId);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF85DBFF),
              Color(0xFFFFF4C7),
              Color(0xFFFFD98B),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: _MenuBackdrop(),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight - 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppCopy.gameTitle,
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.ink,
                                        height: 0.96,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      AppCopy.menuTagline,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.orange,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      AppCopy.menuSubtitle,
                                      style: TextStyle(
                                        color: AppColors.softInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                onPressed: _toggleSound,
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.88),
                                ),
                                icon: Icon(profile.soundOn
                                    ? Icons.volume_up
                                    : Icons.volume_off),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _HeroCard(
                            onPlay: _startGame,
                            equippedSkin: equippedSkin,
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              MenuStatChip(
                                label: 'High Score',
                                value: '${profile.highScore}',
                                icon: Icons.emoji_events_rounded,
                              ),
                              MenuStatChip(
                                label: 'Total Coins',
                                value: '${profile.totalCoins}',
                                icon: Icons.monetization_on_rounded,
                              ),
                              MenuStatChip(
                                label: 'Runs',
                                value: '${profile.totalRuns}',
                                icon: Icons.repeat_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          DailyRewardCard(
                            state: profile.dailyRewardState,
                            now: DateTime.now(),
                            onClaim: _claimDailyReward,
                          ),
                          const SizedBox(height: 24),
                          const _SectionHeader(
                            title: 'Banana Closet',
                            subtitle:
                                'Future skins are already modeled into the save data.',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 248,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: BananaSkins.all.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final skin = BananaSkins.all[index];
                                return SkinPreviewCard(
                                  skin: skin,
                                  isOwned: skin.isOwned(profile.ownedSkinIds),
                                  isEquipped: skin.id == profile.equippedSkinId,
                                  availableCoins: profile.totalCoins,
                                  onPressed: () => _handleSkinAction(skin),
                                  buttonLabel: skin.id == profile.equippedSkinId
                                      ? 'Equipped'
                                      : skin.isOwned(profile.ownedSkinIds)
                                          ? 'Equip'
                                          : 'Buy',
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                          const _SectionHeader(
                            title: 'Mission Board',
                            subtitle:
                                'Short goals that add a bit of "one more run".',
                          ),
                          const SizedBox(height: 10),
                          for (final mission in profile.missionViews) ...[
                            MissionCard(mission: mission),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.swipe_rounded,
                                    color: AppColors.orange),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppCopy.onboarding,
                                    style: TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.onPlay,
    required this.equippedSkin,
  });

  final VoidCallback onPlay;
  final BananaSkin equippedSkin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE56D), Color(0xFFFFA24A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 124,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.24),
                  Colors.white.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.ink.withValues(alpha: 0.0),
                          AppColors.ink.withValues(alpha: 0.18),
                          AppColors.ink.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  bottom: 4,
                  child: Transform.rotate(
                    angle: -0.16,
                    child: Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: BananaPreview(
                        skin: equippedSkin,
                        angle: -0.1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  bottom: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Fast run energy',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Absurd endless runner',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Escape the blender truck\nwith style.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Quick runs, juicy feedback, and a mascot banana that actually feels alive.',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onPlay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: const Text('Play Now'),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: AppColors.ink),
                    SizedBox(width: 8),
                    Text(
                      'Fast restart',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.softInk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MenuBackdrop extends StatelessWidget {
  const _MenuBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MenuBackdropPainter(),
    );
  }
}

class _MenuBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.12),
      82,
      Paint()..color = AppColors.leafGreen.withValues(alpha: 0.1),
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.2),
      66,
      Paint()..color = AppColors.orange.withValues(alpha: 0.1),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.82, size.height * 0.1),
        width: 110,
        height: 110,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );

    final roadPath = Path()
      ..moveTo(size.width * 0.18, size.height)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.78,
        size.width * 0.56,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.58,
        size.width * 0.9,
        size.height * 0.42,
      );
    canvas.drawPath(
      roadPath,
      Paint()
        ..color = AppColors.cream.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      roadPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
