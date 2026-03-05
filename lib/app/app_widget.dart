import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bot_toast/bot_toast.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'PONTIS',
          debugShowCheckedModeBanner: false,
          
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
          ),

          builder: BotToastInit(), 
          
          routerConfig: Modular.routerConfig,
        );
      },
    );
  }
}
