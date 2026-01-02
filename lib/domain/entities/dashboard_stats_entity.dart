import 'package:equatable/equatable.dart';

class DashboardStatsEntity extends Equatable {
  final double dailyCollection;
  final double weeklyCollection;
  final double monthlyCollection;
  final int activeCredits;
  final int clientsInArrears;
  final double totalCollected;
  final double upToDatePercentage;
  final double overduePercentage;
  // Recaudos por método de pago
  final double cashCollection;
  final double transactionCollection;
  final int cashCount;
  final int transactionCount;
  // Datos para gráficas
  final List<Map<String, dynamic>> weeklyCollectionData;
  final int totalClients;

  const DashboardStatsEntity({
    required this.dailyCollection,
    required this.weeklyCollection,
    required this.monthlyCollection,
    required this.activeCredits,
    required this.clientsInArrears,
    required this.totalCollected,
    required this.upToDatePercentage,
    required this.overduePercentage,
    required this.cashCollection,
    required this.transactionCollection,
    required this.cashCount,
    required this.transactionCount,
    required this.weeklyCollectionData,
    required this.totalClients,
  });

  @override
  List<Object?> get props => [
        dailyCollection,
        weeklyCollection,
        monthlyCollection,
        activeCredits,
        clientsInArrears,
        totalCollected,
        upToDatePercentage,
        overduePercentage,
        cashCollection,
        transactionCollection,
        cashCount,
        transactionCount,
        weeklyCollectionData,
        totalClients,
      ];
}
