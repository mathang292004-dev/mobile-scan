import 'package:flutter/material.dart';

/// A stable TextField widget that properly handles TextEditingController lifecycle
/// and prevents keyboard flicker when used with Bloc/Cubit state management.
///
/// **Problem:**
/// When TextFields are wrapped in BlocBuilder and the controller is synced with state
/// on every rebuild (via didUpdateWidget), the TextField loses focus momentarily,
/// causing the keyboard to close and reopen.
///
/// **Solution:**
/// This widget maintains a stable TextEditingController internally and only syncs
/// state → controller when explicitly needed (e.g., initial value or external reset),
/// not on every keystroke.
///
/// **Usage:**
/// ```dart
/// StableTextField(
///   initialValue: someState.fieldValue,
///   hint: 'Enter text',
///   onChanged: (value) => cubit.updateField(value),
/// )
/// ```
class StableTextField extends StatefulWidget {
  /// Initial value for the text field. Only applied on first build or when
  /// [forceUpdateKey] changes.
  final String? initialValue;

  /// Key to force controller text update. Change this value to reset the
  /// controller to [initialValue]. Useful for "reset form" scenarios.
  final Object? forceUpdateKey;

  /// Called when the text changes. Use this to update Bloc/Cubit state.
  final ValueChanged<String>? onChanged;

  /// Hint text displayed when the field is empty.
  final String? hint;

  /// Label text displayed above the field.
  final String? label;

  /// Whether the field is enabled for editing.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Maximum number of lines for the text field.
  final int? maxLines;

  /// Minimum number of lines for the text field.
  final int minLines;

  /// Maximum length of text allowed.
  final int? maxLength;

  /// Focus node for the text field.
  final FocusNode? focusNode;

  /// Keyboard type for the text field.
  final TextInputType keyboardType;

  /// Text input action for the keyboard.
  final TextInputAction? textInputAction;

  /// Content padding for the text field.
  final EdgeInsetsGeometry? contentPadding;

  /// Fill color for the text field background.
  final Color? fillColor;

  /// Border for the text field.
  final InputBorder? border;

  /// Prefix widget.
  final Widget? prefix;

  /// Suffix widget.
  final Widget? suffix;

  /// Prefix icon widget.
  final Widget? prefixIcon;

  /// Suffix icon widget.
  final Widget? suffixIcon;

  /// Validator function for form validation.
  final String? Function(String?)? validator;

  /// Text style for the input text.
  final TextStyle? style;

  /// Hint style for the placeholder text.
  final TextStyle? hintStyle;

  /// Called when the field is tapped.
  final VoidCallback? onTap;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  const StableTextField({
    super.key,
    this.initialValue,
    this.forceUpdateKey,
    this.onChanged,
    this.hint,
    this.label,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.contentPadding,
    this.fillColor,
    this.border,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.style,
    this.hintStyle,
    this.onTap,
    this.obscureText = false,
  });

  @override
  State<StableTextField> createState() => _StableTextFieldState();
}

class _StableTextFieldState extends State<StableTextField> {
  late TextEditingController _controller;
  Object? _lastForceUpdateKey;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _lastForceUpdateKey = widget.forceUpdateKey;
  }

  @override
  void didUpdateWidget(StableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only reset controller when forceUpdateKey changes (explicit reset request)
    // This prevents keyboard flicker from normal state updates
    if (widget.forceUpdateKey != null &&
        widget.forceUpdateKey != _lastForceUpdateKey) {
      _lastForceUpdateKey = widget.forceUpdateKey;
      // Use post frame callback to avoid disrupting current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.text = widget.initialValue ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
      validator: widget.validator,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: widget.hintStyle,
        prefix: widget.prefix,
        suffix: widget.suffix,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        contentPadding:
            widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: widget.fillColor != null,
        fillColor: widget.fillColor,
        border:
            widget.border ??
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: widget.border,
        focusedBorder: widget.border,
      ),
    );
  }
}

/// A mixin that provides stable TextEditingController management for StatefulWidgets.
///
/// Use this mixin when you need to manage multiple controllers in a form and want
/// to ensure they are properly initialized, not recreated on rebuilds, and disposed.
///
/// **Usage:**
/// ```dart
/// class _MyFormState extends State<MyForm> with StableTextFieldControllers {
///   late final TextEditingController nameController;
///   late final TextEditingController emailController;
///
///   @override
///   void initState() {
///     super.initState();
///     nameController = createController(widget.initialName);
///     emailController = createController(widget.initialEmail);
///   }
///
///   // Controllers are automatically disposed when the State is disposed
/// }
/// ```
mixin StableTextFieldControllers<T extends StatefulWidget> on State<T> {
  final List<TextEditingController> _controllers = [];

  /// Creates a new TextEditingController with the given initial text.
  /// The controller will be automatically disposed when the State is disposed.
  TextEditingController createController([String? initialText]) {
    final controller = TextEditingController(text: initialText ?? '');
    _controllers.add(controller);
    return controller;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}
