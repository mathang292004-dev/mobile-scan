import 'package:equatable/equatable.dart';

/// A minimal country record for the phone-number regional selector.
class Country extends Equatable {
  final String name;
  final String flag;
  final String isoCode;
  final String dialCode;

  /// Maximum subscriber number length (digits only, excluding dial code).
  final int maxLength;

  const Country({
    required this.name,
    required this.flag,
    required this.isoCode,
    required this.dialCode,
    this.maxLength = 15,
  });

  @override
  List<Object?> get props => [isoCode];
}

/// Static list of supported countries with per-country digit limits.
const List<Country> kCountries = [
  Country(name: 'India',                flag: '🇮🇳', isoCode: 'IN', dialCode: '+91',  maxLength: 10),
  Country(name: 'United States',        flag: '🇺🇸', isoCode: 'US', dialCode: '+1',   maxLength: 10),
  Country(name: 'United Kingdom',       flag: '🇬🇧', isoCode: 'GB', dialCode: '+44',  maxLength: 10),
  Country(name: 'United Arab Emirates', flag: '🇦🇪', isoCode: 'AE', dialCode: '+971', maxLength: 9),
  Country(name: 'Saudi Arabia',         flag: '🇸🇦', isoCode: 'SA', dialCode: '+966', maxLength: 9),
  Country(name: 'Canada',               flag: '🇨🇦', isoCode: 'CA', dialCode: '+1',   maxLength: 10),
  Country(name: 'Australia',            flag: '🇦🇺', isoCode: 'AU', dialCode: '+61',  maxLength: 9),
  Country(name: 'Germany',              flag: '🇩🇪', isoCode: 'DE', dialCode: '+49',  maxLength: 11),
  Country(name: 'France',               flag: '🇫🇷', isoCode: 'FR', dialCode: '+33',  maxLength: 9),
  Country(name: 'Italy',                flag: '🇮🇹', isoCode: 'IT', dialCode: '+39',  maxLength: 10),
  Country(name: 'Spain',                flag: '🇪🇸', isoCode: 'ES', dialCode: '+34',  maxLength: 9),
  Country(name: 'Netherlands',          flag: '🇳🇱', isoCode: 'NL', dialCode: '+31',  maxLength: 9),
  Country(name: 'Singapore',            flag: '🇸🇬', isoCode: 'SG', dialCode: '+65',  maxLength: 8),
  Country(name: 'Malaysia',             flag: '🇲🇾', isoCode: 'MY', dialCode: '+60',  maxLength: 10),
  Country(name: 'Japan',                flag: '🇯🇵', isoCode: 'JP', dialCode: '+81',  maxLength: 11),
  Country(name: 'China',                flag: '🇨🇳', isoCode: 'CN', dialCode: '+86',  maxLength: 11),
  Country(name: 'Brazil',               flag: '🇧🇷', isoCode: 'BR', dialCode: '+55',  maxLength: 11),
  Country(name: 'Mexico',               flag: '🇲🇽', isoCode: 'MX', dialCode: '+52',  maxLength: 10),
  Country(name: 'South Africa',         flag: '🇿🇦', isoCode: 'ZA', dialCode: '+27',  maxLength: 9),
  Country(name: 'Nigeria',              flag: '🇳🇬', isoCode: 'NG', dialCode: '+234', maxLength: 10),
  Country(name: 'Pakistan',             flag: '🇵🇰', isoCode: 'PK', dialCode: '+92',  maxLength: 10),
  Country(name: 'Bangladesh',           flag: '🇧🇩', isoCode: 'BD', dialCode: '+880', maxLength: 10),
  Country(name: 'Sri Lanka',            flag: '🇱🇰', isoCode: 'LK', dialCode: '+94',  maxLength: 9),
  Country(name: 'Indonesia',            flag: '🇮🇩', isoCode: 'ID', dialCode: '+62',  maxLength: 12),
  Country(name: 'Philippines',          flag: '🇵🇭', isoCode: 'PH', dialCode: '+63',  maxLength: 10),
];

/// Default country (India).
const Country kDefaultCountry =
    Country(name: 'India', flag: '🇮🇳', isoCode: 'IN', dialCode: '+91', maxLength: 10);

/// Finds a country by ISO code (case-insensitive). Returns default if not found.
Country findCountryByIso(String isoCode) {
  final upper = isoCode.toUpperCase();
  return kCountries.firstWhere(
    (c) => c.isoCode == upper,
    orElse: () => kDefaultCountry,
  );
}
