import 'package:better_doc/colors.dart';
import 'package:better_doc/common/widgets/loader.dart';
import 'package:better_doc/models/document_model.dart';
import 'package:better_doc/models/error_model.dart';
import 'package:better_doc/repository/auth_repository.dart';
import 'package:better_doc/repository/document_repository.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  void signOut(WidgetRef ref) {
    ref.read(authRepositoryProvider).signOut();
    ref.read(userProvider.notifier).update((state) => null);
  }

  void createDocument(WidgetRef ref, BuildContext context) async {
    String token = ref.read(userProvider)!.token;
    final navigator = Routemaster.of(context);
    final snackbar = ScaffoldMessenger.of(context);
    final errorModel =
        await ref.read(documentRepositoryProvider).createDocument(token);
    if (errorModel.data != null) {
      navigator.push('/document/${errorModel.data.id}');
    } else {
      snackbar.showSnackBar(
        SnackBar(
          content: Text(errorModel.error!),
        ),
      );
    }
  }

  void navigateToDocument(BuildContext context, String documentId) {
    Routemaster.of(context).push('/document/$documentId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: kBrownColor,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => createDocument(ref, context),
              icon: const Icon(
                Icons.add,
                color: kWhiteColor,
              ),
            ),
            IconButton(
              onPressed: () => signOut(ref),
              icon: const Icon(
                Icons.logout,
                color: kWhiteColor,
              ),
            )
          ],
        ),
        body: FutureBuilder(
          future: ref
              .watch(documentRepositoryProvider)
              .getDocuments(ref.watch(userProvider)!.token),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Loader();
            }
            return Center(
              child: Container(
                width: 600,
                margin: const EdgeInsets.only(top: 10),
                child: ListView.builder(
                    itemCount: snapshot.data!.data.length,
                    itemBuilder: (context, index) {
                      DocumentModel document = snapshot.data!.data[index];
                      return InkWell(
                        onTap: () => navigateToDocument(context, document.id),
                        child: SizedBox(
                          height: 50,
                          child: Card(
                            child: Center(
                              child: Text(
                                document.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
              ),
            );
          },
        ));
  }
}
