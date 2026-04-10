import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool obscurePassword = true;
  bool isEdit = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      setState(() {
        nameController.text = profile['name'] ?? '';
        emailController.text = user.email ?? ''; // 🔥 melhor fonte
      });
    } catch (e) {
      print("Erro: $e");
    }
  }

  Future<void> deleteAccount() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      // 🔥 1. Deleta transações
      await supabase.from('transactions').delete().eq('user_id', user.id);

      // 🔥 2. Deleta categorias
      await supabase.from('categories').delete().eq('user_id', user.id);

      // 🔥 3. Deleta perfil
      await supabase.from('profiles').delete().eq('id', user.id);

      // 🔥 4. Logout
      await supabase.auth.signOut();

      if (!mounted) return;

      // 🔥 5. Vai pro login limpando tudo
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Erro ao excluir: $e",
            selectionColor: Colors.white,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // HEADER
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, isEdit),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Editar Perfil",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 20),

              // AVATAR
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF1B263B),
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),

              const SizedBox(height: 24),

              // INPUT NOME
              _buildInput(label: "Nome", controller: nameController),

              const SizedBox(height: 16),

              // INPUT EMAIL
              _buildInput(label: "Email", controller: emailController),

              const SizedBox(height: 16),

              // INPUT SENHA
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nova Senha",
                    style: TextStyle(color: Color(0xFFB0B0B0)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1B263B),
                      hintText: "Digite a nova senha",
                      hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // BOTÃO SALVAR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = supabase.auth.currentUser;

                    if (user == null) return;

                    try {
                      final newName = nameController.text.trim();
                      final newEmail = emailController.text.trim();
                      final newPassword = passwordController.text.trim();

                      // 🔥 Atualiza tabela profiles
                      await supabase
                          .from('profiles')
                          .update({'name': newName, 'email': newEmail})
                          .eq('id', user.id);

                      // 🔥 Atualiza auth
                      await supabase.auth.updateUser(
                        UserAttributes(
                          email: newEmail,
                          password: newPassword.isEmpty ? null : newPassword,
                        ),
                      );

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text(
                            "Perfil atualizado!",
                            selectionColor: Colors.white,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                      isEdit = true;
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,
                          content: Text(
                            "Erro: $e",
                            selectionColor: Colors.white,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Salvar",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // BOTÃO EXCLUIR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _showDeleteDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Excluir Conta",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // BOTÃO CANCELAR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B263B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // COMPONENTE INPUT PADRÃO
  Widget _buildInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFB0B0B0))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1B263B),
            hintText: "Digite $label",
            hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // MODAL DE CONFIRMAÇÃO
  void _showDeleteDialog() {
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false, // 🔥 impede fechar clicando fora
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1B263B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                "Excluir conta",
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                "Isso irá apagar TODOS os seus dados. Deseja continuar?",
                style: TextStyle(color: Color(0xFFB0B0B0)),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                // 🔥 BOTÃO EXCLUIR COM LOADING
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setStateDialog(() {
                            isDeleting = true;
                          });

                          await deleteAccount(); // 🔥 chama sua função

                          // não precisa dar pop aqui porque você já vai navegar
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Text(
                          "Excluir",
                          style: TextStyle(color: Colors.red),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
