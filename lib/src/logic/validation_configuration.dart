import 'type_converter.dart';
import 'validators.dart';

class ValidationConfiguration<
    DefaultValidationMessagesType extends DefaultValidationMessages> {
  final List<TypeConverter> _typeConverter;
  final DefaultValidationMessagesType defaultValidationMessages;

  static ValidationConfiguration _instance;

  ValidationConfiguration._(
      this.defaultValidationMessages, this._typeConverter);

  factory ValidationConfiguration.initialize(
      DefaultValidationMessagesType defaultValidationMessages,
      {List<TypeConverter> typeConverter = const []}) {
    return _instance = ValidationConfiguration<DefaultValidationMessagesType>._(
        defaultValidationMessages, [
      StringDoubleTypeConverter(),
      IntDoubleTypeConverter(),
      ...typeConverter
    ]);
  }

  TypeConverter<dynamic, OutputType> getTypeConverter<OutputType>(
      Type inputType) {
    return _typeConverter.firstWhere(
        (converter) =>
            converter.inputType == inputType &&
            converter.outputType == OutputType,
        orElse: () => throw UnsupportedError(
            "Converter from Type $inputType, to $OutputType is missing"));
  }

  factory ValidationConfiguration.instance() {
    assert(_instance != null, "ValidationConfiguration is not initialized!");
    return _instance;
  }
}

abstract class DefaultValidationMessages {
  String shouldBeEqualValidationMessage(ShouldBeEqualFormValidator val);

  String shouldBeBetweenOrEqualValidationMessage(
      ShouldBeBetweenOrEqualValidator val, String fieldName);

  String shouldBeBetweenValidationMessage(
      ShouldBeBetweenValidator val, String fieldName);

  String shouldBeSmallerOrEqualThanValidationMessage(
      ShouldBeSmallerOrEqualThenValidator val, String fieldName);

  String shouldBeBiggerOrEqualThanValidationMessage(
      ShouldBeBiggerOrEqualThenValidator val, String fieldName);

  String shouldBeSmallerThanValidationMessage(
      ShouldBeSmallerThenValidator val, String fieldName);

  String shouldBeBiggerThanValidationMessage(
      ShouldBeBiggerThanValidator val, String fieldName);

  String shouldBeInBetweenDatesValidationMessage(
      ShouldInBetweenDatesValidator val, String fieldName);

  String shouldBeFalseValidationMessage(
      ShouldBeFalseValidator val, String fieldName);

  String shouldBeTrueValidationMessage(
      ShouldBeTrueValidator val, String fieldName);

  String shouldNotBeEmptyOrWhiteSpaceValidationMessage(
      ShouldNotBeEmptyOrWhiteSpaceValidator val, String fieldName);

  String shouldNotBeEmptyValidationMessage(
      ShouldNotBeEmptyValidator val, String fieldName);

  String shouldNotBeNullValidationMessage(
      ShouldNotBeNullValidator val, String fieldName);
}
