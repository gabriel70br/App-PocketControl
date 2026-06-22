import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../service/transaction_service.dart';

class CategoryExpensesPage extends StatefulWidget {
  const CategoryExpensesPage({super.key});

  @override
  State<CategoryExpensesPage> createState() => _CategoryExpensesPageState();
}

class _CategoryExpensesPageState extends State<CategoryExpensesPage> {
  final TransactionService service = TransactionService();

  bool loading = true;

  List<Map<String, dynamic>> data = [];

  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    final result = await service.getCategoryExpensesByPeriod(
      start: start,
      end: end,
    );

    setState(() {
      data = result;
      loading = false;
    });
  }

  List<DateTime> get lastMonths {
    return List.generate(12, (i) {
      final now = DateTime.now();
      return DateTime(now.year, now.month - i, 1);
    });
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Gastos por Categoria",
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

              // FILTRO DE MÊS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<DateTime>(
                  value: selectedMonth,
                  dropdownColor: const Color(0xFF1B263B),
                  underline: const SizedBox(),
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  items: lastMonths.map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(
                        DateFormat('MMMM yyyy', 'pt_BR').format(month),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedMonth = value);
                    loadData();
                  },
                ),
              ),

              const SizedBox(height: 20),

              // CONTEÚDO
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : data.isEmpty
                    ? const Center(
                        child: Text(
                          "Nenhum gasto encontrado neste período",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final item = data[index];

                                final name = item['name'];
                                final value = item['value'].toDouble();

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          "${value.toStringAsFixed(1)}%",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
