// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:class_unions/class_unions.dart';

// Use `split` to discriminate: Receive a callback for every case, in order.

int doSplit(Union2<int, String> u) => u.split((i) => i, (s) => s.length);

// Use `splitNamed`: Can handle subset of cases, has `onOther`, may return null.

int? doSplitNamed(Union2<int, String> u) =>
    u.splitNamed(on1: (i) => i, on2: (s) => s.length);

int? doSplitNamedOther(Union2<int, String> u) =>
    u.splitNamed(on2: (s) => s.length, onOther: (_) => 42);

void main() {
  // We can introduce union typed expressions by calling a constructor.
  // The constructor `UnionN.inK` injects a value of the `K`th type argument
  // to a union type `UnionN` with `N` type arguments. For example,
  // `Union2<int, String>.in1` turns an `int` into a `Union2<int, String>`.
  print(doSplit(Union2.in1(10))); // Prints '10'.
  print(doSplit(Union2.in2('ab'))); // '2'.

  // We can also use the extension getters `uNK` where `N` is the arity
  // of the union (the number of operands) and `K` is the position of the type
  // argument describing the actual value. So `u21` on an `int` returns a
  // result of type `Union2<int, Never>` (which will work as a `Union2<int, S>`
  // for any `S`).
  print(doSplit(10.u21)); // '10'.
  print(doSplit('ab'.u22)); // '2'.
  print(doSplitNamed(10.u21)); // '10'.
  print(doSplitNamed('ab'.u22)); // '2'.
  print(doSplitNamedOther(10.u21)); // '42'.

  // It is a compile-time error to create a union typed value with wrong types.
  // Union2<int, String> u1 = Union2.in1(true); // Error.
  // Union2<int, String> u2 = Union2.in2(true); // Error.
  // Union2<int, String> u3 = true.u21; // Error.
  // Union2<int, String> u4 = true.u22; // Error.
}
