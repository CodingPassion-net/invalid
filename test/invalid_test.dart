import 'package:bloc_test/bloc_test.dart';
import 'package:intl/intl.dart';
import 'package:invalid/invalid.dart';
import 'package:test/test.dart';

Matcher resultIsValid(bool value) => isA<ValidationResult<FormKeys>>()
    .having((result) => result.isValid, "", value);

Matcher resultHasMessage(String message) => isA<ValidationResult<FormKeys>>()
    .having((result) => result.message, "", message);

void main() {
  ValidationConfiguration<EmptyDefaultValidationMessages>(
      EmptyDefaultValidationMessages());

  group('FormValidationBloc', () {
    // ignore: close_sinks
    FormValidationBloc<dynamic> parentFormValidationBloc =
        FormValidationBloc<dynamic>(FormValidation());

    blocTest<FormValidationBloc, FormValidation>(
        "If parent validation Bloc enables validation, validation for the current bloc should be enabled to",
        build: () {
          return FormValidationBloc<dynamic>(FormValidation(),
              parentFormValidationBloc: parentFormValidationBloc);
        },
        wait: Duration(milliseconds: 50),
        act: (_) async => parentFormValidationBloc.enableValidation(),
        expect: [FormValidation(enabled: true)]);
  });

  group('Validation', () {
    group('FormValidator', () {
      test('form is valid if all form fields are valid', () {
        var sut = FormValidation<FormKeys>(fields: [
          Field<FormKeys>(
              key: FormKeys.Key1,
              validators: [AlwaysTrueValidator(), AlwaysTrueValidator()]),
          Field<FormKeys>(
              key: FormKeys.Key2,
              validators: [AlwaysTrueValidator(), AlwaysTrueValidator()])
        ]);
        expect(sut.isValid, true);
      });

      test('form is invalid if at least one form field is invalid', () {
        var sut = FormValidation<FormKeys>(fields: [
          Field<FormKeys>(
              key: FormKeys.Key1,
              validators: [AlwaysTrueValidator(), AlwaysFalseValidator()]),
          Field<FormKeys>(
              key: FormKeys.Key2,
              validators: [AlwaysTrueValidator(), AlwaysTrueValidator()])
        ]);
        expect(sut.isValid, false);
      });

      test('form is valid if all form validators are valid', () {
        var sut = FormValidation<FormKeys>(formValidators: [
          AlwaysTrueFormValidator<FormKeys>(),
          AlwaysTrueFormValidator<FormKeys>()
        ]);
        expect(sut.isValid, true);
      });

      test('form is invalid if any form validator is invalid', () {
        var sut = FormValidation<FormKeys>(formValidators: [
          AlwaysFalseFormValidator<FormKeys>(),
          AlwaysTrueFormValidator<FormKeys>()
        ]);
        expect(sut.isValid, false);
      });

      group('test validation messages', () {
        FormValidation<FormKeys> sut;
        setUp(() {
          sut = FormValidation<FormKeys>(enabled: true, fields: [
            Field<FormKeys>(key: FormKeys.Key1, validators: [
              AlwaysTrueValidator(),
              AlwaysFalseValidator(
                  errorMsg: (_, __) => "Validationmessage from Key1")
            ]),
            Field<FormKeys>(
                key: FormKeys.Key2,
                validators: [AlwaysFalseValidator(), AlwaysTrueValidator()])
          ], formValidators: [
            AlwaysFalseFormValidator<FormKeys>(
                key: FormKeys.Key3,
                errorMsg: (_) => "Validationmessage from Key3"),
            AlwaysFalseFormValidator<FormKeys>(key: FormKeys.Key4)
          ]);
        });

        test(
            'validationMessages should return all validation messages of invalid fields and invalid formValidators',
            () {
          expect(sut.validationMessages, [
            'Validationmessage from Key1',
            'Validationmessage from invalid validator',
            'Validationmessage from Key3',
            'Validationmessage from invalid form validator'
          ]);
        });

        test(
            'validationMessagesOfKey should return all validation messages of invalid fields and invalid form validators, but only if they match the key',
            () {
          expect(sut.validationMessagesByKeys([FormKeys.Key1, FormKeys.Key3]), [
            "Validationmessage from Key1",
            "Validationmessage from Key3",
          ]);
        });

        test(
            'formValidatorValidationMessages should return only validation messages of invalid formValidators',
            () {
          expect(sut.formValidatorValidationMessages, [
            "Validationmessage from Key3",
            'Validationmessage from invalid form validator'
          ]);
        });

        test(
            'if validation is disabled no all validation messages should be empty',
            () {
          sut = sut.copyWith(enabled: false);
          expect(sut.validationMessages, []);
          expect(sut.formValidatorValidationMessages, []);
          expect(
              sut.validationMessagesByKeys([FormKeys.Key1, FormKeys.Key3]), []);
        });
      });

      test('the right typeconverter should be picked for type conversion', () {
        var sut = FormValidation<FormKeys>(fields: [
          Field<FormKeys>(
              key: FormKeys.Key1,
              validators: [ShouldBeBiggerThanValidator(19)], //Validator double
              value: "20"), //Input String
        ]);
        expect(sut.isValid, true); // This should just trigger validation
      });

      test('throw exception if the type convert not exists', () {
        var sut = FormValidation<FormKeys>(fields: [
          Field<FormKeys>(
              key: FormKeys.Key1,
              validators: [ShouldBeBiggerThanValidator(19)],
              value: AssertionError()),
        ]);
        expect(() => sut.isValid, throwsA(isA<UnsupportedError>()));
      });

      test('updateField should update field', () {
        var sut = FormValidation<FormKeys>(fields: [
          Field<FormKeys>(
              key: FormKeys.Key1,
              validators: [ShouldBeTrueValidator()],
              value: false),
        ]);
        expect(sut.isValid, false);
        sut = sut.updateField(FormKeys.Key1, true);
        expect(sut.isValid, true);
      });

      test(
          'adding multiple fields with the same key, should only add the first one',
          () {
        var sut = FormValidation<FormKeys>(fields: [
          Field<FormKeys>(
              key: FormKeys.Key1,
              validators: [ShouldBeTrueValidator()],
              value: false),
          Field<FormKeys>(
              key: FormKeys.Key1,
              validators: [ShouldBeTrueValidator()],
              value: false),
        ]);
        sut = sut.addField(
          Field<FormKeys>(
              key: FormKeys.Key1,
              validators: [ShouldBeTrueValidator()],
              value: false),
        );
        expect(
            sut.fields.where((field) => field.key == FormKeys.Key1).length, 1);
      });
    });

    void testFieldValidator(
        FieldValidator<dynamic, FormKeys, FieldValidator> validator,
        dynamic value,
        bool expectValid) {
      expect(1, 1);
      expect(
          FormValidation<FormKeys>(fields: [
            Field<FormKeys>(
                key: FormKeys.Key1, validators: [validator], value: value),
          ]).isValid,
          expectValid);
    }

    group('Validators', () {
      test('Validator allowNull should also be applied if using typeconverter',
          () {
        ValidationConfiguration<EmptyDefaultValidationMessages>(
            EmptyDefaultValidationMessages(),
            typeConverter: [
              DummyForTypeConverterReturnsNullToDoubleTypeConverter()
            ]);
        testFieldValidator(ShouldBeBiggerThanValidator(20),
            DummyForTypeConverterReturnsNull(), true);
      });

      test('ShouldNotBeNull', () {
        testFieldValidator(
            ShouldNotBeNullValidator<String, FormKeys>(), "Hallo", true);
        testFieldValidator(
            ShouldNotBeNullValidator<String, FormKeys>(), null, false);

        expect(
            () => testFieldValidator(
                ShouldNotBeNullValidator<dynamic, FormKeys>(), "Hallo", true),
            throwsA(isA<UnsupportedError>()));

        ValidationConfiguration<EmptyDefaultValidationMessages>(
            EmptyDefaultValidationMessages(),
            typeConverter: [
              DummyForTypeConverterReturnsNullToStringTypeConverter()
            ]);

        testFieldValidator(ShouldNotBeNullValidator<String, FormKeys>(),
            DummyForTypeConverterReturnsNull(), false);
        testFieldValidator(ShouldNotBeNullValidator<String, FormKeys>(),
            DummyForTypeConverterReturnsNull()..test = "Hallo", true);
      });

      test('ShouldNotBeEmpty', () {
        testFieldValidator(ShouldNotBeEmptyValidator<FormKeys>(), "", false);
        testFieldValidator(
            ShouldNotBeEmptyValidator<FormKeys>(), "Hallo", true);
      });

      test('ShouldNotBeEmptyOrWhiteSpace', () {
        testFieldValidator(
            ShouldNotBeEmptyOrWhiteSpaceValidator<FormKeys>(), "Hallo", true);
        testFieldValidator(ShouldNotBeEmptyOrWhiteSpaceValidator<FormKeys>(),
            "               ", false);
      });

      test('ShouldBeTrue', () {
        testFieldValidator(ShouldBeTrueValidator<FormKeys>(), false, false);
        testFieldValidator(ShouldBeTrueValidator<FormKeys>(), true, true);
      });

      test('ShouldBeFalse', () {
        testFieldValidator(ShouldBeFalseValidator<FormKeys>(), true, false);
        testFieldValidator(ShouldBeFalseValidator<FormKeys>(), false, true);
      });

      test('ShouldBeBiggerThenValidator', () {
        testFieldValidator(
            ShouldBeBiggerThanValidator<FormKeys>(5), 4.99, false);
        testFieldValidator(ShouldBeBiggerThanValidator<FormKeys>(5), 5, false);
        testFieldValidator(ShouldBeBiggerThanValidator<FormKeys>(5), 5.1, true);
      });

      test('ShouldBeSmallerThenValidator', () {
        testFieldValidator(
            ShouldBeSmallerThenValidator<FormKeys>(5), 4.99, true);
        testFieldValidator(ShouldBeSmallerThenValidator<FormKeys>(5), 5, false);
        testFieldValidator(
            ShouldBeSmallerThenValidator<FormKeys>(5), 5.1, false);
      });

      test('ShouldBeSmallerOrEqualThenValidator', () {
        testFieldValidator(
            ShouldBeSmallerOrEqualThenValidator<FormKeys>(5), 4.99, true);
        testFieldValidator(
            ShouldBeSmallerOrEqualThenValidator<FormKeys>(5), 5, true);
        testFieldValidator(
            ShouldBeSmallerOrEqualThenValidator<FormKeys>(5), 5.1, false);
      });

      test('ShouldBeBiggerOrEqualThenValidator', () {
        testFieldValidator(
            ShouldBeBiggerOrEqualThenValidator<FormKeys>(5), 4.99, false);
        testFieldValidator(
            ShouldBeBiggerOrEqualThenValidator<FormKeys>(5), 5, true);
        testFieldValidator(
            ShouldBeBiggerOrEqualThenValidator<FormKeys>(5), 5.1, true);
      });

      test('ShouldBeBetweenOrEqualValidator', () {
        testFieldValidator(
            ShouldBeBetweenOrEqualValidator<FormKeys>(5, 10), 4.99, false);
        testFieldValidator(
            ShouldBeBetweenOrEqualValidator<FormKeys>(5, 10), 5, true);
        testFieldValidator(
            ShouldBeBetweenOrEqualValidator<FormKeys>(5, 10), 5.1, true);
        testFieldValidator(
            ShouldBeBetweenOrEqualValidator<FormKeys>(5, 10), 9.9, true);
        testFieldValidator(
            ShouldBeBetweenOrEqualValidator<FormKeys>(5, 10), 10, true);
        testFieldValidator(
            ShouldBeBetweenOrEqualValidator<FormKeys>(5, 10), 10.1, false);
      });

      test('ShouldBeBetweenValidator', () {
        testFieldValidator(
            ShouldBeBetweenValidator<FormKeys>(5, 10), 4.99, false);
        testFieldValidator(ShouldBeBetweenValidator<FormKeys>(5, 10), 5, false);
        testFieldValidator(
            ShouldBeBetweenValidator<FormKeys>(5, 10), 5.1, true);
        testFieldValidator(
            ShouldBeBetweenValidator<FormKeys>(5, 10), 9.9, true);
        testFieldValidator(
            ShouldBeBetweenValidator<FormKeys>(5, 10), 10, false);
        testFieldValidator(
            ShouldBeBetweenValidator<FormKeys>(5, 10), 10.1, false);
      });
    });

    group('FormValidators', () {
      var sut = ShouldBeEqualFormValidator<FormKeys>(
          keysOfFieldsWhichShouldBeEqual: [FormKeys.Key1, FormKeys.Key2]);
      var sutMultiFieldDateValidator = MultiFieldDateValidator<FormKeys>(
          dayFieldKey: FormKeys.Key1,
          monthFieldKey: FormKeys.Key2,
          yearFieldKey: FormKeys.Key3);

      test('should return true if all field values are equal', () {
        expect(
            sut.isValid([
              Field<FormKeys>(
                value: true,
                key: FormKeys.Key1,
              ),
              Field<FormKeys>(
                value: true,
                key: FormKeys.Key2,
              )
            ]),
            true);
      });

      test('should return false any of the field value is different', () {
        expect(
            sut.isValid([
              Field<FormKeys>(
                value: true,
                key: FormKeys.Key1,
              ),
              Field<FormKeys>(
                value: false,
                key: FormKeys.Key2,
              )
            ]),
            false);
      });

      test('should return true if date is valid', () {
        expect(
            sutMultiFieldDateValidator.isValid([
              Field<FormKeys>(
                value: "18",
                key: FormKeys.Key1,
              ),
              Field<FormKeys>(
                value: "06",
                key: FormKeys.Key2,
              ),
              Field<FormKeys>(
                value: "1998",
                key: FormKeys.Key3,
              )
            ]),
            true);
      });

      test('should return false if date is invalid', () {
        expect(
            sutMultiFieldDateValidator.isValid([
              Field<FormKeys>(
                value: "234",
                key: FormKeys.Key1,
              ),
              Field<FormKeys>(
                value: "032346",
                key: FormKeys.Key2,
              ),
              Field<FormKeys>(
                value: "asdf",
                key: FormKeys.Key3,
              )
            ]),
            false);
      });
    });
  });
}

