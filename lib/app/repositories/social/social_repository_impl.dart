import 'package:cuidapet_mobile/app/core/exceptions/failure.dart';
import 'package:cuidapet_mobile/app/core/exceptions/social_login_canceled.dart';
import 'package:cuidapet_mobile/app/models/social_network_model.dart';
import 'package:cuidapet_mobile/app/repositories/social/social_repository.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialRepositoryImpl implements SocialRepository {
  @override
  Future<SocialNetworkModel> googleLogin() async {
    // * Instanciar o GoogleSignIn
    final googleSignIn = GoogleSignIn();

    // * Importante para logar com contas diferentes
    // * Desconecta e retira da memória o usuário logado
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.disconnect();
    }

    // * Abrir o Modal do Google para escolher o usuário
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;

    if (googleAuth != null && googleUser != null) {
      return SocialNetworkModel(
        id: googleAuth.idToken ?? '',
        name: googleUser.displayName ?? '',
        email: googleUser.email,
        type: 'Google',
        avatar: googleUser.photoUrl,
        accessToken: googleAuth.accessToken ?? '',
      );
    } else {
      throw Failure(message: 'Erro ao realizar Login Google');
    }
  }

  @override
  Future<SocialNetworkModel> facebookLogin() async {
    final facebookInstance = FacebookAuth.instance;

    final result = await facebookInstance.login();

    switch (result.status) {
      case LoginStatus.success:
        final userData = await facebookInstance.getUserData();
        return SocialNetworkModel(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          type: 'Facebook',
          accessToken: result.accessToken?.token ?? '',
          avatar: userData['picture']['data']['url'],
        );
      case LoginStatus.cancelled:
        throw SocialLoginCanceled();
      case LoginStatus.failed:
      case LoginStatus.operationInProgress:
        throw Failure(message: result.message);
    }
  }
}
