import 'package:flutter/material.dart';

class AppActionButtonThin extends StatelessWidget {
  const AppActionButtonThin({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.borderColor,
    this.disabledBorderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.minHeight,
    this.iconSize,
    this.iconGap,
    this.expand,
    this.textStyle,
    this.elevation,
    this.shadowColor,
    this.boxShadow,
  });

  final IconData? icon;
  final String title;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final Color? borderColor;
  final Color? disabledBorderColor;
  final double? borderWidth;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? minHeight;
  final double? iconSize;
  final double? iconGap;
  final bool? expand;
  final TextStyle? textStyle;
  final double? elevation;
  final Color? shadowColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final shouldExpand = expand ?? false;
    final style = _buttonStyle();

    return _withShadow(
      SizedBox(
        width: shouldExpand ? double.infinity : null,
        child: ElevatedButton(
          onPressed: onTap,
          style: style,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: shouldExpand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize),
                SizedBox(width: iconGap ?? 8),
              ],
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle? _buttonStyle() {
    final hasOverrides =
        backgroundColor != null ||
        foregroundColor != null ||
        disabledBackgroundColor != null ||
        disabledForegroundColor != null ||
        borderColor != null ||
        disabledBorderColor != null ||
        borderWidth != null ||
        borderRadius != null ||
        padding != null ||
        minHeight != null ||
        textStyle != null ||
        elevation != null ||
        shadowColor != null;

    if (!hasOverrides) return null;

    return ButtonStyle(
      backgroundColor: _stateColor(
        enabled: backgroundColor,
        disabled: disabledBackgroundColor,
      ),
      foregroundColor: _stateColor(
        enabled: foregroundColor,
        disabled: disabledForegroundColor,
      ),
      padding: padding == null ? null : WidgetStatePropertyAll(padding),
      minimumSize: minHeight == null
          ? null
          : WidgetStatePropertyAll(Size(0, minHeight!)),
      textStyle: textStyle == null ? null : WidgetStatePropertyAll(textStyle),
      elevation: elevation == null ? null : WidgetStatePropertyAll(elevation),
      shadowColor: shadowColor == null
          ? null
          : WidgetStatePropertyAll(shadowColor),
      shape: borderRadius == null && borderColor == null && borderWidth == null
          ? null
          : WidgetStateProperty.resolveWith((states) {
              final effectiveBorderColor = states.contains(WidgetState.disabled)
                  ? disabledBorderColor
                  : borderColor;
              final side =
                  effectiveBorderColor == null || (borderWidth ?? 0) <= 0
                  ? BorderSide.none
                  : BorderSide(
                      color: effectiveBorderColor,
                      width: borderWidth ?? 1,
                    );

              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius ?? 8),
                side: side,
              );
            }),
    );
  }

  WidgetStateProperty<Color?>? _stateColor({
    required Color? enabled,
    required Color? disabled,
  }) {
    if (enabled == null && disabled == null) return null;

    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return disabled;
      }
      return enabled;
    });
  }

  Widget _withShadow(Widget child) {
    if (boxShadow == null) return child;

    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: boxShadow),
      child: child,
    );
  }
}
