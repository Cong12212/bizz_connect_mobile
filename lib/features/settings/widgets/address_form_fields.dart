import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts/data/location_repository.dart';

class AddressFormFields extends ConsumerStatefulWidget {
  const AddressFormFields({
    required this.addressDetailController,
    this.initialCountry,
    this.initialState,
    this.initialCity,
    this.onCountryChanged,
    this.onStateChanged,
    this.onCityChanged,
    super.key,
  });

  final TextEditingController addressDetailController;
  final String? initialCountry;
  final String? initialState;
  final String? initialCity;
  final ValueChanged<String?>? onCountryChanged;
  final ValueChanged<String?>? onStateChanged;
  final ValueChanged<String?>? onCityChanged;

  @override
  ConsumerState<AddressFormFields> createState() => _AddressFormFieldsState();
}

class _AddressFormFieldsState extends ConsumerState<AddressFormFields> {
  List<GeoItem> _countries = [];
  List<GeoItem> _states = [];
  List<GeoItem> _cities = [];
  String? _countryCode;
  String? _stateCode;
  String? _cityCode;

  @override
  void initState() {
    super.initState();
    _countryCode = widget.initialCountry;
    _stateCode = widget.initialState;
    _cityCode = widget.initialCity;

    _loadCountries().then((_) async {
      if (_countryCode != null && _countryCode!.isNotEmpty) {
        await _loadStates(_countryCode!);
      }
      if (_stateCode != null && _stateCode!.isNotEmpty) {
        await _loadCities(_stateCode!);
      }
    });
  }

  Future<void> _loadCountries() async {
    final repo = ref.read(locationsRepositoryProvider);
    final list = await repo.getCountries();
    if (mounted) setState(() => _countries = list);
  }

  Future<void> _loadStates(String countryCode) async {
    final repo = ref.read(locationsRepositoryProvider);
    final list = await repo.getStates(countryCode);
    if (mounted) setState(() => _states = list);
  }

  Future<void> _loadCities(String stateCode) async {
    final repo = ref.read(locationsRepositoryProvider);
    final list = await repo.getCities(stateCode);
    if (mounted) setState(() => _cities = list);
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address detail
        const Text(
          'Address Detail',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.addressDetailController,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 16),

        // Country
        DropdownButtonFormField<String>(
          value: _countryCode?.isEmpty == true ? null : _countryCode,
          decoration: _dropdownDecoration('Country'),
          isExpanded: true,
          items: _countries
              .map(
                (e) => DropdownMenuItem(
                  value: e.code,
                  child: Text('${e.name} (${e.code})'),
                ),
              )
              .toList(),
          onChanged: (val) async {
            setState(() {
              _countryCode = val;
              _stateCode = null;
              _cityCode = null;
              _states = [];
              _cities = [];
            });
            widget.onCountryChanged?.call(val);
            if (val != null && val.isNotEmpty) {
              await _loadStates(val);
            }
          },
        ),
        const SizedBox(height: 16),

        // State
        DropdownButtonFormField<String>(
          value: _stateCode?.isEmpty == true ? null : _stateCode,
          decoration: _dropdownDecoration('State'),
          isExpanded: true,
          items: _states
              .map(
                (e) => DropdownMenuItem(
                  value: e.code,
                  child: Text('${e.name} (${e.code})'),
                ),
              )
              .toList(),
          onChanged: (val) async {
            setState(() {
              _stateCode = val;
              _cityCode = null;
              _cities = [];
            });
            widget.onStateChanged?.call(val);
            if (val != null && val.isNotEmpty) {
              await _loadCities(val);
            }
          },
        ),
        const SizedBox(height: 16),

        // City
        DropdownButtonFormField<String>(
          value: _cityCode?.isEmpty == true ? null : _cityCode,
          decoration: _dropdownDecoration('City'),
          isExpanded: true,
          items: _cities
              .map(
                (e) => DropdownMenuItem(
                  value: e.code,
                  child: Text('${e.name} (${e.code})'),
                ),
              )
              .toList(),
          onChanged: (val) {
            setState(() => _cityCode = val);
            widget.onCityChanged?.call(val);
          },
        ),
      ],
    );
  }
}
