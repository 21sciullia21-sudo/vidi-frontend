import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:vidi/models/user_model.dart';
import 'package:vidi/models/job_model.dart';
import 'package:vidi/models/bid_model.dart';
import 'package:vidi/models/post_model.dart';
import 'package:vidi/models/asset_model.dart';
import 'package:vidi/models/payment_method_model.dart';
import 'package:vidi/models/purchase_model.dart';
import 'package:vidi/services/user_service.dart';
import 'package:vidi/services/job_service.dart';
import 'package:vidi/services/bid_service.dart';
import 'package:vidi/services/post_service.dart';
import 'package:vidi/services/asset_service.dart';
import 'package:vidi/services/payment_service.dart';

class AppProvider with ChangeNotifier {
  final UserService _userService = UserService();
  final JobService _jobService = JobService();
  final BidService _bidService = BidService();
  final PostService _postService = PostService();
  final AssetService _assetService = AssetService();
  final PaymentService _paymentService = PaymentService();

  UserModel? _currentUser;
  List<UserModel> _users = [];
  List<JobModel> _jobs = [];
  List<PostModel> _posts = [];
  List<AssetModel> _assets = [];
  List<BidModel> _bids = [];
  List<AssetModel> _cartItems = [];
  List<PaymentMethodModel> _paymentMethods = [];
  bool _isLoading = false;
  bool _showMessagesSidebar = false;

  UserModel? get currentUser => _currentUser;
  bool get showMessagesSidebar => _showMessagesSidebar;
  List<UserModel> get users => _users;
  List<JobModel> get jobs => _jobs;
  List<PostModel> get posts => _posts;
  List<AssetModel> get assets => _assets;
  List<BidModel> get bids => _bids;
  List<AssetModel> get cartItems => _cartItems;
  double get cartTotal => _cartItems.fold(0, (sum, item) => sum + item.price);
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  PaymentMethodModel? get defaultPaymentMethod {
    try {
      return _paymentMethods.firstWhere((method) => method.isDefault);
    } catch (_) {
      return _paymentMethods.isNotEmpty ? _paymentMethods.first : null;
    }
  }
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _userService.getCurrentUser();
    _users = await _userService.getUsers();
    _jobs = await _jobService.getJobs();
    _posts = await _postService.getPosts();
    _assets = await _assetService.getAssets();
    _bids = await _bidService.getAllBids();
    if (_currentUser != null) {
      _paymentMethods = await _paymentService.getPaymentMethods(_currentUser!.id);
    } else {
      _paymentMethods = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> switchRole(String newRole) async {
    await _userService.switchRole(newRole);
    _currentUser = await _userService.getCurrentUser();
    notifyListeners();
  }

  Future<void> setUser(UserModel user) async {
    _currentUser = user;
    _paymentMethods = await _paymentService.getPaymentMethods(user.id);
    notifyListeners();
  }

  Future<void> updateUser(UserModel user) async {
    await _userService.updateCurrentUser(user);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> submitBid(BidModel bid) async {
    await _bidService.addBid(bid);
    await _jobService.incrementBidCount(bid.jobId);
    _jobs = await _jobService.getJobs();
    notifyListeners();
  }

  Future<bool> hasUserBidOnJob(String jobId) async {
    if (_currentUser == null) return false;
    return await _bidService.hasUserBidOnJob(jobId, _currentUser!.id);
  }

  Future<List<BidModel>> getBidsForJob(String jobId) async {
    return await _bidService.getBidsForJob(jobId);
  }

  Future<void> addPost(PostModel post) async {
    await _postService.addPost(post);
    _posts = await _postService.getPosts();
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    if (_currentUser == null) return;
    await _postService.toggleLike(postId, _currentUser!.id);
    _posts = await _postService.getPosts();
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    await _postService.deletePost(postId);
    _posts = await _postService.getPosts();
    notifyListeners();
  }

  Future<void> deleteAsset(String assetId) async {
    await _assetService.deleteAsset(assetId);
    _assets = await _assetService.getAssets();
    notifyListeners();
  }

  Future<void> searchJobs(String query) async {
    _jobs = await _jobService.searchJobs(query);
    notifyListeners();
  }

  Future<void> filterJobsByCategory(String category) async {
    _jobs = await _jobService.filterByCategory(category);
    notifyListeners();
  }

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  void addToCart(AssetModel asset) {
    if (!_cartItems.any((item) => item.id == asset.id)) {
      _cartItems.add(asset);
      notifyListeners();
    }
  }

  void removeFromCart(String assetId) {
    _cartItems.removeWhere((item) => item.id == assetId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<PaymentMethodModel?> addPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
  }) async {
    if (_currentUser == null) {
      throw StateError('User must be signed in to add a payment method.');
    }

    final sanitizedNumber = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitizedNumber.length < 12) {
      throw ArgumentError('Card number must be at least 12 digits');
    }

    final brand = _detectCardBrand(sanitizedNumber);
    final last4 = sanitizedNumber.substring(sanitizedNumber.length - 4);
    final now = DateTime.now();
    final method = PaymentMethodModel(
      id: '',
      userId: _currentUser!.id,
      brand: brand,
      last4: last4,
      expMonth: expMonth,
      expYear: expYear,
      isDefault: _paymentMethods.isEmpty,
      createdAt: now,
    );

    final inserted = await _paymentService.insertPaymentMethod(method);
    if (inserted != null) {
      if (inserted.isDefault) {
        _paymentMethods = [
          inserted,
          ..._paymentMethods.map((existing) => existing.copyWith(isDefault: false)),
        ];
      } else {
        _paymentMethods = [inserted, ..._paymentMethods];
      }
      notifyListeners();
    }
    return inserted;
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    if (_currentUser == null) return;
    await _paymentService.updateDefaultMethod(_currentUser!.id, methodId);
    _paymentMethods = _paymentMethods
        .map((method) => method.copyWith(isDefault: method.id == methodId))
        .toList();
    notifyListeners();
  }

  Future<void> removePaymentMethod(String methodId) async {
    await _paymentService.deletePaymentMethod(methodId);
    _paymentMethods.removeWhere((method) => method.id == methodId);
    notifyListeners();
    if (_paymentMethods.isNotEmpty && !_paymentMethods.any((m) => m.isDefault)) {
      final firstId = _paymentMethods.first.id;
      await setDefaultPaymentMethod(firstId);
    }
  }

  Future<void> recordPurchases(List<AssetModel> items) async {
    if (_currentUser == null) return;
    final now = DateTime.now();
    const uuid = Uuid();
    for (final asset in items) {
      final purchase = PurchaseModel(
        id: uuid.v4(),
        userId: _currentUser!.id,
        assetId: asset.id,
        amount: asset.price,
        purchasedAt: now,
      );
      await _assetService.addPurchase(purchase);
    }
  }

  void toggleMessagesSidebar() {
    _showMessagesSidebar = !_showMessagesSidebar;
    notifyListeners();
  }

  void closeMessagesSidebar() {
    _showMessagesSidebar = false;
    notifyListeners();
  }

  String _detectCardBrand(String cardNumber) {
    if (cardNumber.startsWith('4')) return 'Visa';
    if (cardNumber.startsWith('5')) return 'Mastercard';
    if (cardNumber.startsWith('34') || cardNumber.startsWith('37')) return 'American Express';
    if (cardNumber.startsWith('6')) return 'Discover';
    if (cardNumber.startsWith('35')) return 'JCB';
    if (cardNumber.startsWith('30') || cardNumber.startsWith('36') || cardNumber.startsWith('38')) {
      return 'Diners Club';
    }
    return 'Card';
  }
}
