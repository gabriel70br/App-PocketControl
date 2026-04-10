import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../transaction/transaction_page.dart';
import '../filter/filter_page.dart';
import '../profile/profile_page.dart';
import '../../service/transaction_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double balance = 0;
  bool isLoading = true;
  bool isLoadingTransactions = true;
  double income = 0;
  double expense = 0;
  String userName = '';
  bool isLoadingUser = true;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> chartData = [];
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.blue,
  ];
  final currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    loadBalance();
    loadChart();
    loadUser();
    loadIncomeAndExpense();
    loadTransactions();
  }

  Future<void> loadChart() async {
    final service = TransactionService();

    final result = await service.getChartData();

    if (!mounted) return;

    setState(() {
      chartData = result;
    });
  }

  Future<void> loadBalance() async {
    final service = TransactionService();

    final result = await service.getBalance();

    if (!mounted) return;

    setState(() {
      balance = result;
      isLoading = false;
    });
  }

  Future<void> loadIncomeAndExpense() async {
    final service = TransactionService();

    final result = await service.getIncomeAndExpense();

    if (!mounted) return;

    setState(() {
      income = result["income"]!;
      expense = result["expense"]!;
    });
  }

  Future<void> loadTransactions() async {
    try {
      final service = TransactionService();
      final result = await service.getTransactions();

      if (!mounted) return;

      setState(() {
        transactions = result;
        isLoadingTransactions = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingTransactions = false;
      });
    }
  }

  Future<void> loadUser() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      final response = await supabase
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      setState(() {
        userName = response['name'] ?? 'Usuário';
        isLoadingUser = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        userName = 'Usuário';
        isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionPage()),
            );

            if (result == true) {
              loadBalance();
              loadChart();
              loadIncomeAndExpense();
              loadTransactions();
            }
          },
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    isLoadingUser
                        ? const Text(
                            "Carregando...",
                            style: TextStyle(color: Colors.white),
                          )
                        : Text(
                            "Olá, $userName",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                    Row(
                      children: [
                        // NOTIFICAÇÃO
                        Stack(
                          children: [
                            const Icon(
                              Icons.notifications,
                              color: Color(0xFFB0B0B0),
                              size: 28,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // PERFIL (clicável)
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );

                            if (result == true) {
                              loadUser();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B263B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // CARD DE SALDO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B263B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              currencyFormatter.format(balance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      const SizedBox(height: 8),
                      const Text(
                        "Saldo total",
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // DONUT CHART
                SizedBox(
                  height: 200,
                  child: chartData.isEmpty
                      ? const Center(
                          child: Text(
                            "Sem dados",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        )
                      : PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: chartData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;

                              final value = item["value"] as double;

                              return PieChartSectionData(
                                value: value,
                                title: "${value.toStringAsFixed(0)}%",
                                color: colors[index % colors.length],
                                radius: 50,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // LEGENDAS
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: chartData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return LegendItem(
                      color: colors[index % colors.length],
                      text: item["name"],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // CARDS (Receitas, Despesas, Sem)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InfoCard(
                      title: "Receitas",
                      value: currencyFormatter.format(income),
                      titleColor: const Color(0xFFB0B0B0),
                      valueColor: Colors.white,
                    ),
                    InfoCard(
                      title: "Despesas",
                      value: currencyFormatter.format(expense),
                      titleColor: Colors.red,
                      valueColor: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // HEADER DA LISTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Últimas transações",
                      style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 16),
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FilterPage(),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // LISTA DE TRANSAÇÕES
                isLoadingTransactions
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    : transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            SizedBox(height: 20),
                            Icon(
                              Icons.receipt_long,
                              color: Color(0xFFB0B0B0),
                              size: 50,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Nenhuma transação ainda",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Adicione sua primeira receita ou despesa",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF6C757D),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: transactions.map((item) {
                          final amount = (item['amount'] as num).toDouble();
                          final category = item['categories'];
                          final name = category?['name'] ?? 'Sem categoria';
                          final type = category?['type'];

                          final isIncome = type == 'income';

                          return TransactionItem(
                            icon: isIncome
                                ? Icons.attach_money
                                : Icons.shopping_cart,
                            title: name,
                            value:
                                "${isIncome ? '+' : '-'}R\$ ${currencyFormatter.format(amount)}",
                            valueColor: isIncome ? Colors.green : Colors.red,
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color titleColor;
  final Color valueColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.titleColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B263B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF0D1B2A), // cor do background
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: titleColor, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  const TransactionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ÍCONE
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),

          const SizedBox(width: 12),

          // TEXTO
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),

          // VALOR
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
