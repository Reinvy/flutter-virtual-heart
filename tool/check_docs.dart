// Pemeriksa konsistensi dokumentasi (Fase 4).
//
// Dijalankan di CI dan lewat `make check-docs`. Memeriksa:
//   1. file wajib ada
//   2. blok DEPENDENCY FACTS di docs/DEPENDENCIES.md == pubspec.yaml + .fvmrc
//   3. tidak ada dependency_overrides / paket yang sudah dihapus
//   4. link markdown relatif menunjuk file/folder yang ada
//   5. ID FR di docs/FEATURES.md unik
//   6. README memuat badge versi Flutter dari .fvmrc
//
// Exit 0 = lulus (mencetak ringkasan), exit 1 = ada error (dicetak satu per baris).
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

const _dependencyDoc = 'docs/DEPENDENCIES.md';

const _requiredFiles = [
  'AGENTS.md',
  'README.md',
  'CONTRIBUTING.md',
  'docs/README.md',
  'docs/ARCHITECTURE.md',
  'docs/DATA_MODEL.md',
  'docs/AI_PIPELINE.md',
  'docs/DEPENDENCIES.md',
  'docs/PLATFORM_SETUP.md',
  'docs/PRIVACY.md',
  'docs/TESTING.md',
  'docs/KNOWN_ISSUES.md',
  'docs/AUDIT_2026-11.md',
  'docs/DESIGN.md',
  'docs/FEATURES.md',
  'docs/WORKFLOW.md',
  'tool/check_docs.dart',
];

const _removedPackages = [
  'flutter_gemma',
  'flutter_gemma_litertlm',
  'flutter_gemma_mediapipe',
  'flutter_gemma_speech',
  'lottie',
  'uuid',
  'cupertino_icons',
];

/// Dokumen yang link relatifnya diperiksa.
const _docsToScan = [
  'README.md',
  'AGENTS.md',
  'CONTRIBUTING.md',
  'docs/README.md',
  'docs/ARCHITECTURE.md',
  'docs/DATA_MODEL.md',
  'docs/AI_PIPELINE.md',
  'docs/DEPENDENCIES.md',
  'docs/PLATFORM_SETUP.md',
  'docs/PRIVACY.md',
  'docs/TESTING.md',
  'docs/KNOWN_ISSUES.md',
  'docs/AUDIT_2026-11.md',
  'docs/DESIGN.md',
  'docs/FEATURES.md',
  'docs/WORKFLOW.md',
  'docs/AGENTS.md',
];

Future<void> main() async {
  final errors = <String>[];

  final flutterVersion = _flutterVersion(errors);
  final pubspec = _readYaml('pubspec.yaml', errors);
  final dependencies = _hostedDeps(pubspec, 'dependencies');
  final devDependencies = _hostedDeps(pubspec, 'dev_dependencies');

  _checkRequiredFiles(errors);
  _checkNoOverrides(pubspec, errors);
  _checkRemovedPackages(pubspec, errors);
  _checkDependencyFacts(flutterVersion, dependencies, devDependencies, errors);
  _checkLinks(errors);
  _checkFeatureIds(errors);
  _checkReadmeBadge(flutterVersion, errors);

  if (errors.isEmpty) {
    stdout.writeln(
      'check_docs: OK — ${_requiredFiles.length} file wajib, '
      '${dependencies.length} dependency, ${devDependencies.length} dev dependency, '
      'Flutter $flutterVersion.',
    );
    return;
  }

  stderr.writeln('check_docs: ${errors.length} masalah ditemukan');
  for (final error in errors) {
    stderr.writeln('  - $error');
  }
  exit(1);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String? _flutterVersion(List<String> errors) {
  const path = '.fvmrc';
  final file = File(path);
  if (!file.existsSync()) {
    errors.add('$path tidak ditemukan');
    return null;
  }
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map || decoded['flutter'] is! String) {
      errors.add('$path tidak memuat kunci "flutter"');
      return null;
    }
    return decoded['flutter'] as String;
  } catch (e) {
    errors.add('$path tidak bisa dibaca: $e');
    return null;
  }
}

YamlMap? _readYaml(String path, List<String> errors) {
  final file = File(path);
  if (!file.existsSync()) {
    errors.add('$path tidak ditemukan');
    return null;
  }
  try {
    final loaded = loadYaml(file.readAsStringSync());
    if (loaded is! YamlMap) {
      errors.add('$path bukan mapping YAML');
      return null;
    }
    return loaded;
  } catch (e) {
    errors.add('$path gagal di-parse: $e');
    return null;
  }
}

/// Dependency hosted (entri `sdk: flutter` dilewati) → {nama: constraint}.
Map<String, String> _hostedDeps(YamlMap? pubspec, String section) {
  final node = pubspec?[section];
  if (node is! YamlMap) return {};
  final result = <String, String>{};
  node.forEach((key, value) {
    if (value is YamlMap && value.containsKey('sdk')) return; // flutter/flutter_test
    result['$key'] = '$value'.trim();
  });
  return result;
}

void _checkRequiredFiles(List<String> errors) {
  for (final path in _requiredFiles) {
    if (!File(path).existsSync()) errors.add('file wajib hilang: $path');
  }
}

