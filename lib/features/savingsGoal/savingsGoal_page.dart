import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import '../../service/savings_goal_service.dart';
import '../../models/savings_goal.dart';
import '../../service/transaction_service.dart';

class SavingsGoalPage extends StatefulWidget {
  const SavingsGoalPage({super.key});

  @override
  State<SavingsGoalPage> createState() => _SavingsGoalPageState();
}

class _SavingsGoalPageState extends State<SavingsGoalPage> {
  List<SavingsGoal> goals = [];
  final _service = SavingsGoalService();
  bool _hasChanges = false;

  bool isLoading = true;

  final titleController = TextEditingController();
  final targetController = TextEditingController();
  final savedController = TextEditingController();

  DateTime? selectedDate;
  final currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  bool isFormValid = false;

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    try {
      final result = await _service.getGoals();

      if (!mounted) return;

      setState(() {
        goals = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint(e.toString());
    }
  }

  void _openAddMoneyModal(SavingsGoal goal) {
    final controller = TextEditingController();

    double _parseMoney(String value) {
      return double.tryParse(
            value
                .replaceAll('R\$', '')
                .replaceAll('.', '')
                .replaceAll(',', '.')
                .trim(),
          ) ??
          0;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1B2A),
          title: const Text(
            "Adicionar dinheiro",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            inputFormatters: [
              CurrencyInputFormatter(
                leadingSymbol: 'R\$ ',
                useSymbolPadding: true,
                thousandSeparator: ThousandSeparator.Period,
                mantissaLength: 2,
              ),
            ],
            decoration: const InputDecoration(
              labelText: "Valor",
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final amount = _parseMoney(controller.text);

                  if (amount <= 0) return;

                  final transactionService = TransactionService();

                  await transactionService.addMoneyToGoal(
                    goalId: goal.id,
                    amount: amount,
                    currentSaved: goal.savedAmount,
                  );

                  await loadGoals();

                  _hasChanges = true;

                  if (!mounted) return;

                  Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text("Adicionar"),
            ),
          ],
        );
      },
    );
  }

  void _openGoalModal({SavingsGoal? goal}) {
    final titleController = TextEditingController(text: goal?.title ?? '');

    final targetController = TextEditingController(
      text: goal != null ? currencyFormatter.format(goal.targetAmount) : '',
    );

    final savedController = TextEditingController(
      text: goal != null && goal.savedAmount > 0
          ? currencyFormatter.format(goal.savedAmount)
          : '',
    );

    DateTime? selectedDate = goal?.dueDate;

    bool isValid = goal != null;

    double _parseMoney(String value) {
      return double.tryParse(
            value
                .replaceAll('R\$', '')
                .replaceAll('.', '')
                .replaceAll(',', '.')
                .trim(),
          ) ??
          0;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            void validate() {
              final title = titleController.text.trim();
              final target = _parseMoney(targetController.text);

              setStateModal(() {
                isValid =
                    title.isNotEmpty && target > 0 && selectedDate != null;
              });
            }

            return Dialog(
              backgroundColor: const Color(0xFF0D1B2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Meta de Economia",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // NOME
                      TextField(
                        controller: titleController,
                        onChanged: (_) => validate(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Nome da meta",
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF1B263B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // META
                      TextField(
                        controller: targetController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => validate(),
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          CurrencyInputFormatter(
                            leadingSymbol: 'R\$ ',
                            useSymbolPadding: true,
                            thousandSeparator: ThousandSeparator.Period,
                            mantissaLength: 2,
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: "Valor da meta",
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF1B263B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // DATA PREVISÃO
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B263B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedDate == null
                                    ? "Previsão"
                                    : "Previsão: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );

                                if (picked != null) {
                                  selectedDate = picked;
                                  validate();
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // BOTÃO
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isValid
                                ? const Color(0xFF1E88E5)
                                : const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF0D47A1),
                            disabledForegroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isValid ? 4 : 0,
                          ),

                          onPressed: isValid
                              ? () async {
                                  final double addAmount =
                                      savedController.text.trim().isEmpty
                                      ? 0.0
                                      : _parseMoney(savedController.text);

                                  if (goal == null) {
                                    // 👉 CRIA META
                                    final newGoal = SavingsGoal(
                                      id: DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                      title: titleController.text.trim(),
                                      targetAmount: _parseMoney(
                                        targetController.text,
                                      ),
                                      savedAmount: addAmount,
                                      dueDate: selectedDate!,
                                    );

                                    await _service.createGoal(newGoal);
                                  } else {
                                    // 👉 EDITA META

                                    final updatedGoal = SavingsGoal(
                                      id: goal.id,
                                      title: titleController.text.trim(),
                                      targetAmount: _parseMoney(
                                        targetController.text,
                                      ),
                                      savedAmount: goal
                                          .savedAmount, // ✔ mantém o valor atual
                                      dueDate: selectedDate,
                                    );

                                    await _service.updateGoal(updatedGoal);
                                  }

                                  await loadGoals();
                                  Navigator.pop(context);
                                }
                              : null,

                          child: Text(
                            goal == null ? "Criar Meta" : "Atualizar Meta",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _validateForm() {
    final title = titleController.text.trim();
    final target = double.tryParse(targetController.text);
    final saved = double.tryParse(savedController.text);

    setState(() {
      isFormValid =
          title.isNotEmpty &&
          target != null &&
          target > 0 &&
          saved != null &&
          saved >= 0;
    });
  }

  Widget _buildProgressBar(double progress) {
    final percentage = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF1E88E5)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "$percentage%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E88E5),
        onPressed: () => _openGoalModal(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

          child: Column(
            children: [
              // HEADER PADRÃO
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, _hasChanges),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Meta de economia",
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

              const SizedBox(height: 16),

              // 🔥 CONTEÚDO RESPONSIVO (IMPORTANTE)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: goals.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.savings_outlined,
                                  size: 70,
                                  color: Colors.white54,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Nenhuma meta criada ainda",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Toque no botão + para adicionar sua primeira meta financeira",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: goals.length,
                          itemBuilder: (context, index) {
                            final goal = goals[index];
                            final percent = (goal.progress * 100)
                                .toStringAsFixed(0);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          goal.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                        ),
                                        onPressed: () =>
                                            _openGoalModal(goal: goal),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () async {
                                          await _service.deleteGoal(goal.id);

                                          _hasChanges = true;

                                          await loadGoals();
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    "Meta: ${currencyFormatter.format(goal.targetAmount)}",
                                    style: const TextStyle(color: Colors.white),
                                  ),

                                  Text(
                                    "Valor economizado: ${currencyFormatter.format(goal.savedAmount)}",
                                    style: const TextStyle(color: Colors.white),
                                  ),

                                  Text(
                                    "Previsão: ${goal.dueDate?.day}/${goal.dueDate?.month}/${goal.dueDate?.year}",
                                    style: const TextStyle(color: Colors.white),
                                  ),

                                  const SizedBox(height: 12),

                                  _buildProgressBar(goal.progress),

                                  const SizedBox(height: 8),

                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFF2ECC71,
                                      ), // verde dinheiro
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor: const Color(
                                        0xFF2ECC71,
                                      ).withOpacity(0.35),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    label: const Text(
                                      "Adicionar dinheiro",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    onPressed: () {
                                      _openAddMoneyModal(goal);
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  if (goal.progress >= 1)
                                    Container(
                                      margin: const EdgeInsets.only(top: 10),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "🎉 Meta atingida!",
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
