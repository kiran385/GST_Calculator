import '../models/invoice.dart';

class GstCalculator {
  double calculateGstAmount(Invoice invoice) {
    double totalGst = 0;
    for (var item in invoice.items) {
      final itemTotal = item.product.price * item.quantity;
      totalGst += itemTotal * item.product.gstRate;
    }
    return totalGst;
  }

  double calculateTotalAmount(Invoice invoice) {
    double total = 0;
    for (var item in invoice.items) {
      final itemTotal = item.product.price * item.quantity;
      total += itemTotal + (itemTotal * item.product.gstRate);
    }
    return total;
  }
} 