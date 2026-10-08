import 'package:cloud_firestore/cloud_firestore.dart';

class DemoOrderItem {
  const DemoOrderItem(
      {required this.itemId,
      required this.name,
      required this.unitPriceCents,
      required this.quantity});

  final String itemId;
  final String name;
  final int unitPriceCents;
  final int quantity;

  int get subtotalCents => unitPriceCents * quantity;

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'name': name,
        'unitPriceCents': unitPriceCents,
        'quantity': quantity,
      };

  factory DemoOrderItem.fromMap(Map<String, dynamic> data) => DemoOrderItem(
        itemId: data['itemId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        unitPriceCents: (data['unitPriceCents'] as num?)?.toInt() ?? 0,
        quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      );
}

class DemoOrder {
  const DemoOrder(
      {required this.id,
      required this.customerId,
      required this.vendorId,
      required this.customerName,
      required this.stallName,
      required this.status,
      required this.items,
      required this.totalCents,
      required this.createdAt,
      this.expiresAt,
      this.pickupLatitude,
      this.pickupLongitude,
      this.vendorUnseenRequest = false,
      this.customerUnseenReady = false});

  final String id;
  final String customerId;
  final String vendorId;
  final String customerName;
  final String stallName;
  final String status;
  final List<DemoOrderItem> items;
  final int totalCents;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final bool vendorUnseenRequest;
  final bool customerUnseenReady;

  String get effectiveStatus {
    if (status == 'requested' &&
        expiresAt != null &&
        DateTime.now().isAfter(expiresAt!)) {
      return 'expired';
    }
    return status;
  }

  bool get isActive => !{'collected', 'rejected', 'cancelled', 'expired'}
      .contains(effectiveStatus);

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'vendorId': vendorId,
        'customerName': customerName,
        'stallName': stallName,
        'status': status,
        'items': items.map((item) => item.toMap()).toList(),
        'totalCents': totalCents,
        'createdAt': createdAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'vendorUnseenRequest': vendorUnseenRequest,
        'customerUnseenReady': customerUnseenReady,
      };

  DemoOrder withStatus(String nextStatus) => DemoOrder(
        id: id,
        customerId: customerId,
        vendorId: vendorId,
        customerName: customerName,
        stallName: stallName,
        status: nextStatus,
        items: items,
        totalCents: totalCents,
        createdAt: createdAt,
        expiresAt: nextStatus == 'requested' ? expiresAt : null,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        vendorUnseenRequest: vendorUnseenRequest,
        customerUnseenReady: customerUnseenReady,
      );

  factory DemoOrder.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    return DemoOrder(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      vendorId: data['vendorId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      stallName: data['stallName'] as String? ?? 'Stall',
      status: data['status'] as String? ?? 'requested',
      items: rawItems
          .whereType<Map>()
          .map((item) => DemoOrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      totalCents: (data['totalCents'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      pickupLatitude: (data['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (data['pickupLongitude'] as num?)?.toDouble(),
      vendorUnseenRequest: data['vendorUnseenRequest'] == true,
      customerUnseenReady: data['customerUnseenReady'] == true,
    );
  }

  factory DemoOrder.fromMap(Map<String, dynamic> data) {
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    return DemoOrder(
      id: data['id'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      vendorId: data['vendorId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      stallName: data['stallName'] as String? ?? 'Stall',
      status: data['status'] as String? ?? 'requested',
      items: rawItems
          .whereType<Map>()
          .map((item) => DemoOrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      totalCents: (data['totalCents'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? ''),
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? ''),
      pickupLatitude: (data['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (data['pickupLongitude'] as num?)?.toDouble(),
      vendorUnseenRequest: data['vendorUnseenRequest'] == true,
      customerUnseenReady: data['customerUnseenReady'] == true,
    );
  }
}

String demoOrderStatusLabel(String status) => switch (status) {
      'requested' => 'Booking requested',
      'confirmed' => 'Booking confirmed',
      'preparing' => 'Preparing',
      'ready' => 'Ready for collection',
      'collected' => 'Collected',
      'rejected' => 'Rejected',
      'cancelled' => 'Cancelled',
      'expired' => 'Expired',
      _ => status,
    };
