import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RwTextview extends StatefulWidget {
  const RwTextview({
    super.key,
    required this.controller,
    this.backgroundColor,
    this.bordercolor = Colors.black26,
    this.focusBordercolor = const Color(0xFF96C8E3),
    this.textColor = Colors.black87,
    this.label,
    this.labelColor = Colors.black87,
    this.hint,
    this.hintColor = Colors.grey,
    this.textNumeric = false,
    this.textDouble = false,
    this.isEmail = false,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.iconColor,
    this.validator,
    this.maxLength,
    this.minLength,
    this.onSubmitted, // Nouvelle propriété
  });

  final TextEditingController controller;
  final Color? bordercolor;
  final Color? backgroundColor;
  final Color? focusBordercolor;
  final Color? textColor;
  final String? label;
  final Color? labelColor;
  final String? hint;
  final Color? hintColor;
  final bool? textNumeric;
  final bool? textDouble;
  final bool? isEmail;
  final bool? isPassword;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Color? iconColor;
  final FormFieldValidator? validator;
  final int? maxLength;
  final int? minLength;
  final ValueChanged<String>? onSubmitted; // Nouvelle propriété

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

  String? _validateInput(String? value) {
    // 1. Validateur externe (prioritaire)
    if (widget.validator != null) {
      final externalResult = widget.validator!(value);
      if (externalResult != null) return externalResult;
    }

    // Si la valeur est nulle ou vide, on s'arrête là (la gestion du "Requis" est faite en externe)
    if (value == null || value.isEmpty) return null;

    // 2. Validation Longueur Minimum
    if (widget.minLength != null && value.length < widget.minLength!) {
      return 'Minimum ${widget.minLength} caractères';
    }

    // 3. Validation Double (Montant)
    if (widget.textDouble == true) {
      final n = double.tryParse(value);
      if (n == null) return 'Format numérique invalide';
    }

    // 4. Validation Email
    if (widget.isEmail == true) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) return 'Email invalide';
    }

    // 5. Validation Password (si pas de minLength défini, défaut à 8)
    if (widget.isPassword == true && widget.minLength == null) {
      if (value.length < 8) return 'Minimum 8 caractères';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: _validateInput,
      onFieldSubmitted: widget.onSubmitted,
      // Liaison ici
      obscureText: widget.isPassword == true ? _obscure : false,
      maxLength: widget.maxLength,
      // Limite physique de saisie
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      style: TextStyle(color: widget.textColor),

      keyboardType: (widget.textNumeric == true || widget.textDouble == true)
          ? const TextInputType.numberWithOptions(decimal: true)
          : widget.isEmail == true
          ? TextInputType.emailAddress
          : TextInputType.text,

      inputFormatters: [
        if (widget.textNumeric == true && widget.textDouble == false)
          FilteringTextInputFormatter.digitsOnly,

        if (widget.textDouble == true)
          // Modified Regex: Allows digits, and IF there is a dot, allows max 3 digits after it
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
      ],

      decoration: InputDecoration(
        counterText: "",
        // Masque le compteur par défaut si vous voulez un design épuré
        filled: widget.backgroundColor != null ? true : false,
        fillColor: widget.backgroundColor,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),
        labelText: widget.label,
        labelStyle: TextStyle(color: widget.labelColor),
        hintText: widget.hint,
        hintStyle: TextStyle(color: widget.hintColor),

        prefixIcon: widget.isPassword == true
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: widget.iconColor,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.prefixIcon != null
            ? Icon(widget.prefixIcon!, size: 18, color: widget.iconColor)
            : null,

        suffixIcon: widget.suffixIcon != null
            ? Icon(widget.suffixIcon!, size: 18, color: widget.iconColor)
            : null,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.bordercolor ?? Colors.black26,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.focusBordercolor ?? const Color(0xFF96C8E3),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
