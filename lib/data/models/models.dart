Map<String, dynamic> asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> asList(dynamic v) {
  if (v is List) return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  if (v is Map) {
    for (final k in ['items', 'services', 'categories', 'bookings', 'data', 'result', 'list']) {
      final inner = v[k];
      if (inner is List) return asList(inner);
    }
  }
  return [];
}

String str(dynamic v, [String fb = '']) => v == null ? fb : v.toString();
double numD(dynamic v, [double fb = 0]) {
  if (v == null) return fb;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fb;
}

class UserModel {
  final String id;
  final String fname;
  final String lname;
  final String mobile;
  final String email;
  final String? gender;
  final bool profileCompleted;
  final String? avatar;
  UserModel({
    required this.id,
    required this.fname,
    required this.lname,
    required this.mobile,
    required this.email,
    this.gender,
    this.profileCompleted = false,
    this.avatar,
  });
  String get fullName => '$fname $lname'.trim();
  factory UserModel.fromJson(dynamic j) {
    final m = asMap(j);
    final user = m.containsKey('user') ? asMap(m['user']) : m;
    return UserModel(
      id: str(user['_id'] ?? user['id'] ?? user['userId']),
      fname: str(user['fname'] ?? user['firstName'] ?? user['name']),
      lname: str(user['lname'] ?? user['lastName']),
      mobile: str(user['identifier'] ?? user['mobileNumber'] ?? user['mobile'] ?? user['phone']),
      email: str(user['email']),
      gender: user['gender']?.toString(),
      profileCompleted: user['profileComplete'] == true ||
          user['profileCompleted'] == true ||
          user['isProfileCompleted'] == true,
      avatar: user['avatar']?.toString() ?? user['profileImage']?.toString(),
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String? image;
  final String? description;
  final String? type;
  final int serviceCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.image,
    this.description,
    this.type,
    this.serviceCount = 0,
  });

  bool get isProductCategory {
    final t = (type ?? '').toLowerCase();
    if (t == 'product' || t.contains('product')) return true;
    if (t == 'service' || t.contains('service')) return false;
    final n = name.toLowerCase();
    return n.contains('product') ||
        n.contains('battery') ||
        n.contains('surveilance product');
  }

  factory CategoryModel.fromJson(dynamic j) {
    final m = asMap(j);
    return CategoryModel(
      id: str(m['_id'] ?? m['id']),
      name: str(m['category'] ?? m['name'] ?? m['title'] ?? 'Category'),
      image: (m['image'] ?? m['icon'] ?? m['imageUrl'])?.toString(),
      description: m['description']?.toString(),
      type: (m['categoryType'] ?? m['type'])?.toString(),
      serviceCount: (m['serviceCount'] is num)
          ? (m['serviceCount'] as num).toInt()
          : 0,
    );
  }
}

