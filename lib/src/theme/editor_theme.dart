import 'package:flutter/material.dart';

/// Расширение темы для виджетов редактора и просмотрщика документов
class EditorThemeExtension extends ThemeExtension<EditorThemeExtension> {
  final Color backgroundColor;
  final Color borderColor;
  final Color selectedBorderColor;
  final Color selectedBackgroundColor;
  final Color toolbarColor;
  final Color toolbarIconColor;
  final Color toolbarSelectedIconColor;
  final Color captionColor;
  final Color linkColor;
  final Color placeholderColor;
  final Color floatIndicatorColor;
  final Color floatIndicatorTextColor;

  final double borderRadius;
  final double elementSpacing;
  final BorderRadius containerBorderRadius;
  final BoxShadow containerShadow;

  final TextStyle defaultTextStyle;
  final TextStyle titleTextStyle;
  final TextStyle subtitleTextStyle;
  final TextStyle captionTextStyle;
  final TextStyle placeholderTextStyle;
  final TextStyle floatLabelTextStyle;

  const EditorThemeExtension({
    required this.backgroundColor,
    required this.borderColor,
    required this.selectedBorderColor,
    required this.selectedBackgroundColor,
    required this.toolbarColor,
    required this.toolbarIconColor,
    required this.toolbarSelectedIconColor,
    required this.captionColor,
    required this.linkColor,
    required this.placeholderColor,
    required this.floatIndicatorColor,
    required this.floatIndicatorTextColor,
    required this.borderRadius,
    required this.elementSpacing,
    required this.containerBorderRadius,
    required this.containerShadow,
    required this.defaultTextStyle,
    required this.titleTextStyle,
    required this.subtitleTextStyle,
    required this.captionTextStyle,
    required this.placeholderTextStyle,
    required this.floatLabelTextStyle,
  });

  @override
  ThemeExtension<EditorThemeExtension> copyWith({
    Color? backgroundColor,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? selectedBackgroundColor,
    Color? toolbarColor,
    Color? toolbarIconColor,
    Color? toolbarSelectedIconColor,
    Color? captionColor,
    Color? linkColor,
    Color? placeholderColor,
    Color? floatIndicatorColor,
    Color? floatIndicatorTextColor,
    double? borderRadius,
    double? elementSpacing,
    BorderRadius? containerBorderRadius,
    BoxShadow? containerShadow,
    TextStyle? defaultTextStyle,
    TextStyle? titleTextStyle,
    TextStyle? subtitleTextStyle,
    TextStyle? captionTextStyle,
    TextStyle? placeholderTextStyle,
    TextStyle? floatLabelTextStyle,
  }) {
    return EditorThemeExtension(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      selectedBackgroundColor: selectedBackgroundColor ?? this.selectedBackgroundColor,
      toolbarColor: toolbarColor ?? this.toolbarColor,
      toolbarIconColor: toolbarIconColor ?? this.toolbarIconColor,
      toolbarSelectedIconColor: toolbarSelectedIconColor ?? this.toolbarSelectedIconColor,
      captionColor: captionColor ?? this.captionColor,
      linkColor: linkColor ?? this.linkColor,
      placeholderColor: placeholderColor ?? this.placeholderColor,
      floatIndicatorColor: floatIndicatorColor ?? this.floatIndicatorColor,
      floatIndicatorTextColor: floatIndicatorTextColor ?? this.floatIndicatorTextColor,
      borderRadius: borderRadius ?? this.borderRadius,
      elementSpacing: elementSpacing ?? this.elementSpacing,
      containerBorderRadius: containerBorderRadius ?? this.containerBorderRadius,
      containerShadow: containerShadow ?? this.containerShadow,
      defaultTextStyle: defaultTextStyle ?? this.defaultTextStyle,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      subtitleTextStyle: subtitleTextStyle ?? this.subtitleTextStyle,
      captionTextStyle: captionTextStyle ?? this.captionTextStyle,
      placeholderTextStyle: placeholderTextStyle ?? this.placeholderTextStyle,
      floatLabelTextStyle: floatLabelTextStyle ?? this.floatLabelTextStyle,
    );
  }

