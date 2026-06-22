import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/savings_goal.dart';

class SavingsGoalService {
  final supabase = Supabase.instance.client;

  Future<List<SavingsGoal>> getGoals() async {
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    final response = await supabase
        .from('savings_goals')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((e) => SavingsGoal.fromJson(e)).toList();
  }

  Future<void> createGoal(SavingsGoal goal) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    await supabase.from('savings_goals').insert({
      'user_id': user.id,
      'title': goal.title,
      'target_amount': goal.targetAmount,
      'saved_amount': goal.savedAmount,
      'due_date': goal.dueDate?.toIso8601String(),
    });
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    await supabase
        .from('savings_goals')
        .update({
          'title': goal.title,
          'target_amount': goal.targetAmount,
          'saved_amount': goal.savedAmount,
          'due_date': goal.dueDate?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', goal.id);
  }

  Future<void> deleteGoal(String goalId) async {
    await supabase.from('goal_transactions').delete().eq('goal_id', goalId);

    await supabase.from('savings_goals').delete().eq('id', goalId);
  }
}
