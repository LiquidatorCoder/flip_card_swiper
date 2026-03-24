import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable swipeable card widget with animations and gesture support.
/// Allows cards to be swiped with vertical drag gestures, providing haptic feedback
/// and smooth animations for card transitions.
///
/// **Animation curves (overview)**
/// The main [AnimationController] runs from 0→1 over [animationDuration]. A
/// [CurvedAnimation] with [Curves.easeInOut] wraps that controller; rotation,
/// vertical bounce, and lift tweens read this eased value (not the raw controller).
/// After the midpoint, programmatic completion uses [AnimationController.animateTo]
/// with [Curves.linear] in *time* so the eased parameter still follows a single
/// smooth [Curves.easeInOut] curve. That segment’s wall-clock length is scaled by
/// [completionPhaseScale] (and by upward velocity when finishing a drag).
class FlipCardSwiper<T> extends StatefulWidget {
  /// The list of data used to build the cards.
  final List<T> cardData;

  /// The duration of the card swipe animation.
  final Duration animationDuration;

  /// Scales how long the **second half** of a flip takes after the midpoint when
  /// the gesture auto-completes ([animateTo] to 1.0). `1.0` = proportional to
  /// [animationDuration] only; `1.35` ≈ 35% longer second half (smoother tuck-in).
  final double completionPhaseScale;

  /// The duration of the downward drag animation.
  final Duration downDragDuration;

  /// The maximum distance for a drag gesture to trigger animations.
  final double maxDragDistance;

  /// The limit for dragging down before animation blocks further motion (non-positive).
  final double dragDownLimit;

  /// The threshold value for determining whether to complete the swipe animation (0–1).
  final double thresholdValue;

  /// A callback triggered when the top card changes.
  final void Function(int)? onCardChange;

  /// A builder function to create each card widget.
  /// - `context`: The build context.
  /// - `index`: The index of the card in the data.
  /// - `visibleIndex`: The index of the card in the visible stack (0 = top).
  ///
  /// Prefer keys tied to [index] (or stable ids), not only [visibleIndex], so the
  /// same card does not get a new key when it moves to the back during a flip.
  final Widget Function(BuildContext context, int index, int visibleIndex) cardBuilder;

  /// When false, haptic feedback is not triggered.
  final bool enableHaptics;

  /// Short description for assistive technologies (e.g. TalkBack).
  final String? semanticsLabel;

  /// Extra hint, e.g. how to flip when not obvious from context.
  final String? semanticsHint;

  /// Reserved for future top-card tuning. The flip animation uses fixed motion;
  /// these are not applied to the transform (defaults match pre-2.1 behavior).
  final double topCardOffsetStart;
  final double topCardOffsetEnd;
  final double topCardScaleStart;
  final double topCardScaleEnd;

  // Offset and scale parameters for the second card.
  final double secondCardOffsetStart;
  final double secondCardOffsetEnd;
  final double secondCardScaleStart;
  final double secondCardScaleEnd;

  // Offset and scale parameters for the third card.
  final double thirdCardOffsetStart;
  final double thirdCardOffsetEnd;
  final double thirdCardScaleStart;
  final double thirdCardScaleEnd;

  /// Where the extra lift **peaks** as a fraction of the swipe \[0, 1\]. The lift
  /// then eases back to zero so it does not stick through the second half.
  final double rotationStartFraction;

  /// Extra upward motion as a fraction of [maxDrag] (see [rotationStartFraction]).
  final double earlyLiftBoost;

