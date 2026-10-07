import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/transaction_repository.dart';
import 'state/expense_store.dart';
import 'ui/app_theme.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final repository = await SqliteTransactionRepository.open();
    final preferences = await SharedPreferences.getInstance();
    final store = ExpenseStore(repository, preferences);
    await store.load();
    runApp(
      ChangeNotifierProvider.value(
        value: store,
        child: const TransferLensApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Không thể mở dữ liệu cục bộ. Hãy đóng và mở lại ứng dụng.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: main, child: const Text('Thử lại')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TransferLensApp extends StatelessWidget {
  const TransferLensApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TransferLens',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: context.watch<ExpenseStore>().themeMode,
    home: const HomeScreen(),
  );
}
