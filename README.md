# Motivation for this Flutter Validation library

- **Nested Forms are possible** (not possible with Flutter Form)
- **Reusing validators is easy** (difficult with Flutter Form)
- **Combining validators is easy** (difficult with Flutter Form)
- **Prebuilt validators** (Flutter ships without validators)
- **Form validators allow validation across multiple fields** (Flutter ships without form validators)
- **Positive validation** (not possible with Flutter Form)
- **Specify default validation messages for validators** (not possible with Flutter Form)
- **Combining validation messages of different fields** (not possible with Flutter Form)
- **Display validation messages anywhere on the screen** (not possible with Flutter Form)
- **Easy to test**

# Example project
https://github.com/CodingPassion-net/invalid/blob/master/example/lib/main.dart

# Set up

**Step 1**: Add dependency to your pubspec.yaml:

``` yaml
invalid:
  git:
    url: https://github.com/CodingPassion-net/invalid.git
    # ref: a078afc709cde12a1f7f89c88f34c85b43da0895 // You can pick a specific commit or branch
```

**Step 2**: Implement the abstract class `DefaultValidationMessages`, and provide default validation messages for the validators you want to use.

``` dart
	class MyDefaultValidationMessagesLocalization implements DefaultValidationMessagesLocalization {
		@override
		String shouldBeBetweenOrEqualValidationMessage(
			ShouldBeBetweenOrEqualValidator val, Field field) {
			return "The value for the field ${field.fieldName}, should be between ${val.min} and ${val.max}. Your current value is ${field.value}";
		}
	}
```

