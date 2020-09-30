import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invalid/invalid.dart';

class ValidationMessagesByKeyWidget<FormKeyType> extends StatelessWidget {
  final List<FormKeyType> keys;
  final EdgeInsets padding;
  final Widget Function(List<String> validationMessages)
      validationMessagesBuilder;
  const ValidationMessagesByKeyWidget(this.keys,
      {@required this.validationMessagesBuilder,
      Key key,
      this.padding = EdgeInsets.zero})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FormValidationCubit<FormKeyType>,
        FormValidationState<FormKeyType>>(builder: (context, state) {
      if (state.invalidValidationResultsByKeys(keys).isEmpty)
        return Container();
      return Padding(
        padding: padding,
        child: validationMessagesBuilder(
          state.invalidValidationResultsByKeys(keys).messages.toList(),
        ),
      );
    });
  }
}
