import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'type_converter.dart';
import 'validators.dart';

class FormValidationCubit<KeyType> extends Cubit<FormValidationState<KeyType>> {
  FormValidationCubit(FormValidationState<KeyType> initialState)
      : super(initialState);

  void updateField(KeyType fieldKey, dynamic newValue) =>
      emit(state.updateField(fieldKey, newValue));

  void addField(Field<KeyType> field) => emit(state.addField(field));

  void enableValidation() => emit(state.copyWith(enabled: true));

  void disableValidation() => emit(state.copyWith(enabled: false));
}

class FormValidationState<KeyType> extends Equatable {
  final Iterable<Field<KeyType>> fields;
  final Iterable<FormValidator<KeyType, FormValidator>> formValidators;
  final bool enabled;

  bool get isValid =>
      _validationResults.every((validationResult) => validationResult.isValid);

  Iterable<ValidationResult<KeyType>> get _validationResults =>
      [..._fieldValidationResults, ..._formValidationResults];

  /// Returns all [ValidationResult], when the form is enabled.
  Iterable<ValidationResult<KeyType>> get validationResults =>
      _validationResults.where((_) => enabled);

  /// Returns all invalid [ValidationResult], when the form is enabled.
  Iterable<ValidationResult<KeyType>> get invalidValidationResults =>
      validationResults.where((validationResult) => !validationResult.isValid);

  Iterable<ValidationResult<KeyType>> get _formValidationResults =>
      formValidators.map((formValidator) => formValidator.validate(fields));

  Iterable<ValidationResult<KeyType>> get _fieldValidationResults =>
      fields.expand((field) => field.validationResults);

  /// Returns all invalid [ValidationResult], when the form is enabled, by key.
  Iterable<ValidationResult> invalidValidationResultsByKeys(
          Iterable<KeyType> keys) =>
      invalidValidationResults.where((validationResult) =>
          keys.contains(validationResult.fieldKey) ||
          keys.contains(validationResult.validatorKey) ||
          keys.contains(validationResult.formValidatorKey));

  /// Returns all invalid [ValidationResult], who are returned from FormValidators. Only when the form is enabled.
  Iterable<ValidationResult> get invalidFormValidationResults =>
      invalidValidationResults
          .where((validationResult) => validationResult.isFormValidationResult);

  FormValidationState(
      {Iterable<Field<KeyType>> fields,
      Iterable<FormValidator<KeyType, FormValidator>> formValidators,
      this.enabled = false})
      : fields = (fields ?? []).distinctBy((field) => field.key).toList(),
        formValidators = formValidators ?? [];

  FormValidationState<KeyType> updateField(KeyType fieldKey, dynamic newValue) {
    return copyWith(
        fields: fields
            .map((field) => field.key == fieldKey
                ? field
                    .copyWith(value: newValue)
                    .copyWith(setValueToNull: newValue == null)
                : field.copyWith())
            .toList());
  }

  FormValidationState<KeyType> addField(Field<KeyType> newField) {
    return copyWith(fields: [...fields, newField]);
  }

  FormValidationState<KeyType> copyWith({
    Iterable<Field<KeyType>> fields,
    Iterable<FormValidator<KeyType, FormValidator>> formValidators,
    bool enabled,
  }) {
    return FormValidationState<KeyType>(
        fields: fields ?? this.fields,
        formValidators: formValidators ?? this.formValidators,
        enabled: enabled ?? this.enabled);
  }

  @override
  List<Object> get props => [fields, formValidators, enabled];
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<T> distinctBy(Function(T) selector) {
    var seenKeys = <dynamic>{};
    return where((item) => seenKeys.add(selector(item)));
  }
}

extension ValidationResultsExtension<KeyType>
    on Iterable<ValidationResult<KeyType>> {
  Iterable<String> get messages =>
      map((validationResult) => validationResult.message).toList();
}