class ServiceModel {
  final String id;
  final String name;
  final String? description;
  final num? price;
  final num? mrp;
  final double rating;
  final int ratingCount;
  final String? image;
  final List<String> images;
  final String? categoryId;
  final String? categoryName;
  final int durationMin;
  final bool available;
  final String? availabilityPrompt;
  final String warranty;
  final bool isTopService;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.mrp,
    this.rating = 4.9,
    this.ratingCount = 48,
    this.image,
    this.images = const [],
    this.categoryId,
    this.categoryName,
    this.durationMin = 60,
    this.available = true,
    this.availabilityPrompt,
    this.warranty = '30-Day Warranty',
    this.isTopService = true,
  });

  factory ServiceModel.fromJson(dynamic j) {
    final m = asMap(j);
    final imgs = <String>[];
    for (final k in ['serviceImages', 'images', 'photos', 'banners']) {
      final v = m[k];
      if (v is List) {
        imgs.addAll(v.whereType<Object>().map((e) => e.toString()));
      } else if (v is String && v.isNotEmpty) {
        imgs.add(v);
      }
    }
    final img = (imgs.isNotEmpty
            ? imgs.first
            : (m['image'] ?? m['thumbnail'] ?? m['icon']))
        ?.toString();
    final cat = m['categoryId'] ?? m['category'];
    final catId = cat is Map
        ? str(cat['_id'] ?? cat['id'])
        : str(m['categoryId'] ?? cat);
    final catName = cat is Map
        ? str(cat['category'] ?? cat['name'])
        : str(m['categoryName']);

    final rawPrice = m['discountedPrice'] ?? m['serviceCost'] ?? m['price'] ?? m['cost'];
    final num? p = rawPrice is num
        ? rawPrice
        : (rawPrice != null ? num.tryParse(str(rawPrice)) : null);

    final rawMrp = m['serviceCost'] ?? m['mrp'] ?? m['originalPrice'];
    final num? mrpParsed = rawMrp is num
        ? rawMrp
        : (rawMrp != null ? num.tryParse(str(rawMrp)) : null);
    final num? mrpVal = (mrpParsed != null && p != null && mrpParsed > p) ? mrpParsed : null;

    final ratingSummary = m['ratingSummary'];
    final double ratingVal = ratingSummary is Map && (ratingSummary['averageRating'] is num) && ((ratingSummary['averageRating'] as num) > 0)
        ? (ratingSummary['averageRating'] as num).toDouble()
        : numD(m['rating'] ?? m['avgRating'], 0);

    final int ratingCnt = ratingSummary is Map && (ratingSummary['totalRatings'] is num) && ((ratingSummary['totalRatings'] as num) > 0)
        ? (ratingSummary['totalRatings'] as num).toInt()
        : ((m['ratingCount'] is num)
            ? (m['ratingCount'] as num).toInt()
            : 0);

    final w = (m['serviceWarranty'] ?? m['warranty'])?.toString();
    final warrantyVal = (w != null && w.trim().isNotEmpty) ? w.trim() : 'Service Warranty';

    return ServiceModel(
      id: str(m['_id'] ?? m['id']),
      name: str(m['serviceName'] ?? m['name'] ?? m['title'] ?? 'Service'),
      description:
          m['description']?.toString() ?? m['shortDescription']?.toString(),
      price: p,
      mrp: mrpVal,
      rating: ratingVal,
      ratingCount: ratingCnt,
      image: img,
      images: imgs,
      categoryId: catId.isNotEmpty ? catId : null,
      categoryName: catName.isNotEmpty ? catName : null,
      durationMin: (m['durationMin'] is num)
          ? (m['durationMin'] as num).toInt()
          : (m['duration']?.toString().contains('hour') == true ? 120 : 60),
      available: m['available'] != false && m['isActive'] != false,
      warranty: warrantyVal,
      isTopService: m['isTopService'] == true || (ratingVal >= 4.8 && ratingCnt > 0),
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final num? price;
  final num? mrp;
  final double rating;
  final int ratingCount;
  final String? image;
  final List<String> images;
  final String? categoryId;
  final String? categoryName;
  final String? brand;
  final String warranty;
  final bool inStock;
  final bool quoteRequired;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.mrp,
    this.rating = 4.8,
    this.ratingCount = 85,
    this.image,
    this.images = const [],
    this.categoryId,
    this.categoryName,
    this.brand,
    this.warranty = '1 Year Brand Warranty',
    this.inStock = true,
    this.quoteRequired = false,
  });

  factory ProductModel.fromJson(dynamic j) {
    final m = asMap(j);
    final imgs = <String>[];
    for (final k in ['images', 'photos', 'productImages']) {
      final v = m[k];
      if (v is List) imgs.addAll(v.map((e) => e.toString()));
    }
    final img = (m['image'] ??
            m['thumbnail'] ??
            m['imageUrl'] ??
            (imgs.isNotEmpty ? imgs.first : null))
        ?.toString();
    final cat = m['categoryId'] ?? m['category'];
    final catId = cat is Map
        ? str(cat['_id'] ?? cat['id'])
        : str(m['categoryId'] ?? cat);
    final catName = cat is Map
        ? str(cat['category'] ?? cat['name'])
        : str(m['categoryName']);

    final p = m['price'] is num
        ? m['price']
        : num.tryParse(str(m['price']));

    return ProductModel(
      id: str(m['_id'] ?? m['id'] ?? m['productId']),
      name: str(m['productName'] ?? m['name'] ?? m['title'] ?? 'Product'),
      description:
          m['description']?.toString() ?? m['specifications']?.toString(),
      price: p,
      mrp: m['mrp'] is num
          ? m['mrp']
          : (m['originalPrice'] is num ? m['originalPrice'] : (p != null ? (p * 1.2).round() : null)),
      rating: numD(m['rating'] ?? m['avgRating'], 4.8),
      ratingCount: (m['ratingCount'] is num)
          ? (m['ratingCount'] as num).toInt()
          : 85,
      image: img,
      images: imgs,
      categoryId: catId.isNotEmpty ? catId : null,
      categoryName: catName.isNotEmpty ? catName : null,
      brand: (m['brand'] ?? m['manufacturer'])?.toString() ?? 'RightTouch Pro',
      warranty: m['warranty']?.toString() ?? '1 Year Brand Warranty',
      inStock: m['inStock'] != false && m['isAvailable'] != false,
      quoteRequired: m['quoteRequired'] == true || p == null,
    );
  }
}

