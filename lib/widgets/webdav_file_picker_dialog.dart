import 'dart:typed_data';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/dav_client.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/dialog.dart';
import 'package:fl_clash/widgets/list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WebDAVFilePickerDialog extends ConsumerStatefulWidget {
  final DAVClient client;

  const WebDAVFilePickerDialog({super.key, required this.client});

  @override
  ConsumerState<WebDAVFilePickerDialog> createState() =>
      _WebDAVFilePickerDialogState();
}

class _WebDAVFilePickerDialogState
    extends ConsumerState<WebDAVFilePickerDialog> {
  List<String>? files;
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final fileList = await widget.client.listProfileFiles();
      if (mounted) {
        setState(() {
          files = fileList;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load files: ${e.toString()}';
          loading = false;
        });
      }
    }
  }

  Future<void> _selectFile(String fileName) async {
    try {
      final data = await globalState.appController.safeRun<List<int>>(
        () async => await widget.client.readProfileFile(fileName),
        needLoading: true,
      );
      if (data == null || !mounted) return;
      Navigator.of(context).pop({
        'fileName': fileName,
        'data': Uint8List.fromList(data),
      });
    } catch (e) {
      if (mounted) {
        globalState.showMessage(
          title: appLocalizations.tip,
          message: TextSpan(text: e.toString()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.webdavFileSelection,
      child: SizedBox(
        width: 400,
        height: 400,
        child: loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(appLocalizations.loadingWebDAVFiles),
                  ],
                ),
              )
            : error != null
                ? Center(
                    child: Text(
                      error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  )
                : files == null || files!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(appLocalizations.noFilesInWebDAV),
                            const SizedBox(height: 8),
                            Text(
                              'Path: ${widget.client.profilesRoot}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: files!.length,
                        itemBuilder: (context, index) {
                          final fileName = files![index];
                          return ListItem(
                            onTap: () => _selectFile(fileName),
                            title: Text(fileName),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          );
                        },
                      ),
      ),
    );
  }
}