void _checkNoOverrides(YamlMap? pubspec, List<String> errors) {
  if (pubspec != null && pubspec.containsKey('dependency_overrides')) {
    errors.add('pubspec.yaml masih memakai dependency_overrides (tidak diizinkan)');
  }
}

void _checkRemovedPackages(YamlMap? pubspec, List<String> errors) {
  if (pubspec == null) return;
  final names = <String>{
    ..._hostedDeps(pubspec, 'dependencies').keys,
    ..._hostedDeps(pubspec, 'dev_dependencies').keys,
  };
  for (final removed in _removedPackages) {
    if (names.contains(removed)) {
      errors.add('pubspec.yaml masih memuat paket yang sudah dihapus: $removed');
    }
  }
}

void _checkDependencyFacts(
  String? flutterVersion,
  Map<String, String> dependencies,
  Map<String, String> devDependencies,
  List<String> errors,
) {
  final file = File(_dependencyDoc);
  if (!file.existsSync()) return; // sudah dilaporkan oleh _checkRequiredFiles

  const begin = '<!-- BEGIN DEPENDENCY FACTS';
  const end = 'END DEPENDENCY FACTS -->';
  final text = file.readAsStringSync();
  final start = text.indexOf(begin);
  final stop = text.indexOf(end);
  if (start < 0 || stop < 0 || stop < start) {
    errors.add('$_dependencyDoc tidak memuat blok DEPENDENCY FACTS');
    return;
  }

  final raw = text.substring(start + begin.length, stop);
  // Buang pagar code fence (```yaml / ```).
  final yamlText = raw
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('```'))
      .join('\n');

  Object? parsed;
  try {
    parsed = loadYaml(yamlText);
  } catch (e) {
    errors.add('blok DEPENDENCY FACTS bukan YAML valid: $e');
    return;
  }
  if (parsed is! YamlMap) {
    errors.add('blok DEPENDENCY FACTS bukan mapping YAML');
    return;
  }

  final docFlutter = '${parsed['flutter']}'.trim();
  if (flutterVersion != null && docFlutter != flutterVersion) {
    errors.add(
      'versi Flutter di $_dependencyDoc ($docFlutter) != .fvmrc ($flutterVersion)',
    );
  }

  _compareSection('dependencies', parsed['dependencies'], dependencies, errors);
  _compareSection('dev_dependencies', parsed['dev_dependencies'], devDependencies, errors);
}

void _compareSection(
  String name,
  Object? documented,
  Map<String, String> actual,
  List<String> errors,
) {
  if (documented is! YamlMap) {
    errors.add('blok DEPENDENCY FACTS tidak memuat bagian "$name"');
    return;
  }
  final doc = <String, String>{
    for (final entry in documented.entries) '${entry.key}': '${entry.value}'.trim(),
  };

  for (final entry in actual.entries) {
    if (!doc.containsKey(entry.key)) {
      errors.add('$name: "${entry.key}" ada di pubspec.yaml, tidak ada di $_dependencyDoc');
    } else if (doc[entry.key] != entry.value) {
      errors.add(
        '$name: "${entry.key}" constraint berbeda '
        '($_dependencyDoc: ${doc[entry.key]}, pubspec.yaml: ${entry.value})',
      );
    }
  }
  for (final key in doc.keys) {
    if (!actual.containsKey(key)) {
      errors.add('$name: "$key" ada di $_dependencyDoc, tidak ada di pubspec.yaml');
    }
  }
}

void _checkLinks(List<String> errors) {
  final linkPattern = RegExp(r'\[[^\]]*\]\(([^)\s]+)\)');
  for (final path in _docsToScan) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      for (final match in linkPattern.allMatches(lines[i])) {
        final target = match.group(1)!;
        if (target.startsWith('http') ||
            target.startsWith('mailto:') ||
            target.startsWith('#')) {
          continue;
        }
        final cleaned = target.split('#').first.split('?').first;
        if (cleaned.isEmpty) continue;

        final resolved = File(cleaned).isAbsolute
            ? cleaned
            : '${File(path).parent.path}/$cleaned';
        final existsFile = File(resolved).existsSync();
        final existsDir = Directory(resolved).existsSync();
        if (!existsFile && !existsDir) {
          errors.add('$path:${i + 1}: link relatif tidak ditemukan -> $target');
        }
      }
    }
  }
}

void _checkFeatureIds(List<String> errors) {
  const path = 'docs/FEATURES.md';
  final file = File(path);
  if (!file.existsSync()) return;

  final pattern = RegExp(r'^#{2,6}\s+(FR-\d+)\b');
  final seen = <String, int>{};
  for (final line in file.readAsLinesSync()) {
    final match = pattern.firstMatch(line);
    if (match == null) continue;
    final id = match.group(1)!;
    seen[id] = (seen[id] ?? 0) + 1;
  }
  if (seen.isEmpty) {
    errors.add('$path tidak memuat definisi FR-XX');
  }
  seen.forEach((id, count) {
    if (count > 1) errors.add('$path: ID $id muncul $count kali (harus unik)');
  });
}

void _checkReadmeBadge(String? flutterVersion, List<String> errors) {
  if (flutterVersion == null) return;
  final file = File('README.md');
  if (!file.existsSync()) return;
  if (!file.readAsStringSync().contains('Flutter-$flutterVersion')) {
    errors.add('README.md tidak memuat badge "Flutter-$flutterVersion"');
  }
}
