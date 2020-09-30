import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invalid/invalid.dart';

class ValidationFormMessagesSummary<FormKeyType> extends StatelessWidget {
  final bool showOnlyFormValidatorMessages;
  final Widget Function(List<String> validationMessages)
      validationMessagesBuilder;
  const ValidationFormMessagesSummary(
      {@required this.validationMessagesBuilder,
      Key key,
      this.showOnlyFormValidatorMessages = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FormValidationCubit<FormKeyType>,
        FormValidationState<FormKeyType>>(builder: (context, state) {
      return validationMessagesBuilder((showOnlyFormValidatorMessages
              ? state.validationResultsWhenFormIsEnabled.onlyInvalid
                  .onlyFormValidationResults.messages
              : state.validationResultsWhenFormIsEnabled.onlyInvalid.messages)
          .toList());
    });
  }
}
