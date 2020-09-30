import 'package:test/test.dart';
import 'package:intl/intl.dart';
import 'package:invalid/invalid.dart';

Matcher resultIsValid(bool value) => isA<ValidationResult<FormKeys>>()
    .having((result) => result.isValid, "", value);

Matcher resultHasMessage(String message) => isA<ValidationResult<FormKeys>>()
    .having((result) => result.message, "", message);

void main() {
  ValidationConfiguration<EmptyDefaultValidationMessages>.initialize(
      EmptyDefaultValidationMessages());

  group('Validation', () {
    group('FormValidator', () {
      test('form is valid if all form fields are valid', () {
        var sut = FormValidationState<FormKeys>(fields: [
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
        var sut = FormValidationState<FormKeys>(fields: [
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
        var sut = FormValidationState<FormKeys>(formValidators: [
          AlwaysTrueFormValidator<FormKeys>(),
          AlwaysTrueFormValidator<FormKeys>()
        ]);
        expect(sut.isValid, true);
      });

      test('form is invalid if any form validator is invalid', () {
        var sut = FormValidationState<FormKeys>(formValidators: [
          AlwaysFalseFormValidator<FormKeys>(),
          AlwaysTrueFormValidator<FormKeys>()
        ]);
        expect(sut.isValid, false);
      });

      group('test validation results', () {
        FormValidationState<FormKeys> sut;
        setUp(() {
          sut = FormValidationState<FormKeys>(enabled: true, fields: [
            Field<FormKeys>(key: FormKeys.Key1, validators: [
              AlwaysTrueValidator(
                  errorMsg: (_, __) => "(Key1) (Valid) (Fieldvalidator)"),
              AlwaysFalseValidator(
                  key: FormKeys.Key4,
                  errorMsg: (_, __) => "(Key4) (Invalid) (Fieldvalidator)")
            ]),
            Field<FormKeys>(key: FormKeys.Key2, validators: [
              AlwaysFalseValidator(),
              AlwaysTrueValidator(
                  errorMsg: (_, __) => "(Key2) (Invalid) (Fieldvalidator)")
            ])
          ], formValidators: [
            AlwaysFalseFormValidator<FormKeys>(
                key: FormKeys.Key3,
                errorMsg: (_, __) => "(Key3) (Invalid) (Formvalidator)"),
            AlwaysFalseFormValidator<FormKeys>(key: FormKeys.Key4)
          ]);
        });

        test(
            'validationResultsWhenFormIsEnabled should return empty list if form is disabled',
            () {
          sut = sut.copyWith(enabled: false);
          expect(sut.validationResultsWhenFormIsEnabled, <ValidationResult>[]);
        });

        test(
            'validationResultsWhenFormIsEnabled should return ValidationResults when form is enabled',
            () {
          sut = sut.copyWith(enabled: true);
          expect(sut.validationResultsWhenFormIsEnabled,
              hasLength(greaterThan(0)));
        });
        test(
            'validationResultsWhenFormIsEnabled should return ValidationResults when form is enabled',
            () {
          sut = sut.copyWith(enabled: true);
          expect(sut.allValidationResults, hasLength(greaterThan(0)));
          sut = sut.copyWith(enabled: false);
          expect(sut.allValidationResults, hasLength(greaterThan(0)));
        });

        test(
            'filterByKeys should only return validation results where the key is in the list',
            () {
          expect(
              sut.allValidationResults
                  .filterByKeys([FormKeys.Key4, FormKeys.Key3]),
              [
                matchValidationResultWithMessage(
                    "(Key4) (Invalid) (Fieldvalidator)"),
                matchValidationResultWithMessage(
                    "(Key3) (Invalid) (Formvalidator)"),
                matchValidationResultWithMessage(
                    "(Default) (Invalid) (Formvalidator)"),
              ]);
        });

        test('onlyInvald should only return invald validation results', () {
          expect(sut.allValidationResults.onlyInvalid, [
            matchValidationResultWithMessage(
                "(Key4) (Invalid) (Fieldvalidator)"),
            matchValidationResultWithMessage(
                "(Default) (Invalid) (Fieldvalidator)"),
            matchValidationResultWithMessage(
                "(Key3) (Invalid) (Formvalidator)"),
            matchValidationResultWithMessage(
                "(Default) (Invalid) (Formvalidator)"),
          ]);
        });

        test('onlyValid should only return invald validation results', () {
          expect(sut.allValidationResults.onlyValid, [
            matchValidationResultWithMessage("(Key1) (Valid) (Fieldvalidator)"),
            matchValidationResultWithMessage(
                "(Key2) (Invalid) (Fieldvalidator)"),
          ]);
        });

        test(
            'onlyFormValidationResults should only return ValidationResults from FormValidators',
            () {
          expect(sut.allValidationResults.onlyFormValidationResults, [
            matchValidationResultWithMessage(
                "(Key3) (Invalid) (Formvalidator)"),
            matchValidationResultWithMessage(
                "(Default) (Invalid) (Formvalidator)"),
          ]);
        });

        test(
            'onlyFieldValidationResults should only return ValidationResults from FieldValidators',
            () {
          expect(sut.allValidationResults.onlyFieldValidationResults, [
            matchValidationResultWithMessage("(Key1) (Valid) (Fieldvalidator)"),
            matchValidationResultWithMessage(
                "(Key4) (Invalid) (Fieldvalidator)"),
            matchValidationResultWithMessage(
                "(Default) (Invalid) (Fieldvalidator)"),
            matchValidationResultWithMessage(
                "(Key2) (Invalid) (Fieldvalidator)"),
          ]);
        });
      });

      test('the right typeconverter should be picked for type conversion', () {
        var sut = FormValidationState<FormKeys>(fields: [
          Field<FormKeys>(
              key: FormKeys.Key1,
              validators: [ShouldBeBiggerThanValidator(19)], //Validator double
              value: "20"), //Input String
        ]);
        expect(sut.isValid, true); // This should just trigger validation
      });

      test('throw exception if the type convert not exists', () {
        var sut = FormValidationState<FormKeys>(fields: [
          Field<FormKeys>(
              key: FormKeys.Key1,
              validators: [ShouldBeBiggerThanValidator(19)],
              value: AssertionError()),
        ]);
        expect(() => sut.isValid, throwsA(isA<UnsupportedError>()));
      });

      test('updateField should update field', () {
        var sut = FormValidationState<FormKeys>(fields: [
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
        var sut = FormValidationState<FormKeys>(fields: [
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
          FormValidationState<FormKeys>(fields: [
            Field<FormKeys>(
                key: FormKeys.Key1, validators: [validator], value: value),
          ]).isValid,
          expectValid);
    }

    group('Validators', () {
      test('Validator allowNull should also be applied if using typeconverter',
          () {
        ValidationConfiguration<EmptyDefaultValidationMessages>.initialize(
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

        ValidationConfiguration<EmptyDefaultValidationMessages>.initialize(
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

TypeMatcher<ValidationResult> matchValidationResultWithMessage(
        String message) =>
    isA<ValidationResult>().having((result) => result.message, "", message);

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
      {String Function(AlwaysFalseValidator val, Field field) errorMsg,
      FormKeys key})
      : super(
            errorMsg ?? (_, __) => "(Default) (Invalid) (Fieldvalidator)", key);

  @override
  bool isValid(dynamic value) {
    return false;
  }
}

class AlwaysTrueValidator
    extends FieldValidator<dynamic, FormKeys, AlwaysTrueValidator> {
  AlwaysTrueValidator(
      {String Function(AlwaysTrueValidator val, Field field) errorMsg,
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
      {KeyType key,
      String Function(AlwaysFalseFormValidator val, Iterable<Field> fields)
          errorMsg})
      : super(errorMsg ?? (_, __) => "(Default) (Invalid) (Formvalidator)",
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
      String Function(
              AlwaysTrueFormValidator<KeyType> val, Iterable<Field> fields)
          errorMsg})
      : super(errorMsg ?? (_, __) => "(Default) (Invalid) (Formvalidator)",
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
    double convertedDouble;
    try {
      convertedDouble = NumberFormat().parse(inputType.test) as double;
    } on FormatException catch (_) {
      return null;
    } on TypeError catch (_) {
      return null;
    }
    return convertedDouble;
  }
}

class EmptyDefaultValidationMessages
    extends DefaultValidationMessagesLocalization {
  @override
  String shouldBeEqualValidationMessage(_, __) => "empty val msg";

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
