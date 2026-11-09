import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';

/// Marks an endpoint as intentionally unused. It belongs in the Rust doc
/// comment; FRB copies doc comments into the generated Dart bindings.
final _allowUnusedMarker = RegExp(
  r'frb-api-usage:\s*allow-unused(?:\s*\(([^)]*)\))?',
);

const _hint =
    'Remove unused functions from the Rust FRB API, call them from '
    'application code under lib/, or mark them in their Rust doc comment with '
    '"frb-api-usage: allow-unused (<reason>)".';

Future<void> main() async {
  final appDirectory = Directory.current.absolute;
  final generatedApiDirectory = Directory(
    '${appDirectory.path}${Platform.pathSeparator}lib'
    '${Platform.pathSeparator}src${Platform.pathSeparator}rust'
    '${Platform.pathSeparator}api',
  );
  final appLibDirectory = Directory(
    '${appDirectory.path}${Platform.pathSeparator}lib',
  );

  if (!generatedApiDirectory.existsSync() || !appLibDirectory.existsSync()) {
    stderr.writeln(
      'Could not find the generated FRB API or application lib directory. '
      'Run this command from app/flutter after generating the FRB bindings.',
    );
    exitCode = 2;
    return;
  }

  final generatedFiles = _dartFiles(generatedApiDirectory).toList();
  if (generatedFiles.isEmpty) {
    stderr.writeln(
      'No generated FRB API files found in ${generatedApiDirectory.path}.',
    );
    exitCode = 2;
    return;
  }

  // analysis_options.yaml excludes lib/src/rust/** from `flutter analyze`.
  // Listing every file explicitly keeps the generated bindings analyzable here.
  final collection = AnalysisContextCollection(
    includedPaths: [
      for (final file in [...generatedFiles, ..._dartFiles(appLibDirectory)])
        file.absolute.path,
    ],
  );
  try {
    final endpoints = <String, _Endpoint>{};
    for (final file in generatedFiles) {
      final unit = await _resolvedUnit(collection, file);
      unit.accept(_EndpointCollector(file, unit.lineInfo, endpoints));
    }

    final usedEndpoints = <String>{};
    for (final file in _dartFiles(appLibDirectory)) {
      if (_isGeneratedBinding(appDirectory, file)) {
        continue;
      }

      final unit = await _resolvedUnit(collection, file);
      unit.accept(_ApiReferenceVisitor(endpoints.keys.toSet(), usedEndpoints));
    }

    final findings = <_Finding>[];
    final intentionallyUnused = <_Endpoint>[];
    for (final MapEntry(:key, value: endpoint) in endpoints.entries) {
      final used = usedEndpoints.contains(key);
      final reason = endpoint.allowUnusedReason;
      if (reason == null) {
        if (!used) {
          findings.add(_Finding(endpoint, 'is not referenced from lib/'));
        }
      } else if (reason.isEmpty) {
        findings.add(
          _Finding(endpoint, 'has an allow-unused marker without a reason'),
        );
      } else if (used) {
        findings.add(
          _Finding(endpoint, 'is used in lib/ but still marked allow-unused'),
        );
      } else {
        intentionallyUnused.add(endpoint);
      }
    }
    findings.sort((left, right) => left.endpoint.compareTo(right.endpoint));
    intentionallyUnused.sort((left, right) => left.compareTo(right));

    if (intentionallyUnused.isNotEmpty) {
      stdout.writeln('Intentionally unused FRB API functions:');
      for (final endpoint in intentionallyUnused) {
        stdout.writeln(
          '  ${endpoint.name} (${endpoint.location(appDirectory)}): '
          '${endpoint.allowUnusedReason}',
        );
      }
    }
    _reportToGitHubActions(appDirectory, findings, intentionallyUnused);

    if (findings.isEmpty) {
      stdout.writeln(
        'All generated FRB API functions are referenced by app code or '
        'marked as intentionally unused.',
      );
      return;
    }

    stderr.writeln('FRB API usage problems:');
    for (final finding in findings) {
      final endpoint = finding.endpoint;
      stderr.writeln(
        '  ${endpoint.name} (${endpoint.location(appDirectory)}) '
        '${finding.problem}',
      );
    }
    stderr.writeln(_hint);
    exitCode = 1;
  } finally {
    await collection.dispose();
  }
}

