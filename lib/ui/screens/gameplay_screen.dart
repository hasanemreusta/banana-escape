import 'dart:async';
import 'dart:math' as math;

import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/config/game_config.dart';
import 'package:banana_escape/core/game_session_result.dart';
import 'package:banana_escape/core/hud_snapshot.dart';
import 'package:banana_escape/game/banana_escape_game.dart';
import 'package:banana_escape/models/game_profile.dart';
import 'package:banana_escape/models/shop_overview.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/models/upgrade.dart';
import 'package:banana_escape/services/app_services.dart';
import 'package:banana_escape/ui/format.dart';
import 'package:banana_escape/ui/screens/shop_screen.dart';
import 'package:banana_escape/ui/widgets/shop_nudge_card.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({
    super.key,
    required this.services,
  });

  final AppServices services;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  late BananaEscapeGame _game;
  late AnimationController _shakeController;
  late ValueNotifier<HudSnapshot> _hudNotifier;
  late Widget _gameView;
  Timer? _hudTimer;
  GameSessionResult? _lastResult;

  /// A crash waiting on the player's answer to the continue offer. The session
  /// is only applied to the profile once the run is really over.
  GameSessionResult? _pendingRevive;

  /// Set while a continue offer is being answered, so a tap landing together
  /// with the countdown expiring cannot apply the session twice.
  bool _reviveResolving = false;
  bool _paused = false;
  double _dragDistanceX = 0;
  double _dragDistanceYAbs = 0;
  bool _swipeConsumed = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _hudNotifier = ValueNotifier(HudSnapshot.empty);
    _createGame();
  }

  @override
  void dispose() {
    _hudTimer?.cancel();
    _hudNotifier.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _createGame() {
    _hudTimer?.cancel();
    _lastResult = null;
    _pendingRevive = null;
    _reviveResolving = false;
    _paused = false;
    _hudNotifier.value = HudSnapshot.empty;
    unawaited(widget.services.audio.playGameplayMusic());
    _game = BananaEscapeGame(
      audio: widget.services.audio,
      skin: BananaSkins.byId(widget.services.profile.equippedSkinId),
      loadout: widget.services.profile.runLoadout,
      // Saved the moment it breaks, so quitting mid-run cannot refund it.
      onShieldUsed: () => unawaited(
        widget.services.saveProfile(widget.services.profile.consumeShield()),
      ),
      onGameOver: (result) async {
        _shakeController.forward(from: 0);
        unawaited(widget.services.audio.pauseMusic());
        if (!mounted) {
          return;
        }
        _hudNotifier.value = _game.hudSnapshot;
        if (widget.services.profile.totalCoins >= _reviveCost) {
          setState(() {
            _pendingRevive = result;
          });
          return;
        }
        await _finishSession(result);
      },
    );
    _gameView = RepaintBoundary(
      child: GameWidget(game: _game),
    );

    _hudTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted || _paused || _runStopped) {
        return;
      }
      final nextHud = _game.hudSnapshot;
      if (nextHud == _hudNotifier.value) {
        return;
      }
      _hudNotifier.value = nextHud;
    });
  }

  int get _reviveCost => Shop.reviveCost(_game.revivesUsed);

  Future<void> _finishSession(GameSessionResult result) async {
    final updated = widget.services.profile.applySession(result);
    await widget.services.saveProfile(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingRevive = null;
      _lastResult = result;
    });
  }

  Future<void> _acceptRevive() async {
    final cost = _reviveCost;
    final profile = widget.services.profile;
    if (_pendingRevive == null ||
        _reviveResolving ||
        profile.totalCoins < cost) {
      return;
    }
    _reviveResolving = true;
    await widget.services.audio.playButton();
    await widget.services.saveProfile(profile.spendCoins(cost));
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingRevive = null;
      _reviveResolving = false;
    });
    _game.revive();
    unawaited(widget.services.audio.resumeMusic());
  }

  Future<void> _declineRevive() async {
    final result = _pendingRevive;
    if (result == null || _reviveResolving) {
      return;
    }
    _reviveResolving = true;
    await widget.services.audio.playButton();
    await _finishSession(result);
    _reviveResolving = false;
  }

  bool get _runStopped => _lastResult != null || _pendingRevive != null;

  Future<void> _togglePause() async {
    if (_runStopped) {
      return;
    }
    await widget.services.audio.playButton();
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _game.pauseEngine();
      } else {
        _game.resumeEngine();
      }
    });
    if (_paused) {
      await widget.services.audio.pauseMusic();
    } else {
      await widget.services.audio.resumeMusic();
    }
  }

  Future<void> _restart() async {
    await widget.services.audio.playButton();
    setState(_createGame);
  }

  Future<void> _openShop(ShopTab tab) async {
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

  Future<void> _backToMenu() async {
    await widget.services.audio.playButton();
    await widget.services.audio.stopMusic();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _handleSwipeStart(DragStartDetails details) {
    _dragDistanceX = 0;
    _dragDistanceYAbs = 0;
    _swipeConsumed = false;
  }

  void _handleSwipeUpdate(DragUpdateDetails details) {
    if (_runStopped || _paused || _swipeConsumed) {
      return;
    }
    _dragDistanceX += details.delta.dx;
    _dragDistanceYAbs += details.delta.dy.abs();

    final hasEnoughDistance =
        _dragDistanceX.abs() >= GameConfig.swipeThreshold;
    final horizontalDominant =
        _dragDistanceX.abs() > (_dragDistanceYAbs * 0.9);
    if (!hasEnoughDistance || !horizontalDominant) {
      return;
    }

    _swipeConsumed = true;
    _triggerLaneMove(_dragDistanceX < 0 ? -1 : 1);
  }

  void _handleSwipeEnd(DragEndDetails details) {
    if (_runStopped || _paused) {
      _resetSwipeState();
      return;
    }
    if (!_swipeConsumed) {
      final velocity = details.velocity.pixelsPerSecond;
      final fastHorizontal =
          velocity.dx.abs() >= GameConfig.swipeVelocityThreshold &&
              velocity.dx.abs() > velocity.dy.abs();
      if (fastHorizontal) {
        _triggerLaneMove(velocity.dx < 0 ? -1 : 1);
      }
    }
    _resetSwipeState();
  }

  void _resetSwipeState() {
    _dragDistanceX = 0;
    _dragDistanceYAbs = 0;
    _swipeConsumed = false;
  }

  void _triggerLaneMove(int direction) {
    if (direction < 0) {
      _game.moveLeft();
    } else {
      _game.moveRight();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.services.profile;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _handleSwipeStart,
            onPanUpdate: _handleSwipeUpdate,
            onPanEnd: _handleSwipeEnd,
            onPanCancel: _resetSwipeState,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final intensity =
                          math.sin(_shakeController.value * math.pi * 12) *
                              (1 - _shakeController.value) *
                              10;
                      return Transform.translate(
                        offset: Offset(intensity, 0),
                        child: child,
                      );
                    },
                    child: _gameView,
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: ValueListenableBuilder<HudSnapshot>(
                      valueListenable: _hudNotifier,
                      builder: (context, hud, _) => _HudOverlay(
                        score: hud.score,
                        distance: hud.distance,
                        coins: hud.coins,
                        stage: hud.stage,
                        magnetRemaining: hud.magnetRemaining,
                        statusText: hud.statusText,
                        comboMultiplier: hud.comboMultiplier,
                        shieldReady: hud.shieldReady,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 16,
                  child: SafeArea(
                    child: IconButton.filled(
                      onPressed: _togglePause,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.panelGlass,
                        elevation: 8,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                      ),
                      icon: Icon(
                        _paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                    ),
                  ),
                ),
                if (_paused)
                  Positioned.fill(
                    child: _PauseOverlay(
                      onResume: _togglePause,
                      onRestart: _restart,
                      onMenu: _backToMenu,
                    ),
                  ),
                if (_pendingRevive != null)
                  Positioned.fill(
                    child: _ReviveOverlay(
                      cost: _reviveCost,
                      bank: profile.totalCoins,
                      runCoins: _pendingRevive!.coinsCollected,
                      onRevive: _acceptRevive,
                      onDecline: _declineRevive,
                    ),
                  ),
                if (_lastResult != null)
                  Positioned.fill(
                    child: _GameOverOverlay(
                      result: _lastResult!,
                      profile: profile,
                      onRetry: _restart,
                      onMenu: _backToMenu,
                      onShop: _openShop,
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

class _HudOverlay extends StatelessWidget {
  const _HudOverlay({
    required this.score,
    required this.distance,
    required this.coins,
    required this.stage,
    required this.magnetRemaining,
    required this.comboMultiplier,
    required this.shieldReady,
    this.statusText,
  });

  final int score;
  final int distance;
  final int coins;
  final int stage;
  final double magnetRemaining;
  final int comboMultiplier;
  final bool shieldReady;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 390;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, narrow ? 8 : 12, 72, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HudPill(
                      label: 'Score',
                      value: '$score',
                      icon: Icons.bolt_rounded,
                      compact: narrow,
                    ),
                    _HudPill(
                      label: 'Meters',
                      value: '$distance',
                      icon: Icons.route_rounded,
                      compact: narrow,
                    ),
                    _HudPill(
                      label: 'Coins',
                      value: '$coins',
                      icon: Icons.monetization_on_rounded,
                      compact: narrow,
                    ),
                    _HudPill(
                      label: 'Stage',
                      value: '$stage',
                      icon: Icons.whatshot_rounded,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (comboMultiplier > 1)
                      _HudPill(
                        label: 'Combo',
                        value: 'x$comboMultiplier',
                        accent: AppColors.panelAlt,
                        icon: Icons.local_fire_department_rounded,
                        compact: narrow,
                      ),
                    if (shieldReady)
                      _HudPill(
                        label: 'Shield',
                        value: 'Ready',
                        accent: AppColors.mint,
                        icon: Icons.shield_rounded,
                        compact: narrow,
                      ),
                    if (magnetRemaining > 0)
                      _HudPill(
                        label: 'Magnet',
                        value: '${magnetRemaining.toStringAsFixed(1)}s',
                        accent: AppColors.mint,
                        icon: Icons.auto_fix_high_rounded,
                        compact: narrow,
                      ),
                  ],
                ),
                if (statusText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: narrow ? 12 : 14,
                      vertical: narrow ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA554), AppColors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      statusText!,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: narrow ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.panel,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.98),
            Colors.white.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: AppColors.ink),
          SizedBox(width: compact ? 6 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.softInk,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onMenu,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return _OverlayPanel(
      title: 'Paused',
      subtitle: 'Catch your breath. The blender is still lurking.',
      actions: [
        _ActionButton(label: 'Continue', onPressed: onResume, primary: true),
        _ActionButton(label: 'Restart', onPressed: onRestart),
        _ActionButton(label: 'Main Menu', onPressed: onMenu),
      ],
    );
  }
}

class _ReviveOverlay extends StatefulWidget {
  const _ReviveOverlay({
    required this.cost,
    required this.bank,
    required this.runCoins,
    required this.onRevive,
    required this.onDecline,
  });

  final int cost;
  final int bank;
  final int runCoins;
  final VoidCallback onRevive;
  final VoidCallback onDecline;

  /// Long enough to read the offer, short enough that walking away from the
  /// phone still ends the run.
  static const Duration countdown = Duration(seconds: 5);

  @override
  State<_ReviveOverlay> createState() => _ReviveOverlayState();
}

class _ReviveOverlayState extends State<_ReviveOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timer;

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(vsync: this, duration: _ReviveOverlay.countdown)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onDecline();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  void _revive() {
    _timer.stop();
    widget.onRevive();
  }

  @override
  Widget build(BuildContext context) {
    return _OverlayPanel(
      title: 'So close!',
      subtitle: 'Spend coins to shake off the blender and keep this run going.',
      extra: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ResultTile(
                  label: 'Your coins',
                  value: formatCoins(widget.bank),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResultTile(
                  label: 'This run',
                  value: '+${widget.runCoins}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _timer,
            builder: (context, _) {
              final left = (_ReviveOverlay.countdown.inSeconds *
                      (1 - _timer.value))
                  .ceil();
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: 1 - _timer.value,
                      minHeight: 8,
                      backgroundColor: AppColors.panelAlt,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Run ends in ${left}s',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.softInk,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      actions: [
        _ActionButton(
          label: 'Continue for ${formatCoins(widget.cost)} coins',
          onPressed: _revive,
          primary: true,
        ),
        _ActionButton(label: 'No thanks', onPressed: widget.onDecline),
      ],
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.result,
    required this.profile,
    required this.onRetry,
    required this.onMenu,
    required this.onShop,
  });

  final GameSessionResult result;
  final GameProfile profile;
  final VoidCallback onRetry;
  final VoidCallback onMenu;
  final ValueChanged<ShopTab> onShop;

  @override
  Widget build(BuildContext context) {
    final isNewBest = result.score >= profile.highScore && result.score > 0;
    final overview = ShopOverview.of(profile);
    final openMissions =
        profile.missionViews.where((mission) => !mission.isComplete).toList();
    return _OverlayPanel(
      title: 'Blended!',
      subtitle: 'Too ripe to quit. Hit retry and beat that run.',
      extra: Column(
        children: [
          if (isNewBest) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC85A), AppColors.orange],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'New Best!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _ResultTile(
                  label: 'Run Score',
                  value: '${result.score}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResultTile(
                  label: 'Best',
                  value: '${profile.highScore}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ResultTile(
                  label: 'Coins',
                  value: '+${result.coinsCollected}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResultTile(
                  label: 'Distance',
                  value: '${result.distance}m',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ShopNudgeCard(
            overview: overview,
            coins: profile.totalCoins,
            compact: true,
            onOpen: () => onShop(overview.nextGoal?.tab ?? ShopTab.upgrades),
          ),
          if (openMissions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mission Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            for (final mission in openMissions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.panelAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          mission.definition.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        '${mission.progress}/${mission.definition.target}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.softInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
      actions: [
        _ActionButton(label: 'Retry', onPressed: onRetry, primary: true),
        _ActionButton(label: 'Main Menu', onPressed: onMenu),
      ],
    );
  }
}

class _OverlayPanel extends StatelessWidget {
  const _OverlayPanel({
    required this.title,
    required this.subtitle,
    required this.actions,
    this.extra,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.42),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      // The run summary is taller than a small phone's viewport; scrolling
      // beats clipping the Main Menu button off the bottom.
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.softInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (extra != null) ...[
                const SizedBox(height: 18),
                extra!,
              ],
              const SizedBox(height: 18),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: primary ? AppColors.orange : AppColors.ink,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.softInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
