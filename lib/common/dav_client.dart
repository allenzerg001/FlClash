import 'dart:async';
import 'dart:typed_data';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:webdav_client/webdav_client.dart';

class DAVClient {
  late Client client;
  Completer<bool> pingCompleter = Completer();
  late String fileName;

  DAVClient(DAV dav) {
    client = newClient(
      dav.uri,
      user: dav.user,
      password: dav.password,
    );
    fileName = dav.fileName;
    client.setHeaders(
      {
        'accept-charset': 'utf-8',
        'Content-Type': 'text/xml',
      },
    );
    client.setConnectTimeout(8000);
    client.setSendTimeout(60000);
    client.setReceiveTimeout(60000);
    pingCompleter.complete(_ping());
  }

  Future<bool> _ping() async {
    try {
      await client.ping();
      return true;
    } catch (_) {
      return false;
    }
  }

  String get root => '/$appName';

  String get backupFile => '$root/$fileName';

  String get profilesRoot => '/';  // Use WebDAV root directory for profiles

  Future<bool> backup(Uint8List data) async {
    await client.mkdir(root);
    await client.write(backupFile, data);
    return true;
  }

  Future<List<int>> recovery() async {
    await client.mkdir(root);
    final data = await client.read(backupFile);
    return data;
  }

  Future<List<String>> listFiles(String path) async {
    try {
      // Try to create directory if it doesn't exist
      try {
        await client.mkdir(path);
      } catch (_) {
        // Directory might already exist, continue
      }
      
      final files = await client.readDir(path);
      final fileNames = <String>[];
      
      for (final file in files) {
        // Skip directories and current/parent directory entries
        if (file.name == null || file.name == '.' || file.name == '..') {
          continue;
        }
        // Only include files, not directories
        if (file.isDir == false) {
          fileNames.add(file.name!);
        }
      }
      
      return fileNames;
    } catch (e) {
      // Return empty list on error
      commonPrint.log('Error listing WebDAV files: $e', logLevel: LogLevel.warning);
      return [];
    }
  }

  Future<List<int>> readFile(String path) async {
    final data = await client.read(path);
    return data;
  }

  Future<List<String>> listProfileFiles() async {
    return await listFiles(profilesRoot);
  }

  Future<List<int>> readProfileFile(String fileName) async {
    return await readFile('$profilesRoot/$fileName');
  }
}
