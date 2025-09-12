import 'package:flutter/cupertino.dart';

class DSInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final int? maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;
  final FocusNode? focusNode;
  final TapRegionCallback? onTapOutside;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;

  const DSInputField({
    super.key,
    this.controller,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.focusNode,
    this.onTapOutside,
    this.onEditingComplete,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLength: maxLength,
      maxLines: maxLines,
      prefix: prefix,
      suffix: suffix,
      enabled: enabled,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.separator, width: 1),
      ),
      style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
      placeholderStyle: const TextStyle(color: CupertinoColors.placeholderText),
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      onTapOutside: onTapOutside,
      focusNode: focusNode,
    );
  }
}
