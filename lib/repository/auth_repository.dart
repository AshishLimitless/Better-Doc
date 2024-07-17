import 'dart:convert';

import 'package:better_doc/constants.dart';
import 'package:better_doc/models/error_model.dart';
import 'package:better_doc/models/user_model.dart';
import 'package:better_doc/repository/local_storage_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    googleSignIn: GoogleSignIn(),
    client: Client(),
    localStorageRepository: LocalStorageRepository(),
  ),
);

final userProvider = StateProvider<UserModel?>((ref) => null);

class AuthRepository {
  //final String host=
  final GoogleSignIn _googleSignIn;
  final Client _client;
  final LocalStorageRepository _localStorageRepository;
  AuthRepository({
    required GoogleSignIn googleSignIn,
    required Client client,
    required LocalStorageRepository localStorageRepository,
  })  : _googleSignIn = googleSignIn,
        _client = client,
        _localStorageRepository = localStorageRepository;
  Future<ErrorModel> signInWithGoogle() async {
    ErrorModel error = ErrorModel(error: 'Some unexpected error ', data: null);
    try {
      final user = await _googleSignIn.signIn();

      if (user != null) {
        // print('ashish');
        final userAcc = UserModel(
            name: user.displayName ?? '',
            email: user.email,
            profilePic: user.photoUrl ?? '',
            uid: '',
            token: '');
        var res = await _client.post(Uri.parse('$host/api/signup'),
            body: userAcc.toJson(),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
            });
        // print(res.statusCode);
        switch (res.statusCode) {
          case 201:
            //print("ashish");
            final newUser = userAcc.copyWith(
              uid: jsonDecode(res.body)['user']['_id'],
              token: jsonDecode(res.body)['token'],
            );
            error = ErrorModel(error: null, data: newUser);
            _localStorageRepository.setToken(newUser.token);
            break;
          default:
        }
      }
    } catch (e) {
      error = ErrorModel(error: e.toString(), data: null);
    }
    return error;
  }

  Future<ErrorModel> getUserData() async {
    ErrorModel error = ErrorModel(error: 'Some unexpected error ', data: null);
    try {
      String? token = await _localStorageRepository.getToken();
      //print(token);
      if (token != null) {
        var res = await _client.get(Uri.parse('$host/'), headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        });
        //print(res.statusCode);
        switch (res.statusCode) {
          case 200:
            //print("ashish");
            final newUser = UserModel.fromJson(
              jsonEncode(
                jsonDecode(res.body)['user'],
              ),
            ).copyWith(
              token: token,
            );
            error = ErrorModel(error: null, data: newUser);
            _localStorageRepository.setToken(newUser.token);
            break;
          default:
        }
      }

      // print(res.statusCode);
    } catch (e) {
      error = ErrorModel(error: e.toString(), data: null);
    }
    return error;
  }

  void signOut() async {
    await _googleSignIn.signOut();
    _localStorageRepository.setToken('');
  }
}
