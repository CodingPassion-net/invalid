import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:collection/collection.dart';
import 'validators.dart';

class FormValidationCubit<KeyType> extends Cubit<FormValidationState<KeyType>> {
  FormValidationCubit(FormValidationState<KeyType> initialState) : super(initialState);

  /// This updates the value in a field
  void updateFieldValue(KeyType fieldKey, dynamic newValue) => emit(state.updateFieldValue(fieldKey, newValue));

  /// This adds or replaces a field to the form.
  void addOrReplaceField(Field<KeyType> field) => emit(state.addOrReplaceField(field));

  /// Validation messages are hidden by default, calling this method will enable validation.
  /// Use case for this is when you have a form, and you want validation messages to appear after the user
  /// has clicked the submit button.
  void enableValidation() => emit(state.copyWith(enabled: true));

  /// Calling this method will disable validation.
  /// After submitting a form for example, the validation should turn disabled again until the user clicks submit again.
  void disableValidation() => emit(state.copyWith(enabled: false));
}

class FormValidationState<KeyType> extends Equatable {
  final Iterable<Field<KeyType>> fields;
  final Iterable<FormValidator<KeyType, FormValidator>> formValidators;
  final bool enabled;

  bool get isValid => allValidationResults.every((validationResult) => validationResult.isValid);

  /// Returns list of all [ValidationResult].
  Iterable<ValidationResult<KeyType>> get allValidationResults =>
      [..._fieldValidationResults, ..._formValidationResults];

  /// Returns list of all [ValidationResult], when the form is enabled.
  Iterable<ValidationResult<KeyType>> get validationResultsWhenFormIsEnabled =>
      allValidationResults.where((_) => enabled);

  Iterable<ValidationResult<KeyType>> get _formValidationResults =>
      formValidators.map((formValidator) => formValidator.validate(fields));

  Iterable<ValidationResult<KeyType>> get _fieldValidationResults => fields.expand((field) => field.validationResults);

  FormValidationState(
      {Iterable<Field<KeyType>>? fields,
      Iterable<FormValidator<KeyType, FormValidator>>? formValidators,
      this.enabled = false})
      : fields = (fields ?? []).distinctBy((field) => field.key).toList(),
        formValidators = formValidators ?? [];

  FormValidationState<KeyType> updateFieldValue(KeyType fieldKey, dynamic newValue) {
    return copyWith(
        fields: fields
            .map((field) => field.key == fieldKey
                ? field.copyWith(value: newValue).copyWith(setValueToNull: newValue == null)
                : field.copyWith())
            .toList());
  }

  FormValidationState<KeyType> addOrReplaceField(Field<KeyType> newField) {
    if (fields.any((element) => element.key == newField.key)) {
      return copyWith(fields: fields.map((oldField) => oldField.key == newField.key ? newField : oldField).toList());
    } else {
      return copyWith(fields: [...fields, newField]);
    }
  }

  FormValidationState<KeyType> copyWith({
    Iterable<Field<KeyType>>? fields,
    Iterable<FormValidator<KeyType, FormValidator>>? formValidators,
    bool? enabled,
  }) {
    return FormValidationState<KeyType>(
        fields: fields ?? this.fields,
        formValidators: formValidators ?? this.formValidators,
        enabled: enabled ?? this.enabled);
  }

  @override
  List<Object> get props => [fields, formValidators, enabled];
}

/// A field represents a value of a form, that needs validation. For example a TextField or a DatePicker.
class Field<KeyType> extends Equatable {
  final Iterable<FieldValidator<dynamic, KeyType, dynamic>> validators;
  final dynamic value;
  final KeyType key;
  final String fieldName;

  bool get isValid => validationResults.every((validationResult) => validationResult.isValid);

  Iterable<ValidationResult<KeyType>> get validationResults =>
      validators.map((validator) => validator.validate(this).copyWith(fieldKey: key)).toList();

  Field({
    required this.key,
    Iterable<FieldValidator<dynamic, KeyType, dynamic>>? validators,
    this.value,
    this.fieldName = '',
  }) : validators = validators ?? [];

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
  List<Object?> get props => [value, key, validators, fieldName];
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<T> distinctBy(Function(T) selector) {
    var seenKeys = <dynamic>{};
    return where((item) => seenKeys.add(selector(item)));
  }
}

extension FieldFinder<KeyType> on Iterable<Field<KeyType>> {
  Field<KeyType>? findByFieldKey(KeyType fieldKey) {
    return singleWhereOrNull((field) => field.key == fieldKey);
  }

  Iterable<Field<KeyType>> findByFieldKeys(Iterable<KeyType> fieldKeys) {
    var foundFields = where((field) => fieldKeys.contains(field.key));
    return foundFields;
  }
}

extension ValidationResultsExtension<KeyType> on Iterable<ValidationResult<KeyType>> {
  Iterable<String> get messages => map((validationResult) => validationResult.message).toList();

  Iterable<ValidationResult<KeyType>> get onlyInvalid => where((validationResult) => !validationResult.isValid);

  Iterable<ValidationResult<KeyType>> get onlyValid => where((validationResult) => validationResult.isValid);

  Iterable<ValidationResult<KeyType>> filterByKeys(Iterable<KeyType> keys) => where((validationResult) =>
      keys.contains(validationResult.fieldKey) ||
      keys.contains(validationResult.validatorKey) ||
      keys.contains(validationResult.formValidatorKey));

  Iterable<ValidationResult<KeyType>> get onlyFormValidationResults =>
      where((validationResult) => validationResult.isFormValidationResult);

  Iterable<ValidationResult<KeyType>> get onlyFieldValidationResults =>
      where((validationResult) => !validationResult.isFormValidationResult);
}