  /// Creates a FlipCardSwiper widget.
  const FlipCardSwiper({
    required this.cardData,
    required this.cardBuilder,
    this.animationDuration = const Duration(milliseconds: 600),
    this.completionPhaseScale = 1,
    this.downDragDuration = const Duration(milliseconds: 300),
    this.maxDragDistance = 220.0,
    this.dragDownLimit = -40.0,
    this.thresholdValue = 0.3,
    this.onCardChange,
    this.enableHaptics = true,
    this.semanticsLabel,
    this.semanticsHint,
    this.topCardOffsetStart = 0.0,
    this.topCardOffsetEnd = -15.0,
    this.topCardScaleStart = 1.0,
    this.topCardScaleEnd = 0.9,
    this.secondCardOffsetStart = -15.0,
    this.secondCardOffsetEnd = 0.0,
    this.secondCardScaleStart = 0.95,
    this.secondCardScaleEnd = 1.0,
    this.thirdCardOffsetStart = -30.0,
    this.thirdCardOffsetEnd = -15.0,
    this.thirdCardScaleStart = 0.9,
    this.thirdCardScaleEnd = 0.95,
    this.rotationStartFraction = 0.28,
    this.earlyLiftBoost = 0.1,
    super.key,
  }) : assert(maxDragDistance > 0),
       assert(thresholdValue >= 0 && thresholdValue <= 1),
       assert(dragDownLimit <= 0),
       assert(rotationStartFraction >= 0.0 && rotationStartFraction <= 0.48),
       assert(earlyLiftBoost >= 0.0 && earlyLiftBoost <= 0.35),
       assert(completionPhaseScale > 0.0 && completionPhaseScale <= 3.0);

  @override
  State<FlipCardSwiper<T>> createState() => _FlipCardSwiperState<T>();
}

