import 'package:cuidapet_mobile/app/core/exceptions/social_login_canceled.dart';
import 'package:cuidapet_mobile/app/core/exceptions/user_exists_exception.dart';
import 'package:cuidapet_mobile/app/core/exceptions/user_notfound_exception.dart';
import 'package:cuidapet_mobile/app/core/helpers/logger.dart';
import 'package:cuidapet_mobile/app/core/ui/widgets/loader.dart';
import 'package:cuidapet_mobile/app/core/ui/widgets/messages.dart';
import 'package:cuidapet_mobile/app/models/social_type.dart';
import 'package:cuidapet_mobile/app/services/user/user_service.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';
part 'login_controller.g.dart';

class LoginController = _LoginControllerBase with _$LoginController;

abstract class _LoginControllerBase with Store {
  final UserService _userService;
  final Logger _log;

  _LoginControllerBase({
    required UserService userService,
    required Logger log,
  })  : _userService = userService,
        _log = log;

  Future<void> login(String email, String password) async {
    try {
      Loader.show();
      await _userService.login(email, password);
      Loader.hide();
      Modular.to.navigate('/auth/');
    } on UserNotfoundException {
      Loader.hide();
      Messages.alert('Login ou senha inválidos');
    } catch (e, s) {
      _log.error('Erro ao realizar login', e, s);
      Loader.hide();
      Messages.alert('Erro ao realizar login, tente novamente mais tarde');
    }
  }

  Future<void> socialLogin(SocialType type) async {
    try {
      Loader.show();
      await _userService.socialLogin(type);
      Loader.hide();
      Modular.to.navigate('/auth/');

      // * Quando o usuário apertar o botão CANCELAR LOGIN
    } on SocialLoginCanceled {
      Loader.hide();
      _log.error('Login cancelado');
      Messages.info('Login cancelado');

      // * Quando tentar registrar e já existir o e-mail cadastrado com outro Provedor (Google, Facebook, Apple, etc..)
    } on UserExistsException catch (e, s) {
      Loader.hide();
      _log.error('Usuário registrado com outro provedor', e, s);
      Messages.alert(e.message ?? '');

      // * Qualquer outro tipo de erro
    } catch (e, s) {
      Loader.hide();
      _log.error('Erro ao realizar login', e, s);
      Messages.alert('Erro ao realizar login');
    }
  }
}
