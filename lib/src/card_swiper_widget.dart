import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable swipeable card widget with animations and gesture support.
/// Allows cards to be swiped with vertical drag gestures, providing haptic feedback
/// and smooth animations for card transitions.
class FlipCardSwiper<T> extends StatefulWidget {
  /// The list of data used to build the cards.
  final List<T> cardData;

  /// The duration of the card swipe animation.
  final Duration animationDuration;

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
  final Widget Function(BuildContext context, int index, int visibleIndex)
      cardBuilder;

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

  /// Creates a FlipCardSwiper widget.
  const FlipCardSwiper({
    required this.cardData,
    required this.cardBuilder,
    this.animationDuration = const Duration(milliseconds: 800),
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
    super.key,
  })  : assert(maxDragDistance > 0),
        assert(thresholdValue >= 0 && thresholdValue <= 1),
        assert(dragDownLimit <= 0);

  @override
  State<FlipCardSwiper<T>> createState() => _FlipCardSwiperState<T>();
}

class _FlipCardSwiperState<T> extends State<FlipCardSwiper<T>>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _yOffsetAnimation;
  Animation<double>? _rotationAnimation;
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

  Timer? _debounceTimer;

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

  double get _safeMaxDrag =>
      widget.maxDragDistance <= 0 ? 1e-6 : widget.maxDragDistance;

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

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    );

    _yOffsetAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 0.5),
        weight: 45.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.5, end: 0.0),
        weight: 55.0,
      ),
    ]).animate(_animation!);

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: -180.0,
    ).animate(_animation!);

    _downDragController = AnimationController(
      duration: widget.downDragDuration,
      vsync: this,
    );

    _downDragAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_downDragController!);

    _frameListenable = Listenable.merge(<Listenable>[
      _controller!,
      _downDragController!,
    ]);

    _controller!.addListener(_onSwipeTick);

    _updateCardWidgets();
  }

  void _onSwipeTick() {
    if (_cardData.length > 1) {
      if (!_isCardSwitched && (_controller?.value ?? 0.0) >= 0.5) {
        if (_debounceTimer?.isActive ?? false) {
          _isCardSwitched = true;
          return;
        }

        _poppedCardIndex = _dataIndices[0];
        final T firstCard = _cardData.removeAt(0);
        _dataIndices.removeAt(0);
        _poppedCardWidget =
            widget.cardBuilder(context, _poppedCardIndex ?? 0, -1);
        _cardData.add(firstCard);
        _dataIndices.add(_poppedCardIndex!);

        onCardSwitchVibration();

        _isCardSwitched = true;

        _updateCardWidgets();

        widget.onCardChange?.call(_dataIndices[0]);

        _debounceTimer = Timer(const Duration(milliseconds: 300), () {});
      }

      if ((_controller?.value ?? 0.0) == 1.0) {
        _isCardSwitched = false;
        _controller?.reset();
        _hasReachedHalf = false;
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
      _controller?.stop();
      _downDragController?.stop();

      _resetStackFromWidgetData();
      _isCardSwitched = false;
      _hasReachedHalf = false;
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
  }

  @override
  void dispose() {
    _controller?.removeListener(_onSwipeTick);
    _controller?.dispose();
    _downDragController?.dispose();
    _debounceTimer?.cancel();
    _cancelHapticTimers();
    super.dispose();
  }

  void _keyboardFlipToNext() {
    if (_cardData.length <= 1) return;
    if (_controller?.isAnimating == true ||
        _downDragController?.isAnimating == true) {
      return;
    }
    final Duration d = _mainDuration(context);
    if (d == Duration.zero) {
      _controller?.value = 1.0;
    } else {
      _controller?.animateTo(1.0, duration: d, curve: Curves.easeOut);
    }
    _isAnimationBlocked = true;
  }

  // Handle the start of the vertical drag
  void _onVerticalDragStart(DragStartDetails details) {
    if (_controller?.isAnimating == true ||
        _downDragController?.isAnimating == true ||
        _cardData.length == 1) {
      return;
    }
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
    if (_hasReachedHalf) {
      return;
    }

    final double dragDistance =
        _dragStartPosition - details.globalPosition.dy;

    if (dragDistance >= 0) {
      final double dragFraction = dragDistance / _safeMaxDrag;
      final double newValue =
          (_startAnimationValue + dragFraction).clamp(0.0, 1.0);
      _controller?.value = newValue;
      _dragOffset = 0.0;

      if ((_controller?.value ?? 0.0) >= 0.5 && !_hasReachedHalf) {
        _hasReachedHalf = true;
        final double remaining = 1.0 - (_controller?.value ?? 0.0);
        final int durationMs =
            ((_controller?.duration?.inMilliseconds ?? 0) * remaining).round();
        if (durationMs > 0) {
          _controller?.animateTo(
            1.0,
            duration: Duration(milliseconds: durationMs),
            curve: Curves.easeOut,
          );
          _isAnimationBlocked = true;
        } else {
          _controller?.value = 1.0;
        }
      }
    } else {
      _controller?.value = _startAnimationValue;
      final double downDragOffset =
          dragDistance.clamp(_dragDownLimit, 0.0);
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
    if (_controller?.isAnimating == true ||
        _downDragController?.isAnimating == true ||
        _isAnimationBlocked ||
        _cardData.length == 1) {
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
      ).animate(CurvedAnimation(
        parent: _downDragController!,
        curve: Curves.easeOutCubic,
      ));
      _downDragController?.forward(from: 0.0);
    } else if (!_hasReachedHalf) {
      if ((_controller?.value ?? 0.0) >= _threshold) {
        final double remaining = 1.0 - (_controller?.value ?? 0.0);
        final int durationMs =
            ((_controller?.duration?.inMilliseconds ?? 0) * remaining).round();
        if (durationMs > 0) {
          _controller?.animateTo(
            1.0,
            duration: Duration(milliseconds: durationMs),
            curve: Curves.easeOut,
          );
          _isAnimationBlocked = true;
        } else {
          _controller?.value = 1.0;
        }
      } else {
        final int durationMs = ((_controller?.duration?.inMilliseconds ?? 0) *
                (_controller?.value ?? 0.0))
            .round();
        if (durationMs > 0) {
          _controller?.animateBack(
            0.0,
            duration: Duration(milliseconds: durationMs),
            curve: Curves.easeOut,
          );
        } else {
          _controller?.value = 0.0;
        }
      }
    }
    _shouldPlayVibration = true;
  }

  List<Widget> _buildStackedCards() {
    final double yOffsetAnimationValue = _yOffsetAnimation?.value ?? 0.0;
    final double rotation = _rotationAnimation?.value ?? 0.0;
    double totalYOffset = -yOffsetAnimationValue * _safeMaxDrag +
        (_downDragController?.isAnimating == true
            ? _downDragAnimation?.value ?? 0.0
            : _dragOffset);

    if ((_controller?.value ?? 0.0) >= 0.5) {
      totalYOffset += _cardData.length == 2
          ? widget.secondCardOffsetStart
          : widget.thirdCardOffsetStart;
    }

    final List<Widget> stackChildren = <Widget>[];

    if (_cardData.length == 1) {
      stackChildren.add(_topCardWidget ?? const SizedBox.shrink());
    } else {
      final int cardCount = min(_cardData.length, 3);

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

    final String defaultHint =
        widget.semanticsHint ?? 'Swipe up to move to the next card.';

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
                return Stack(
                  alignment: Alignment.center,
                  children: _buildStackedCards(),
                );
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

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(0.0, yOffset, 0, 1)
        ..translateByDouble(
          0.0,
          _isCardSwitched
              ? (-widget.thirdCardOffsetStart) *
                  (((_rotationAnimation?.value ?? 0) + 180) / 90)
              : 0,
          0,
          1,
        )
        ..setEntry(3, 2, 0.001)
        ..rotateX(rotation * pi / 180)
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
        yOff = initialOffset -
            widget.secondCardOffsetStart +
            widget.secondCardOffsetEnd * progress;
      } else {
        yOff = initialOffset -
            widget.thirdCardOffsetStart +
            widget.thirdCardOffsetEnd * progress;
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
