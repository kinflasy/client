import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppTabBar extends StatefulWidget {
  AppTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.activeColor,
    this.height,
    this.tabHorizontalPadding,
    this.containerPadding,
    this.activeTextStyle,
    this.inactiveTextStyle,
    this.animationDuration,
    this.animationCurve,
  }) : assert(tabs.isNotEmpty, 'AppTabBar requires at least one tab.'),
       assert(
         selectedIndex >= 0 && selectedIndex < tabs.length,
         'selectedIndex must be within the tabs range.',
       );

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final Color? activeColor;
  final double? height;
  final double? tabHorizontalPadding;
  final EdgeInsetsGeometry? containerPadding;
  final TextStyle? activeTextStyle;
  final TextStyle? inactiveTextStyle;
  final Duration? animationDuration;
  final Curve? animationCurve;

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar> {
  late final ScrollController _scrollController;
  double? _lastViewportWidth;
  double? _lastContentWidth;
  bool _didScheduleScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant AppTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _didScheduleScroll = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final activeColor = widget.activeColor ?? colorScheme.primary;
    final height = math.max(widget.height ?? 48.0, 44.0);
    final horizontalPadding = widget.tabHorizontalPadding ?? 16;
    final resolvedContainerPadding =
        (widget.containerPadding ?? EdgeInsets.zero).resolve(
          Directionality.of(context),
        );
    final animationDuration =
        widget.animationDuration ?? const Duration(milliseconds: 200);
    final animationCurve = widget.animationCurve ?? Curves.easeInOut;
    final activeTextStyle =
        widget.activeTextStyle ??
        textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ) ??
        TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        );
    final inactiveTextStyle =
        widget.inactiveTextStyle ??
        textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        );
    final backgroundColor = Color.alphaBlend(
      activeColor.withValues(alpha: 0.12),
      colorScheme.surfaceContainerHigh,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);
        final intrinsicWidths = [
          for (final tab in widget.tabs)
            _measureTabWidth(
              context: context,
              label: tab,
              style: inactiveTextStyle,
              horizontalPadding: horizontalPadding,
              textScaleFactor: textScaleFactor,
            ),
        ];

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final contentAvailableWidth = math.max(
          0,
          availableWidth -
              resolvedContainerPadding.left -
              resolvedContainerPadding.right,
        );
        final intrinsicTotalWidth = intrinsicWidths.fold<double>(
          0,
          (sum, width) => sum + width,
        );
        final usesExpandedTabs = intrinsicTotalWidth <= contentAvailableWidth;
        final tabWidths = usesExpandedTabs
            ? List<double>.filled(
                widget.tabs.length,
                contentAvailableWidth / widget.tabs.length,
              )
            : intrinsicWidths;
        final offsets = _computeOffsets(
          tabWidths,
          resolvedContainerPadding.left,
        );
        final contentWidth = usesExpandedTabs
            ? availableWidth
            : tabWidths.fold<double>(0, (sum, width) => sum + width) +
                  resolvedContainerPadding.horizontal;

        if (!usesExpandedTabs) {
          _scheduleEnsureVisible(
            viewportWidth: availableWidth,
            contentWidth: contentWidth,
            targetLeft: offsets[widget.selectedIndex],
            targetWidth: tabWidths[widget.selectedIndex],
            duration: animationDuration,
            curve: animationCurve,
          );
        } else {
          _didScheduleScroll = false;
          _lastViewportWidth = availableWidth;
          _lastContentWidth = contentWidth;
        }

        final content = SizedBox(
          width: usesExpandedTabs ? availableWidth : contentWidth,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: animationDuration,
                curve: animationCurve,
                left: offsets[widget.selectedIndex],
                top: resolvedContainerPadding.top,
                width: tabWidths[widget.selectedIndex],
                height: height - resolvedContainerPadding.vertical,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: resolvedContainerPadding,
                  child: Row(
                    children: [
                      for (var index = 0; index < widget.tabs.length; index++)
                        SizedBox(
                          width: tabWidths[index],
                          child: _AppTabBarItem(
                            label: widget.tabs[index],
                            isSelected: index == widget.selectedIndex,
                            activeTextStyle: activeTextStyle,
                            inactiveTextStyle: inactiveTextStyle,
                            animationDuration: animationDuration,
                            animationCurve: animationCurve,
                            onTap: () => widget.onTabChanged(index),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        if (usesExpandedTabs) {
          return content;
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SingleChildScrollView(
            key: const Key('app-tab-bar-scroll-view'),
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: content,
          ),
        );
      },
    );
  }

  double _measureTabWidth({
    required BuildContext context,
    required String label,
    required TextStyle style,
    required double horizontalPadding,
    required double textScaleFactor,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: TextScaler.linear(textScaleFactor),
    )..layout();

    return painter.width + (horizontalPadding * 2);
  }

  List<double> _computeOffsets(List<double> widths, double start) {
    final offsets = <double>[];
    var current = start;
    for (final width in widths) {
      offsets.add(current);
      current += width;
    }
    return offsets;
  }

  void _scheduleEnsureVisible({
    required double viewportWidth,
    required double contentWidth,
    required double targetLeft,
    required double targetWidth,
    required Duration duration,
    required Curve curve,
  }) {
    if (_didScheduleScroll &&
        _lastViewportWidth == viewportWidth &&
        _lastContentWidth == contentWidth) {
      return;
    }

    _didScheduleScroll = true;
    _lastViewportWidth = viewportWidth;
    _lastContentWidth = contentWidth;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final currentOffset = _scrollController.offset;
      final tabRight = targetLeft + targetWidth;
      final viewportRight = currentOffset + viewportWidth;
      if (targetLeft >= currentOffset && tabRight <= viewportRight) {
        return;
      }

      final targetCenter = targetLeft + (targetWidth / 2);
      final desiredOffset = targetCenter - (viewportWidth / 2);
      final maxOffset = math.max(0.0, contentWidth - viewportWidth);
      final clampedOffset = desiredOffset.clamp(0.0, maxOffset);

      _scrollController.animateTo(
        clampedOffset,
        duration: duration,
        curve: curve,
      );
    });
  }
}

class _AppTabBarItem extends StatefulWidget {
  const _AppTabBarItem({
    required this.label,
    required this.isSelected,
    required this.activeTextStyle,
    required this.inactiveTextStyle,
    required this.animationDuration,
    required this.animationCurve,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final TextStyle activeTextStyle;
  final TextStyle inactiveTextStyle;
  final Duration animationDuration;
  final Curve animationCurve;
  final VoidCallback onTap;

  @override
  State<_AppTabBarItem> createState() => _AppTabBarItemState();
}

class _AppTabBarItemState extends State<_AppTabBarItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      selected: widget.isSelected,
      button: true,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1,
        duration: Duration(milliseconds: _isPressed ? 80 : 120),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapCancel: () => setState(() => _isPressed = false),
            onTapUp: (_) => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: double.infinity,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedDefaultTextStyle(
                    duration: widget.animationDuration,
                    curve: widget.animationCurve,
                    style: widget.isSelected
                        ? widget.activeTextStyle
                        : widget.inactiveTextStyle,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
