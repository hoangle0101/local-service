import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated heart button for favoriting items
/// Features scale and bounce animation when toggled
class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onToggle;
  final double size;
  final EdgeInsetsGeometry padding;
  final Color favoriteColor;
  final Color unfavoriteColor;

  const FavoriteButton({
    super.key,
    required this.isFavorite,
    this.onToggle,
    this.size = 24,
    this.padding = const EdgeInsets.all(8.0),
    this.favoriteColor = Colors.red,
    this.unfavoriteColor = Colors.grey,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _controller.forward(from: 0);
    }
  }

  void _handleTap() {
    // Haptic feedback
    HapticFeedback.lightImpact();

    _controller.forward(from: 0);
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: widget.padding,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(widget.isFavorite),
                  size: widget.size,
                  color: widget.isFavorite
                      ? widget.favoriteColor
                      : widget.unfavoriteColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A small favorite indicator badge overlay
class FavoriteIndicator extends StatelessWidget {
  final bool isFavorite;
  final double size;

  const FavoriteIndicator({
    super.key,
    required this.isFavorite,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFavorite) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.favorite,
        size: size,
        color: Colors.red,
      ),
    );
  }
}
