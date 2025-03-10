import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String userId;
  final DateTime orderDate;
  final String status;
  final String? deliveryStaffId;
  final String? deliveryStaffName;
  final DateTime? updatedAt;
  final List<Medicine> medicines;
  final double totalAmount;
  final String deliveryAddress;
  final GeoPoint? deliveryLocation;
  final String? deliveryNotes;
  final String? proofImageUrl;
  final String? signatureUrl;
  final String patientName;
  final String? patientEmail;
  final String? patientPhone;
  final String? patientPhotoUrl;
  final String? addressId;

  Order({
    required this.id,
    required this.userId,
    required this.orderDate,
    required this.status,
    this.deliveryStaffId,
    this.deliveryStaffName,
    this.updatedAt,
    required this.medicines,
    required this.totalAmount,
    required this.deliveryAddress,
    this.deliveryLocation,
    this.deliveryNotes,
    this.proofImageUrl,
    this.signatureUrl,
    required this.patientName,
    this.patientEmail,
    this.patientPhone,
    this.patientPhotoUrl,
    this.addressId,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse medicines list
    final medicinesList = (data['medicines'] as List<dynamic>? ?? [])
        .map((medicineData) => Medicine.fromMap(medicineData))
        .toList();

    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'processing',
      deliveryStaffId: data['deliveryStaffId'],
      deliveryStaffName: data['deliveryStaffName'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      medicines: medicinesList,
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: data['deliveryAddress'] ?? 'No address provided',
      deliveryLocation: data['deliveryLocation'] as GeoPoint?,
      deliveryNotes: data['deliveryNotes'],
      proofImageUrl: data['proofImageUrl'],
      signatureUrl: data['signatureUrl'],
      patientName: data['patientName'] ?? 'Unknown Patient',
      patientEmail: data['patientEmail'],
      patientPhone: data['patientPhone'],
      patientPhotoUrl: data['patientPhotoUrl'],
      addressId: data['addressId'],
    );
  }

  // Create a new Order with patient details from the users collection
  static Future<Order> fromFirestoreWithPatientDetails(
      DocumentSnapshot doc) async {
    final order = Order.fromFirestore(doc);

    if (order.userId.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(order.userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Create a new order with user details
          Order updatedOrder = order.copyWith(
            patientName: userData['displayName'] ??
                userData['name'] ??
                'Unknown Patient',
            patientEmail: userData['email'] ?? order.patientEmail,
            patientPhone: userData['phone'] ?? order.patientPhone,
            patientPhotoUrl: userData['photoURL'] ?? order.patientPhotoUrl,
          );

          // If we have an addressId, try to fetch the address details
          if (order.addressId != null && order.addressId!.isNotEmpty) {
            try {
              final addressDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(order.userId)
                  .collection('addresses')
                  .doc(order.addressId)
                  .get();

              if (addressDoc.exists) {
                final addressData = addressDoc.data() as Map<String, dynamic>;

                // Get address details
                final address = addressData['address'] ?? 'No address provided';
                final additionalInfo = addressData['additionalInfo'] ?? '';
                final fullAddress = additionalInfo.isNotEmpty
                    ? '$address (Near $additionalInfo)'
                    : address;

                // Get location coordinates
                final latitude = addressData['latitude'];
                final longitude = addressData['longitude'];
                GeoPoint? location;

                if (latitude != null && longitude != null) {
                  location = GeoPoint(latitude, longitude);
                }

                // Update order with address details
                updatedOrder = updatedOrder.copyWith(
                  deliveryAddress: fullAddress,
                  deliveryLocation: location ?? order.deliveryLocation,
                );
              }
            } catch (e) {
              print('Error fetching address details: $e');
            }
          }

          return updatedOrder;
        }
      } catch (e) {
        print('Error fetching patient details: $e');
      }
    }

    return order;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status,
      'deliveryStaffId': deliveryStaffId,
      'deliveryStaffName': deliveryStaffName,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'medicines': medicines.map((medicine) => medicine.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'deliveryLocation': deliveryLocation,
      'deliveryNotes': deliveryNotes,
      'proofImageUrl': proofImageUrl,
      'signatureUrl': signatureUrl,
      'patientName': patientName,
      'patientEmail': patientEmail,
      'patientPhone': patientPhone,
      'patientPhotoUrl': patientPhotoUrl,
      'addressId': addressId,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    DateTime? orderDate,
    String? status,
    String? deliveryStaffId,
    String? deliveryStaffName,
    DateTime? updatedAt,
    List<Medicine>? medicines,
    double? totalAmount,
    String? deliveryAddress,
    GeoPoint? deliveryLocation,
    String? deliveryNotes,
    String? proofImageUrl,
    String? signatureUrl,
    String? patientName,
    String? patientEmail,
    String? patientPhone,
    String? patientPhotoUrl,
    String? addressId,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      deliveryStaffId: deliveryStaffId ?? this.deliveryStaffId,
      deliveryStaffName: deliveryStaffName ?? this.deliveryStaffName,
      updatedAt: updatedAt ?? this.updatedAt,
      medicines: medicines ?? this.medicines,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      patientName: patientName ?? this.patientName,
      patientEmail: patientEmail ?? this.patientEmail,
      patientPhone: patientPhone ?? this.patientPhone,
      patientPhotoUrl: patientPhotoUrl ?? this.patientPhotoUrl,
      addressId: addressId ?? this.addressId,
    );
  }
}

class Medicine {
  final String medicineName;
  final int quantity;
  final String dosage;
  final String frequency;
  final int daysSupply;
  final double pricePerUnit;
  final double totalPrice;

  Medicine({
    required this.medicineName,
    required this.quantity,
    required this.dosage,
    required this.frequency,
    required this.daysSupply,
    required this.pricePerUnit,
    required this.totalPrice,
  });

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      medicineName: map['medicineName'] ?? '',
      quantity: map['quantity'] ?? 0,
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      daysSupply: map['daysSupply'] ?? 0,
      pricePerUnit: (map['pricePerUnit'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'quantity': quantity,
      'dosage': dosage,
      'frequency': frequency,
      'daysSupply': daysSupply,
      'pricePerUnit': pricePerUnit,
      'totalPrice': totalPrice,
    };
  }
}

class DeliveryUpdate {
  final String id;
  final String status;
  final DateTime timestamp;
  final GeoPoint? location;
  final String updatedBy;
  final String? notes;
  final bool hasProofImage;
  final bool hasSignature;
  final String? proofImageUrl;
  final String? signatureUrl;

  DeliveryUpdate({
    required this.id,
    required this.status,
    required this.timestamp,
    this.location,
    required this.updatedBy,
    this.notes,
    this.hasProofImage = false,
    this.hasSignature = false,
    this.proofImageUrl,
    this.signatureUrl,
  });

  factory DeliveryUpdate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DeliveryUpdate(
      id: doc.id,
      status: data['status'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] as GeoPoint?,
      updatedBy: data['updatedBy'] ?? '',
      notes: data['notes'],
      hasProofImage: data['hasProofImage'] ?? false,
      hasSignature: data['hasSignature'] ?? false,
      proofImageUrl: data['proofImageUrl'],
      signatureUrl: data['signatureUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
      'updatedBy': updatedBy,
      'notes': notes,
      'hasProofImage': hasProofImage,
      'hasSignature': hasSignature,
      'proofImageUrl': proofImageUrl,
      'signatureUrl': signatureUrl,
    };
  }
}
