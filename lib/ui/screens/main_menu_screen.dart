import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/config/app_copy.dart';
import 'package:banana_escape/models/game_profile.dart';
import 'package:banana_escape/models/shop_overview.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/models/upgrade.dart';
import 'package:banana_escape/services/app_services.dart';
import 'package:banana_escape/ui/format.dart';
import 'package:banana_escape/ui/screens/gameplay_screen.dart';
import 'package:banana_escape/ui/screens/shop_screen.dart';
import 'package:banana_escape/ui/shop_actions.dart';
import 'package:banana_escape/ui/widgets/banana_stage.dart';
import 'package:banana_escape/ui/widgets/coin_balance_pill.dart';
import 'package:banana_escape/ui/widgets/daily_reward_card.dart';
import 'package:banana_escape/ui/widgets/mission_card.dart';
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
  /// The daily reward pops up by itself once per launch while it is waiting,
  /// then only lives behind its tab — nagging on every return is worse.
  static bool _dailyPromptShown = false;

  GameProfile get profile => widget.services.profile;

  @override
  void initState() {
    super.initState();
    widget.services.audio.playMenuMusic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dailyPromptShown &&
          mounted &&
          profile.canClaimDailyReward(DateTime.now())) {
        _dailyPromptShown = true;
        _openDaily();
      }
    });
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

  Future<void> _openShop([ShopTab tab = ShopTab.upgrades]) async {
    await widget.services.audio.playButton();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopScreen(services: widget.services, initialTab: tab),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _quickBuyShield() async {
    final outcome = await ShopActions(widget.services).buyShield();
    _showMessage(outcome.message);
  }

  Future<void> _openDaily() async {
    await widget.services.audio.playButton();
    if (!mounted) {
      return;
    }
    await _showSheet(
      title: 'Daily Bunch',
      subtitle: 'Come back every day — the reward grows with your streak.',
      child: DailyRewardCard(
        state: profile.dailyRewardState,
        now: DateTime.now(),
        onClaim: _claimDailyReward,
      ),
    );
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
    Navigator.of(context).pop();
    _showMessage('Daily bunch collected: +${formatCoins(reward)} coins');
  }

  Future<void> _openMissions() async {
    await widget.services.audio.playButton();
    if (!mounted) {
      return;
    }
    await _showSheet(
      title: 'Missions',
      subtitle: 'Short goals that add a bit of "one more run".',
      child: Column(
        children: [
          for (final mission in profile.missionViews) ...[
            MissionCard(mission: mission),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _showSheet({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.softInk.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
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
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final equippedSkin = BananaSkins.byId(profile.equippedSkinId);
    final shopOverview = ShopOverview.of(profile);
    final missionsDone =
        profile.missionViews.where((mission) => mission.isComplete).length;
    final dailyReady = profile.canClaimDailyReward(DateTime.now());

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
              child: IgnorePointer(child: _MenuBackdrop()),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    _TopBar(
                      highScore: profile.highScore,
                      coins: profile.totalCoins,
                      soundOn: profile.soundOn,
                      onSound: _toggleSound,
                      onCoins: _openShop,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      AppCopy.gameTitle,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppCopy.menuTagline,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.orange,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = (constraints.maxHeight * 0.6)
                              .clamp(90.0, 210.0)
                              .toDouble();
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _openShop(ShopTab.skins),
                                child: BananaStage(
                                  skin: equippedSkin,
                                  size: size,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _SkinNameTag(
                                skin: equippedSkin,
                                onTap: () => _openShop(ShopTab.skins),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    _LoadoutStrip(
                      shieldCount: profile.shieldCount,
                      canBuyShield: profile.canBuyShield,
                      onQuickShield: _quickBuyShield,
                    ),
                    const SizedBox(height: 12),
                    _PlayButton(onPressed: _startGame),
                    const SizedBox(height: 8),
                    const Text(
                      AppCopy.onboarding,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.softInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _NavTile(
                          icon: Icons.storefront_rounded,
                          label: 'Shop',
                          color: AppColors.orange,
                          badge: shopOverview.affordableCount > 0
                              ? '${shopOverview.affordableCount}'
                              : null,
                          onTap: _openShop,
                        ),
                        _NavTile(
                          icon: Icons.checkroom_rounded,
                          label: 'Skins',
                          color: const Color(0xFF9B59D6),
                          onTap: () => _openShop(ShopTab.skins),
                        ),
                        _NavTile(
                          icon: Icons.flag_rounded,
                          label: 'Missions',
                          color: AppColors.ocean,
                          badge: '$missionsDone/${profile.missionViews.length}',
                          badgeColor: AppColors.ink,
                          onTap: _openMissions,
                        ),
                        _NavTile(
                          icon: Icons.card_giftcard_rounded,
                          label: 'Daily',
                          color: AppColors.leafDeep,
                          badge: dailyReady ? '!' : null,
                          onTap: _openDaily,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.highScore,
    required this.coins,
    required this.soundOn,
    required this.onSound,
    required this.onCoins,
  });

  final int highScore;
  final int coins;
  final bool soundOn;
  final VoidCallback onSound;
  final VoidCallback onCoins;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                formatCoins(highScore),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        CoinBalancePill(coins: coins, onTap: onCoins),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: onSound,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.94),
            foregroundColor: AppColors.ink,
          ),
          icon: Icon(
            soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          ),
        ),
      ],
    );
  }
}

class _SkinNameTag extends StatelessWidget {
  const _SkinNameTag({required this.skin, required this.onTap});

  final BananaSkin skin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                skin.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 8),
              RarityChip(rarity: skin.rarity),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.softInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one button the whole screen leads to. A slow pulse keeps the eye on
/// it without the cheap look of a blinking label.
class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.035).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 66,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, size: 34),
                SizedBox(width: 6),
                Text(
                  'PLAY',
                  style: TextStyle(
                    fontSize: 24,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the next run starts with, sitting right above Play so a shield can
/// be bought on the way in rather than from a screen two taps away.
class _LoadoutStrip extends StatelessWidget {
  const _LoadoutStrip({
    required this.shieldCount,
    required this.canBuyShield,
    required this.onQuickShield,
  });

  final int shieldCount;
  final bool canBuyShield;
  final VoidCallback onQuickShield;

  @override
  Widget build(BuildContext context) {
    final hasShield = shieldCount > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            hasShield ? Icons.shield_rounded : Icons.shield_outlined,
            color: hasShield ? AppColors.leafDeep : AppColors.softInk,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasShield
                  ? 'Shields ×$shieldCount · double-tap in a run'
                  : 'No shields — grab one for tough runs',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
          if (shieldCount < Shop.maxShields)
            FilledButton.icon(
              onPressed: onQuickShield,
              style: FilledButton.styleFrom(
                backgroundColor: canBuyShield
                    ? AppColors.leafGreen
                    : const Color(0xFFD9D4DC),
                foregroundColor:
                    canBuyShield ? Colors.white : AppColors.softInk,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                canBuyShield ? Icons.add_rounded : Icons.lock_rounded,
                size: 18,
              ),
              label: Text(
                formatCoins(Shop.shieldCost),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
    this.badgeColor = AppColors.coral,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                top: -6,
                right: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
