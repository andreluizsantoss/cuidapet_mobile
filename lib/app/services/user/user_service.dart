import 'package:cuidapet_mobile/app/models/social_type.dart';

abstract class UserService {
  Future<void> register(String email, String password);
  Future<void> login(String email, String password);
  Future<void> socialLogin(SocialType socialType);
}
