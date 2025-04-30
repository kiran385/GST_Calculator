class GstService {
  static const List<double> gstRates = [0.05, 0.12, 0.18, 0.28];

  static double calculateCGST(double amount, double gstRate) {
    return (amount * gstRate) / 2;
  }

  static double calculateSGST(double amount, double gstRate) {
    return (amount * gstRate) / 2;
  }

  static double calculateTotalGST(double amount, double gstRate) {
    return amount * gstRate;
  }

  static double calculateTotalAmount(double amount, double gstRate) {
    return amount + calculateTotalGST(amount, gstRate);
  }

  static String formatGSTRate(double rate) {
    return '${(rate * 100).toInt()}%';
  }
} 