enum FormKeys {
  Key1,
  Key2,
  Key3,
  Key4,
}

class AlwaysFalseValidator
    extends FieldValidator<dynamic, FormKeys, AlwaysFalseValidator> {
  @override
  bool get allowNull => false;

  AlwaysFalseValidator(
      {String Function(AlwaysFalseValidator val, String fieldName) errorMsg,
      FormKeys key})
      : super(errorMsg ?? (_, __) => "Validationmessage from invalid validator",
            key);

  @override
  bool isValid(dynamic value) {
    return false;
  }
}

class AlwaysTrueValidator
    extends FieldValidator<dynamic, FormKeys, AlwaysTrueValidator> {
  AlwaysTrueValidator(
      {String Function(AlwaysTrueValidator val, String fieldName) errorMsg,
      FormKeys key})
      : super(errorMsg ?? (_, __) => "asdf", key);

  @override
  bool isValid(dynamic value) {
    return true;
  }
}

class AlwaysFalseFormValidator<KeyType>
    extends FormValidator<KeyType, AlwaysFalseFormValidator<KeyType>> {
  AlwaysFalseFormValidator(
      {KeyType key, String Function(AlwaysFalseFormValidator val) errorMsg})
      : super(
            errorMsg ?? (_) => "Validationmessage from invalid form validator",
            key: key);

  @override
  bool isValid(Iterable<Field<KeyType>> value) {
    return false;
  }
}

