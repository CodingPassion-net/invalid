import 'package:invalid/invalid.dart';

class ValidationConfiguration<DefaultValidationMessagesType extends DefaultValidationMessagesLocalization> {
  final List<TypeConverter> _typeConverter;
  final DefaultValidationMessagesType defaultValidationMessagesLocalization;

  static late ValidationConfiguration<DefaultValidationMessagesLocalization> _instance;

  ValidationConfiguration._(this.defaultValidationMessagesLocalization, this._typeConverter);

  factory ValidationConfiguration.initialize(
      {DefaultValidationMessagesType? defaultValidationMessages, List<TypeConverter> typeConverter = const []}) {
    return _instance = ValidationConfiguration<DefaultValidationMessagesType>._(
        defaultValidationMessages ?? EmptyDefaultValidationMessages() as DefaultValidationMessagesType,
        [StringDoubleTypeConverter(), IntDoubleTypeConverter(), ...typeConverter]);
  }

  TypeConverter<dynamic, OutputType> getTypeConverter<OutputType>(Type inputType) {
    return _typeConverter.firstWhere(
            (converter) => converter.inputType == inputType && converter.outputType == OutputType,
            orElse: () => throw UnsupportedError("Converter from Type $inputType, to $OutputType is missing"))
        as TypeConverter<dynamic, OutputType>;
  }

  factory ValidationConfiguration.instance() {
    return _instance as ValidationConfiguration<DefaultValidationMessagesType>;
  }
}

abstract class DefaultValidationMessagesLocalization {
  String shouldBeEqualValidationMessage(ShouldBeEqualFormValidator val, Iterable<Field> fields);

  String shouldBeBetweenOrEqualValidationMessage(ShouldBeBetweenOrEqualValidator val, Field field);

  String shouldBeBetweenValidationMessage(ShouldBeBetweenValidator val, Field field);

  String shouldBeSmallerOrEqualThanValidationMessage(ShouldBeSmallerOrEqualThenValidator val, Field field);

  String shouldBeBiggerOrEqualThanValidationMessage(ShouldBeBiggerOrEqualThenValidator val, Field field);

  String shouldBeSmallerThanValidationMessage(ShouldBeSmallerThenValidator val, Field field);

  String shouldBeBiggerThanValidationMessage(ShouldBeBiggerThanValidator val, Field field);

  String shouldBeInBetweenDatesValidationMessage(ShouldInBetweenDatesValidator val, Field field);

  String shouldBeFalseValidationMessage(ShouldBeFalseValidator val, Field field);

  String shouldBeTrueValidationMessage(ShouldBeTrueValidator val, Field field);

  String shouldNotBeEmptyOrWhiteSpaceValidationMessage(ShouldNotBeEmptyOrWhiteSpaceValidator val, Field field);

  String shouldNotBeEmptyValidationMessage(ShouldNotBeEmptyValidator val, Field field);

  String shouldNotBeNullValidationMessage(ShouldNotBeNullValidator val, Field field);
}

class EmptyDefaultValidationMessages extends DefaultValidationMessagesLocalization {
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
  String shouldNotBeEmptyOrWhiteSpaceValidationMessage(_, __) => "empty val msg";

  @override
  String shouldNotBeEmptyValidationMessage(_, __) => "empty val msg";

  @override
  String shouldNotBeNullValidationMessage(_, __) => "empty val msg";
}
