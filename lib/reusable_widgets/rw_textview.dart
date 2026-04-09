import 'package:flutter/material.dart';

class RwTextview extends StatefulWidget {
  const RwTextview({
    super.key,
    required this.controller,
    this.bordercolor = Colors.black26,
    this.focusBordercolor = const Color(0xFF96C8E3),
    this.textColor = Colors.black87,
    this.label,
    this.labelColor = Colors.black87,
    this.hint,
    this.hintColor = Colors.grey,
    this.textNumeric = false,
    this.isEmail = false,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.iconColor,
    this.validator,
  });

  final TextEditingController controller;
  final Color? bordercolor;
  final Color? focusBordercolor;
  final Color? textColor;
  final String? label;
  final Color? labelColor;
  final String? hint;
  final Color? hintColor;
  final bool? textNumeric;
  final bool? isEmail;
  final bool? isPassword;

  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Color? iconColor;

  final FormFieldValidator? validator;

  @override
  State<RwTextview> createState() => _RwTextviewState();
}

class _RwTextviewState extends State<RwTextview> {
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword == true;
  }

  // Helper method for email validation
  String? _validateInput(String? value) {
    // 1. Run the custom validator if one was provided externally
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    // 2. Internal Email Validation Logic
    if (widget.isEmail == true) {
      if (value == null || value.isEmpty) {
        return 'Veuillez entrer votre email';
      }
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Veuillez entrer un email valide';
      }
    }

    // 3. Internal Password Validation Logic (Min 8 characters)
    if (widget.isPassword == true) {
      if (value == null || value.isEmpty) {
        return 'Veuillez entrer un mot de passe';
      }
      if (value.length < 8) {
        return 'Le mot de passe doit contenir au moins 8 caractères';
      }
    }

    return null; // Return null if everything is fine
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      // Use the new internal validation method
      validator: _validateInput,

      obscureText: widget.isPassword == true ? _obscure : false,

      keyboardType: widget.textNumeric == true
          ? TextInputType.number
          : widget.isEmail == true
          ? TextInputType.emailAddress
          : TextInputType.text,

      style: TextStyle(color: widget.textColor),

      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        labelText: widget.label,
        labelStyle: TextStyle(color: widget.labelColor),
        hintText: widget.hint,
        hintStyle: TextStyle(color: widget.hintColor),

        prefixIcon: widget.isPassword == true
            ? IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            size: 15,
            color: widget.iconColor,
          ),
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
        )
            : widget.prefixIcon != null
            ? Icon(
          widget.prefixIcon!,
          size: 15,
          color: widget.iconColor,
        )
            : null,

        suffixIcon: widget.suffixIcon != null
            ? Icon(
          widget.suffixIcon!,
          size: 15,
          color: widget.iconColor,
        )
            : null,

        // ... borders remain the same ...
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: widget.bordercolor!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: widget.focusBordercolor!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
