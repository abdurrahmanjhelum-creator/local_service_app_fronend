import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final List<String> typingUsers;
  final String currentUserId;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final otherTypingUsers = typingUsers.where((id) => id != currentUserId).toList();
    
    if (otherTypingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: _TypingDots(),
          ),
          const SizedBox(width: 8),
          Text(
            _getTypingText(otherTypingUsers.length),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypingText(int count) {
    if (count == 1) {
      return 'Someone is typing...';
    } else {
      return '$count people are typing...';
    }
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    _animation2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeInOut),
      ),
    );

    _animation3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _AnimatedDot(animation: _animation1),
        _AnimatedDot(animation: _animation2),
        _AnimatedDot(animation: _animation3),
      ],
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedDot({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + (animation.value * 0.5),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}