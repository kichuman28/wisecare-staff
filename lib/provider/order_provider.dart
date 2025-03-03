import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:wisecare_staff/core/models/order_model.dart';
import 'package:wisecare_staff/services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<Order> _allOrders = [];
  List<Order> _todayOrders = [];
  Map<String, dynamic>? _performanceMetrics;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Order> get allOrders => _allOrders;
  List<Order> get todayOrders => _todayOrders;
  Map<String, dynamic>? get performanceMetrics => _performanceMetrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered orders
  List<Order> get processingOrders =>
      _allOrders.where((order) => order.status == 'processing').toList();

  List<Order> get dispatchedOrders =>
      _allOrders.where((order) => order.status == 'dispatched').toList();

  List<Order> get deliveredOrders =>
      _allOrders.where((order) => order.status == 'delivered').toList();

  // Order counts
  int get processingCount => processingOrders.length;
  int get dispatchedCount => dispatchedOrders.length;
  int get deliveredCount => deliveredOrders.length;
  int get totalCount => _allOrders.length;

  // Initialize streams
  void init() {
    // Listen to all orders
    _orderService.getOrdersForCurrentStaff().listen((orders) {
      _allOrders = orders;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = error.toString();
      notifyListeners();
    });

    // Listen to today's orders
    _orderService.getTodayOrders().listen((orders) {
      _todayOrders = orders;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = error.toString();
      notifyListeners();
    });

    // Fetch performance metrics
    fetchPerformanceMetrics();
  }

  // Fetch performance metrics
  Future<void> fetchPerformanceMetrics() async {
    try {
      _isLoading = true;
      notifyListeners();

      _performanceMetrics = await _orderService.getPerformanceMetrics();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _orderService.updateOrderStatus(orderId, newStatus);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Complete delivery with proof
  Future<void> completeDelivery({
    required String orderId,
    File? proofImage,
    Uint8List? signature,
    String notes = '',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _orderService.completeDelivery(
        orderId: orderId,
        proofImage: proofImage,
        signature: signature,
        notes: notes,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Get a single order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      return await _orderService.getOrderById(orderId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get delivery updates for an order
  Stream<List<DeliveryUpdate>> getDeliveryUpdates(String orderId) {
    return _orderService.getDeliveryUpdates(orderId);
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
