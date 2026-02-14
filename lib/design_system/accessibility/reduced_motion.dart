import 'package:flutter/widgets.dart';

bool prefersReducedMotion(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  if (media == null) return false;
  return media.disableAnimations || media.accessibleNavigation;
}
