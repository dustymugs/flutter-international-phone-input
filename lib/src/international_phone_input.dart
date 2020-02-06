//library international_phone_input;

import 'dart:async';
import 'dart:convert';

import 'package:international_phone_input/src/phone_service.dart';

import 'country.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InternationalPhoneInput extends StatefulWidget {

	static const String ERROR_TEXT = 'Please enter a valid phone number';
	static const String HINT_TEXT = 'eg. 244056345';
	static const String HELPER_TEXT = 'A valid phone number includes area/city code';
	static const String LABEL_TEXT = 'Phone number';

  final void Function(
		String phoneNumber,
	 	String internationalizedPhoneNumber,
	 	String isoCode
	) onPhoneNumberChange;
  final String initialPhoneNumber;
  final String initialSelection;
  final String errorText;
  final String hintText;
	final String helperText;
	final String labelText;
  final TextStyle errorStyle;
  final TextStyle hintStyle;
  final TextStyle helperStyle;
  final TextStyle labelStyle;
  final int errorMaxLines;
	final bool showFlags;
	final bool useTextFormField;
	final FocusNode dialCodeFocusNode;
	final FocusNode phoneTextFocusNode;
	final TextInputAction phoneTextInputAction;
	final void Function(String value) phoneTextOnFieldSubmitted;

  InternationalPhoneInput({
		this.onPhoneNumberChange,
		this.initialPhoneNumber,
		this.initialSelection,
		this.errorText = ERROR_TEXT,
		this.hintText = HINT_TEXT,
		this.helperText = HELPER_TEXT,
		this.labelText = LABEL_TEXT,
		this.errorStyle,
		this.hintStyle,
		this.helperStyle,
		this.labelStyle,
		this.errorMaxLines = 3,
		this.dialCodeFocusNode,
		this.phoneTextFocusNode,
		this.phoneTextInputAction,
		this.phoneTextOnFieldSubmitted,
		this.useTextFormField = false,
		this.showFlags = true,
	});

  static Future<String> internationalizeNumber(String number, String iso) {
    return PhoneService.getNormalizedPhoneNumber(number, iso);
  }

  @override
  _InternationalPhoneInputState createState() =>
      _InternationalPhoneInputState();
}

class _InternationalPhoneInputState extends State<InternationalPhoneInput> {
  Country selectedItem;
  List<Country> itemList;

  bool hasError = false;

  TextEditingController phoneTextController;

  @override
  void initState() {
		itemList = <Country>[];

		phoneTextController = TextEditingController();
    phoneTextController.addListener(_validatePhoneNumber);
    phoneTextController.text = widget.initialPhoneNumber;

    _fetchCountryData().then((list) {
      Country preSelectedItem;

      if (widget.initialSelection != null) {
				String initialSelection = widget.initialSelection.toString().toUpperCase();
        preSelectedItem = list.firstWhere(
            (e) => (
							(e.code.toUpperCase() == initialSelection) ||
							(e.code3.toUpperCase() == initialSelection) ||
							(e.dialCode == initialSelection)
						),
            orElse: () => list[0]);
      } else {
        preSelectedItem = list[0];
      }

      setState(() {
        itemList = list;
        selectedItem = preSelectedItem;
      });
    });

    super.initState();
  }

	@override
	void dispose() {
		phoneTextController.dispose();
		super.dispose();
	}

  _validatePhoneNumber() {
    String phoneText = phoneTextController.text;
    if (phoneText != null && phoneText.isNotEmpty) {
      PhoneService.parsePhoneNumber(phoneText, selectedItem.code)
          .then((isValid) {
        setState(() {
          hasError = !isValid;
        });

        if (widget.onPhoneNumberChange != null) {
          if (isValid) {
            PhoneService.getNormalizedPhoneNumber(phoneText, selectedItem.code)
                .then((number) {
              widget.onPhoneNumberChange(phoneText, number, selectedItem.code);
            });
          } else {
            widget.onPhoneNumberChange('', '', selectedItem.code);
          }
        }
      });
    }
  }

  Future<List<Country>> _fetchCountryData() async {
    var list = await DefaultAssetBundle.of(context)
        .loadString('packages/international_phone_input/assets/countries.json');
    var jsonList = json.decode(list);
    List<Country> elements = [];
    jsonList.forEach((s) {
      Map elem = Map.from(s);
      elements.add(Country(
          name: elem['en_short_name'],
          code: elem['alpha_2_code'],
          code3: elem['alpha_3_code'],
          dialCode: elem['dial_code'],
          flagUri: 'assets/flags/${elem['alpha_2_code'].toLowerCase()}.png'));
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
              child: DropdownButton<Country>(
                value: selectedItem,
								focusNode: widget.dialCodeFocusNode,
                onChanged: (Country newValue) {
                  setState(() {
                    selectedItem = newValue;
                  });
                  _validatePhoneNumber();
                },
                items: itemList.map<DropdownMenuItem<Country>>((Country value) {
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
                }).toList(),
              ),
            ),
          ),
          Flexible(
            child: _buildTextWidget(),
					),
        ],
      ),
    );
  }

	Widget _buildTextWidget() {
		if (widget.useTextFormField) {
			return TextFormField(
				keyboardType: TextInputType.phone,
				controller: phoneTextController,
				focusNode: widget.phoneTextFocusNode,
				textInputAction: widget.phoneTextInputAction,
				onFieldSubmitted: widget.phoneTextOnFieldSubmitted,
				decoration: InputDecoration(
					errorText: hasError ? widget.errorText : null,
					hintText: widget.hintText,
					helperText: widget.helperText,
					labelText: widget.labelText,
					errorStyle: widget.errorStyle,
					hintStyle: widget.hintStyle,
					helperStyle: widget.helperStyle,
					labelStyle: widget.labelStyle,
					errorMaxLines: widget.errorMaxLines,
				),
			);
		}
		else {
			return TextField(
				keyboardType: TextInputType.phone,
				controller: phoneTextController,
				focusNode: widget.phoneTextFocusNode,
				textInputAction: widget.phoneTextInputAction,
				decoration: InputDecoration(
					errorText: hasError ? widget.errorText : null,
					hintText: widget.hintText,
					helperText: widget.helperText,
					labelText: widget.labelText,
					errorStyle: widget.errorStyle,
					hintStyle: widget.hintStyle,
					helperStyle: widget.helperStyle,
					labelStyle: widget.labelStyle,
					errorMaxLines: widget.errorMaxLines,
				),
			);
		}
	}

}