class SlotModel {
  final String date;
  final List<String> times;
  SlotModel({required this.date, required this.times});
  factory SlotModel.fromJson(dynamic j) {
    final m = asMap(j);
    final t = m['slots'] ?? m['times'] ?? m['timings'] ?? [];
    return SlotModel(date: str(m['date'] ?? m['day']), times: t is List ? t.map((e) => e.toString()).toList() : []);
  }
}

class BookingModel {
  final String id;
  final String status;
  final String? serviceName;
  final String? serviceId;
  final num? amount;
  final dynamic scheduledAt;
  final String? addressLine;
  final String? technicianName;
  final String? paymentStatus;
  BookingModel({required this.id, required this.status, this.serviceName, this.serviceId, this.amount, this.scheduledAt, this.addressLine, this.technicianName, this.paymentStatus});
  factory BookingModel.fromJson(dynamic j) {
    final m = asMap(j);
    final svc = m['service'];
    return BookingModel(
      id: str(m['_id'] ?? m['id'] ?? m['bookingId']),
      status: str(m['status'] ?? m['bookingStatus'] ?? 'pending'),
      serviceName: svc is Map ? str(svc['name']) : str(m['serviceName']),
      serviceId: svc is Map ? str(svc['_id']) : str(m['serviceId']),
      amount: m['totalAmount'] is num ? m['totalAmount'] : (m['amount'] is num ? m['amount'] : null),
      scheduledAt: m['scheduledAt'] ?? m['slot'] ?? m['bookingDate'] ?? m['createdAt'],
      addressLine: str(m['addressLine'] ?? (m['address'] is Map ? m['address']['addressLine'] : '')),
      technicianName: m['technician'] is Map ? str(m['technician']['name']) : str(m['technicianName']),
      paymentStatus: str(m['paymentStatus']),
    );
  }
}

class CartItemModel {
  final String id;
  final String itemId;
  final String itemType;
  final String name;
  final String? image;
  final num? price;
  final num? originalPrice;
  final int qty;

  CartItemModel({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.name,
    this.image,
    this.price,
    this.originalPrice,
    this.qty = 1,
  });

