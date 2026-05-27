import 'package:flutter/material.dart';

Route<T> fadeRoute<T>(Widget page, {Duration duration = const Duration(milliseconds: 350)}) =>
    PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: duration,
    );