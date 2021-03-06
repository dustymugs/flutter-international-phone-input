//library international_phone_input;

import 'dart:async';
import 'dart:convert';

import 'package:international_phone_input/src/phone_service.dart';

import 'country.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InternationalPhoneInput extends StatefulWidget {

	static const String ERROR_TEXT = 'Please enter a valid phone number';
	static const String REQUIRED_TEXT = 'A valid phone number is required';
	static const String HINT_TEXT = 'eg. 244056345';
	static const String HELPER_TEXT = 'A valid phone number includes area/city code';
	static const String LABEL_TEXT = 'Phone number';

  final void Function(
	 	String countryCode,
		String phoneNumber,
	 	String internationalizedPhoneNumber,
	) onPhoneNumberChange;

  final String initialPhoneNumber;
  final String initialCountryCode;
  final String errorText;
	final String requiredText;
  final String hintText;
	final String helperText;
	final String labelText;
  final TextStyle errorStyle;
  final TextStyle hintStyle;
  final TextStyle helperStyle;
  final TextStyle labelStyle;
  final int errorMaxLines;
  final int helperMaxLines;
	final bool isRequired;
	final bool showFlags;
	final bool enabled;
	final bool useFormFields;
	final GlobalKey<FormFieldState> phoneTextKey;
	final FocusNode dialCodeFocusNode;
	final List<String> filteredDialCodes;
	final FocusNode phoneTextFocusNode;
	final TextInputAction phoneTextInputAction;
	final void Function(String newValue) phoneTextOnFieldSubmitted;
	final void Function(Country newValue) dialCodeOnChange;

  InternationalPhoneInput({
		this.onPhoneNumberChange,
		this.initialPhoneNumber,
		this.initialCountryCode,
		this.errorText = ERROR_TEXT,
		this.requiredText = REQUIRED_TEXT,
		this.hintText = HINT_TEXT,
		this.helperText = HELPER_TEXT,
		this.labelText = LABEL_TEXT,
		this.errorStyle,
		this.hintStyle,
		this.helperStyle,
		this.labelStyle,
		this.errorMaxLines = 3,
		this.helperMaxLines = 2,
		this.dialCodeFocusNode,
		this.phoneTextFocusNode,
		this.phoneTextInputAction,
		this.phoneTextOnFieldSubmitted,
		this.dialCodeOnChange,
		this.useFormFields = false,
		this.phoneTextKey,
		this.isRequired = false,
		this.showFlags = true,
		this.enabled = true,
		this.filteredDialCodes,
	});

  static Future<String> internationalizeNumber(String number, String iso) {
    return PhoneService.getNormalizedPhoneNumber(number, iso);
  }

  @override
  _InternationalPhoneInputState createState() =>
      _InternationalPhoneInputState();
}

class _InternationalPhoneInputState extends State<InternationalPhoneInput> {

	GlobalKey<FormFieldState> phoneTextKey;

  Country selectedCountry;
  List<Country> itemList;

  String errorMessage = null;

  TextEditingController phoneTextController;
	bool _inAsyncValidation;

  @override
  void initState() {
		itemList = <Country>[];

		if (widget.useFormFields)
			phoneTextKey = widget.phoneTextKey ?? GlobalKey<FormFieldState>();

		phoneTextController = TextEditingController();
    phoneTextController.text = widget.initialPhoneNumber;

    _fetchCountryData().then((list) {
      Country preSelectedItem;

      if (widget.initialCountryCode != null) {
				String initialCountryCode = widget.initialCountryCode.toString().toUpperCase();
        preSelectedItem = list.firstWhere(
            (e) => (
							(e.code.toUpperCase() == initialCountryCode) ||
							(e.code3.toUpperCase() == initialCountryCode) ||
							(e.dialCode == initialCountryCode)
						),
            orElse: () => list[0]);
      }
		 	else {
        preSelectedItem = list[0];
      }

      setState(() {
        itemList = list;
        selectedCountry = preSelectedItem;
      });
    });

    super.initState();
  }

	@override
	void dispose() {
		phoneTextController.dispose();
		debugPrint('dispose');
		super.dispose();
	}

  String _validatePhoneNumber() {
    String phoneText = phoneTextController.text;

		if (widget.useFormFields && _inAsyncValidation == false) {
			_inAsyncValidation = null;
			return errorMessage;
		}

		if (widget.isRequired && (phoneText == null || phoneText.isEmpty)) {
			if (mounted) {
				setState(() {
					errorMessage = widget.requiredText;
				});
			}
		}
		else if (phoneText != null && phoneText.isNotEmpty) {
			_inAsyncValidation = true;
      PhoneService.parsePhoneNumber(
				phoneText,
			 	selectedCountry.code
			).then((isValid) {
				if (widget.onPhoneNumberChange != null) {
					if (isValid) {
						PhoneService.getNormalizedPhoneNumber(
							phoneText,
						 	selectedCountry.code
						).then(
							(number) {
							 	widget.onPhoneNumberChange(selectedCountry.code3, phoneText, number);
						 	}
						);
					}
				 	else {
						widget.onPhoneNumberChange(selectedCountry.code3, '', '');
					}
				}

				if (mounted) {
					setState(() {
						_inAsyncValidation = false;
						errorMessage = isValid ? null : widget.errorText;
					});
				}

      });
    }
		else {
			if (mounted) {
				setState(() {
					errorMessage = null;
				});
			}
		}

		return errorMessage;
  }

