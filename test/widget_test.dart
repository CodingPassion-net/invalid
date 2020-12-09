import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invalid/invalid.dart';

final fieldOneKey = ValueKey("Field1");
final fieldTwoKey = ValueKey("Field2");

Finder get fieldOneFinder => find.byKey(fieldOneKey);
Finder get fieldTwoFinder => find.byKey(fieldTwoKey);

void main() {
  setUpAll(() {
    ValidationConfiguration<EmptyDefaultValidationMessages>.initialize();
  });

  Future<void> setUpValidationForm(WidgetTester tester,
      {Iterable<FormValidator<FormKeys, FormValidator>> formValidators,
      Function(FormValidationState<FormKeys>) onFormTurnedValid,
      Function(FormValidationState<FormKeys>) onFormTurnedInValid,
      Function(FormValidationState<FormKeys>) onUpdate,
      Function(FormValidationCubit<FormKeys>) onFormValidationCubitCreated,
      bool enabled = false,
      Widget validationMessages}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ValidationForm<FormKeys>(
          onFormTurnedInValid: onFormTurnedInValid,
          formValidators: [
            ShouldBeEqualFormValidator(
                buildErrorMessage: (validator, fields) => "should be equal",
                keysOfFieldsWhichShouldBeEqual: [FormKeys.Key1, FormKeys.Key2])
          ],
          onFormValidationCubitCreated: onFormValidationCubitCreated,
          onFormTurnedValid: onFormTurnedValid,
          onUpdate: onUpdate,
          enabled: enabled,
          child: Column(
            children: [
              CustomTextField(
                key: fieldOneKey,
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
                key: fieldTwoKey,
                validationCapability: TextValidationCapability<FormKeys>(
                    validationKey: FormKeys.Key2,
                    validators: [
                      ShouldNotBeEmptyValidator(
                        buildErrorMessage: (validator, field) =>
                            "should not be empty (Key 2)",
                      )
                    ]),
              ),
              if (validationMessages != null) validationMessages
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('ValidationForm', () {
    testWidgets('onFormValidationCubitCreated should provide the current',
        (tester) async {
      await setUpValidationForm(tester,
          onFormValidationCubitCreated:
              expectAsync1<dynamic, FormValidationCubit<FormKeys>>(
            (formValidationCubit) => expect(formValidationCubit, isNotNull),
          ));
    }, timeout: Timeout(Duration(seconds: 1)));

    testWidgets('onFormTurnedValid should be called once the form turns valid',
        (tester) async {
      await setUpValidationForm(tester, onFormTurnedValid:
          expectAsync1<dynamic, FormValidationState<FormKeys>>((state) {
        expect(state.isValid, true);
      }));
      await tester.enterText(fieldOneFinder, "test");
      await tester.enterText(fieldTwoFinder, "test");
    }, timeout: Timeout(Duration(seconds: 1)));

    testWidgets(
        'onFormTurnedInValid should be called once the form turns invalid',
        (tester) async {
      await setUpValidationForm(tester,
          onFormTurnedInValid:
              expectAsync1<dynamic, FormValidationState<FormKeys>>((state) {
            expect(state.isValid, false);
          }, count: 2));

      // turn valid
      await tester.enterText(fieldOneFinder, "test");
      await tester.enterText(fieldTwoFinder, "test");

      //turn invalid
      await tester.enterText(fieldOneFinder, "");
      await tester.pumpAndSettle();
    }, timeout: Timeout(Duration(seconds: 1)));

    testWidgets('validationMessages should be hidden when form is disabled',
        (tester) async {
      await setUpValidationForm(tester,
          enabled: false,
          validationMessages: CustomValidationMessages(
            filterByKeys: [FormKeys.Key1],
          ));
      expect(find.text("should not be empty (Key 1)"), findsNothing);
    }, timeout: Timeout(Duration(seconds: 1)));

    testWidgets('validationMessages should shown when the form is enabled',
        (tester) async {
      await setUpValidationForm(tester,
          enabled: true,
          validationMessages: CustomValidationMessages(
            filterByKeys: [FormKeys.Key1],
          ));
      expect(find.text("should not be empty (Key 1)"), findsOneWidget);
    }, timeout: Timeout(Duration(seconds: 1)));
  });

  group('ValidationMessages', () {
    testWidgets(
        'should show validation messages of all invalid fields and invalid form validators',
        (tester) async {
      await setUpValidationForm(tester,
          enabled: true,
          validationMessages: CustomValidationMessages<FormKeys>());

      // Make one field invalid
      await tester.enterText(fieldOneFinder, "test");
      await tester.pumpAndSettle();

      expect(find.text("should not be empty (Key 1)"), findsNothing);
      expect(find.text("should not be empty (Key 2)"), findsOneWidget);
    });

    testWidgets(
        'should show validation messages of invalid and valid fields when filterByValidity is set to ValidityFilter.ValidAndInvalid',
        (tester) async {
      await setUpValidationForm(tester,
          enabled: true,
          validationMessages: CustomValidationMessages<FormKeys>(
            filterByValidity: ValidityFilter.ValidAndInvalid,
          ));

      // Make one field invalid
      await tester.enterText(fieldOneFinder, "test");
      await tester.pumpAndSettle();

      expect(find.text("should not be empty (Key 1)"), findsOneWidget);
      expect(find.text("should not be empty (Key 2)"), findsOneWidget);
    });

    testWidgets(
        'should show validation messages of valid fields when filterByValidity is set to ValidityFilter.OnlyValid',
        (tester) async {
      await setUpValidationForm(tester,
          enabled: true,
          validationMessages: CustomValidationMessages<FormKeys>(
            filterByValidity: ValidityFilter.OnlyValid,
          ));

      // Make one field valid
      await tester.enterText(fieldOneFinder, "test");
      await tester.pumpAndSettle();

      expect(find.text("should not be empty (Key 1)"), findsOneWidget);
      expect(find.text("should not be empty (Key 2)"), findsNothing);
    });

    testWidgets(
        'filterByKeys should show only validation messages with keys, that are in the given list',
        (tester) async {
      await setUpValidationForm(tester,
          enabled: true,
          validationMessages: CustomValidationMessages(
            filterByKeys: [FormKeys.Key1],
          ));

      expect(find.text("should not be empty (Key 1)"), findsOneWidget);
      expect(find.text("should not be empty (Key 2)"), findsNothing);
    });

    testWidgets(
        'when filterByValidatorType is set to ValidatorType.FieldValidator it should show only validation messages of field validators',
        (tester) async {
      await setUpValidationForm(tester,
          enabled: true,
          validationMessages: CustomValidationMessages<FormKeys>(
            filterByValidatorType: ValidatorTypeFilter.FieldValidator,
          ));

      // Make form validator invalid
      await tester.enterText(fieldOneFinder, "test");
      await tester.pumpAndSettle();

      expect(find.text("should not be empty (Key 1)"),
          findsNothing); // Field 1 is valid
      expect(find.text("should not be empty (Key 2)"), findsOneWidget);
      expect(find.text("should be equal"), findsNothing);
    });

    testWidgets(
        'when filterByValidatorType is set to ValidatorType.FormValidator it should show only validation messages of form validators',
        (tester) async {
      await setUpValidationForm(tester,
          enabled: true,
          validationMessages: CustomValidationMessages<FormKeys>(
            filterByValidatorType: ValidatorTypeFilter.FormValidator,
          ));

      // Make form validator invalid
      await tester.enterText(fieldOneFinder, "test");
      await tester.pumpAndSettle();

      expect(find.text("should not be empty (Key 1)"), findsNothing);
      expect(find.text("should not be empty (Key 2)"), findsNothing);
      expect(find.text("should be equal"), findsOneWidget);
    });

    testWidgets(
        'when ignoreIfFormIsEnabled is true, validation messages should be shown, even when the form is disabled',
        (tester) async {
      await setUpValidationForm(tester,
          enabled: false,
          validationMessages: CustomValidationMessages<FormKeys>(
            ignoreIfFormIsEnabled: true,
          ));

      expect(find.text("should not be empty (Key 1)"), findsOneWidget);
      expect(find.text("should not be empty (Key 2)"), findsOneWidget);
    });

    testWidgets(
        'when showOnlyTopMessage is true, only the top validation messages should be shown',
        (tester) async {
      await setUpValidationForm(tester,
          enabled: true,
          validationMessages: CustomValidationMessages<FormKeys>(
              filterByKeys: [FormKeys.Key1], onlyFirstValidationResult: true));

      expect(find.text("should not be empty (Key 1)"), findsOneWidget);
      expect(
          find.text("should not be empty or whitespace (Key 1)"), findsNothing);

      // Make top validator valid
      await tester.enterText(fieldOneFinder, "   ");
      await tester.pumpAndSettle();

      expect(find.text("should not be empty (Key 1)"), findsNothing);
      expect(find.text("should not be empty or whitespace (Key 1)"),
          findsOneWidget);
    });
  });

  testWidgets(
      'should placeholder widget when no validation messages are present',
          (tester) async {
        final validationResultsPlaceholderKey = ValueKey("validationResultsPlaceholderKey");

        await setUpValidationForm(tester,
            enabled: true,
            validationMessages: CustomValidationMessages<FormKeys>(
              validationResultPlaceholder: Container(key: validationResultsPlaceholderKey,),
            ));

        // Make fields valid
        await tester.enterText(fieldOneFinder, "test");
        await tester.enterText(fieldTwoFinder, "test");
        await tester.pumpAndSettle();

        expect(find.byKey(validationResultsPlaceholderKey), findsOneWidget);
      });

  testWidgets(
      'should placeholder widget when no validation took place',
          (tester) async {
        final validationResultsPlaceholderKey = ValueKey("validationResultsPlaceholderKey");

        await setUpValidationForm(tester,
            enabled: false,
            validationMessages: CustomValidationMessages<FormKeys>(
              validationResultPlaceholder: Container(key: validationResultsPlaceholderKey,),
            ));

        expect(find.byKey(validationResultsPlaceholderKey), findsOneWidget);
      });
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
  final Widget validationResultPlaceholder;

  const CustomValidationMessages(
      {Key key,
      this.filterByKeys,
      this.filterByValidatorType,
      this.ignoreIfFormIsEnabled = false,
      this.filterByValidity = ValidityFilter.OnlyInvalid,
      this.validationResultPlaceholder,
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
      validationResultPlaceholder: widget.validationResultPlaceholder,
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
