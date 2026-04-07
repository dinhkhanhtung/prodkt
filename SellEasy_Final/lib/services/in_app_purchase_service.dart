import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Lớp để biểu thị kết quả của giao dịch mua hàng
class PurchaseResult {
  final String productId;
  final bool success;
  final String? errorMessage;

  PurchaseResult({
    required this.productId,
    required this.success,
    this.errorMessage,
  });
}

class InAppPurchaseService {
  static const String _kPremiumProductId = 'selleasy_premium_50k';
  static const String _kPremiumPurchasedKey = 'premium_purchased';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final StreamController<bool> _purchaseStatusController =
      StreamController<bool>.broadcast();
  // Thêm stream controller mới để thông báo khi giao dịch hoàn tất
  final StreamController<PurchaseResult> _purchaseResultController =
      StreamController<PurchaseResult>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isPremiumPurchased = false;
  String? _pendingPurchaseId;

  Stream<bool> get purchaseStatusStream => _purchaseStatusController.stream;
  Stream<PurchaseResult> get purchaseResultStream =>
      _purchaseResultController.stream;
  bool get isAvailable => _isAvailable;
  bool get isPremiumPurchased => _isPremiumPurchased;
  List<ProductDetails> get products => _products;

  // Singleton pattern
  static final InAppPurchaseService _instance =
      InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  Future<void> initialize() async {
    // Kiểm tra xem người dùng đã mua premium chưa
    await _loadPurchasedStatus();

    // Kiểm tra xem cửa hàng có khả dụng không
    final isAvailable = await _inAppPurchase.isAvailable();
    _isAvailable = isAvailable;

    if (!isAvailable) {
      _products = [];
      _purchaseStatusController.add(_isPremiumPurchased);
      return;
    }

    // Lắng nghe các sự kiện mua hàng
    _subscription = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        // Xử lý lỗi
        debugPrint('In-app purchase error: $error');
      },
    );

    // Lấy thông tin sản phẩm
    await _loadProducts();
    _purchaseStatusController.add(_isPremiumPurchased);
  }

  Future<void> _loadPurchasedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremiumPurchased = prefs.getBool(_kPremiumPurchasedKey) ?? false;
  }

  Future<void> _savePurchasedStatus(bool isPurchased) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPremiumPurchasedKey, isPurchased);
    _isPremiumPurchased = isPurchased;
    _purchaseStatusController.add(_isPremiumPurchased);
  }

  Future<void> _loadProducts() async {
    final Set<String> kIds = <String>{_kPremiumProductId};
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(kIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
  }

  // Phương thức mua hàng
  Future<bool> buyPremium() async {
    // Kiểm tra nếu đã mua rồi thì thông báo và trả về true
    if (_isPremiumPurchased) {
      debugPrint('Premium already purchased');
      // Thông báo qua stream để UI cập nhật
      _purchaseResultController.add(PurchaseResult(
        productId: _kPremiumProductId,
        success: true,
        errorMessage: 'Bạn đã sở hữu sản phẩm này',
      ));
      return true;
    }

    if (!_isAvailable) {
      debugPrint('Store is not available');
      // Thông báo lỗi qua stream
      _purchaseResultController.add(PurchaseResult(
        productId: _kPremiumProductId,
        success: false,
        errorMessage: 'Cửa hàng Google Play không khả dụng',
      ));
      return false;
    }

    if (_products.isEmpty) {
      debugPrint('No products available');
      await _loadProducts(); // Thử tải lại sản phẩm

      if (_products.isEmpty) {
        // Thông báo lỗi qua stream
        _purchaseResultController.add(PurchaseResult(
          productId: _kPremiumProductId,
          success: false,
          errorMessage: 'Không tìm thấy sản phẩm',
        ));
        return false;
      }
    }

    try {
      final ProductDetails productDetails = _products.firstWhere(
        (product) => product.id == _kPremiumProductId,
        orElse: () => throw Exception('Product not found: $_kPremiumProductId'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );

      if (Platform.isAndroid) {
        final bool available = await _inAppPurchase.isAvailable();
        if (!available) {
          debugPrint('Google Play Store is not available');
          return false;
        }

        // Lưu ID sản phẩm đang chờ mua
        _pendingPurchaseId = _kPremiumProductId;

        // Bắt đầu quá trình mua hàng
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

        // Trả về true để chỉ ra rằng quá trình mua đã bắt đầu thành công
        // Kết quả thực sự sẽ được thông báo qua purchaseResultStream
        return true;
      } else if (Platform.isIOS) {
        // Lưu ID sản phẩm đang chờ mua
        _pendingPurchaseId = _kPremiumProductId;

        // Bắt đầu quá trình mua hàng
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

        // Trả về true để chỉ ra rằng quá trình mua đã bắt đầu thành công
        return true;
      }
    } catch (e) {
      debugPrint('Error during purchase: $e');
      // Thông báo lỗi qua stream
      _purchaseResultController.add(PurchaseResult(
        productId: _kPremiumProductId,
        success: false,
        errorMessage: e.toString(),
      ));
      return false;
    }

    return false;
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      // Kiểm tra nếu sản phẩm đã được mua trước đó
      if (purchaseDetails.productID == _kPremiumProductId &&
          _isPremiumPurchased) {
        // Nếu đã mua rồi, hoàn thành giao dịch và bỏ qua
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }

        // Thông báo cho UI biết đã mua rồi
        if (purchaseDetails.productID == _pendingPurchaseId) {
          _purchaseResultController.add(PurchaseResult(
            productId: purchaseDetails.productID,
            success: true,
            errorMessage: 'Bạn đã sở hữu sản phẩm này',
          ));
          _pendingPurchaseId = null;
        }
        continue; // Bỏ qua các bước xử lý tiếp theo
      }

      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Đang xử lý giao dịch
        debugPrint('Purchase pending for ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Giao dịch bị lỗi
        debugPrint(
            'Purchase error for ${purchaseDetails.productID}: ${purchaseDetails.error?.message}');
        _handlePurchaseError(purchaseDetails);

        // Thông báo lỗi đã được xử lý trong _handlePurchaseError
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        // Giao dịch thành công
        if (purchaseDetails.productID == _kPremiumProductId) {
          _verifyAndSavePurchase(purchaseDetails);

          // Thông báo thành công qua stream nếu đây là sản phẩm đang chờ mua
          if (purchaseDetails.productID == _pendingPurchaseId) {
            _purchaseResultController.add(PurchaseResult(
              productId: purchaseDetails.productID,
              success: true,
            ));
            _pendingPurchaseId = null;
          }
        }
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        // Khôi phục giao dịch
        if (purchaseDetails.productID == _kPremiumProductId) {
          _savePurchasedStatus(true);
          debugPrint('Premium restored successfully');
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        debugPrint('Purchase canceled by user');

        // Thông báo hủy qua stream nếu đây là sản phẩm đang chờ mua
        if (purchaseDetails.productID == _pendingPurchaseId) {
          _purchaseResultController.add(PurchaseResult(
            productId: purchaseDetails.productID,
            success: false,
            errorMessage: 'Giao dịch đã bị hủy',
          ));
          _pendingPurchaseId = null;
        }
      }

      // Hoàn thành giao dịch
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    final error = purchaseDetails.error;
    if (error != null) {
      if (error.code == 'purchase-canceled') {
        debugPrint('Purchase was canceled by user');
      } else if (error.code == 'item-already-owned') {
        // Người dùng đã sở hữu sản phẩm này
        _savePurchasedStatus(true);
        debugPrint('User already owns this product');

        // Thông báo thành công qua stream nếu đây là sản phẩm đang chờ mua
        if (purchaseDetails.productID == _pendingPurchaseId) {
          _purchaseResultController.add(PurchaseResult(
            productId: purchaseDetails.productID,
            success: true,
            errorMessage: 'Bạn đã sở hữu sản phẩm này',
          ));
          _pendingPurchaseId = null;
        }
      } else if (error.code == 'billing-unavailable') {
        // Dịch vụ thanh toán không khả dụng
        debugPrint('Billing service unavailable: ${error.message}');
        if (purchaseDetails.productID == _pendingPurchaseId) {
          _purchaseResultController.add(PurchaseResult(
            productId: purchaseDetails.productID,
            success: false,
            errorMessage:
                'Dịch vụ thanh toán không khả dụng. Vui lòng kiểm tra cài đặt Google Play.',
          ));
          _pendingPurchaseId = null;
        }
      } else if (error.code == 'developer-error') {
        // Lỗi phát triển
        debugPrint('Developer error: ${error.message}');
        if (purchaseDetails.productID == _pendingPurchaseId) {
          _purchaseResultController.add(PurchaseResult(
            productId: purchaseDetails.productID,
            success: false,
            errorMessage: 'Lỗi hệ thống. Vui lòng thử lại sau.',
          ));
          _pendingPurchaseId = null;
        }
      } else {
        debugPrint('Purchase error: ${error.code} - ${error.message}');
        if (purchaseDetails.productID == _pendingPurchaseId) {
          _purchaseResultController.add(PurchaseResult(
            productId: purchaseDetails.productID,
            success: false,
            errorMessage: 'Lỗi: ${error.message}',
          ));
          _pendingPurchaseId = null;
        }
      }
    }
  }

  Future<void> _verifyAndSavePurchase(PurchaseDetails purchaseDetails) async {
    // Trong môi trường thực tế, bạn nên xác minh giao dịch với máy chủ của bạn
    // Ở đây chúng ta chỉ kiểm tra cơ bản
    if (purchaseDetails.productID == _kPremiumProductId) {
      if (Platform.isAndroid) {
        // Trường hợp Android, chúng ta chỉ cần kiểm tra trạng thái đã mua
        await _savePurchasedStatus(true);
        debugPrint('Premium purchased successfully on Android');
      } else if (Platform.isIOS) {
        // Trường hợp iOS
        await _savePurchasedStatus(true);
        debugPrint('Premium purchased successfully on iOS');
      }
    }
  }

  Future<bool> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('Store is not available');
      return false;
    }

    try {
      await _inAppPurchase.restorePurchases();
      // Kết quả sẽ được xử lý trong _listenToPurchaseUpdated
      return true;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  // Phương thức giả lập mua hàng (chỉ dùng cho mục đích phát triển)
  Future<void> simulatePurchase() async {
    await _savePurchasedStatus(true);
    debugPrint('Simulated purchase completed');
  }

  // Phương thức xóa trạng thái đã mua
  Future<void> resetPurchaseStatus() async {
    await _savePurchasedStatus(false);
    debugPrint('Purchase status reset to false');
  }

  void dispose() {
    _subscription?.cancel();
    _purchaseStatusController.close();
    _purchaseResultController.close();
  }
}
