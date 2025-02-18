import 'dart:math';

import 'package:flutter/material.dart';

class StatefulRandomBackground extends StatefulWidget {
  const StatefulRandomBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<StatefulRandomBackground> createState() =>
      _StatefulRandomBackgroundState();
}

class _StatefulRandomBackgroundState extends State<StatefulRandomBackground> {
  static final _random = Random();
  static const _colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.lightBlue,
    Colors.blue,
    Colors.purple,
  ];

  final color = _colors[_random.nextInt(_colors.length)];

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: color,
        child: widget.child,
      );
}
