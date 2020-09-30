# Motivation

- **Nested Forms** (not possible with Flutter Form)
- **Reusing validators is easy** (difficult with Flutter Form)
- **Combining validators is easy** (difficult with Flutter Form)
- **Prebuilt validators** (Flutter ships without validators)
- **Form validators allow validation across multiple forms** (Flutter ships without form validators)
- **Positive validation** (not possible with Flutter Form)
- **Specify default validation messages for validators** (not possible with Flutter Form)
- **Combining validation messages of different fields** (not possible with Flutter Form)
- **Display validation messages anywhere on the screen** (not possible with Flutter Form)
- **Easy to test**

# Set up

Step 1: Implement the abstract class `DefaultValidationMessages`, and provide default validation messages for the validators you want to use.

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
class DemoLocalizations {
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

Step 2: Initialize the the library like following. 

If you are using localization, you need to do this, somewhere where you have access to `context` and below `WidgetsApp` in the widget tree. For example in `initState` of a descendent of `WidgetsApp`.

If you are not using localization, you can initialize for example in the `main` function.

``` dart
ValidationConfiguration<DefaultValidationMessagesLocalization>.initialize(MyDefaultValidationMessagesLocalization(loc)]);
```

# Troubleshooting
- Types?