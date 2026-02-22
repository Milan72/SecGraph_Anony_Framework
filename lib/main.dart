import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'providers/app_provider.dart';
import 'screens/upload_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NetGUCApp());
}

class NetGUCApp extends StatelessWidget {
  const NetGUCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const UploadScreen(),
      ),
    );
  }
}
