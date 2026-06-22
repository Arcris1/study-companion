import 'dart:math' as math;
import 'package:flutter/material.dart';

class FlipCardWidget extends StatefulWidget {
  final Widget front;
  final Widget back;
  final VoidCallback? onFlip;
  final FlipCardController? controller;

  const FlipCardWidget({
    super.key,
    required this.front,
    required this.back,
    this.onFlip,
    this.controller,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(FlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller?._state = this;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flip() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    _isFlipped = !_isFlipped;
    widget.onFlip?.call();
  }

  void reset() {
    _controller.reset();
    _isFlipped = false;
  }

  bool get isFlipped => _isFlipped;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final isFrontVisible = angle < math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            child: isFrontVisible
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

class FlipCardController {
  _FlipCardWidgetState? _state;

  void flip() => _state?.flip();
  void reset() => _state?.reset();
  bool get isFlipped => _state?.isFlipped ?? false;
}
