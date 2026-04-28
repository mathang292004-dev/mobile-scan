import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/inputs/country_code_data.dart';
import 'package:emergex/helpers/widgets/inputs/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable phone-number input with an inline regional (country-code) selector.
///
/// Visual layout matches the Figma design for the Add Single User dialog:
/// a single rounded-pill container where the left side shows `+<dial> ▾`
/// and the right side is an expanded digits-only text field.
class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? hint;
  final bool enabled;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.onChanged,
    this.errorText,
    this.hint,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final uniqueDialCodes = kCountries.map((c) => c.dialCode).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ColorHelper.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: hasError ? ColorHelper.starColor : Colors.transparent,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D101828),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Country selector using CustomDropdown
              Align(
                alignment: Alignment.center,
                child: CustomDropdown(
                  items: uniqueDialCodes,
                  initialValue: selectedCountry.dialCode,
                  onChanged: (code) {
                    final country = kCountries.firstWhere(
                      (c) => c.dialCode == code,
                      orElse: () => kDefaultCountry,
                    );
                    onCountryChanged(country);
                  },
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                  decoration: const BoxDecoration(color: Colors.transparent),
                  iconSize: 18,
                  iconColor: ColorHelper.draftColor,
                  textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColorHelper.draftColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              // Phone digits
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(selectedCountry.maxLength),
                  ],
                  onChanged: onChanged,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColorHelper.draftColor,
                      ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorHelper.draftColor.withValues(alpha: 0.5),
                        ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorHelper.starColor,
                    fontSize: 12,
                  ),
            ),
          ),
      ],
    );
  }
}
