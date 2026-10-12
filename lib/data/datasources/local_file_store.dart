import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Archivos de texto por nombre en el almacenamiento privado de la app (sin respaldo en la nube:
/// `allowBackup=false` en Android).
abstract class LocalFileStore {
  Future<String?> read(String name);
  Future<void> write(String name, String content);

  /// Borra todos los archivos salvo los de [keep].
  Future<void> deleteAll({Set<String> keep = const {}});
}

class AppSupportFileStore implements LocalFileStore {
  Directory? _dir;

  Future<Directory> _directory() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    return _dir = await Directory('${base.path}${Platform.pathSeparator}offline').create(recursive: true);
  }

  Future<File> _file(String name) async => File('${(await _directory()).path}${Platform.pathSeparator}$name');

  @override
  Future<String?> read(String name) async {
    final file = await _file(name);
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String name, String content) async {
    final file = await _file(name);
    // Escribir y renombrar: un cierre de la app a mitad de escritura no deja el archivo a medias
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<void> deleteAll({Set<String> keep = const {}}) async {
    final dir = await _directory();
    await for (final entity in dir.list()) {
      final name = entity.uri.pathSegments.last;
      if (entity is File && !keep.contains(name)) await entity.delete();
    }
  }
}

/// Para tests.
class MemoryFileStore implements LocalFileStore {
  final Map<String, String> files = {};

  @override
  Future<String?> read(String name) async => files[name];

  @override
  Future<void> write(String name, String content) async => files[name] = content;

  @override
  Future<void> deleteAll({Set<String> keep = const {}}) async => files.removeWhere((name, _) => !keep.contains(name));
}
