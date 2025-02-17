<!--
[![Build Status](https://github.com/eernstg/extension_type_unions/workflows/Dart%20CI/badge.svg)](https://github.com/lrhn/charcode/actions?query=workflow%3A"Dart+CI")
[![Pub](https://img.shields.io/pub/v/unline_union_type.svg)](https://pub.dev/packages/extension_type_unions)
[![package publisher](https://img.shields.io/pub/publisher/extension_type_unions.svg)](https://pub.dev/packages/extension_type_unions/publisher)
-->

# Class Unions

Support for union types in Dart has been requested at least [since 2012](https://github.com/dart-lang/language/issues/1222). This repository provides a basic level of support for union types in Dart.

This is a variant of the package [`extension_type_unions`][] that uses classes rather than extension types. This is more costly in terms of space and time consumption at run time, but in return it provides stronger guarantees at run time.

The core difference is that `extension_type_unions` use a static-only approach such that a value of a union type is really the object itself, whereas this package uses a real (reified) wrapper object.

This implies that it is not possible to create (or in any way obtain) a reference to an object of type, say, `Union2<int, String>` whose `value` isn't either an `int` or a `String`. So there are no invalid values of a union type from this package. On the other hard, a value `u` whose type is `Union2<int, String>` does not have any of the operand types; that is, `u is int` and `u is String` are both false, even though `u is Union2<int, String>` is true. This implies that all usages of union types from this package _must_ take an explicit step to retrieve the underlying value, e.g., `if (u.is1) print(u.as1);`.

[`extension_type_unions`]: https://github.com/eernstg/extension_type_unions

## Union Types, and the kind offered here

There are several different ways to define the notion of a union type. Here is how to understand union types in the context of this package:

A union type is a type which is created by taking the union of several other types. At the conceptual level, we could use a notation like `int | String` to denote the union of the types `int` and `String`. (Note that this package does _not_ support new syntax for union types, this notation is only used to talk about the meaning of union types.) The basic semantics of a union type is that an object has the union type iff it has any of the types that we're taking the union of. For example, `1` has type `int | String`, and so does `'Hello'`.

This package supports union types that are **untagged**: There is no run-time entity that keeps track of the operand type which was used to justify the typing of a given object. So if you have an expression of type `Object | num` and the value has run-time type `int` then you can't tell whether it's considered to have that union type because it's a `num`, or because it's an `Object`.

The kind of union type which is supported by this package does not have any of the algebraic properties that one would normally expect. In particular, there is no support for computing the traditional subtype relationships (such that `int | String` is the same type as `String | int`, and `int` and `String` are both subtypes of `int | String`, etc). Similarly, there is no support for detecting (and acting on) the otherwise standard property that `Object | num` is the same as `Object`.

Those properties would certainly be supported by an actual language mechanism, but this package just provides a very simple version of union types where these algebraic properties are considered unknown. In general, these union types are unrelated, except for standard covariance (e.g., `int | Car | Never` is a subtype of `num | Vehicle | String`, assuming that `Car` is a subtype of `Vehicle`).

## Concrete syntax and example

Now please forget about the nice, conceptual notation `T1 | T2`. The actual notation for that union type with this package is `Union2<T1, T2>`. There is a generic extension type for each arity up to 9, that is `Union2, Union3, ... Union9`.

Here is an example showing how it can be used:

```dart
import 'package:class_unions/class_unions.dart';

int f(Union2<int, String> x) => x.split(
      (i) => i + 1,
      (s) => s.length,
    );

void main() {
  print(f(1.u21)); // '2'.
  print(f('Hello'.u22)); // '5'.
}
```

This example illustrates that this kind of union type can be used to declare that a particular formal parameter can be an `int` or a `String`, and nothing else, and it is then possible to pass actual arguments which are of type `int` or `String`, as long as they are explicitly marked as having the union type and being a particular operand (first or second, in this case) of that union type.

The method `split` is used to handle the different cases (when the value of `x` is actually an `int` respectively a `String`). It is safe in the sense that it accepts actual arguments for the operands of the union type; that is, the first argument is a function (a callback) that receives an argument of type `int`, and the second argument is a function that receives an argument of type `String`, and `split` is going to call the one that fits the actual `value`.

The extension getters `u21` and `u22` invoke the corresponding extension type constructors. For example, `1.u21` is the same thing as `Union2<int, Never>.in1(1)`, which may again be understood conceptually as "turn `1` into a value of type `int | Never`, using the first type in the union". Note that this is a subtype of `Union2<int, T>` for any type `T`, which makes it usable, e.g., where a `Union2<int, String>` is expected.

An alternative approach would be to use a plain type test:

```dart
int g(Union2<int, String> x) => switch (x.value) {
      int i => i + 1,
      String s => s.length,
      _ => throw "Unexpected type",
    };
```

This will run just fine, but there is no static type check on the cases: `x.value` has the type `Object?`, and there is no notification (error or warning) if we test for the wrong set of types (say, if we're testing for a `double` and for a `String`, and forget all about `int`).

## Usage

There is a run-time cost associated with the use of these union types, compared to the situation where we use a much more general type (say, `dynamic`) and then pass actual arguments of type, say, `int` or `String`. Applied to the example from the previous section, we would get the following variant:

```dart
int h(dynamic x) => switch (x) {
      int() => x + 1,
      String() => x.length,
      _ => throw "Unexpected type",
    };
```

The approach that uses class union types is useful because `g` gives rise to static type checks: It is an error to pass an actual argument to `g` which is not an instance of `Union2<int, String>`, and it is guaranteed that the `value` of such an object is an `int` or a `String`. So `g` offers better static type checking, but `h` is faster and uses less memory.

(`f` is probably slightly more expensive than `g` because it includes the creation and invocation of function literals. However, `f` has even better type safety and, arguably, better readability.)

The static type checks are strict, as usual, in that it is a compile-time error to pass, say, an argument of type `Union2<double, String>` to `f` or `g`. This means that we do keep track of the fact that `f` is intended to work on an `int` or on a `String`, and not on any other kind of object.

In addition to the compile-time type checking, Dart maintains soundness at run time, which provides a guarantee that an expression of type `Union2<int, String>` is guaranteed to have that type (or a subtype) at run time. In turn, the set of available constructors of this type provides a guarantee that every `Union2<int, String>` will have a `value` whose run-time type is `int` or `String` (or a subtype thereof).

(In contrast, a union type from `extension_type_unions` can have a value which is invalid, that is, where that `value` does not have the type `int` nor the type `String`. In return, `extension_type_unions` are as cheap as `h` above in terms of run-time resource consumption.)

## The type Json

This package includes an extension type named `Json` which is used to support an encoding which is typically used when a JSON term is parsed and modeled as an object structure that consists of lists, maps, and certain primitive values. In particular, `jsonDecode` in 'dart:convert' uses this encoding.

This could be modeled as a recursive union type, but not as a plain union type. For example, a `Json` typed value could be a `List<Json>` that contains elements of type `Json` which could in turn be `List<Json>`, and so on. This implies that we cannot describe `Json` as a simple union of other types.

```dart
// Assuming that Dart supports recursive typedefs (but it doesn't).
rec typedef Json =
    Null
  | bool
  | int
  | double
  | List<Json>
  | Map<String, Json>;
```

We could of course say that `Json` is just a plain union with operands `Null`, `bool`, `int`, `double`, `List<dynamic>`, and `Map<String, dynamic>`. However, if we do that then we haven't modeled the constraint that the contents of those collections must again be of type `Json`. So we could have, for example, `<dynamic>[#foo]`, which _should_ be prevented because we don't expect to encounter a `Symbol` in a JSON value.

It is not hard to express the recursive nature of these object graphs in terms of member signatures: We just make sure that a value of type `Json` is typed as a `Map<String, Json>` in the case where it is a map, and so on. This doesn't rely on any special type system magic. It just requires that each recursive type is supported by a corresponding extension type, because `Union6` won't suffice. Example:

```dart
import 'package:class_unions/class_json.dart';

void main() {
  var json = Json.fromSource(
      '{"text": "foo", "value": 1, "status": false, "extra": null}');

  json.splitNamed(
    onMap: (map) {
      for (var key in map.keys) {
        print('$key => ${map[key]}');
      }
    },
    onOther: (other) => throw "Expected a JSON map, got $other!",
  );
}
```

## Future extensions

If Dart adds support for [implicit constructors][] then we will be able to avoid the unwieldy syntax at sites where a given expression needs to get a union type:

[implicit constructors]: https://github.com/dart-lang/language/blob/main/working/0107%20-%20implicit-constructors/feature-specification.md

```dart
import 'package:class_unions/class_unions.dart';

int f(Union2<int, String> x) => x.split(
      (i) => i + 1,
      (s) => s.length,
    );

void main() {
  print(f(1)); // '2'.
  print(f('Hello')); // '5'.
}
```

This would work because an expression `e` of type `int` in a location where a `Union2<int, String>` is expected is implicitly rewritten as `Union2<int, String>.in1(e)` if `Union2.in1` is an implicit constructor. Similarly, `'Hello'` would be implicitly rewritten as `Union2<int, String>.in2('Hello')` if `Union2.in2` is implicit.