/// Returns null without a marker, an empty string for a marker without a
/// reason, and the reason otherwise.
String? _allowUnusedReason(Comment? documentation) {
  if (documentation == null) {
    return null;
  }
  final text = documentation.tokens.map((token) => token.lexeme).join('\n');
  final match = _allowUnusedMarker.firstMatch(text);
  return match == null ? null : (match.group(1) ?? '').trim();
}

Future<CompilationUnit> _resolvedUnit(
  AnalysisContextCollection collection,
  File file,
) async {
  final path = file.absolute.path;
  final result = await collection
      .contextFor(path)
      .currentSession
      .getResolvedUnit(path);
  if (result is! ResolvedUnitResult) {
    throw StateError('Could not analyze Dart source: $path');
  }
  return result.unit;
}

Iterable<File> _dartFiles(Directory directory) sync* {
  for (final entity in directory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}

bool _isGeneratedBinding(Directory appDirectory, File file) {
  final relative = _relativePath(appDirectory, file);
  return relative.startsWith('lib/src/rust/');
}

String _relativePath(Directory base, File file) {
  final basePath = base.absolute.path;
  final filePath = file.absolute.path;
  return filePath
      .substring(basePath.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}

String _elementKey(ExecutableElement element) {
  final enclosing = element.enclosingElement;
  final owner = enclosing is LibraryElement ? '' : '${enclosing?.name}.';
  final setter = element is SetterElement ? '=' : '';
  return '${element.library.uri}::$owner${element.name}$setter';
}

/// Collects the Dart endpoints FRB generates for the Rust API: top-level
/// functions, plus class members that call into Rust. Members without a body
/// belong to opaque Rust types; FRB implements them in frb_generated.dart.
/// Dart-only members such as `==`, `hashCode` and plain const constructors of
/// mirrored structs are not endpoints.
class const _EndpointCollector(
  final File generatedFile,
  final LineInfo lineInfo,
  final Map<String, _Endpoint> endpoints,
) extends RecursiveAstVisitor<void> {
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is CompilationUnit) {
      _add(
        node.declaredFragment?.element,
        node.name.lexeme,
        node.name.offset,
        node.documentationComment,
      );
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final isOverride = node.metadata.any(
      (annotation) => annotation.name.name == 'override',
    );
    if (!node.isOperator && !isOverride && _callsRust(node.body)) {
      final setter = node.isSetter ? '=' : '';
      _add(
        node.declaredFragment?.element,
        '${node.name.lexeme}$setter',
        node.name.offset,
        node.documentationComment,
      );
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // A constructor without a body is a plain Dart constructor of a mirrored
    // struct, so only constructors that forward to Rust count.
    final name = node.name;
    if (node.body is! EmptyFunctionBody && _callsRust(node.body)) {
      _add(
        node.declaredFragment?.element,
        name?.lexeme ?? '',
        (name ?? node.typeName ?? node.beginToken).offset,
        node.documentationComment,
      );
    }
  }

  bool _callsRust(FunctionBody body) =>
      body is EmptyFunctionBody ||
      body.toSource().contains('RustLib.instance.api');

  void _add(
    ExecutableElement? element,
    String memberName,
    int nameOffset,
    Comment? documentation,
  ) {
    final owner = element?.enclosingElement;
    final ownerName = owner is LibraryElement ? null : owner?.name;
    if (element == null ||
        memberName.startsWith('_') ||
        (ownerName?.startsWith('_') ?? false)) {
      return;
    }

    final displayName = ownerName == null
        ? memberName
        : memberName.isEmpty
        ? ownerName
        : '$ownerName.$memberName';
    endpoints.putIfAbsent(
      _elementKey(element),
      () => _Endpoint(
        name: displayName,
        generatedFile: generatedFile,
        line: lineInfo.getLocation(nameOffset).lineNumber,
        allowUnusedReason: _allowUnusedReason(documentation),
      ),
    );
  }
}

/// Adds one annotation per finding and a job summary, so the details are
/// visible on the workflow run page without opening the raw log.
void _reportToGitHubActions(
  Directory appDirectory,
  List<_Finding> findings,
  List<_Endpoint> intentionallyUnused,
) {
  final environment = Platform.environment;
  if (environment['GITHUB_ACTIONS'] != 'true') {
    return;
  }

  final workspace = environment['GITHUB_WORKSPACE'];
  final summary = StringBuffer()..writeln('### FRB API usage');
  if (findings.isNotEmpty) {
    summary
      ..writeln()
      ..writeln('| Function | Problem | Generated Dart binding |')
      ..writeln('| --- | --- | --- |');
  }
  for (final finding in findings) {
    final endpoint = finding.endpoint;
    final repoPath = workspace == null
        ? endpoint.location(appDirectory)
        : _relativePath(Directory(workspace), endpoint.generatedFile);
    final location = 'file=$repoPath,line=${endpoint.line}';
    final message = '${endpoint.name} ${finding.problem}. $_hint';
    stdout.writeln('::warning $location,title=FRB API usage::$message');
    summary.writeln(
      '| `${endpoint.name}` | ${finding.problem} '
      '| `${endpoint.location(appDirectory)}` |',
    );
  }
  if (intentionallyUnused.isNotEmpty) {
    summary
      ..writeln()
      ..writeln('Intentionally unused (allow-unused marker):')
      ..writeln()
      ..writeln('| Function | Reason | Generated Dart binding |')
      ..writeln('| --- | --- | --- |');
    for (final endpoint in intentionallyUnused) {
      summary.writeln(
        '| `${endpoint.name}` | ${endpoint.allowUnusedReason} '
        '| `${endpoint.location(appDirectory)}` |',
      );
    }
  }
  summary
    ..writeln()
    ..writeln(findings.isEmpty ? 'No problems found.' : _hint);

  final summaryPath = environment['GITHUB_STEP_SUMMARY'];
  if (summaryPath != null) {
    File(summaryPath)
        .writeAsStringSync(summary.toString(), mode: FileMode.append);
  }
}

class const _Endpoint({
  required final String name,
  required final File generatedFile,
  required final int line,
  required final String? allowUnusedReason,
}) {
  String location(Directory appDirectory) =>
      '${_relativePath(appDirectory, generatedFile)}:$line';

  int compareTo(_Endpoint other) {
    final byFile = generatedFile.path.compareTo(other.generatedFile.path);
    return byFile != 0 ? byFile : line.compareTo(other.line);
  }
}

class const _Finding(final _Endpoint endpoint, final String problem);

class const _ApiReferenceVisitor(
  final Set<String> apiFunctionKeys,
  final Set<String> usedApiFunctions,
) extends RecursiveAstVisitor<void> {
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _markUsed(node.element);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _markUsed(node.element);
    super.visitConstructorName(node);
  }

  // Setters and compound assignments resolve through the expression, not the
  // identifier on the left-hand side.
  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _markCompound(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _markCompound(node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _markCompound(node);
    super.visitPostfixExpression(node);
  }

  void _markCompound(CompoundAssignmentExpression node) {
    _markUsed(node.readElement);
    _markUsed(node.writeElement);
  }

  void _markUsed(Element? element) {
    final base = element?.baseElement;
    if (base is ExecutableElement) {
      final key = _elementKey(base);
      if (apiFunctionKeys.contains(key)) {
        usedApiFunctions.add(key);
      }
    }
  }
}