  factory CartItemModel.fromJson(dynamic j) {
    final m = asMap(j);
    // itemId can be a populated Map or an ObjectId string; item can also be a Map
    final itObj = m['itemId'] is Map
        ? asMap(m['itemId'])
        : (m['item'] is Map ? asMap(m['item']) : m);

    final rawName = itObj['serviceName'] ??
        itObj['productName'] ??
        itObj['name'] ??
        itObj['title'] ??
        m['name'] ??
        m['title'];
    final name = str(rawName, 'Item');

    String? img;
    for (final k in ['serviceImages', 'productImages', 'images', 'photos', 'banners']) {
      final v = itObj[k] ?? m[k];
      if (v is List && v.isNotEmpty) {
        img = v.first.toString();
        break;
      }
    }
    img ??= (itObj['image'] ?? itObj['thumbnail'] ?? itObj['icon'] ?? m['image'])?.toString();

    final rawPrice = itObj['discountedPrice'] ??
        itObj['serviceCost'] ??
        itObj['price'] ??
        itObj['cost'] ??
        m['discountedPrice'] ??
        m['serviceCost'] ??
        m['price'] ??
        m['unitPrice'];
    final num? p = rawPrice is num
        ? rawPrice
        : (rawPrice != null ? num.tryParse(str(rawPrice)) : null);

    final rawMrp = itObj['serviceCost'] ??
        itObj['mrp'] ??
        itObj['originalPrice'] ??
        m['serviceCost'] ??
        m['mrp'];
    final num? mrpVal = rawMrp is num
        ? rawMrp
        : (rawMrp != null ? num.tryParse(str(rawMrp)) : null);

    final rawQty = m['quantity'] ?? m['qty'] ?? itObj['quantity'] ?? itObj['qty'];
    final int q = rawQty is num ? rawQty.toInt() : (int.tryParse(str(rawQty)) ?? 1);

    final itId = m['itemId'] is Map
        ? str(itObj['_id'] ?? itObj['id'])
        : str(m['itemId'] ?? itObj['_id'] ?? itObj['id']);

    return CartItemModel(
      id: str(m['_id'] ?? m['id'] ?? m['cartItemId']),
      itemId: itId,
      itemType: str(m['itemType'] ?? itObj['itemType'] ?? 'service'),
      name: name,
      image: img,
      price: p,
      originalPrice: (mrpVal != null && p != null && mrpVal > p) ? mrpVal : null,
      qty: q > 0 ? q : 1,
    );
  }
}

class AddressModel {
  final String id;
  final String type;
  final String line;
  final String city;
  final String state;
  final String pincode;
  final double lat;
  final double lng;
  final bool isDefault;
  AddressModel({required this.id, required this.type, required this.line, required this.city, required this.state, required this.pincode, this.lat = 0, this.lng = 0, this.isDefault = false});
  factory AddressModel.fromJson(dynamic j) {
    final m = asMap(j);
    return AddressModel(
      id: str(m['_id'] ?? m['id'] ?? m['addressId']),
      type: str(m['addressType'] ?? m['type'], 'Home'),
      line: str(m['addressLine'] ?? m['line'] ?? m['address']),
      city: str(m['city']),
      state: str(m['state']),
      pincode: str(m['pincode'] ?? m['zipcode']),
      lat: numD(m['latitude'] ?? m['lat']),
      lng: numD(m['longitude'] ?? m['lng']),
      isDefault: m['isDefault'] == true || m['default'] == true,
    );
  }
  Map<String, dynamic> toJson() => {
        'addressType': type, 'addressLine': line, 'city': city,
        'state': state, 'pincode': pincode, 'latitude': lat, 'longitude': lng,
      };
}

class PaymentModel {
  final String bookingId;
  final String status;
  final num? amount;
  final String? method;
  final String? txnId;
  PaymentModel({required this.bookingId, required this.status, this.amount, this.method, this.txnId});
  factory PaymentModel.fromJson(dynamic j) {
    final m = asMap(j);
    return PaymentModel(
      bookingId: str(m['bookingId'] ?? m['booking'] ?? m['_id']),
      status: str(m['status'] ?? m['paymentStatus'] ?? 'pending'),
      amount: m['amount'] is num ? m['amount'] : (m['totalAmount'] is num ? m['totalAmount'] : null),
      method: m['paymentMethod']?.toString() ?? m['method']?.toString(),
      txnId: m['transactionId']?.toString() ?? m['txnId']?.toString(),
    );
  }
}

