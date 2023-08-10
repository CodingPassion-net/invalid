import 'package:flutter/material.dart';
import 'package:invalid/invalid.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FormValidationCubit<FormKeys> _formValidation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: ValidationForm<FormKeys>(
        onFormValidationCubitCreated: (formValidation) =>
            _formValidation = formValidation,
        formValidators: [
          ShouldBeEqualFormValidator(
              buildErrorMessage: (validator, fields) => "should be equal",
              keysOfFieldsWhichShouldBeEqual: [FormKeys.Key1, FormKeys.Key2])
        ],
        child: Column(
          children: [
            CustomTextField(
              key: ValueKey("Field1"),
              validationCapability: TextValidationCapability<FormKeys>(
                  validationKey: FormKeys.Key1,
                  validators: [
                    ShouldNotBeEmptyValidator(
                      buildErrorMessage: (validator, field) =>
                          "should not be empty (Key 1)",
                    ),
                    ShouldNotBeEmptyOrWhiteSpaceValidator(
                      buildErrorMessage: (validator, field) =>
                          "should not be empty or whitespace (Key 1)",
                    )
                  ]),
            ),
            CustomTextField(
              key: ValueKey("Field2"),
              validationCapability: TextValidationCapability<FormKeys>(
                  validationKey: FormKeys.Key2,
                  validators: [
                    ShouldNotBeEmptyValidator(
                      buildErrorMessage: (validator, field) =>
                          "should not be empty (Key 2)",
                    )
                  ]),
            ),
            CustomValidationMessages<FormKeys>(),
            ElevatedButton(
              onPressed: () {
                _formValidation.enableValidation();
              },
              child: Text("Validate"),
            )
          ],
        ),
      )),
    );
  }
}

enum FormKeys { Key1, Key2 }

class CustomTextField extends StatefulWidget {
  final TextValidationCapability validationCapability;
  CustomTextField({Key key, this.validationCapability}) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final TextEditingController _textEditingController = TextEditingController();
  @override
  void initState() {
    super.initState();
    widget.validationCapability
        .init(context, controller: _textEditingController);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textEditingController,
    );
  }
}

class CustomValidationMessages<FormKeyType> extends StatefulWidget {
  final List<FormKeyType> filterByKeys;
  final ValidatorTypeFilter filterByValidatorType;
  final ValidityFilter filterByValidity;
  final bool ignoreIfFormIsEnabled;
  final bool onlyFirstValidationResult;

  const CustomValidationMessages(
      {Key key,
      this.filterByKeys,
      this.filterByValidatorType,
      this.ignoreIfFormIsEnabled = false,
      this.filterByValidity = ValidityFilter.OnlyInvalid,
      this.onlyFirstValidationResult = false})
      : super(key: key);
  @override
  CustomValidationMessagesState createState() =>
      CustomValidationMessagesState<FormKeyType>();
}

class CustomValidationMessagesState<FormKeyType>
    extends State<CustomValidationMessages> {
  @override
  Widget build(BuildContext context) {
    return ValidationResults<FormKeyType>(
      filterByKeys: widget.filterByKeys as List<FormKeyType>,
      filterByValidatorType: widget.filterByValidatorType,
      filterByValidity: widget.filterByValidity,
      ignoreIfFormIsEnabled: widget.ignoreIfFormIsEnabled,
      onlyFirstValidationResult: widget.onlyFirstValidationResult,
      validationResultsBuilder: (validationMessages) {
        return Column(
          children: [
            for (ValidationResult result in validationMessages)
              Text(result.message)
          ],
        );
      },
    );
  }
}
