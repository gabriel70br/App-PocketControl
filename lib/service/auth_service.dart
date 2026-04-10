import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name, // 👈 salva nome no usuário
        },
      );

      if (response.user != null) {
        return null; // sucesso
      } else {
        return "Erro ao criar conta";
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        return {"error": "Erro ao fazer login"};
      }

      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        
        await supabase.auth.signOut();

        return {"error": "Conta não encontrada. Crie um perfil novamente."};
      }

      // 🔥 PEGA NOME DO PROFILE (melhor que metadata)
      final name = profile['name'] ?? 'Usuário';

      return {"error": null, "name": name};
    } catch (e) {
      return {"error": "Email ou senha inválidos"};
    }
  }
}
