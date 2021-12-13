import 'package:cuidapet_mobile/app/core/helpers/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobx/mobx.dart';

import 'package:cuidapet_mobile/app/core/local_storages/local_storage.dart';
import 'package:cuidapet_mobile/app/models/user_model.dart';

part 'auth_store.g.dart';

class AuthStore = _AuthStoreBase with _$AuthStore;

abstract class _AuthStoreBase with Store {
  final LocalStorage _localStorage;

  @observable
  UserModel? userModel;

  _AuthStoreBase({
    required LocalStorage localStorage,
  }) : _localStorage = localStorage;

  @action
  Future<void> loadUser() async {
    // * Busca os dados no LocalStorage
    final userLoggedData =
        await _localStorage.read<String>(Constants.USER_DATA_KEY);

    if (userLoggedData != null) {
      // * Envia os dados JSON do LocalStorage para o UserModel
      userModel = UserModel.fromJson(userLoggedData);
    } else {
      userModel = UserModel.empty();
    }

    // * Verifica mudança no Firebase
    // * Caso o usuário esteja deslogado - Faz o processo de Logout no Firebase
    FirebaseAuth.instance.authStateChanges().listen((user) {
      // * Desloga o Usuário do Firebase
      if (user == null) {
        userModel = UserModel.empty();
      }
    });
  }

  @action
  Future<void> logout() async {
    // * Limpar o LocalStorage com os dados do Usuário
    await _localStorage.clear();
    userModel = null;
  }
}
