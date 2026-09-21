import 'package:flutter/material.dart';

/// Mirrors ui/components/ArtboardInputField.kt.
class ArtboardInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final bool isPassword;
  final TextInputType keyboardType;

  const ArtboardInputField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder = '',
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<ArtboardInputField> createState() => _ArtboardInputFieldState();
}

class _ArtboardInputFieldState extends State<ArtboardInputField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
