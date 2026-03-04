import 'package:client/app/home_page.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppModule extends Module {
  @override
  void binds(i) {}

  @override
  void routes(RouteManager r) {
    super.routes(r);
    r.child('/', child: (context) => HomePage(),);
  }
}
