import 'package:equatable/equatable.dart';
import 'package:invalid/invalid.dart';
import 'package:meta/meta.dart';
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
  bool get stringify => true;

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
  final String Function(TFieldValidator validator, Field<KeyType> field)
      buildErrorMessage;

  bool get allowNull => true;

  FieldValidator(this.buildErrorMessage, KeyType key) : super(key);

  TypeOfValidatedValue parseValue(dynamic value) =>
      ValidationConfiguration.instance()
          .getTypeConverter<TypeOfValidatedValue>(value.runtimeType as Type)
          .canConvert(value);

  ValidationResult<KeyType> validate(Field<KeyType> field) {
    if (field.value == null)
      return createValidationResult(null, allowNull, field);
    if (field.value.runtimeType == TypeOfValidatedValue)
      return createValidationResult(field.value as TypeOfValidatedValue,
          isValid(field.value as TypeOfValidatedValue), field);
    var parsedValue = parseValue(field.value);
    return createValidationResult(parsedValue,
        parsedValue == null ? allowNull : isValid(parsedValue), field);
  }

  @protected
  bool isValid(TypeOfValidatedValue value) => true;

  ValidationResult<KeyType> createValidationResult(
      TypeOfValidatedValue value, bool isValid, Field<KeyType> field) {
    return ValidationResult<KeyType>(
        isValid, buildErrorMessage(this as TFieldValidator, field), false,
        validatorKey: key);
  }
}

/// A [FormValidator] is a validator, that can span multiple fields.
@immutable
abstract class FormValidator<KeyType,
        TFormValidator extends FormValidator<KeyType, TFormValidator>>
    extends Validator<KeyType> {
  final String Function(
          TFormValidator validator, Iterable<Field<KeyType>> fields)
      buildErrorMessage;

  FormValidator(this.buildErrorMessage, {KeyType key}) : super(key);

  ValidationResult<KeyType> validate(Iterable<Field<KeyType>> fields) {
    return ValidationResult<KeyType>(isValid(fields),
        buildErrorMessage(this as TFormValidator, fields), true,
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
      String Function(ShouldBeEqualFormValidator<KeyType> validator,
              Iterable<Field> fields)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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
      String Function(MultiFieldDateValidator<KeyType> validator,
              Iterable<Field> fields)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                (MultiFieldDateValidator<KeyType> _, __) => null,
            key: key);

  @override
  bool isValid(Iterable<Field<KeyType>> fields) {
    String dayValue = fields.findByFieldKey(dayFieldKey)?.value as String;
    String monthValue = fields.findByFieldKey(monthFieldKey)?.value as String;
    String yearValue = fields.findByFieldKey(yearFieldKey)?.value as String;

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
class ShouldNotBeNullValidator<TypeOfValidatedValue, KeyType>
    extends FieldValidator<TypeOfValidatedValue, KeyType,
        ShouldNotBeNullValidator<TypeOfValidatedValue, KeyType>> {
  @override
  bool get allowNull => false;

  ShouldNotBeNullValidator(
      {String Function(
              ShouldNotBeNullValidator<TypeOfValidatedValue, KeyType>
                  buildErrorMessage,
              Field field)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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

class ShouldNotBeEmptyValidator<KeyType> extends FieldValidator<String, KeyType,
    ShouldNotBeEmptyValidator<KeyType>> {
  ShouldNotBeEmptyValidator(
      {String Function(
              ShouldNotBeEmptyValidator<KeyType> validator, Field field)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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
              Field field)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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
      {String Function(ShouldBeTrueValidator<KeyType> validator, Field field)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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
      {String Function(ShouldBeFalseValidator<KeyType> validator, Field field)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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
              ShouldInBetweenDatesValidator<KeyType> validator, Field field)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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
    String Function(ShouldBeBiggerThanValidator<KeyType> validator, Field field)
        buildErrorMessage,
  }) : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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
              ShouldBeSmallerThenValidator<KeyType> validator, Field field)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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
      {String Function(ShouldBeBiggerOrEqualThenValidator<KeyType> validator,
              Field field)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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
      {String Function(ShouldBeSmallerOrEqualThenValidator<KeyType> validator,
              Field field)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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
      {String Function(ShouldBeBetweenValidator<KeyType> validator, Field field)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
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
      {String Function(
              ShouldBeBetweenOrEqualValidator<KeyType> validator, Field field)
          buildErrorMessage,
      KeyType key})
      : super(
            buildErrorMessage ??
                ValidationConfiguration.instance()
                    .defaultValidationMessagesLocalization
                    .shouldBeBetweenOrEqualValidationMessage,
            key);

  @override
  bool isValid(double value) {
    return min <= value && value <= max;
  }
}
