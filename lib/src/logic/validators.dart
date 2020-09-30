import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'type_converter.dart';
import 'validation_configuration.dart';

@immutable
class ValidationResult<KeyType> extends Equatable {
  final KeyType formValidatorKey;
  final KeyType validatorKey;
  final KeyType fieldKey;
  final bool isValid;
  final String message;
  final bool isFormValidationResult;

  ValidationResult(this.isValid, this.message, this.isFormValidationResult,
      {this.fieldKey, this.formValidatorKey, this.validatorKey})
      : assert(isValid != null),
        assert(isFormValidationResult != null);

  ValidationResult<KeyType> copyWith({KeyType fieldKey}) {
    return ValidationResult(
      isValid,
      message,
      isFormValidationResult,
      fieldKey: fieldKey ?? this.fieldKey,
      validatorKey: validatorKey,
      formValidatorKey: formValidatorKey,
    );
  }

  @override
  List<Object> get props => [
        formValidatorKey,
        validatorKey,
        fieldKey,
        isValid,
        message,
        isFormValidationResult
      ];
}

abstract class Validator<KeyType> {
  final KeyType key;

  Validator(this.key);
}

@immutable
abstract class FieldValidator<
    TypeOfValidatedValue,
    KeyType,
    TFieldValidator extends FieldValidator<TypeOfValidatedValue, KeyType,
        TFieldValidator>> extends Validator<KeyType> {
  final String Function(TFieldValidator validator, String fieldName)
      buildErrorMessage;

  bool get allowNull => true;

  FieldValidator(this.buildErrorMessage, KeyType key) : super(key);

  TypeOfValidatedValue parseValue(dynamic value) =>
      ValidationConfiguration.instance()
          .getTypeConverter<TypeOfValidatedValue>(value.runtimeType)
          .canConvert(value);

  ValidationResult<KeyType> validate(dynamic value, [String fieldName]) {
    if (value == null)
      return createValidationResult(null, allowNull, fieldName);
    if (value.runtimeType == TypeOfValidatedValue)
      return createValidationResult(value as TypeOfValidatedValue,
          isValid(value as TypeOfValidatedValue), fieldName);
    var parsedValue = parseValue(value);
    return createValidationResult(parsedValue,
        parsedValue == null ? allowNull : isValid(parsedValue), fieldName);
  }

  @protected
  bool isValid(TypeOfValidatedValue value) => true;

  ValidationResult<KeyType> createValidationResult(
      TypeOfValidatedValue value, bool isValid, String fieldName) {
    return ValidationResult<KeyType>(
        isValid, buildErrorMessage(this, fieldName), false,
        validatorKey: key);
  }
}

@immutable
abstract class FormValidator<KeyType,
        TFormValidator extends FormValidator<KeyType, TFormValidator>>
    extends Validator<KeyType> {
  final String Function(TFormValidator validator) buildErrorMessage;

  FormValidator(this.buildErrorMessage, {KeyType key}) : super(key);

  ValidationResult<KeyType> validate(Iterable<Field<KeyType>> fields) {
    return ValidationResult<KeyType>(
        isValid(fields), buildErrorMessage(this), true,
        formValidatorKey: key);
  }

  @protected
  bool isValid(Iterable<Field<KeyType>> fields);
}

