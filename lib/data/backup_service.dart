import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/strings.dart';
import 'database.dart';

const int backupVersion = 1;
const String _worksKey = 'works';
const String _sessionsKey = 'reading_sessions';
const String _notesKey = 'notes';
const String _quotesKey = 'quotes';
const String _analysesKey = 'analyses';
const String _linksKey = 'analysis_works';

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupData {
  const BackupData({
    required this.works,
    required this.sessions,
    required this.notes,
    required this.quotes,
    required this.analyses,
    required this.links,
  });

  final List<Work> works;
  final List<ReadingSession> sessions;
  final List<Note> notes;
  final List<Quote> quotes;
  final List<Analysis> analyses;
  final List<AnalysisWork> links;

  int get workCount => works.length;
  int get noteCount => notes.length;
  int get analysisCount => analyses.length;
}

BackupData parseBackup(String content) {
  Object? decoded;
  try {
    decoded = jsonDecode(content);
  } catch (_) {
    throw const BackupException(AppStrings.invalidJson);
  }
  if (decoded is! Map<String, dynamic>) {
    throw const BackupException(AppStrings.invalidBackup);
  }
  final root = decoded;
  if (root['version'] != backupVersion) {
    throw const BackupException(AppStrings.unsupportedVersion);
  }

  List<dynamic> rawList(String key) {
    final value = root[key];
    if (value is! List<dynamic>) {
      throw const BackupException(AppStrings.invalidBackup);
    }
    return value;
  }

  List<T> parseList<T>(String key, T Function(Map<String, dynamic>) factory) {
    final result = <T>[];
    for (final item in rawList(key)) {
      if (item is! Map<String, dynamic>) {
        throw const BackupException(AppStrings.invalidBackup);
      }
      try {
        result.add(factory(item));
      } catch (_) {
        throw const BackupException(AppStrings.invalidBackup);
      }
    }
    return result;
  }

  return BackupData(
    works: parseList(_worksKey, Work.fromJson),
    sessions: parseList(_sessionsKey, ReadingSession.fromJson),
    notes: parseList(_notesKey, Note.fromJson),
    quotes: parseList(_quotesKey, Quote.fromJson),
    analyses: parseList(_analysesKey, Analysis.fromJson),
    links: parseList(_linksKey, AnalysisWork.fromJson),
  );
}

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  Future<Map<String, dynamic>> _readAll() async {
    final works = await _db.select(_db.works).get();
    final sessions = await _db.select(_db.readingSessions).get();
    final notes = await _db.select(_db.notes).get();
    final quotes = await _db.select(_db.quotes).get();
    final analyses = await _db.select(_db.analyses).get();
    final links = await _db.select(_db.analysisWorks).get();

    return {
      'version': backupVersion,
      _worksKey: works.map((item) => item.toJson()).toList(),
      _sessionsKey: sessions.map((item) => item.toJson()).toList(),
      _notesKey: notes.map((item) => item.toJson()).toList(),
      _quotesKey: quotes.map((item) => item.toJson()).toList(),
      _analysesKey: analyses.map((item) => item.toJson()).toList(),
      _linksKey: links.map((item) => item.toJson()).toList(),
    };
  }

  Future<String> exportJson() async => jsonEncode(await _readAll());

  Future<void> exportBackup() async {
    try {
      final content = await exportJson();
      final directory = await getTemporaryDirectory();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final file = File('${directory.path}/diario_leituras_$stamp.json');
      await file.writeAsString(content);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: AppStrings.exportData,
          title: AppStrings.exportData,
        ),
      );
    } catch (_) {
      throw const BackupException(AppStrings.exportError);
    }
  }

  Future<BackupData?> pickBackup() async {
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: AppStrings.importData,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty) return null;
      final path = files.first.path;
      if (path == null) {
        throw const BackupException(AppStrings.invalidBackup);
      }
      return parseBackup(await File(path).readAsString());
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException(AppStrings.importError);
    }
  }

  Future<void> importBackup(BackupData data) async {
    try {
      await _db.transaction(() async {
        await _db.delete(_db.quotes).go();
        await _db.delete(_db.analysisWorks).go();
        await _db.delete(_db.notes).go();
        await _db.delete(_db.readingSessions).go();
        await _db.delete(_db.analyses).go();
        await _db.delete(_db.works).go();

        for (final work in data.works) {
          await _db.into(_db.works).insert(work);
        }
        for (final analysis in data.analyses) {
          await _db.into(_db.analyses).insert(analysis);
        }
        for (final note in data.notes) {
          await _db.into(_db.notes).insert(note);
        }
        for (final session in data.sessions) {
          await _db.into(_db.readingSessions).insert(session);
        }
        for (final quote in data.quotes) {
          await _db.into(_db.quotes).insert(quote);
        }
        for (final link in data.links) {
          await _db.into(_db.analysisWorks).insert(link);
        }
      });
    } catch (_) {
      throw const BackupException(AppStrings.importError);
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});