class _FlipCardSwiperState<T> extends State<FlipCardSwiper<T>> with TickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _yOffsetAnimation;
  Animation<double>? _rotationAnimation;
  Animation<double>? _liftBoostAnimation;
  Animation<double>? _animation;
  AnimationController? _downDragController;
  Animation<double>? _downDragAnimation;

  /// Single merge used by [AnimatedBuilder] (avoid reallocating each frame).
  late final Listenable _frameListenable;

  double _startAnimationValue = 0.0;
  double _dragStartPosition = 0.0;
  double _dragOffset = 0.0;
  bool _isCardSwitched = false;
  bool _hasReachedHalf = false;
  bool _isAnimationBlocked = false;
  bool _shouldPlayVibration = true;

  late List<T> _cardData;

  /// Parallel to [_cardData]: index into [FlipCardSwiper.cardData] for each entry.
  late List<int> _dataIndices;

  final List<Timer> _hapticTimers = <Timer>[];

  /// If [animateTo] for the second half never starts, the controller stops ticking
  /// and nothing calls [_onSwipeTick] again - this one-shot timer retries once.
  Timer? _completionWatchdogTimer;

  Widget? _topCardWidget;
  int? _topCardIndex;

  Widget? _secondCardWidget;
  int? _secondCardIndex;

  Widget? _thirdCardWidget;
  int? _thirdCardIndex;

  Widget? _poppedCardWidget;
  int? _poppedCardIndex;

  double get _threshold => widget.thresholdValue.clamp(0.0, 1.0);

  double get _dragDownLimit => widget.dragDownLimit.clamp(double.negativeInfinity, 0.0);

  double get _safeMaxDrag => widget.maxDragDistance <= 0 ? 1e-6 : widget.maxDragDistance;

  /// Last sampled Y for upward-drag velocity (px/s, positive = finger moving up).
  double? _dragLastSampleY;
  int? _dragLastSampleTimeUs;
  double _dragUpwardVelocityPxPerS = 0.0;

  /// Scales base duration: slow upward motion -> longer completion; fast fling -> shorter.
  double _velocityMultiplierForSecondHalf(double upwardVelocityPxPerSec) {
    final double v = upwardVelocityPxPerSec.clamp(0.0, 8000.0);
    // Floor so the second half never compresses to a near-instant snap (felt as a
    // "jump" when auto-play continues after crossing the midpoint; also reads as
    // "too fast" under slow-motion / time dilation).
    return (1.55 - 1.05 * (v / 8000.0)).clamp(0.85, 1.55);
  }

  int _completionDurationMsForRemaining(double remaining, double upwardVelocityPxPerSec) {
    final int baseMs = ((_controller?.duration?.inMilliseconds ?? 0) * remaining).round();
    if (baseMs <= 0) return 0;
    final double m = _velocityMultiplierForSecondHalf(upwardVelocityPxPerSec);
    final double scaled = baseMs * m * widget.completionPhaseScale;
    return scaled.round().clamp(100, 6000);
  }

  void _cancelCompletionWatchdog() {
    _completionWatchdogTimer?.cancel();
    _completionWatchdogTimer = null;
  }

  /// Clears gates set when scheduling completion; call if we will not run [animateTo].
  void _resetGestureCompletionGates() {
    _cancelCompletionWatchdog();
    _hasReachedHalf = false;
    _isAnimationBlocked = false;
  }

  /// Springs the main flip [AnimationController] back to 0 (cancel flip).
  void _springMainControllerToZero() {
    final AnimationController? c = _controller;
    if (c == null) return;
    final double v = c.value;
    if (v <= 0.0) return;
    final int durationMs = ((c.duration?.inMilliseconds ?? 0) * v).round();
    if (durationMs > 0) {
      c.animateBack(
        0.0,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeOut,
      );
    } else {
      c.value = 0.0;
    }
  }

  /// On pointer up: finish the flip toward 1.0 or spring back to 0 based on [controller] value.
  void _resolveFlipGestureEnd(DragEndDetails details) {
    final AnimationController? c = _controller;
    if (c == null || !mounted || _cardData.length <= 1) return;

    if (_downDragController?.isAnimating == true) return;

    // Let an in-flight [animateTo] / [forward] run unless we're clearly stuck.
    if (c.isAnimating) return;

    final double v = c.value;
    final double upward = math.max(0.0, -details.velocity.pixelsPerSecond.dy);

    // Stuck after crossing half: gates set but nothing is driving the controller.
    if (_hasReachedHalf && _isAnimationBlocked && v >= 0.5 && v < 1.0) {
      _scheduleAnimateToEnd(upward);
      return;
    }

    // Inconsistent flags while idle - clear and decide from [v] only.
    if (_isAnimationBlocked && !c.isAnimating) {
      _resetGestureCompletionGates();
    }

    // Commit: past midpoint, or strong-enough pre-half swipe (see [thresholdValue]).
    final bool commit = v >= 0.5 || (!_hasReachedHalf && v >= _threshold);
    if (commit && v < 1.0) {
      if (v >= 0.5 && !_hasReachedHalf) {
        _hasReachedHalf = true;
      }
      _isAnimationBlocked = true;
      _scheduleAnimateToEnd(upward);
      return;
    }

    // Cancel: release finger before committing - spring back.
    _resetGestureCompletionGates();
    _springMainControllerToZero();
  }

  /// Retries [animateTo] if completion was requested but the controller is idle mid-flight.
  void _tryResumeStuckCompletion() {
    if (!mounted) return;
    final AnimationController? c = _controller;
    if (c == null) return;
    if (!_isAnimationBlocked) return;
    if (c.isAnimating) return;
    final double v = c.value;
    if (v <= 0.0 || v >= 1.0) return;
    final int d = _completionDurationMsForRemaining(1.0 - v, _dragUpwardVelocityPxPerS);
    if (d <= 0) {
      c.value = 1.0;
      return;
    }
    c.animateTo(
      1.0,
      duration: Duration(milliseconds: d),
      curve: Curves.linear,
    );
  }

  /// Animates the main controller toward 1.0. May start from any progress in (0, 1);
  /// when value crosses 0.5 during the tween, [_onSwipeTick] performs the card swap.
  ///
  /// A one-shot [Timer] watchdog retries [animateTo] if it never attaches.
  void _scheduleAnimateToEnd(double upwardVelocityPxPerSec) {
    final AnimationController? c = _controller;
    if (c == null) {
      _resetGestureCompletionGates();
      return;
    }
    if (c.value >= 1.0) {
      _resetGestureCompletionGates();
      return;
    }

    _cancelCompletionWatchdog();

    if (!mounted) {
      _resetGestureCompletionGates();
      return;
    }

    final double v = c.value;
    if (v <= 0.0) {
      _resetGestureCompletionGates();
      return;
    }
    final int durationMs = _completionDurationMsForRemaining(1.0 - v, upwardVelocityPxPerSec);
    if (durationMs <= 0) {
      c.value = 1.0;
      return;
    }
    c.animateTo(
      1.0,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.linear,
    );

    // If [animateTo] never attaches (or stalls with no ticks), recover once.
    _completionWatchdogTimer = Timer(const Duration(milliseconds: 72), () {
      _completionWatchdogTimer = null;
      _tryResumeStuckCompletion();
    });
  }

  void _sampleDragVelocity(DragUpdateDetails details) {
    final double y = details.globalPosition.dy;
    final int now = DateTime.now().microsecondsSinceEpoch;
    if (_dragLastSampleY != null && _dragLastSampleTimeUs != null) {
      final double dt = (now - _dragLastSampleTimeUs!) / 1e6;
      if (dt > 1e-5) {
        final double instant = (_dragLastSampleY! - y) / dt;
        _dragUpwardVelocityPxPerS = _dragUpwardVelocityPxPerS * 0.65 + instant * 0.35;
      }
    }
    _dragLastSampleY = y;
    _dragLastSampleTimeUs = now;
  }

  void _resetDragVelocitySamples() {
    _dragLastSampleY = null;
    _dragLastSampleTimeUs = null;
    _dragUpwardVelocityPxPerS = 0.0;
  }

  Duration _mainDuration(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Duration.zero;
    }
    return widget.animationDuration;
  }

  Duration _downDuration(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Duration.zero;
    }
    return widget.downDragDuration;
  }

  void _syncAnimationDurations(BuildContext context) {
    final main = _mainDuration(context);
    final down = _downDuration(context);
    if (_controller != null && _controller!.duration != main) {
      _controller!.duration = main;
    }
    if (_downDragController != null && _downDragController!.duration != down) {
      _downDragController!.duration = down;
    }
  }

  void _cancelHapticTimers() {
    for (final t in _hapticTimers) {
      t.cancel();
    }
    _hapticTimers.clear();
  }

  void _scheduleHaptic(VoidCallback action, Duration delay) {
    _hapticTimers.add(
      Timer(delay, () {
        if (!mounted) return;
        if (!widget.enableHaptics) return;
        action();
      }),
    );
  }

  /// Triggers haptic feedback when a card is successfully switched.
  void onCardSwitchVibration() {
    if (!widget.enableHaptics) return;
    HapticFeedback.lightImpact();
    _scheduleHaptic(HapticFeedback.selectionClick, const Duration(milliseconds: 250));
  }

  /// Triggers haptic feedback when dragging down is blocked.
  void onCardBlockVibration() {
    if (!widget.enableHaptics) return;
    HapticFeedback.lightImpact();
    _scheduleHaptic(HapticFeedback.lightImpact, const Duration(milliseconds: 100));
    _scheduleHaptic(HapticFeedback.mediumImpact, const Duration(milliseconds: 300));
  }

  void _resetStackFromWidgetData() {
    _cardData = List<T>.from(widget.cardData);
    _dataIndices = List<int>.generate(_cardData.length, (int i) => i);
  }

  @override
  void initState() {
    super.initState();

    _resetStackFromWidgetData();

    _controller = AnimationController(duration: widget.animationDuration, vsync: this);

    _animation = CurvedAnimation(parent: _controller!, curve: Curves.easeInOut);

    // Slightly higher first peak so the stack reads as “lift” before tilt.
    _yOffsetAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 0.55), weight: 44.0),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.55, end: 0.0), weight: 56.0),
    ]).animate(_animation!);

    // Full-swipe rotation (same eased progress as the vertical bounce - no delayed
    // interval that bunches rotation at the end of the gesture).
    _rotationAnimation = Tween<double>(begin: 0.0, end: -180.0).animate(_animation!);

    _syncLiftAnimation();

    _downDragController = AnimationController(duration: widget.downDragDuration, vsync: this);

    _downDragAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_downDragController!);

    _frameListenable = Listenable.merge(<Listenable>[_controller!, _downDragController!]);

    _controller!.addListener(_onSwipeTick);
    _controller!.addStatusListener(_onFlipAnimationStatus);

    _updateCardWidgets();
  }

  /// One clean completion signal (avoids relying on [value] == 1.0 every tick).
  void _onFlipAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!mounted) return;
    _cancelCompletionWatchdog();
    if (_cardData.length <= 1) {
      _isCardSwitched = false;
      _hasReachedHalf = false;
      _isAnimationBlocked = false;
      _controller?.reset();
      return;
    }
    _isCardSwitched = false;
    _controller?.reset();
    _hasReachedHalf = false;
    _isAnimationBlocked = false;
  }

  /// Early lift: 0→1→0 over the swipe so the boost does not plateau through the
  /// second half (which caused a vertical snap when the controller reset).
  void _syncLiftAnimation() {
    if (widget.earlyLiftBoost <= 0.0 || widget.rotationStartFraction <= 0.0) {
      _liftBoostAnimation = const AlwaysStoppedAnimation<double>(0.0);
    } else {
      final double peak = widget.rotationStartFraction.clamp(0.05, 0.48);
      final double w1 = peak * 100.0;
      final double w2 = (1.0 - peak) * 100.0;
      _liftBoostAnimation = TweenSequence<double>([
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: w1,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)),
          weight: w2,
        ),
      ]).animate(_controller!);
    }
  }

  void _onSwipeTick() {
    if (_cardData.length > 1) {
      if (!_isCardSwitched && (_controller?.value ?? 0.0) >= 0.5) {
        _poppedCardIndex = _dataIndices[0];
        // Reuse the same widget instance as the pre-swap top card so Element/state
        // and keys stay stable across the z-order swap (rebuilding via cardBuilder
        // with a new visibleIndex often changes ValueKey(visibleIndex) and reads as a snap).
        _poppedCardWidget = _topCardWidget;
        final T firstCard = _cardData.removeAt(0);
        _dataIndices.removeAt(0);
        _cardData.add(firstCard);
        _dataIndices.add(_poppedCardIndex!);

        onCardSwitchVibration();

        _isCardSwitched = true;

        _updateCardWidgets();

        widget.onCardChange?.call(_dataIndices[0]);
      }
    } else {
      _controller?.reset();
    }
  }

  /// Updates the widgets for the top three visible cards.
  void _updateCardWidgets() {
    if (_cardData.isNotEmpty) {
      _topCardIndex = _dataIndices[0];
      _topCardWidget = widget.cardBuilder(context, _topCardIndex ?? 0, 0);
    } else {
      _topCardIndex = null;
      _topCardWidget = null;
    }

    if (_cardData.length > 1) {
      _secondCardIndex = _dataIndices[1];
      _secondCardWidget = widget.cardBuilder(context, _secondCardIndex ?? 0, 1);
    } else {
      _secondCardIndex = null;
      _secondCardWidget = null;
    }

    if (_cardData.length > 2) {
      _thirdCardIndex = _dataIndices[2];
      _thirdCardWidget = widget.cardBuilder(context, _thirdCardIndex ?? 0, 2);
    } else {
      _thirdCardIndex = null;
      _thirdCardWidget = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationDurations(context);
  }

  @override
  void didUpdateWidget(FlipCardSwiper<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool dataChanged = !listEquals(widget.cardData, oldWidget.cardData);
    if (dataChanged) {
      _cancelCompletionWatchdog();
      _controller?.stop();
      _downDragController?.stop();

      _resetStackFromWidgetData();
      _isCardSwitched = false;
      _hasReachedHalf = false;
      _isAnimationBlocked = false;
      _startAnimationValue = 0.0;
      _dragStartPosition = 0.0;
      _dragOffset = 0.0;

      _controller?.reset();
      _downDragController?.reset();

      _updateCardWidgets();
    }

    if (widget.animationDuration != oldWidget.animationDuration ||
        widget.downDragDuration != oldWidget.downDragDuration) {
      _syncAnimationDurations(context);
    }

    if (widget.rotationStartFraction != oldWidget.rotationStartFraction ||
        widget.earlyLiftBoost != oldWidget.earlyLiftBoost) {
      _syncLiftAnimation();
    }
  }

  @override
  void dispose() {
    _cancelCompletionWatchdog();
    _controller?.removeListener(_onSwipeTick);
    _controller?.removeStatusListener(_onFlipAnimationStatus);
    _controller?.dispose();
    _downDragController?.dispose();
    _cancelHapticTimers();
    super.dispose();
  }

  void _keyboardFlipToNext() {
    if (_cardData.length <= 1) return;
    if (_controller?.isAnimating == true || _downDragController?.isAnimating == true) {
      return;
    }
    final Duration d = _mainDuration(context);
    if (d == Duration.zero) {
      _controller?.value = 1.0;
    } else {
      // Linear segment: [_animation] already applies Curves.easeInOut to controller
      // values; easeOut here would compose easeInOut(easeOut(t)) and bunch the flip.
      _controller?.forward(from: 0.0);
    }
    _isAnimationBlocked = true;
  }

  // Handle the start of the vertical drag
  void _onVerticalDragStart(DragStartDetails details) {
    if (_controller?.isAnimating == true || _downDragController?.isAnimating == true || _cardData.length == 1) {
      return;
    }
    _resetDragVelocitySamples();
    _isAnimationBlocked = false;
    _startAnimationValue = _controller?.value ?? 0.0;
    _dragStartPosition = details.globalPosition.dy;
    _controller?.stop(canceled: false);
    _downDragController?.stop();
    _hasReachedHalf = false;
  }

  // Update the animation value based on the drag
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_controller?.isAnimating == true ||
        _downDragController?.isAnimating == true ||
        _hasReachedHalf ||
        _isAnimationBlocked ||
        _cardData.length == 1) {
      return;
    }

    final double dragDistance = _dragStartPosition - details.globalPosition.dy;

    if (dragDistance >= 0) {
      _sampleDragVelocity(details);
      final double dragFraction = dragDistance / _safeMaxDrag;
      final double newValue = (_startAnimationValue + dragFraction).clamp(0.0, 1.0);
      _controller?.value = newValue;
      _dragOffset = 0.0;

      final double cv = _controller?.value ?? 0.0;
      // Require t in (0.5, 1) so we never schedule completion when the controller
      // already hit 1.0 in the same listener pass (would strand _hasReachedHalf).
      if (cv >= 0.5 && cv < 1.0 && !_hasReachedHalf) {
        _hasReachedHalf = true;
        _scheduleAnimateToEnd(_dragUpwardVelocityPxPerS);
        _isAnimationBlocked = true;
      }
    } else {
      _controller?.value = _startAnimationValue;
      final double downDragOffset = dragDistance.clamp(_dragDownLimit, 0.0);
      _dragOffset = -downDragOffset;
      if (downDragOffset == _dragDownLimit) {
        if (_shouldPlayVibration) {
          onCardBlockVibration();
          _shouldPlayVibration = false;
        }
      }
    }
  }

  // Continue the animation when the drag ends
  void _onVerticalDragEnd(DragEndDetails details) {
    if (_cardData.length == 1) {
      _shouldPlayVibration = true;
      return;
    }
    if (_dragOffset != 0.0) {
      // Capture pull distance for the tween, then clear so when [isAnimating] becomes
      // false we do not fall back to a stale offset (regression after removing the
      // down-drag listener that mirrored the tween into [_dragOffset]).
      final double pull = _dragOffset;
      _dragOffset = 0.0;
      _downDragAnimation = Tween<double>(
        begin: pull,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _downDragController!, curve: Curves.easeOutCubic));
      _downDragController?.forward(from: 0.0);
      _shouldPlayVibration = true;
      return;
    }

    // Do not return early on [_isAnimationBlocked]: we must complete or spring back
    // when the finger lifts, including if [animateTo] never started after crossing half.
    _resolveFlipGestureEnd(details);
    _shouldPlayVibration = true;
  }

  List<Widget> _buildStackedCards() {
    final double yOffsetAnimationValue = _yOffsetAnimation?.value ?? 0.0;
    final double rotation = _rotationAnimation?.value ?? 0.0;
    double totalYOffset =
        -yOffsetAnimationValue * _safeMaxDrag +
        (_downDragController?.isAnimating == true ? _downDragAnimation?.value ?? 0.0 : _dragOffset);

    final double liftBoost = _liftBoostAnimation?.value ?? 0.0;
    totalYOffset -= liftBoost * widget.earlyLiftBoost * _safeMaxDrag;

    // Smooth the mid-swipe stack nudge (avoids a step at t == 0.5 that read as a pop).
    final double cv = _controller?.value ?? 0.0;
    if (_cardData.length > 1) {
      const double nudgeFrom = 0.42;
      const double nudgeTo = 0.58;
      final double target = _cardData.length == 2 ? widget.secondCardOffsetStart : widget.thirdCardOffsetStart;
      double stackNudge = 0.0;
      if (cv <= nudgeFrom) {
        stackNudge = 0.0;
      } else if (cv >= nudgeTo) {
        stackNudge = target;
      } else {
        stackNudge = target * Curves.easeInOut.transform((cv - nudgeFrom) / (nudgeTo - nudgeFrom));
      }
      totalYOffset += stackNudge;
    }

    final List<Widget> stackChildren = <Widget>[];

    if (_cardData.length == 1) {
      stackChildren.add(_topCardWidget ?? const SizedBox.shrink());
    } else {
      final int cardCount = math.min(_cardData.length, 3);

      if (_isCardSwitched) {
        for (int i = 0; i < cardCount; i++) {
          if (i == 0) {
            stackChildren.add(_buildTopCardLayer(totalYOffset, rotation));
          } else {
            stackChildren.add(_buildCardLayer(cardCount - i));
          }
        }
      } else {
        for (int i = cardCount - 1; i >= 0; i--) {
          if (i == 0) {
            stackChildren.add(_buildTopCardLayer(totalYOffset, rotation));
          } else {
            stackChildren.add(_buildCardLayer(i));
          }
        }
      }
    }
    return stackChildren;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cardData.isEmpty) {
      return Semantics(
        label: widget.semanticsLabel ?? 'Card stack',
        hint: widget.semanticsHint,
        child: const SizedBox.shrink(),
      );
    }

    final String defaultHint = widget.semanticsHint ?? 'Swipe up to move to the next card.';

    return Semantics(
      label: widget.semanticsLabel ?? 'Card stack',
      hint: defaultHint,
      child: Focus(
        skipTraversal: false,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _keyboardFlipToNext();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: AnimatedBuilder(
              animation: _frameListenable,
              builder: (BuildContext context, Widget? child) {
                return Stack(alignment: Alignment.center, children: _buildStackedCards());
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Top card layer (outer [AnimatedBuilder] already listens to the controller).
  Widget _buildTopCardLayer(double yOffset, double rotation) {
    if (_topCardWidget == null) {
      return const SizedBox.shrink();
    }

    final Widget cardWidget = _isCardSwitched && _cardData.length > 1
        ? (_poppedCardWidget ?? const SizedBox.shrink())
        : (_topCardWidget ?? const SizedBox.shrink());

    final double controllerValue = _controller?.value ?? 0.0;

    double scale;
    if (_cardData.length == 2) {
      if (controllerValue <= 0.5 && _cardData.length > 1) {
        if (controllerValue >= 0.45) {
          final double progress = (controllerValue - 0.45) / 0.05;
          scale = 1.0 - 0.05 * progress;
        } else {
          scale = 1.0;
        }
      } else {
        scale = 0.95;
      }
    } else {
      if (controllerValue <= 0.5 && _cardData.length > 1) {
        if (controllerValue >= 0.4) {
          final double progress = (controllerValue - 0.4) / 0.1;
          scale = 1.0 - 0.1 * progress;
        } else {
          scale = 1.0;
        }
      } else {
        scale = 0.9;
      }
    }

    // Mid-flip Y correction was gated on [_isCardSwitched], which flips at t >= 0.5.
    // That turned the full correction on in one frame (~30px) and looked like a jump,
    // especially during animateTo's second half. Ramp 0→1 only after t=0.5 so the
    // pre-swap top card still gets zero extra Y (same as the old false branch).
    const double flipAdjustRamp = 0.08;
    final double flipAdjustBlend = controllerValue < 0.5
        ? 0.0
        : Curves.easeInOut.transform(((controllerValue - 0.5) / flipAdjustRamp).clamp(0.0, 1.0));
    final double midFlipYOffset =
        flipAdjustBlend * (-widget.thirdCardOffsetStart) * (((_rotationAnimation?.value ?? 0) + 180) / 90);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(0.0, yOffset, 0, 1)
        ..translateByDouble(0.0, midFlipYOffset, 0, 1)
        ..setEntry(3, 2, 0.001)
        ..rotateX(rotation * math.pi / 180)
        ..scaleByDouble(scale, scale, 1.0, 1),
      child: cardWidget,
    );
  }

  /// Underlying card layers (same: one [AnimatedBuilder] for the stack).
  Widget _buildCardLayer(int index) {
    if (_cardData.length <= 1 || index >= _cardData.length) {
      return const SizedBox.shrink();
    }

    Widget? cardWidget;
    if (_isCardSwitched) {
      if (index == 1) {
        cardWidget = _topCardWidget;
      } else if (index == 2) {
        cardWidget = _secondCardWidget;
      } else {
        return const SizedBox.shrink();
      }
    } else {
      if (index == 1) {
        cardWidget = _secondCardWidget;
      } else if (index == 2) {
        cardWidget = _thirdCardWidget;
      } else {
        return const SizedBox.shrink();
      }
    }

    if (cardWidget == null) {
      return const SizedBox.shrink();
    }

    final double controllerValue = _controller?.value ?? 0.0;

    double initialOffset = 0.0;
    double initialScale = 1.0;
    double targetScale = 1.0;

    if (_cardData.length == 2) {
      if (index == 1) {
        initialOffset = widget.secondCardOffsetStart;
        initialScale = widget.secondCardScaleStart;
        targetScale = widget.secondCardScaleEnd;
      }
    } else {
      if (index == 1) {
        initialOffset = widget.secondCardOffsetStart;
        initialScale = widget.secondCardScaleStart;
        targetScale = widget.secondCardScaleEnd;
      } else if (index == 2) {
        initialOffset = widget.thirdCardOffsetStart;
        initialScale = widget.thirdCardScaleStart;
        targetScale = widget.thirdCardScaleEnd;
      }
    }

    double yOff = initialOffset;
    double scale = initialScale;

    if (controllerValue <= 0.5) {
      double progress = controllerValue / 0.5;

      if (_cardData.length == 2) {
        yOff = initialOffset - widget.secondCardOffsetStart * progress;
      } else {
        yOff = initialOffset - widget.thirdCardOffsetStart * progress;
      }
      progress = Curves.easeOut.transform(progress);

      scale = initialScale;
    } else {
      double progress = (controllerValue - 0.5) / 0.5;

      if (_cardData.length == 2) {
        yOff = initialOffset - widget.secondCardOffsetStart + widget.secondCardOffsetEnd * progress;
      } else {
        yOff = initialOffset - widget.thirdCardOffsetStart + widget.thirdCardOffsetEnd * progress;
      }
      progress = Curves.easeOut.transform(progress);

      scale = initialScale + (targetScale - initialScale) * progress;
    }

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(0.0, yOff, 0, 1)
        ..scaleByDouble(scale, scale, 1.0, 1),
      child: cardWidget,
    );
  }
}