// Form Validators -----------------------------------------------
class ShouldBeEqualFormValidator<KeyType>
    extends FormValidator<KeyType, ShouldBeEqualFormValidator<KeyType>> {
  final Iterable<KeyType> keysOfFieldsWhichShouldBeEqual;

  ShouldBeEqualFormValidator(
      {@required this.keysOfFieldsWhichShouldBeEqual,
      String Function(ShouldBeEqualFormValidator<KeyType> validator)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldBeEqualValidationMessage,
            key: key) {
    assert(keysOfFieldsWhichShouldBeEqual.length >= 2);
  }

  @override
  bool isValid(Iterable<Field<KeyType>> fields) {
    var fieldValues = fields
        .findByFieldKeys(keysOfFieldsWhichShouldBeEqual)
        .map<dynamic>((field) => field.value);

    return fieldValues.toSet().length <= 1;
  }
}

class MultiFieldDateValidator<KeyType>
    extends FormValidator<KeyType, MultiFieldDateValidator<KeyType>> {
  final KeyType dayFieldKey;
  final KeyType monthFieldKey;
  final KeyType yearFieldKey;

  MultiFieldDateValidator(
      {@required this.dayFieldKey,
      @required this.monthFieldKey,
      @required this.yearFieldKey,
      String Function(ShouldBeEqualFormValidator<KeyType> validator)
          buildErrorMessage,
      KeyType key})
      : super(buildErrorMessage ?? (_) => null, key: key);

  @override
  bool isValid(Iterable<Field<KeyType>> fields) {
    var dayValue = fields.findByFieldKey(dayFieldKey)?.value;
    var monthValue = fields.findByFieldKey(monthFieldKey)?.value;
    var yearValue = fields.findByFieldKey(yearFieldKey)?.value;

    var dayInput = dayValue == null ? null : int.tryParse(dayValue);
    var monthInput = monthValue == null ? null : int.tryParse(monthValue);
    var yearInput = yearValue == null ? null : int.tryParse(yearValue);
    if (monthInput == null || dayInput == null || yearInput == null)
      return false;
    var date = isValidDate(dayInput, monthInput, yearInput);
    return date != null;
  }

  DateTime isValidDate(int day, int month, int year) {
    var dateTime = DateTime(year, month, day);
    return dateTime.year == year &&
            dateTime.month == month &&
            dateTime.day == day
        ? dateTime
        : null;
  }
}

// Field Validators ----------------------------------------------
// abstract class BaseCompareFieldValidator<
//     T,
//     KeyType,
//     TFieldValidator extends BaseCompareFieldValidator<T, KeyType,
//         TFieldValidator>> extends FieldValidator<T, KeyType, TFieldValidator> {
//   final T compareValue;

//   BaseCompareFieldValidator(
//       this.compareValue,
//       String Function(TFieldValidator validator, String fieldName)
//           buildErrorMessage,
//       KeyType key)
//       : super(buildErrorMessage, key);
// }

abstract class BaseShouldNotBeNullValidator<
        TypeOfValidatedValue,
        KeyType,
        TFieldValidator extends BaseShouldNotBeNullValidator<
            TypeOfValidatedValue, KeyType, TFieldValidator>>
    extends FieldValidator<TypeOfValidatedValue, KeyType, TFieldValidator> {
  @override
  bool get allowNull => false;

  BaseShouldNotBeNullValidator(
      String Function(TFieldValidator buildErrorMessage, String fieldName)
          buildErrorMessage,
      KeyType key)
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldNotBeNullValidationMessage,
            key);

  @override
  TypeOfValidatedValue parseValue(dynamic value) {
    try {
      return super.parseValue(value);
    } on UnsupportedError catch (e) {
      throw UnsupportedError(
          "Either you didn't specify the type argument 'TypeOfValidatedValue', or there is no TypeConverter registered: $e");
    }
  }
}

