import 'dart:async';
import 'package:flutter/material.dart';
import '../services/in_app_purchase_service.dart';

class PurchaseProvider extends ChangeNotifier {
  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  bool _isPremiumPurchased = false;
  bool _isLoading = true;
  StreamSubscription<bool>? _subscription;
  StreamSubscription<PurchaseResult>? _purchaseResultSubscription;

  // Thêm controller để thông báo kết quả giao dịch
  final StreamController<PurchaseResult> _purchaseResultController =
      StreamController<PurchaseResult>.broadcast();

  bool get isPremiumPurchased => _isPremiumPurchased;
  bool get isLoading => _isLoading;
  bool get isStoreAvailable => _purchaseService.isAvailable;

  // Stream để các widget có thể lắng nghe kết quả giao dịch
  Stream<PurchaseResult> get purchaseResultStream =>
      _purchaseResultController.stream;

  PurchaseProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    await _purchaseService.initialize();
    _isPremiumPurchased = _purchaseService.isPremiumPurchased;

    // Lắng nghe trạng thái mua hàng
    _subscription = _purchaseService.purchaseStatusStream.listen((isPurchased) {
      _isPremiumPurchased = isPurchased;
      _isLoading = false;
      notifyListeners();
    });

    // Lắng nghe kết quả giao dịch
    _purchaseResultSubscription =
        _purchaseService.purchaseResultStream.listen((result) {
      // Chuyển tiếp kết quả đến các widget đang lắng nghe
      _purchaseResultController.add(result);
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> buyPremium() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Bắt đầu quá trình mua hàng
      final result = await _purchaseService.buyPremium();

      // Chỉ cập nhật trạng thái loading, kết quả thực sự sẽ được thông báo qua stream
      _isLoading = false;
      notifyListeners();

      // Trả về true nếu quá trình mua đã bắt đầu thành công
      return result;
    } catch (e) {
      debugPrint('Error buying premium: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _purchaseService.restorePurchases();
      // Đợi một chút để đảm bảo các sự kiện mua hàng được xử lý
      await Future.delayed(const Duration(seconds: 1));
      _isPremiumPurchased = _purchaseService.isPremiumPurchased;
      _isLoading = false;
      notifyListeners();
      return result && _isPremiumPurchased;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Phương thức giả lập mua hàng (chỉ dùng cho mục đích phát triển)
  Future<bool> simulatePurchase() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _purchaseService.simulatePurchase();
      _isPremiumPurchased = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error simulating purchase: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Phương thức xóa trạng thái đã mua
  Future<bool> resetPurchaseStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _purchaseService.resetPurchaseStatus();
      _isPremiumPurchased = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error resetting purchase status: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _purchaseResultSubscription?.cancel();
    _purchaseResultController.close();
    super.dispose();
  }
}
