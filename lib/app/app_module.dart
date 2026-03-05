import 'package:client/app/modules/auth/auth_module.dart';
import 'package:client/app/modules/home/home_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:dio/dio.dart';

class AppModule extends Module {
  @override
  void binds(i) {
    //i.addLazySingleton(() => Dio(BaseOptions(baseUrl: 'http://SEU_IP_AQUI:8080')));
  }

  @override
  void routes(r) {
    // Definindo as rotas principais
    r.module('/', module: AuthModule());
    r.module('/home', module: HomeModule());
  }
}