	bool _canUseCountry(Map elem) {
		List<String> filteredDialCodes = widget.filteredDialCodes ?? [];
		if (filteredDialCodes.length < 1)
			return true;

		for (final String dialCode in filteredDialCodes) {
			String _dialCode = dialCode.toString().toUpperCase();
			if (
				(elem['alpha_2_code'].toUpperCase() == _dialCode) ||
				(elem['alpha_3_code'].toUpperCase() == _dialCode) ||
				(elem['dial_code'] == _dialCode)
			) {
				return true;
			}
		}

		return false;
	}

  Future<List<Country>> _fetchCountryData() async {
    var list = await DefaultAssetBundle.of(context).loadString(
			'packages/international_phone_input/assets/countries.json'
		);
    var jsonList = json.decode(list);
    List<Country> elements = [];
    jsonList.forEach((s) {
      Map elem = Map.from(s);
			if (!_canUseCountry(elem)) {
				return;
			}

      elements.add(
				Country(
          name: elem['en_short_name'],
          code: elem['alpha_2_code'],
          code3: elem['alpha_3_code'],
          dialCode: elem['dial_code'],
          flagUri: 'assets/flags/${elem['alpha_2_code'].toLowerCase()}.png'
				)
			);
    });
    return elements;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          DropdownButtonHideUnderline(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: _buildDialCodeWidget(),
            ),
          ),
          Flexible(
            child: _buildPhoneTextWidget(),
					),
        ],
      ),
    );
  }

	Widget _buildDialCodeWidget() {

		List<DropdownMenuItem<Country>> items = itemList.map<DropdownMenuItem<Country>>(
			(Country value) {
				return DropdownMenuItem<Country>(
					value: value,
					child: Container(
						padding: const EdgeInsets.only(bottom: 5.0),
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							children: <Widget>[
								(
									widget.showFlags ?
										Image.asset(
											value.flagUri,
											width: 32.0,
											package: 'international_phone_input',
										) :
										Text(value.code3)
								),
								SizedBox(width: 4),
								Text(value.dialCode)
							],
						),
					),
				);
			}
		).toList();

		// cannot use DropdownButtonFormField as we cannot pass a FocusNode to it
		DropdownButton dropdown = DropdownButton<Country>(
			value: selectedCountry,
			focusNode: widget.dialCodeFocusNode,
			onChanged: (
				widget.enabled ?
					(Country newValue) {
						setState(() {
							selectedCountry = newValue;
						});
						_validatePhoneNumber();
						if (widget.dialCodeOnChange != null)
							widget.dialCodeOnChange(newValue);
					} :
					null
			),
			items: items,
		);

		return dropdown;
	}

	Widget _buildPhoneTextWidget() {

		InputDecoration inputDecoration = InputDecoration(
			errorText: errorMessage,
			hintText: widget.hintText,
			helperText: widget.helperText,
			labelText: widget.labelText,
			errorStyle: widget.errorStyle,
			hintStyle: widget.hintStyle,
			helperStyle: widget.helperStyle,
			labelStyle: widget.labelStyle,
			errorMaxLines: widget.errorMaxLines,
			helperMaxLines: widget.helperMaxLines,
		);

		if (widget.useFormFields) {
			// run validators on reload to process async results
			if (_inAsyncValidation == false)
			 	phoneTextKey.currentState?.validate();

			return TextFormField(
				key: phoneTextKey,
				keyboardType: TextInputType.phone,
				controller: phoneTextController,
				focusNode: widget.phoneTextFocusNode,
				textInputAction: widget.phoneTextInputAction,
				decoration: inputDecoration,
				onChanged: (String value) => _validatePhoneNumber(),
				validator: (String value) => _validatePhoneNumber(),
				onFieldSubmitted: widget.phoneTextOnFieldSubmitted,
				enabled: widget.enabled,
			);
		}
		else {
			return TextField(
				keyboardType: TextInputType.phone,
				controller: phoneTextController,
				focusNode: widget.phoneTextFocusNode,
				textInputAction: widget.phoneTextInputAction,
				decoration: inputDecoration,
				onChanged: (String value) => _validatePhoneNumber(),
				enabled: widget.enabled,
			);
		}
	}
}