  @override
  ThemeExtension<EditorThemeExtension> lerp(covariant ThemeExtension<EditorThemeExtension>? other, double t) {
    if (other is! EditorThemeExtension) {
      return this;
    }

    // Вспомогательная функция для интерполяции значений
    double _lerpDouble(double a, double b, double t) {
      return a + (b - a) * t;
    }

    return EditorThemeExtension(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      selectedBorderColor: Color.lerp(selectedBorderColor, other.selectedBorderColor, t)!,
      selectedBackgroundColor: Color.lerp(selectedBackgroundColor, other.selectedBackgroundColor, t)!,
      toolbarColor: Color.lerp(toolbarColor, other.toolbarColor, t)!,
      toolbarIconColor: Color.lerp(toolbarIconColor, other.toolbarIconColor, t)!,
      toolbarSelectedIconColor: Color.lerp(toolbarSelectedIconColor, other.toolbarSelectedIconColor, t)!,
      captionColor: Color.lerp(captionColor, other.captionColor, t)!,
      linkColor: Color.lerp(linkColor, other.linkColor, t)!,
      placeholderColor: Color.lerp(placeholderColor, other.placeholderColor, t)!,
      floatIndicatorColor: Color.lerp(floatIndicatorColor, other.floatIndicatorColor, t)!,
      floatIndicatorTextColor: Color.lerp(floatIndicatorTextColor, other.floatIndicatorTextColor, t)!,
      borderRadius: _lerpDouble(borderRadius, other.borderRadius, t),
      elementSpacing: _lerpDouble(elementSpacing, other.elementSpacing, t),
      containerBorderRadius: BorderRadius.lerp(containerBorderRadius, other.containerBorderRadius, t)!,
      containerShadow: BoxShadow.lerp(containerShadow, other.containerShadow, t)!,
      defaultTextStyle: TextStyle.lerp(defaultTextStyle, other.defaultTextStyle, t)!,
      titleTextStyle: TextStyle.lerp(titleTextStyle, other.titleTextStyle, t)!,
      subtitleTextStyle: TextStyle.lerp(subtitleTextStyle, other.subtitleTextStyle, t)!,
      captionTextStyle: TextStyle.lerp(captionTextStyle, other.captionTextStyle, t)!,
      placeholderTextStyle: TextStyle.lerp(placeholderTextStyle, other.placeholderTextStyle, t)!,
      floatLabelTextStyle: TextStyle.lerp(floatLabelTextStyle, other.floatLabelTextStyle, t)!,
    );
  }

