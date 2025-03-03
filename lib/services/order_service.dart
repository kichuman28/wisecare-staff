import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wisecare_staff/core/models/order_model.dart';
import 'package:wisecare_staff/core/services/cloudinary_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get orders for the current delivery staff
  Stream<List<Order>> getOrdersForCurrentStaff() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('orders')
        .where('deliveryStaffId', isEqualTo: currentUserId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final orders = <Order>[];
      for (final doc in snapshot.docs) {
        final order = await Order.fromFirestoreWithPatientDetails(doc);
        orders.add(order);
      }
      return orders;
    });
  }

  // Get orders by status
  Stream<List<Order>> getOrdersByStatus(String status) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('orders')
        .where('deliveryStaffId', isEqualTo: currentUserId)
        .where('status', isEqualTo: status)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final orders = <Order>[];
      for (final doc in snapshot.docs) {
        final order = await Order.fromFirestoreWithPatientDetails(doc);
        orders.add(order);
      }
      return orders;
    });
  }

  // Get today's orders
  Stream<List<Order>> getTodayOrders() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('orders')
        .where('deliveryStaffId', isEqualTo: currentUserId)
        .where('orderDate', isGreaterThanOrEqualTo: startOfDay)
        .where('orderDate', isLessThan: endOfDay)
        .orderBy('orderDate', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final orders = <Order>[];
      for (final doc in snapshot.docs) {
        final order = await Order.fromFirestoreWithPatientDetails(doc);
        orders.add(order);
      }
      return orders;
    });
  }

  // Get a single order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return Order.fromFirestoreWithPatientDetails(doc);
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition();

      // Update order document
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusUpdateLocation': GeoPoint(position.latitude, position.longitude),
      });

      // Add to delivery updates subcollection
      await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('delivery_updates')
          .add({
        'status': newStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'location': GeoPoint(position.latitude, position.longitude),
        'updatedBy': currentUserId,
        'notes': ''
      });
    } catch (e) {
      print('Error updating order status: $e');
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
      final batch = _firestore.batch();
      final orderRef = _firestore.collection('orders').doc(orderId);

      // Update fields map
      final Map<String, dynamic> updateFields = {
        'status': 'delivered',
        'updatedAt': FieldValue.serverTimestamp(),
        'deliveryNotes': notes,
      };

      // Upload proof image if provided
      if (proofImage != null) {
        // Upload to Cloudinary
        final response = await _cloudinaryService.uploadFile(
            proofImage, 'delivery_proofs/$orderId');
        updateFields['proofImageUrl'] = response.secureUrl;
      }

      // Upload signature if provided
      if (signature != null) {
        // Upload to Cloudinary
        final fileName =
            'signature_${DateTime.now().millisecondsSinceEpoch}.png';
        final response = await _cloudinaryService.uploadImageBytes(
            signature, 'delivery_proofs/$orderId', fileName);
        updateFields['signatureUrl'] = response.secureUrl;
      }

      // Update order
      batch.update(orderRef, updateFields);

      // Add delivery update
      final position = await Geolocator.getCurrentPosition();
      final updateRef = orderRef.collection('delivery_updates').doc();
      batch.set(updateRef, {
        'status': 'delivered',
        'timestamp': FieldValue.serverTimestamp(),
        'location': GeoPoint(position.latitude, position.longitude),
        'updatedBy': currentUserId,
        'notes': notes,
        'hasProofImage': proofImage != null,
        'hasSignature': signature != null,
        'proofImageUrl': updateFields['proofImageUrl'],
        'signatureUrl': updateFields['signatureUrl'],
      });

      // Commit batch
      await batch.commit();
    } catch (e) {
      print('Error completing delivery: $e');
      throw e;
    }
  }

  // Get delivery updates for an order
  Stream<List<DeliveryUpdate>> getDeliveryUpdates(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('delivery_updates')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeliveryUpdate.fromFirestore(doc))
          .toList();
    });
  }

  // Get performance metrics for the current delivery staff
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    if (currentUserId == null) {
      return {
        'deliveryRate': 0.0,
        'avgDeliveryTime': 0.0,
        'totalDelivered': 0,
      };
    }

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final query = await _firestore
          .collection('orders')
          .where('deliveryStaffId', isEqualTo: currentUserId)
          .where('orderDate', isGreaterThan: thirtyDaysAgo)
          .get();

      final orders = query.docs;
      final delivered = orders
          .where((doc) => (doc.data()['status'] as String?) == 'delivered')
          .length;
      final total = orders.length;
      final deliveryRate = total > 0 ? delivered / total : 0.0;

      // Calculate average delivery time
      double avgTimeMinutes = 0;
      int completedOrdersCount = 0;

      for (final doc in orders) {
        final data = doc.data();
        if (data['status'] == 'delivered' &&
            data['updatedAt'] != null &&
            data['orderDate'] != null) {
          final start = (data['orderDate'] as Timestamp).toDate();
          final end = (data['updatedAt'] as Timestamp).toDate();
          final diffMinutes = end.difference(start).inMinutes;

          avgTimeMinutes += diffMinutes;
          completedOrdersCount++;
        }
      }

      if (completedOrdersCount > 0) {
        avgTimeMinutes = avgTimeMinutes / completedOrdersCount;
      }

      return {
        'deliveryRate': deliveryRate,
        'avgDeliveryTime': avgTimeMinutes,
        'totalDelivered': delivered,
      };
    } catch (e) {
      print('Error getting performance metrics: $e');
      return {
        'deliveryRate': 0.0,
        'avgDeliveryTime': 0.0,
        'totalDelivered': 0,
      };
    }
  }
}
