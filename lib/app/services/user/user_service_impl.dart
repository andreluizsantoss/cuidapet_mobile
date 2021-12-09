import 'package:cuidapet_mobile/app/core/exceptions/failure.dart';
import 'package:cuidapet_mobile/app/core/helpers/constants.dart';
import 'package:cuidapet_mobile/app/core/helpers/logger.dart';
import 'package:cuidapet_mobile/app/core/local_storages/local_security_storage.dart';
import 'package:cuidapet_mobile/app/core/local_storages/local_storage.dart';
import 'package:cuidapet_mobile/app/models/social_network_model.dart';
import 'package:cuidapet_mobile/app/models/social_type.dart';
import 'package:cuidapet_mobile/app/repositories/social/social_repository.dart';
import 'package:cuidapet_mobile/app/repositories/user/user_repository.dart';
import 'package:cuidapet_mobile/app/services/user/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserServiceImpl implements UserService {
  final UserRepository _userRepository;
  final Logger _log;
  final LocalStorage _localStorage;
  final LocalSecurityStorage _localSecurityStorage;
  final SocialRepository _socialRepository;

  UserServiceImpl({
    required UserRepository userRepository,
    required Logger log,
    required LocalStorage localStorage,
    required LocalSecurityStorage localSecurityStorage,
    required SocialRepository socialRepository,
  })  : _userRepository = userRepository,
        _log = log,
        _localStorage = localStorage,
        _localSecurityStorage = localSecurityStorage,
        _socialRepository = socialRepository;

  @override
  Future<void> register(String email, String password) async {
    try {
      await _userRepository.register(email, password);
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e, s) {
      _log.error('Erro ao criar usuário no FirebaseAuth', e, s);
      throw Failure(message: 'Erro ao criar usuário no FirebaseAuth');
    }
  }

  @override
  Future<void> login(String email, String password) async {
    try {
      final accessToken = await _userRepository.login(email, password);
      FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      await _saveAccessToken(accessToken);
      await _confirmLogin();
      await _getUserData();
    } on FirebaseAuthException catch (e, s) {
      _log.error('Erro ao fazer login no Firebase Auth', e, s);
      throw Failure(message: 'Erro ao fazer login no Firebase');
    }
  }

  Future<void> _saveAccessToken(String accessToken) =>
      _localStorage.write<String>(Constants.ACCESS_TOKEN_KEY, accessToken);

  Future<void> _confirmLogin() async {
    final confirmLoginModel = await _userRepository.confirmLogin();
    await _saveAccessToken(confirmLoginModel.accessToken);
    await _localSecurityStorage.write(
        Constants.REFRESH_TOKEN_KEY, confirmLoginModel.refreshToken);
  }

  Future<void> _getUserData() async {
    final userLogged = await _userRepository.getUserLogged();
    await _localStorage.write<String>(
        Constants.USER_DATA_KEY, userLogged.toJson());
  }

  @override
  Future<void> socialLogin(SocialType socialType) async {
    String? email;

    try {
      // * Declarações
      final SocialNetworkModel socialModel;
      final AuthCredential authCredential;
      final firebaseAuth = FirebaseAuth.instance;

      // * Estrutura de Login com o Google
      switch (socialType) {
        case SocialType.google:
          socialModel = await _socialRepository.googleLogin();
          authCredential = GoogleAuthProvider.credential(
            accessToken: socialModel.accessToken,
            idToken: socialModel.id,
          );
          break;
      }

      // * Efetua o Login no Firebase com Credential (Provedor)
      await firebaseAuth.signInWithCredential(authCredential);

      // * Efetua o Login em nosso banco de dados (via API)
      final accessToken = await _userRepository.socialLogin(socialModel);

      // * Salva o Access Token
      await _saveAccessToken(accessToken);

      // * Confirma o Login
      await _confirmLogin();

      // * Pega os dados do Usuário Logado
      await _getUserData();
    } on FirebaseAuthException catch (e, s) {
      _log.error('Erro ao realizar login no Firebase', e, s);
      throw Failure(message: 'Erro ao realizar login no Firebase');
    }
  }
}
