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

Implement the abstract class `DefaultValidationMessages`, and provide default validation messages for the validators you want to use.

``` dart
    class FazuaDefaultValidationMessages implements DefaultValidationMessages {
    @override
    String shouldBeBetweenOrEqualValidationMessage(
        ShouldBeBetweenOrEqualValidator val, Field field) {
        return "The value for the field ${field.fieldName}, should be between ${val.min} and ${val.max}. Your current value is ${field.value}";
    }
    }




    ValidationConfiguration<FazuaDefaultValidationMessages initialize(
        LocalizedValidationMessages(loc),
        typeConverter: [DateInputResultConverter()]);