class QuotationModel {
  final String id;
  final String status;
  final String? title;
  final num? amount;
  final dynamic createdAt;
  QuotationModel({required this.id, required this.status, this.title, this.amount, this.createdAt});
  factory QuotationModel.fromJson(dynamic j) {
    final m = asMap(j);
    return QuotationModel(
      id: str(m['_id'] ?? m['id']),
      status: str(m['status'] ?? 'pending'),
      title: (m['title'] ?? m['productName'] ?? m['serviceName'])?.toString(),
      amount: m['amount'] is num ? m['amount'] : (m['quotedPrice'] is num ? m['quotedPrice'] : null),
      createdAt: m['createdAt'],
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool read;
  final dynamic createdAt;
  NotificationModel({required this.id, required this.title, required this.body, this.read = false, this.createdAt});
  factory NotificationModel.fromJson(dynamic j) {
    final m = asMap(j);
    return NotificationModel(
      id: str(m['_id'] ?? m['id']),
      title: str(m['title'] ?? m['heading'] ?? 'Notification'),
      body: str(m['body'] ?? m['message'] ?? m['description']),
      read: m['read'] == true || m['isRead'] == true,
      createdAt: m['createdAt'],
    );
  }
}

class QuoteRequestModel {
  final String id;
  final String requirement;
  final String status;
  final String? preferredContactMethod;
  final String? addressLine;
  final dynamic createdAt;

  QuoteRequestModel({
    required this.id,
    required this.requirement,
    required this.status,
    this.preferredContactMethod,
    this.addressLine,
    this.createdAt,
  });

  factory QuoteRequestModel.fromJson(dynamic j) {
    final m = asMap(j);
    return QuoteRequestModel(
      id: str(m['_id'] ?? m['id']),
      requirement: str(m['requirementDescription'] ?? m['requirement'] ?? m['description'] ?? 'Product Quote Request'),
      status: str(m['status'] ?? 'pending'),
      preferredContactMethod: m['preferredContactMethod']?.toString(),
      addressLine: m['address'] is Map ? str(m['address']['addressLine']) : m['addressId']?.toString(),
      createdAt: m['createdAt'],
    );
  }
}

class ProductBookingModel {
  final String id;
  final String status;
  final num? amount;
  final String? quotationId;
  final String? productName;
  final dynamic createdAt;

  ProductBookingModel({
    required this.id,
    required this.status,
    this.amount,
    this.quotationId,
    this.productName,
    this.createdAt,
  });

  factory ProductBookingModel.fromJson(dynamic j) {
    final m = asMap(j);
    return ProductBookingModel(
      id: str(m['_id'] ?? m['id']),
      status: str(m['status'] ?? m['bookingStatus'] ?? 'confirmed'),
      amount: m['finalAmount'] is num ? m['finalAmount'] : (m['amount'] is num ? m['amount'] : null),
      quotationId: str(m['quotationId'] ?? m['quotation']),
      productName: (m['productName'] ?? m['title'])?.toString(),
      createdAt: m['createdAt'],
    );
  }
}

class ReportModel {
  final String id;
  final String bookingId;
  final String complaint;
  final String category;
  final String status;
  final dynamic createdAt;

  ReportModel({
    required this.id,
    required this.bookingId,
    required this.complaint,
    required this.category,
    required this.status,
    this.createdAt,
  });

  factory ReportModel.fromJson(dynamic j) {
    final m = asMap(j);
    return ReportModel(
      id: str(m['_id'] ?? m['id']),
      bookingId: str(m['bookingId'] ?? m['booking']),
      complaint: str(m['complaint'] ?? m['description'] ?? m['subject'] ?? 'Service complaint'),
      category: str(m['category'] ?? 'service'),
      status: str(m['status'] ?? 'pending'),
      createdAt: m['createdAt'],
    );
  }
}
