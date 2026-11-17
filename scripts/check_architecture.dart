import 'dart:io';

/// Source dependency checks, deliberately independent of analyzer internals.
List<String> architectureViolations(Directory source) {
  final violations = <String>[];
  final dependencies = <String, List<String>>{};
  final directives = RegExp(r'''\b(?:import|export)\s+['"]([^'"]+)['"]''');
  const package = 'package:assessment_project_fb_international_frontend/';
  for (final file in source.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    final relative = file.path
        .substring(source.path.length + 1)
        .replaceAll('\\', '/');
    final text = file.readAsStringSync();
    final imports = directives
        .allMatches(text)
        .map((match) => match.group(1)!)
        .toList();
    int group(String uri) => uri.startsWith('dart:')
        ? 0
        : uri.startsWith('package:') && !uri.startsWith(package)
        ? 1
        : uri.startsWith(package)
        ? 2
        : 3;
    for (var index = 1; index < imports.length; index++) {
      if (group(imports[index]) < group(imports[index - 1])) {
        violations.add(
          '$relative: import groups must be SDK, external packages, then project',
        );
      }
    }
    dependencies[relative] = [];
    for (final uri in imports) {
      final target = uri.startsWith(package)
          ? uri.substring(package.length)
          : !uri.contains(':')
          ? file.uri
                .resolve(uri)
                .toFilePath()
                .substring(source.absolute.path.length + 1)
                .replaceAll('\\', '/')
          : null;
      if (target != null) dependencies[relative]!.add(target);
      final rule = switch (relative) {
        _
            when relative.startsWith('core/network/') &&
                (uri == 'package:flutter/material.dart' ||
                    uri == 'package:flutter/widgets.dart') =>
          'network imports UI',
        _
            when relative.startsWith('core/') &&
                target != null &&
                (target.startsWith('features/') ||
                    target.startsWith('app/') ||
                    target.startsWith('routes/') ||
                    target.startsWith('demo/')) =>
          'Core imports application/business code',
        _
            when relative.contains('/view/') &&
                (uri.startsWith('package:dio/') ||
                    (target?.contains('/service/') ?? false)) =>
          'view imports transport/service',
        _
            when relative.contains('/controller/') &&
                (target?.contains('/view/') ?? false) =>
          'controller imports presentation',
        _
            when relative.contains('/service/') &&
                (target?.contains('/controller/') ?? false) =>
          'service imports controller',
        _
            when relative.contains('/model/') &&
                (uri.startsWith('package:dio/') ||
                    uri.contains('riverpod/') ||
                    uri.startsWith('package:flutter/')) =>
          'model imports infrastructure/UI',
        _ => null,
      };
      if (rule != null) violations.add('$relative: $rule ($uri)');
    }
    if (relative.contains('/view/') && text.contains('ApiEndpoints')) {
      violations.add('$relative: view references API endpoints');
    }
  }
  final visited = <String>{};
  final stack = <String>[];
  void visit(String file) {
    if (stack.contains(file)) {
      violations.add(
        'Import cycle: ${[...stack.skip(stack.indexOf(file)), file].join(' -> ')}',
      );
      return;
    }
    if (!visited.add(file)) return;
    stack.add(file);
    for (final dependency in dependencies[file] ?? const <String>[]) {
      visit(dependency);
    }
    stack.removeLast();
  }

  for (final file in dependencies.keys) {
    visit(file);
  }
  return violations;
}

void main() {
  final violations = architectureViolations(Directory('lib').absolute);
  if (violations.isEmpty) {
    stdout.writeln('Architecture checks passed.');
  } else {
    stderr.writeln(violations.join('\n'));
    exitCode = 1;
  }
}
