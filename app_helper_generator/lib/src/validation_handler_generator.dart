// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:app_helper/app_helper.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class ValidationHandlerGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    if (library.allElements.isEmpty) {
      return '';
    }

    for (final classElement in library.classes) {
      final fields = <FieldElement>[];
      for (final field in classElement.fields) {
        if (TypeChecker.fromRuntime(ServerValidateField)
            .hasAnnotationOf(field)) {
          fields.add(field);
        }
      }
      if (fields.isNotEmpty) {
        final fieldsHandler = StringBuffer();
        final resetFieldsHandler = StringBuffer();

        for (final field in fields) {
          final name = field.name;
          fieldsHandler.writeln("""
if (validationError.property == '$name') {
  errors.$name = errorMessage;
}
          """);
          resetFieldsHandler.writeln("""
errors.$name = null;""");
        }
        final className = classElement.name.replaceFirst('_', '');
        return """
mixin _\$${className}Validators {
  final errors = ${className}Errors();

  void handleValidationError(Exception error) {
    if (error is ValidationErrorResponse) {
      for (var validationError in error.message) {
      final errorMessage = validationError.constraints[validationError.constraints.keys.first];
        ${fieldsHandler}
      }
    }
  }

  void resetErrors() {
    $resetFieldsHandler
  }
}
        """;
      }
    }

    return '';
  }
}
