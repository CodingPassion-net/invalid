import 'type_converter.dart';
import 'validators.dart';

class ValidationConfiguration<
    DefaultValidationMessagesType extends DefaultValidationMessages> {
  final List<TypeConverter> _typeConverter;
  final DefaultValidationMessagesType defaultValidationMessages;

  static ValidationConfiguration<DefaultValidationMessages> _instance;

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
                "Converter from Type $inputType, to $OutputType is missing"))
        as TypeConverter<dynamic, OutputType>;
  }

  factory ValidationConfiguration.instance() {
    assert(_instance != null, "ValidationConfiguration is not initialized!");
    return _instance as ValidationConfiguration<DefaultValidationMessagesType>;
  }
}

abstract class DefaultValidationMessages {
  String shouldBeEqualValidationMessage(
      ShouldBeEqualFormValidator val, Iterable<Field> fields);

  String shouldBeBetweenOrEqualValidationMessage(
      ShouldBeBetweenOrEqualValidator val, Field field);

  String shouldBeBetweenValidationMessage(
      ShouldBeBetweenValidator val, Field field);

  String shouldBeSmallerOrEqualThanValidationMessage(
      ShouldBeSmallerOrEqualThenValidator val, Field field);

  String shouldBeBiggerOrEqualThanValidationMessage(
      ShouldBeBiggerOrEqualThenValidator val, Field field);

  String shouldBeSmallerThanValidationMessage(
      ShouldBeSmallerThenValidator val, Field field);

  String shouldBeBiggerThanValidationMessage(
      ShouldBeBiggerThanValidator val, Field field);

  String shouldBeInBetweenDatesValidationMessage(
      ShouldInBetweenDatesValidator val, Field field);

  String shouldBeFalseValidationMessage(
      ShouldBeFalseValidator val, Field field);

  String shouldBeTrueValidationMessage(ShouldBeTrueValidator val, Field field);

  String shouldNotBeEmptyOrWhiteSpaceValidationMessage(
      ShouldNotBeEmptyOrWhiteSpaceValidator val, Field field);

  String shouldNotBeEmptyValidationMessage(
      ShouldNotBeEmptyValidator val, Field field);

  String shouldNotBeNullValidationMessage(
      ShouldNotBeNullValidator val, Field field);
}
