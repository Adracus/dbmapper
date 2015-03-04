// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library dbmapper.test;

import 'package:unittest/unittest.dart';

import 'dbmapper_definition_test.dart' as definition_test;
import 'dbmapper_memory_test.dart' as memory_test;

main() {
  group("dbmapper", () {
    definition_test.defineTests();
    memory_test.defineTests();
  });
}
