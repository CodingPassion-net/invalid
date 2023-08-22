import 'package:intl/intl.dart';

/// When for example the value in a field is of type int, but the validator expects a string,
/// then the TypeConverter can convert the type of field value (int) to the type the validator expects (string).
/// This allows us to reuse validators even if the types need to be converted at first. For example a
abstract class TypeConverter<InputType, OutputType> {
  Type get inputType => InputType;

  Type get outputType => OutputType;

  OutputType? canConvert(InputType inputType);
}

class StringDoubleTypeConverter extends TypeConverter<String, double> {
  @override
  double? canConvert(String inputType) {
    double convertedDouble;
    try {
      convertedDouble = NumberFormat().parse(inputType) as double;
    } on FormatException catch (_) {
      return null;
    } on TypeError catch (_) {
      return null;
    }
    return convertedDouble;
  }
}

class StringIntTypeConverter extends TypeConverter<String, int> {
  @override
  int? canConvert(String inputType) {
    return int.tryParse(inputType);
  }
}

class IntDoubleTypeConverter extends TypeConverter<int, double> {
  @override
  double canConvert(int inputType) {
    return inputType.toDouble();
  }
}
