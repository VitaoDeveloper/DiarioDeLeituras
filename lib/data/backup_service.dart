import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/strings.dart';
import 'database.dart';

const int backupVersion = 2;
const int _legacyBackupVersion = 1;
const String _worksKey = 'works';
const String _readingsKey = 'readings';
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
    required this.readings,
    required this.sessions,
    required this.notes,
    required this.quotes,
    required this.analyses,
    required this.links,
  });

  final List<Work> works;
  final List<Reading> readings;
  final List<ReadingSession> sessions;
  final List<Note> notes;
  final List<Quote> quotes;
  final List<Analysis> analyses;
  final List<AnalysisWork> links;

  int get workCount => works.length;
  int get readingCount => readings.length;
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
  final version = root['version'];
  if (version is! int ||
      (version != _legacyBackupVersion && version != backupVersion)) {
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

  final works = parseList(_worksKey, Work.fromJson);
  var sessions = parseList(_sessionsKey, ReadingSession.fromJson);
  final notes = parseList(_notesKey, Note.fromJson);
  final quotes = parseList(_quotesKey, Quote.fromJson);
  final analyses = parseList(_analysesKey, Analysis.fromJson);
  final links = parseList(_linksKey, AnalysisWork.fromJson);

  late final List<Reading> readings;
  if (version == _legacyBackupVersion) {
    // Backups antigos guardavam o estado da leitura na própria obra. Cada obra
    // vira a leitura 1 e as sessões são vinculadas a ela.
    readings = [
      for (final work in works)
        Reading(
          id: work.id,
          workId: work.id,
          number: 1,
          status: work.status,
          rating: work.rating,
          startedAt: work.startedAt,
          finishedAt: work.finishedAt,
          createdAt: work.createdAt,
        ),
    ];
    final readingByWork = {
      for (final reading in readings) reading.workId: reading,
    };
    sessions = sessions
        .map(
          (session) => session.copyWith(
            readingId: Value(readingByWork[session.workId]?.id),
          ),
        )
        .toList();
  } else {
    readings = parseList(_readingsKey, Reading.fromJson);
    final readingsByWork = <int, List<Reading>>{};
    for (final reading in readings) {
      readingsByWork.putIfAbsent(reading.workId, () => []).add(reading);
    }
    sessions = sessions.map((session) {
      if (session.readingId != null) return session;
      final candidates = readingsByWork[session.workId];
      if (candidates == null || candidates.isEmpty) return session;
      return session.copyWith(readingId: Value(candidates.first.id));
    }).toList();
  }

  return BackupData(
    works: works,
    readings: readings,
    sessions: sessions,
    notes: notes,
    quotes: quotes,
    analyses: analyses,
    links: links,
  );
}

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  Future<Map<String, dynamic>> _readAll() async {
    final works = await _db.select(_db.works).get();
    final readings = await _db.select(_db.readings).get();
    final sessions = await _db.select(_db.readingSessions).get();
    final notes = await _db.select(_db.notes).get();
    final quotes = await _db.select(_db.quotes).get();
    final analyses = await _db.select(_db.analyses).get();
    final links = await _db.select(_db.analysisWorks).get();

    return {
      'version': backupVersion,
      _worksKey: works.map((item) => item.toJson()).toList(),
      _readingsKey: readings.map((item) => item.toJson()).toList(),
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
        await _db.delete(_db.readings).go();
        await _db.delete(_db.analyses).go();
        await _db.delete(_db.works).go();

        for (final work in data.works) {
          await _db.into(_db.works).insert(work);
        }
        for (final reading in data.readings) {
          await _db.into(_db.readings).insert(reading);
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