You can also use it directly in your class where all your localized resources are defined. But be aware that using `Intl.message` with arguments means, that the parameter of the enclosing function of `Intl.message`, must be also passed to the `arg` parameter of `Intl.message` and all parameters must be of type `String`. This is a limitation of [Intl](https://api.flutter.dev/flutter/intl/Intl/message.html).

``` dart
class DemoLocalizations extends DefaultValidationMessagesLocalization {
	DemoLocalizations(this.localeName);

	static Future<DemoLocalizations> load(Locale locale) {
		final String name = locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
		final String localeName = Intl.canonicalizedLocale(name);
		return initializeMessages(localeName).then((_) {
		return DemoLocalizations(localeName);
		});
	}

	static DemoLocalizations of(BuildContext context) {
		return Localizations.of<DemoLocalizations>(context, DemoLocalizations);
	}

	final String localeName;

	String shouldBeBetweenOrEqualValidationMessage(
		ShouldBeBetweenOrEqualValidator val, Field field) {
		return shouldBeBetweenOrEqualValidationMessageLoc(field.fieldName, val.min, val.max, field.value);
	}

	String get shouldBeBetweenOrEqualValidationMessageLoc(String fieldName, String min, String max, String value) {
		return Intl.message(
			'The value for the field ${fieldName}, should be between ${min} and ${max}. Your current value is ${value}',
			name: 'title',
			locale: localeName,
			args: [
				fieldName,
				min,
				max,
				value
			]
		);
	}
}
```

**Step 3**: Initialize the the library like following. 

If you are using localization, you need to initialize, somewhere where you have access to `context` and below `WidgetsApp` in the widget tree. For example in `initState` of a descendent widget of `WidgetsApp`.

If you are not using localization, you can initialize for example in the `main` function.

``` dart
ValidationConfiguration<DefaultValidationMessagesLocalization>.initialize(defaultValidationMessages: MyDefaultValidationMessagesLocalization(loc)]);
```

**Step 4**: With `ValidationCapability` you can add validation to all of your input widgets like for example `TextField`, `Slider` or even `Checkbox`.

For `TextField` there exists a prebuilt `TextValidationCapability`:

``` dart
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
```

For all other input widgets you need to use `ValidationCapability`.

**Step 5 (optional)**:
It's suggested to also add a custom validation messages widget, which can be styled in the design of your app and resued across the application.

``` dart
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
      validationResultsBuilder: (validationResults) {
		
		// Here you can style your widget as you want
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
```

# Documentation

## ValidationForm

All input fields with validation capability must be children of `ValidationForm`. Each form is uniquely identified by the type of the key. In this case `ChangePasswordForm`. 


``` dart
ValidationForm<ChangePasswordForm>(
	enabled: true, // To enable validation from the beginning. Normally this will be enabled a click on a button.
	onUpdate: (state) {}, // Is called when the validation state updates
	onFormTurnedInValid: (state) {}, // Is called when the form turns invalid
	onFormTurnedValid: (state) {}, // Is called when the form turns valid
	onFormValidationCubitCreated: (form) {}, // Gives access to the form
	formValidators: [], // Adding FormValidators 
	child: Container()
)
```

We suggest to create an enum with keys for each form. The type of the enum identifies the form. The values of the enums can be used as keys to identify fields, field validators, form validators.

``` dart
enum ChangePasswordForm { OldPasswordField, NewPasswordField, NewPasswordFieldConfirmation, PasswordsMustBeEqualFormValidatorKey }

```

## Input (Validation Fields)

Every input field must be a descendant of the `ValidationForm` in the widget tree. The type the form key must be specified as type parameter of `ValidationCapability`. This is how the form knows, which fields are belonging to it.

``` dart
CustomTextField(
	validationCapability: TextValidationCapability<ChangePasswordForm>( // Don't forget the key type.
		validationKey: ChangePasswordForm.OldPasswordField,
		validators: [ShouldNotBeEmptyValidator()],
		autovalidate: false // Should this TextField be validated as you type.
	),
)
```

## ValidationMessages

The `ValidationMessages` widget is there to display validation messages in any kind and at any place within the app, as long as it is a child of the form. The type the form key must be specified as type parameter of `ValidationMessages`. ValidationMessages is a very flexible widget (all filters apply as logical AND):

This displays all validation messages of the form `ChangePasswordForm`.
``` dart
CustomValidationMessages<ChangePasswordForm>()
```

This displays only the validation messages for the field with the key `ChangePasswordForm.OldPasswordField`.
``` dart
CustomValidationMessages<ChangePasswordForm>(
	filterByKeys: [ChangePasswordForm.OldPasswordField],
)
```

You can also display only the validation messages for the specific field and form validators, by assigning them keys.
``` dart
CustomValidationMessages<ChangePasswordForm>(
	filterByKeys: [ChangePasswordForm.PasswordsMustBeEqualFormValidatorKey],
)
```

You can also show only validation messages from field validators or only from form validators.
``` dart
CustomValidationMessages<ChangePasswordForm>(
	filterByValidatorType: ValidatorTypeFilter.FieldValidator, // Can also be ValidatorTypeFilter.FormValidator
)
```

If you for example have a field with multiple validators, like a password field you can specify to always show the first validation message.
``` dart
CustomValidationMessages<ChangePasswordForm>(
	filterByKeys: [ChangePasswordForm.NewPasswordField],
	onlyFirstValidationResult: true
)
```

### Positive Validation

If you want to show a list of password requirements and show the user which one he has already fulfilled and which one he still needs to fulfill. You can specify that validation messages for valid and invald validators are shown.

``` dart
ValidationResults<ChangePasswordForm>(
	filterByValidity: ValidityFilter.ValidAndInvalid, // ValidityFilter.OnlyValid is also possible 
	ignoreIfFormIsEnabled: true,
	validationResultsBuilder: (validationResults) {
        return Column(
          children: [
            for (ValidationResult result in validationResults)
              Text(result.message + result.isValid.toString())
          ],
        );
      },
)
```

## Validators

For every validator you can specify a translatable default message. But often you just need something customized. That's why there is the `buildErrorMessage` callback, where you can build your custom validation message. There you have access to the current validator, either a form or a field validator.

You can reuse any validator by assigning it to a variable:
``` dart
var weightValidator = ShouldBeBetweenValidator(
	min: 3,
	max: 5,
	buildErrorMessage: (validator, field) =>
		"You should weigh between ${validator.min} and ${validator.min}. 
		 Your current weight is ${field.value}. Fieldname: ${field.fieldName}",
)
```

### Field Validators

Field validators only validate one value (the field).

For field validators you have also access to the field, to retrieve the `fieldName` and the `value` within the `buildErrorMessage` callback.

``` dart
ShouldBeBetweenValidator(
	min: 3,
	max: 5,
	buildErrorMessage: (validator, field) =>
		"You should weigh between ${validator.min} and ${validator.min}. 
		 Your current weight is ${field.value}. Fieldname: ${field.fieldName}",
)
```

### Form Validators
Form validators can validate across all the fields in the form.

In the `buildErrorMessage` callback for form validators you have access to all the fields of the form, again to retrieve `fieldName` and `value` of any field.

``` dart
ShouldBeEqualFormValidator(
	buildErrorMessage: (validator, fields) =>
		"${fields.findByFieldKey(ChangePasswordForm.NewPasswordField).fieldName} must be equal to ${fields.findByFieldKey(ChangePasswordForm.NewPasswordFieldConfirmation).fieldName}",
	keysOfFieldsWhichShouldBeEqual: [
		ChangePasswordForm.NewPasswordField, 
		ChangePasswordForm.NewPasswordFieldConfirmation
	]
)
```

## FormValidationCubit
The `FormValidationCubit` is basically the controller for the form validation.

You can retrieve it either this way:

``` dart
class _MyHomePageState extends State<MyHomePage> {
  FormValidationCubit<FormKeys> _formValidation;

  @override
  Widget build(BuildContext context) {
    return ValidationForm<FormKeys>(
      onFormValidationCubitCreated: (formValidation) =>
          _formValidation = formValidation,
    );
  }
}
```

or in the subtree with:

``` dart
Widget build(BuildContext context) {
	var _form = context.getForm<FormKeys>();
}
```

### Enable the validation for the form after clicking a button

``` dart
class _MyHomePageState extends State<MyHomePage> {
  FormValidationCubit<FormKeys> _formValidation;

  @override
  Widget build(BuildContext context) {
    return ValidationForm<FormKeys>(
      onFormValidationCubitCreated: (formValidation) =>
          _formValidation = formValidation,
      child: Column(
        children: [
          CustomTextField(
           /// ...
          ),
          CustomValidationMessages<FormKeys>(),
          RaisedButton(
            onPressed: () {
              _formValidation.enableValidation();
            },
            child: Text("Validate"),
          )
        ],
      ),
    );
  }
}
```

# Troubleshooting
- `ValidationForm`, `ValidationCapability`, `ValidationMessages` always need to have the type of the form key passed as a type parameter. Maybe you have this forgotton?

# Suggestions
- We strongly suggest to activate strong typing and disable implicit dynamic in your `analysis_options.yaml`

``` yaml
implicit-casts: false
implicit-dynamic: false
```
