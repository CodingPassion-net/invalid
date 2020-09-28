import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'validators.dart';

class Field<KeyType> extends Equatable {
  final Iterable<FieldValidator<dynamic, KeyType, dynamic>> validators;
  final dynamic value;
  final KeyType key;
  final String fieldName;

  bool get isValid =>
      validationResults.every((validationResult) => validationResult.isValid);

  Iterable<ValidationResult<KeyType>> get validationResults => validators
      .map((validator) =>
          validator.validate(value, fieldName).copyWith(fieldKey: key))
      .toList();

  Field(
      {@required this.key,
      Iterable<FieldValidator<dynamic, KeyType, dynamic>> validators,
      this.value,
      this.fieldName})
      : validators = validators ?? [],
        assert(key != null);

  Field<KeyType> copyWith({
    dynamic value,
    bool setValueToNull = false,
  }) {
    return Field<KeyType>(
      validators: validators,
      key: key,
      fieldName: fieldName,
      value: setValueToNull ? null : value ?? this.value,
    );
  }

  @override
  List<Object> get props => [value, key, validators, fieldName];
}

abstract class TypeConverter<InputType, OutputType> {
  Type get inputType => InputType;

  Type get outputType => OutputType;

  OutputType canConvert(InputType inputType);
}

class StringDoubleTypeConverter extends TypeConverter<String, double> {
  @override
  double canConvert(String inputType) {
    var convertedDouble;
    try {
      convertedDouble = NumberFormat().parse(inputType);
    } on FormatException catch (_) {
      return null;
    }
    return convertedDouble;
  }
}

class StringIntTypeConverter extends TypeConverter<String, int> {
  @override
  int canConvert(String inputType) {
    return int.tryParse(inputType);
  }
}

class IntDoubleTypeConverter extends TypeConverter<int, double> {
  @override
  double canConvert(int inputType) {
    return inputType.toDouble();
  }
}

extension FieldFinder<KeyType> on Iterable<Field<KeyType>> {
  Field<KeyType> findByFieldKey(KeyType fieldKey) {
    return singleWhere((field) => field.key == fieldKey, orElse: () => null);
  }

  Iterable<Field<KeyType>> findByFieldKeys(Iterable<KeyType> fieldKeys) {
    var foundFields = where((field) => fieldKeys.contains(field.key));
    return foundFields;
  }
}
