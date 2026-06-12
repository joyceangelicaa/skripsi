import 'package:flutter/material.dart';
import 'root/app_route.dart';
import 'service/user_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await UserService.loadToken();
  await UserService.loadUserData();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // UserService.loadToken();
    // UserService.loadUserData();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoute.login, 
      onGenerateRoute: AppRoute.generateRoute,
      );
  }
}