  // Светлая тема по умолчанию
  static EditorThemeExtension light = EditorThemeExtension(
    backgroundColor: Colors.white,
    borderColor: Colors.grey.shade300,
    selectedBorderColor: Colors.blue.shade400,
    selectedBackgroundColor: Colors.blue.shade50,
    toolbarColor: Colors.white,
    toolbarIconColor: Colors.grey.shade700,
    toolbarSelectedIconColor: Colors.blue,
    captionColor: Colors.grey,
    linkColor: Colors.blue,
    placeholderColor: Colors.grey.shade400,
    floatIndicatorColor: Colors.blue.withOpacity(0.2),
    floatIndicatorTextColor: Colors.blue,
    borderRadius: 8.0,
    elementSpacing: 16.0,
    containerBorderRadius: BorderRadius.circular(8.0),
    containerShadow: BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 4.0),
    defaultTextStyle: TextStyle(fontSize: 16.0, color: Colors.black87),
    titleTextStyle: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87),
    subtitleTextStyle: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500, color: Colors.black87),
    captionTextStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 12.0, color: Colors.grey),
    placeholderTextStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16.0),
    floatLabelTextStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
  );

  // Темная тема по умолчанию
  static EditorThemeExtension dark = EditorThemeExtension(
    backgroundColor: Colors.grey.shade900,
    borderColor: Colors.grey.shade700,
    selectedBorderColor: Colors.blue.shade300,
    selectedBackgroundColor: Colors.blue.shade900,
    toolbarColor: Colors.grey.shade800,
    toolbarIconColor: Colors.grey.shade300,
    toolbarSelectedIconColor: Colors.blue.shade300,
    captionColor: Colors.grey.shade400,
    linkColor: Colors.blue.shade300,
    placeholderColor: Colors.grey.shade600,
    floatIndicatorColor: Colors.blue.shade900,
    floatIndicatorTextColor: Colors.blue.shade300,
    borderRadius: 8.0,
    elementSpacing: 16.0,
    containerBorderRadius: BorderRadius.circular(8.0),
    containerShadow: BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 4.0),
    defaultTextStyle: TextStyle(fontSize: 16.0, color: Colors.white),
    titleTextStyle: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
    subtitleTextStyle: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500, color: Colors.white),
    captionTextStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 12.0, color: Colors.grey.shade400),
    placeholderTextStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16.0),
    floatLabelTextStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade300),
  );

  /// Создает тему редактора на основе colorScheme текущей темы приложения
  static EditorThemeExtension fromColorScheme(
    ColorScheme colorScheme, {
    // Опциональные параметры для стилей текста
    TextStyle? defaultTextStyle,
    TextStyle? titleTextStyle,
    TextStyle? subtitleTextStyle,
    TextStyle? captionTextStyle,
    TextStyle? placeholderTextStyle,
    TextStyle? floatLabelTextStyle,
    // Опциональные параметры для размеров и радиусов
    double? borderRadius,
    double? elementSpacing,
    BorderRadius? containerBorderRadius,
    // Опциональный параметр для настройки тени
    BoxShadow? containerShadow,
    // Опциональные параметры для цветов
    Color? backgroundColor,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? selectedBackgroundColor,
    Color? toolbarColor,
    Color? toolbarIconColor,
    Color? toolbarSelectedIconColor,
    Color? captionColor,
    Color? linkColor,
    Color? placeholderColor,
    Color? floatIndicatorColor,
    Color? floatIndicatorTextColor,
  }) {
    final bool isDark = colorScheme.brightness == Brightness.dark;

    // Базовые цвета из colorScheme
    final primaryColor = colorScheme.primary;
    final secondaryColor = colorScheme.secondary;
    final defaultBackgroundColor = colorScheme.surface;
    final surfaceColor = colorScheme.surfaceVariant;
    final defaultBorderColor = isDark ? colorScheme.outline.withOpacity(0.7) : colorScheme.outline.withOpacity(0.4);
    final textColor = colorScheme.onSurface;
    final onPrimaryColor = colorScheme.onPrimary;

    // Цвета для тулбара и элементов интерфейса
    final defaultToolbarColor = isDark ? colorScheme.surfaceVariant : colorScheme.surface;
    final defaultFloatIndicatorColor = primaryColor.withOpacity(isDark ? 0.3 : 0.15);

    // Общие настройки для обеих тем
    final defaultBorderRadius = 8.0;
    final defaultElementSpacing = 16.0;

    // Настройка параметров тени
    final defaultContainerShadow = BoxShadow(
      color: isDark ? Colors.black : Colors.black12,
      offset: Offset(0, 2),
      blurRadius: isDark ? 6.0 : 4.0,
    );

    // Настройка стилей текста
    final baseDefaultTextStyle = TextStyle(fontSize: 16.0, color: textColor);

    final baseTitleTextStyle = TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: textColor);

    final baseSubtitleTextStyle = TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500, color: textColor);

    final baseCaptionTextStyle = TextStyle(
      fontStyle: FontStyle.italic,
      fontSize: 12.0,
      color: colorScheme.onSurfaceVariant,
    );

    final basePlaceholderTextStyle = TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7), fontSize: 16.0);

    final baseFloatLabelTextStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor);

    return EditorThemeExtension(
      backgroundColor: backgroundColor ?? defaultBackgroundColor,
      borderColor: borderColor ?? defaultBorderColor,
      selectedBorderColor: selectedBorderColor ?? primaryColor,
      selectedBackgroundColor: selectedBackgroundColor ?? primaryColor.withOpacity(isDark ? 0.3 : 0.1),
      toolbarColor: toolbarColor ?? defaultToolbarColor,
      toolbarIconColor: toolbarIconColor ?? colorScheme.onSurfaceVariant,
      toolbarSelectedIconColor: toolbarSelectedIconColor ?? primaryColor,
      captionColor: captionColor ?? colorScheme.onSurfaceVariant,
      linkColor: linkColor ?? secondaryColor,
      placeholderColor: placeholderColor ?? colorScheme.surfaceVariant,
      floatIndicatorColor: floatIndicatorColor ?? defaultFloatIndicatorColor,
      floatIndicatorTextColor: floatIndicatorTextColor ?? primaryColor,
      borderRadius: borderRadius ?? defaultBorderRadius,
      elementSpacing: elementSpacing ?? defaultElementSpacing,
      containerBorderRadius: containerBorderRadius ?? BorderRadius.circular(borderRadius ?? defaultBorderRadius),
      containerShadow: containerShadow ?? defaultContainerShadow,
      defaultTextStyle: defaultTextStyle ?? baseDefaultTextStyle,
      titleTextStyle: titleTextStyle ?? baseTitleTextStyle,
      subtitleTextStyle: subtitleTextStyle ?? baseSubtitleTextStyle,
      captionTextStyle: captionTextStyle ?? baseCaptionTextStyle,
      placeholderTextStyle: placeholderTextStyle ?? basePlaceholderTextStyle,
      floatLabelTextStyle: floatLabelTextStyle ?? baseFloatLabelTextStyle,
    );
  }

  /// Создает тему редактора на основе текущей темы приложения
  static EditorThemeExtension fromTheme(
    ThemeData theme, {
    // Опциональные параметры для стилей текста
    TextStyle? defaultTextStyle,
    TextStyle? titleTextStyle,
    TextStyle? subtitleTextStyle,
    TextStyle? captionTextStyle,
    TextStyle? placeholderTextStyle,
    TextStyle? floatLabelTextStyle,
    // Опциональные параметры для размеров и радиусов
    double? borderRadius,
    double? elementSpacing,
    BorderRadius? containerBorderRadius,
    // Опциональный параметр для настройки тени
    BoxShadow? containerShadow,
    // Опциональные параметры для цветов
    Color? backgroundColor,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? selectedBackgroundColor,
    Color? toolbarColor,
    Color? toolbarIconColor,
    Color? toolbarSelectedIconColor,
    Color? captionColor,
    Color? linkColor,
    Color? placeholderColor,
    Color? floatIndicatorColor,
    Color? floatIndicatorTextColor,
  }) {
    // Используем стили текста из темы, если они не предоставлены
    final TextStyle? baseDefaultTextStyle = defaultTextStyle;
    final TextStyle? baseTitleTextStyle = titleTextStyle;
    final TextStyle? baseSubtitleTextStyle = subtitleTextStyle;
    final TextStyle? baseCaptionTextStyle =
        captionTextStyle ?? theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic);
    final TextStyle? basePlaceholderTextStyle =
        placeholderTextStyle ??
        theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7));
    final TextStyle? baseFloatLabelTextStyle =
        floatLabelTextStyle ?? TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary);

    return fromColorScheme(
      theme.colorScheme,
      defaultTextStyle: baseDefaultTextStyle,
      titleTextStyle: baseTitleTextStyle,
      subtitleTextStyle: baseSubtitleTextStyle,
      captionTextStyle: baseCaptionTextStyle,
      placeholderTextStyle: basePlaceholderTextStyle,
      floatLabelTextStyle: baseFloatLabelTextStyle,
      borderRadius: borderRadius,
      elementSpacing: elementSpacing,
      containerBorderRadius: containerBorderRadius,
      containerShadow: containerShadow,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      selectedBorderColor: selectedBorderColor,
      selectedBackgroundColor: selectedBackgroundColor,
      toolbarColor: toolbarColor,
      toolbarIconColor: toolbarIconColor,
      toolbarSelectedIconColor: toolbarSelectedIconColor,
      captionColor: captionColor,
      linkColor: linkColor,
      placeholderColor: placeholderColor,
      floatIndicatorColor: floatIndicatorColor,
      floatIndicatorTextColor: floatIndicatorTextColor,
    );
  }

  // Вспомогательный метод для получения расширения из темы
  static EditorThemeExtension of(BuildContext context) {
    final themeExtension = Theme.of(context).extension<EditorThemeExtension>();
    if (themeExtension != null) {
      return themeExtension;
    }

    // Если расширение не найдено, создаем его на основе текущей темы
    return fromTheme(Theme.of(context));
  }
}
