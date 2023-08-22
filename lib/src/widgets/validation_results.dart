import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invalid/invalid.dart';

class ValidationResults<FormKeyType> extends StatelessWidget {
  final List<FormKeyType>? filterByKeys;
  final ValidatorTypeFilter filterByValidatorType;
  final EdgeInsets padding;
  final ValidityFilter filterByValidity;
  final bool ignoreIfFormIsEnabled;
  final bool onlyFirstValidationResult;
  final Widget Function(List<ValidationResult> validationResults) validationResultsBuilder;

  /// Placeholder widget when the validation results are empty. Defaults to [SizedBox.shrink]
  final Widget validationResultPlaceholder;

  const ValidationResults({
    this.filterByKeys,
    required this.validationResultsBuilder,
    Key? key,
    this.filterByValidatorType = ValidatorTypeFilter.FieldValidator,
    this.validationResultPlaceholder = const SizedBox.shrink(),
    this.padding = EdgeInsets.zero,
    this.filterByValidity = ValidityFilter.OnlyInvalid,
    this.ignoreIfFormIsEnabled = false,
    this.onlyFirstValidationResult = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FormValidationCubit<FormKeyType>, FormValidationState<FormKeyType>>(builder: (context, state) {
      var filteredValidationResults =
          ignoreIfFormIsEnabled ? state.allValidationResults : state.validationResultsWhenFormIsEnabled;

      switch (filterByValidity) {
        case ValidityFilter.OnlyValid:
          filteredValidationResults = filteredValidationResults.onlyValid;
          break;
        case ValidityFilter.OnlyInvalid:
          filteredValidationResults = filteredValidationResults.onlyInvalid;
          break;
        default:
      }

      if (filterByKeys != null) filteredValidationResults = filteredValidationResults.filterByKeys(filterByKeys!);

      switch (filterByValidatorType) {
        case ValidatorTypeFilter.FieldValidator:
          filteredValidationResults = filteredValidationResults.onlyFieldValidationResults;
          break;
        case ValidatorTypeFilter.FormValidator:
          filteredValidationResults = filteredValidationResults.onlyFormValidationResults;
          break;
      }

      if (onlyFirstValidationResult) filteredValidationResults = filteredValidationResults.take(1);

      return filteredValidationResults.isEmpty
          ? validationResultPlaceholder
          : Padding(
              padding: padding,
              child: validationResultsBuilder(
                filteredValidationResults.toList(),
              ),
            );
    });
  }
}

enum ValidatorTypeFilter {
  FieldValidator,
  FormValidator,
}

enum ValidityFilter { OnlyValid, OnlyInvalid, ValidAndInvalid }
