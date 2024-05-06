class CountryData {
  final String name;
  final String isoCode;
  final String iso3Code;
  final String phoneCode;

  CountryData(
      {required this.isoCode,
      required this.iso3Code,
      required this.phoneCode,
      required this.name});

  factory CountryData.fromMap(Map<String, String> map) => CountryData(
        name: map['name']!,
        isoCode: map['isoCode']!,
        iso3Code: map['iso3Code']!,
        phoneCode: map['phoneCode']!,
      );
}
