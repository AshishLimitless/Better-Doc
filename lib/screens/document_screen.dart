import 'dart:async';

import 'package:better_doc/colors.dart';
import 'package:better_doc/common/widgets/loader.dart';
import 'package:better_doc/models/document_model.dart';
import 'package:better_doc/models/error_model.dart';
import 'package:better_doc/repository/auth_repository.dart';
import 'package:better_doc/repository/document_repository.dart';
import 'package:better_doc/repository/socket_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';

class DocumentScreen extends ConsumerStatefulWidget {
  final String id;

  const DocumentScreen({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  TextEditingController titleController =
      TextEditingController(text: 'Untitled Document');
  late quill.QuillController _controller = quill.QuillController.basic();
  ErrorModel? errorModel;

  SocketRepository socketRepository = SocketRepository();

  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
  }

  @override
  void initState() {
    super.initState();
    SocketRepository().joinRoom(widget.id);
    fetchDocumentData();
    SocketRepository().changeListener((data) {
      _controller?.compose(
        Delta.fromJson(data['delta']),
        _controller?.selection ?? const TextSelection.collapsed(offset: 0),
        quill.ChangeSource.remote,
      );
    });
    Timer.periodic(const Duration(seconds: 2), (timer) {
      SocketRepository().autoSave(<String, dynamic>{
        'delta': _controller!.document.toDelta(),
        'room': widget.id,
      });
    });
  }

  void fetchDocumentData() async {
    errorModel = await ref
        .read(documentRepositoryProvider)
        .getDocumentById(ref.read(userProvider)!.token, widget.id);
    if (errorModel!.data != null) {
      titleController.text = (errorModel!.data as DocumentModel).title;

      _controller = quill.QuillController(
        document: errorModel!.data.content.isEmpty
            ? quill.Document()
            : quill.Document.fromDelta(
                Delta.fromJson(errorModel!.data.content),
              ),
        selection: const TextSelection.collapsed(offset: 0),
      );

      setState(() {});
    }
    // ignore: unnecessary_set_literal
    _controller!.document.changes.listen((event) => {
          // event is nothing but a DocChange

          if (event.source == quill.ChangeSource.local)
            {
              socketRepository
                  .typing({'delta': event.change, 'room': widget.id})
            }
        });
  }

  void updateTitle(WidgetRef ref, String title) {
    ref.read(documentRepositoryProvider).updateTitle(
          token: ref.read(userProvider)!.token,
          id: widget.id,
          title: title,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Loader());
    }
    return Scaffold(
        appBar: AppBar(
          backgroundColor: kBrownColor,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                          text:
                              'http://localhost:3000/#/document/${widget.id}'))
                      .then(
                    (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Link copied!',
                          ),
                        ),
                      );
                    },
                  );
                },
                label: const Text('Share'),
                icon: const Icon(
                  Icons.share,
                  size: 20,
                  color: kRedColor,
                ),
              ),
            )
          ],
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: GestureDetector(
                    onTap: () {
                      Routemaster.of(context).replace('/');
                    },
                    child: Image.asset(
                      'assets/images/docs-logo.png',
                      height: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: titleController,
                    style: const TextStyle(
                      color: kWhiteColor,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: kWhiteColor,
                        ),
                      ),
                      contentPadding: EdgeInsets.only(left: 10),
                    ),
                    onSubmitted: (value) => updateTitle(ref, value),
                  ),
                ),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                color: kWhiteColor,
                width: 0.1,
              )),
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            quill.QuillToolbar.simple(
              configurations: quill.QuillSimpleToolbarConfigurations(
                  controller: _controller),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SizedBox(
                width: 750,
                child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: quill.QuillEditor.basic(
                      configurations: quill.QuillEditorConfigurations(
                          controller: _controller),
                    ),
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
