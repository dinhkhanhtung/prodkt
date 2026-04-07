class CalculationUtils {
  /// Tính tổng tiền hàng (chưa bao gồm thuế, giảm giá, phí ship)
  static double calculateSubtotal(List<dynamic> items) {
    return items.fold<double>(
      0,
      (sum, item) {
        // Kiểm tra nếu item là object có thuộc tính total
        try {
          if (item.total != null) {
            return sum + item.total;
          }
        } catch (e) {
          // Nếu không có thuộc tính total, tiếp tục kiểm tra các trường hợp khác
        }

        // Kiểm tra nếu item là map có key 'quantity' và 'price'
        if (item is Map && item['quantity'] != null && item['price'] != null) {
          final quantity = (item['quantity'] is num)
              ? (item['quantity'] as num).toDouble()
              : 0.0;
          final price =
              (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
          return sum + (quantity * price);
        }

        // Trường hợp không xác định, trả về sum hiện tại
        return sum;
      },
    );
  }

  /// Tính tiền thuế
  static double calculateTax(double subtotal, double taxPercent) {
    if (taxPercent <= 0) return 0;
    return (subtotal * taxPercent / 100).roundToDouble();
  }

  /// Tính tiền giảm giá
  static double calculateDiscount(double subtotal, double discountAmount) {
    if (discountAmount <= 0) return 0;
    // Đảm bảo giảm giá không vượt quá tổng tiền hàng
    return discountAmount > subtotal ? subtotal : discountAmount;
  }

  /// Tính tổng tiền cuối cùng
  static double calculateTotal({
    required double subtotal,
    required double taxPercent,
    required double discountAmount,
    required double shippingFee,
  }) {
    final tax = calculateTax(subtotal, taxPercent);
    final discount = calculateDiscount(subtotal, discountAmount);
    final total = subtotal + tax - discount + shippingFee;
    return total > 0 ? total : 0; // Đảm bảo tổng tiền không âm
  }

  /// Tính tiền còn nợ
  static double calculateDebt({
    required double total,
    required double paid,
  }) {
    // Đảm bảo số tiền trả không âm
    final validPaid = paid < 0 ? 0 : paid;
    // Đảm bảo số tiền trả không vượt quá tổng tiền
    final actualPaid = validPaid > total ? total : validPaid;
    final debt = total - actualPaid;
    return debt > 0 ? debt : 0; // Đảm bảo nợ không âm
  }

  /// Tính lợi nhuận từ đơn hàng
  static double calculateProfit({
    required double total,
    required double cost,
    required double shippingFee,
    required double discountAmount,
    required double refundAmount,
    required double paid,
    required double debt,
    required bool isExchanged,
    required double originalProfit,
  }) {
    // Nếu đơn hàng đã thanh toán đủ và không phải đổi hàng
    if (paid >= total && !isExchanged) {
      return total - cost - discountAmount + shippingFee - refundAmount;
    }

    // Nếu là đơn hàng đổi, lấy lợi nhuận ban đầu trừ đi công nợ
    if (isExchanged) {
      return originalProfit - debt;
    }

    // Nếu đơn hàng chưa thanh toán đủ, chỉ tính lợi nhuận trên phần đã thanh toán
    final double paymentRatio = total > 0 ? paid / total : 0;
    final double adjustedCost = cost * paymentRatio;
    final double adjustedDiscount = discountAmount * paymentRatio;

    // Lợi nhuận = (Doanh thu đã thanh toán - Chi phí điều chỉnh - Chiết khấu điều chỉnh + Phí ship) - Hoàn tiền - Công nợ
    return (paid - adjustedCost - adjustedDiscount + shippingFee) -
        refundAmount -
        debt;
  }

  /// Validate số tiền hoàn trả
  static bool isValidRefund(double refundAmount, double orderTotal) {
    return refundAmount > 0 && refundAmount <= orderTotal;
  }

  /// Tính tổng giá trị đơn hàng (bao gồm cả đổi hàng)
  static double calculateOrderTotal({
    required double subtotal,
    required double taxPercent,
    required double discountAmount,
    required double shippingFee,
    required double exchangeAmount,
  }) {
    final tax = calculateTax(subtotal, taxPercent);
    final discount = calculateDiscount(subtotal, discountAmount);
    // Tổng tiền = Tổng hàng + Thuế - Giảm giá + Phí ship + Chênh lệch đổi hàng
    final total = subtotal + tax - discount + shippingFee + exchangeAmount;
    return total > 0 ? total : 0;
  }

  /// Tính chênh lệch khi đổi hàng
  static double calculateExchangeDifference({
    required double oldPrice,
    required double newPrice,
    required int quantity,
  }) {
    return (newPrice - oldPrice) * quantity;
  }
}