class ShouldNotBeNullValidator<TypeOfValidatedValue, KeyType>
    extends FieldValidator<TypeOfValidatedValue, KeyType,
        ShouldNotBeNullValidator<TypeOfValidatedValue, KeyType>> {
  @override
  bool get allowNull => false;

  ShouldNotBeNullValidator(
      {String Function(
              ShouldNotBeNullValidator<TypeOfValidatedValue, KeyType>
                  buildErrorMessage,
              String fieldName)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldNotBeNullValidationMessage,
            key);
}

//class ShouldNotBeEmptyValidator<KeyType> extends BaseShouldNotBeNullValidator<
//    String, KeyType, ShouldNotBeEmptyValidator<KeyType>> {
//  ShouldNotBeEmptyValidator(
//      {String Function(
//              ShouldNotBeEmptyValidator<KeyType> validator, String fieldName)
//          buildErrorMessage,
//      KeyType key})
//      : super(
//            buildErrorMessage ??
//                ValidationConfiguration.instance()
//                    .defaultValidationMessages
//                    .shouldNotBeEmptyValidationMessage,
//            key);
//
//  @override
//  bool isValid(String value) {
//    return super.isValid(value) && value.isNotEmpty;
//  }
//}

class ShouldNotBeEmptyValidator<KeyType> extends FieldValidator<String, KeyType,
    ShouldNotBeEmptyValidator<KeyType>> {
  ShouldNotBeEmptyValidator(
      {String Function(
              ShouldNotBeEmptyValidator<KeyType> validator, String fieldName)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldNotBeEmptyValidationMessage,
            key);

  @override
  bool isValid(String value) {
    return super.isValid(value) && value.isNotEmpty;
  }
}

class ShouldNotBeEmptyOrWhiteSpaceValidator<KeyType> extends FieldValidator<
    String, KeyType, ShouldNotBeEmptyOrWhiteSpaceValidator<KeyType>> {
  ShouldNotBeEmptyOrWhiteSpaceValidator(
      {String Function(ShouldNotBeEmptyOrWhiteSpaceValidator<KeyType> validator,
              String fieldName)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldNotBeEmptyOrWhiteSpaceValidationMessage,
            key);

  @override
  bool isValid(String value) {
    return super.isValid(value) && value.trim() != "";
  }
}

class ShouldBeTrueValidator<KeyType>
    extends FieldValidator<bool, KeyType, ShouldBeTrueValidator<KeyType>> {
  ShouldBeTrueValidator(
      {String Function(
              ShouldBeTrueValidator<KeyType> validator, String fieldName)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldBeTrueValidationMessage,
            key);

  @override
  bool isValid(bool value) {
    return value;
  }
}

class ShouldBeFalseValidator<KeyType>
    extends FieldValidator<bool, KeyType, ShouldBeFalseValidator<KeyType>> {
  ShouldBeFalseValidator(
      {String Function(
              ShouldBeFalseValidator<KeyType> validator, String fieldName)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldBeFalseValidationMessage,
            key);

  @override
  bool isValid(bool value) {
    return !value;
  }
}

class ShouldInBetweenDatesValidator<KeyType> extends FieldValidator<DateTime,
    KeyType, ShouldInBetweenDatesValidator<KeyType>> {
  final DateTime max;
  final DateTime min;

  ShouldInBetweenDatesValidator(this.min, this.max,
      {String Function(
              ShouldBeEqualFormValidator<KeyType> validator, String fieldName)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldBeInBetweenDatesValidationMessage,
            key);

  @override
  bool isValid(DateTime date) {
    return (date.compareTo(min) > 0 && date.compareTo(max) < 0);
  }
}

class ShouldBeBiggerThanValidator<KeyType> extends FieldValidator<double,
    KeyType, ShouldBeBiggerThanValidator<KeyType>> {
  final double min;

  ShouldBeBiggerThanValidator(
    this.min, {
    KeyType key,
    String Function(
            ShouldBeEqualFormValidator<KeyType> validator, String fieldName)
        buildErrorMessage,
  }) : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldBeBiggerThanValidationMessage,
            key);

  @override
  bool isValid(double value) {
    return value > min;
  }
}

class ShouldBeSmallerThenValidator<KeyType> extends FieldValidator<double,
    KeyType, ShouldBeSmallerThenValidator<KeyType>> {
  final double max;

  ShouldBeSmallerThenValidator(this.max,
      {String Function(
              ShouldBeEqualFormValidator<KeyType> validator, String fieldName)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldBeSmallerThanValidationMessage,
            key);

  @override
  bool isValid(double value) {
    return value < max;
  }
}

class ShouldBeBiggerOrEqualThenValidator<KeyType> extends FieldValidator<double,
    KeyType, ShouldBeBiggerOrEqualThenValidator<KeyType>> {
  final double min;

  ShouldBeBiggerOrEqualThenValidator(this.min,
      {String Function(
              ShouldBeEqualFormValidator<KeyType> validator, String fieldName)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldBeBiggerOrEqualThanValidationMessage,
            key);

  @override
  bool isValid(double value) {
    return value >= min;
  }
}

class ShouldBeSmallerOrEqualThenValidator<KeyType> extends FieldValidator<
    double, KeyType, ShouldBeSmallerOrEqualThenValidator<KeyType>> {
  final double max;

  ShouldBeSmallerOrEqualThenValidator(this.max,
      {String Function(
              ShouldBeEqualFormValidator<KeyType> validator, String fieldName)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldBeSmallerOrEqualThanValidationMessage,
            key);

  @override
  bool isValid(double value) {
    return value <= max;
  }
}

class ShouldBeBetweenValidator<KeyType>
    extends FieldValidator<double, KeyType, ShouldBeBetweenValidator<KeyType>> {
  final double max;
  final double min;

  ShouldBeBetweenValidator(this.min, this.max,
      {String Function(
              ShouldBeEqualFormValidator<KeyType> validator, String fieldName)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldBeBetweenValidationMessage,
            key);

  @override
  bool isValid(double value) {
    return min < value && value < max;
  }
}

class ShouldBeBetweenOrEqualValidator<KeyType> extends FieldValidator<double,
    KeyType, ShouldBeBetweenOrEqualValidator<KeyType>> {
  final double max;
  final double min;

  ShouldBeBetweenOrEqualValidator(this.min, this.max,
      {String Function(ShouldBeBetweenOrEqualValidator<KeyType> validator,
              String fieldName)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessages
                    .shouldBeBetweenOrEqualValidationMessage,
            key);

  // ShouldBeBetweenOrEqualValidator.fromRange(DoubleRange range,
  //     {String Function(ShouldBeBetweenOrEqualValidator<KeyType> validator,
  //             String fieldName)
  //         buildErrorMessage,
  //     KeyType key})
  //     : super(
  //           range.min,
  //           range.max,
  //           buildErrorMessage ??
  //               ValidationConfiguration.instance()
  //                  .defaultValidationMessages
  //                   .shouldBeBetweenOrEqualValidationMessage,
  //           key);

  @override
  bool isValid(double value) {
    return min <= value && value <= max;
  }
}