class AlwaysTrueFormValidator<KeyType>
    extends FormValidator<KeyType, AlwaysTrueFormValidator<KeyType>> {
  AlwaysTrueFormValidator(
      {KeyType key,
      String Function(AlwaysTrueFormValidator<KeyType> val) errorMsg})
      : super(
            errorMsg ?? (_) => "Validationmessage from invalid form validator",
            key: key);

  @override
  bool isValid(Iterable<Field<KeyType>> value) {
    return true;
  }
}

class DummyForTypeConverterReturnsNull {
  String test;
}

class DummyForTypeConverterReturnsNullToStringTypeConverter
    extends TypeConverter<DummyForTypeConverterReturnsNull, String> {
  @override
  String canConvert(DummyForTypeConverterReturnsNull inputType) {
    return inputType.test;
  }
}

class DummyForTypeConverterReturnsNullToDoubleTypeConverter
    extends TypeConverter<DummyForTypeConverterReturnsNull, double> {
  @override
  double canConvert(DummyForTypeConverterReturnsNull inputType) {
    if (inputType.test == null) return null;
    var convertedDouble;
    try {
      convertedDouble = NumberFormat().parse(inputType.test);
    } on FormatException catch (_) {
      return null;
    }
    return convertedDouble;
  }
}

class EmptyDefaultValidationMessages extends DefaultValidationMessages {
  @override
  String shouldBeEqualValidationMessage(_) => "empty val msg";

  @override
  String shouldBeBetweenOrEqualValidationMessage(_, __) => "empty val msg";

  @override
  String shouldBeBetweenValidationMessage(_, __) => "empty val msg";

  @override
  String shouldBeBiggerOrEqualThanValidationMessage(_, __) => "empty val msg";

  @override
  String shouldBeBiggerThanValidationMessage(_, __) => "empty val msg";

  @override
  String shouldBeFalseValidationMessage(_, __) => "empty val msg";

  @override
  String shouldBeInBetweenDatesValidationMessage(_, __) => "empty val msg";

  @override
  String shouldBeSmallerOrEqualThanValidationMessage(_, __) => "empty val msg";

  @override
  String shouldBeSmallerThanValidationMessage(_, __) => "empty val msg";

  @override
  String shouldBeTrueValidationMessage(_, __) => "empty val msg";

  @override
  String shouldNotBeEmptyOrWhiteSpaceValidationMessage(_, __) =>
      "empty val msg";

  @override
  String shouldNotBeEmptyValidationMessage(_, __) => "empty val msg";

  @override
  String shouldNotBeNullValidationMessage(_, __) => "empty val msg";
}
