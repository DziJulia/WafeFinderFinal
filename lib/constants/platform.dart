import 'package:flutter/foundation.dart';

/// This file contains constants that help determine the current platform.
/// The constants in this file are only applicable for mobile (Android and iOS) and macOS platforms.

/// Determines if the current platform is mobile.
/// This is `true` when the [defaultTargetPlatform] is either [TargetPlatform.android] or [TargetPlatform.iOS].
final bool isMobile = (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// Determines if the current platform is macOS.
/// This is `true` when the [defaultTargetPlatform] is [TargetPlatform.macOS].
final bool isMacOS = (defaultTargetPlatform == TargetPlatform.macOS);

/// Determines if the current platform is Android.
/// This is `true` when the [defaultTargetPlatform] is [TargetPlatform.android].
final bool isAndroid = (defaultTargetPlatform == TargetPlatform.android);

/// Determines if the current platform is iOS.
/// This is `true` when the [defaultTargetPlatform] is [TargetPlatform.android].
final bool isiOS = (defaultTargetPlatform == TargetPlatform.iOS);
