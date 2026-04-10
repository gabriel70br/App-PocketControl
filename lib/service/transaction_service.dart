import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionService {
  final supabase = Supabase.instance.client;

  Future<double> getBalance() async {
    final user = supabase.auth.currentUser;

    if (user == null) return 0;

    final response = await supabase
        .from('transactions')
        .select('amount, categories(type)')
        .eq('user_id', user.id);

    double income = 0;
    double expense = 0;

    for (final item in response) {
      final amount = (item['amount'] as num).toDouble();
      final type = item['categories']?['type'];

      if (type == 'income') {
        income += amount;
      } else if (type == 'expense') {
        expense += amount;
      }
    }

    return income - expense;
  }

  Future<List<Map<String, dynamic>>> getChartData() async {
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    final response = await supabase
        .from('transactions')
        .select('amount, categories(name, type)')
        .eq('user_id', user.id);

    final Map<String, double> categoryTotals = {};

    double total = 0;

    for (final item in response) {
      final category = item['categories'];

      if (category == null) continue;

      if (category['type'] != 'expense') continue;

      final name = category['name'];
      final amount = (item['amount'] as num).toDouble();

      total += amount;

      categoryTotals[name] = (categoryTotals[name] ?? 0) + amount;
    }

    // Converter para porcentagem
    final List<Map<String, dynamic>> result = [];

    categoryTotals.forEach((name, value) {
      final percentage = (value / total) * 100;

      result.add({"name": name, "value": percentage});
    });

    return result;
  }

  Future<Map<String, double>> getIncomeAndExpense() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return {"income": 0, "expense": 0};
    }

    final response = await supabase
        .from('transactions')
        .select('amount, categories(type)')
        .eq('user_id', user.id);

    double income = 0;
    double expense = 0;

    for (final item in response) {
      final amount = (item['amount'] as num).toDouble();
      final type = item['categories']?['type'];

      if (type == 'income') {
        income += amount;
      } else if (type == 'expense') {
        expense += amount;
      }
    }

    return {"income": income, "expense": expense};
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    final response = await supabase
        .from('transactions')
        .select('amount, created_at, categories(name, type)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(10);

    return response;
  }

  Future<void> createTransaction({
    required String title,
    required String categoryName,
    required bool isExpense,
    required double amount,
    required DateTime date,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) throw Exception("Usuário não logado");

    // 🔥 1. BUSCAR OU CRIAR CATEGORIA
    final existingCategory = await supabase
        .from('categories')
        .select()
        .eq('user_id', user.id)
        .eq('name', categoryName)
        .maybeSingle();

    String categoryId;

    if (existingCategory == null) {
      final newCategory = await supabase
          .from('categories')
          .insert({
            'user_id': user.id,
            'name': categoryName,
            'type': isExpense ? 'expense' : 'income',
          })
          .select()
          .single();

      categoryId = newCategory['id'];
    } else {
      categoryId = existingCategory['id'];
    }

    // 🔥 2. INSERIR TRANSAÇÃO
    await supabase.from('transactions').insert({
      'user_id': user.id,
      'category_id': categoryId,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
    });
  }
}
