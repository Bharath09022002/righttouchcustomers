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

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'image': image,
    'description': description,
    'type': type,
    'serviceCount': serviceCount,
  };
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
  final String? durationText;
  final bool available;
  final String? availabilityPrompt;
  final String warranty;
  final bool isTopService;
  final List<String> whatIncluded;
  final List<String> whatNotIncluded;
  final List<String> serviceHighlights;
  final List<String> frequentlyAskedQuestions;
  final List<String> serviceChecklist;
  final String? cancellationPolicy;

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
    this.durationText,
    this.available = true,
    this.availabilityPrompt,
    this.warranty = '30-Day Warranty',
    this.isTopService = true,
    this.whatIncluded = const [],
    this.whatNotIncluded = const [],
    this.serviceHighlights = const [],
    this.frequentlyAskedQuestions = const [],
    this.serviceChecklist = const [],
    this.cancellationPolicy,
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

    List<String> parseStrList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    final durText = m['duration']?.toString();

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
          : (durText?.contains('hour') == true ? 120 : 60),
      durationText: durText,
      available: m['available'] != false && m['isActive'] != false,
      warranty: warrantyVal,
      isTopService: m['isTopService'] == true || (ratingVal >= 4.8 && ratingCnt > 0),
      whatIncluded: parseStrList(m['whatIncluded']),
      whatNotIncluded: parseStrList(m['whatNotIncluded']),
      serviceHighlights: parseStrList(m['serviceHighlights']),
      frequentlyAskedQuestions: parseStrList(m['frequentlyAskedQuestions']),
      serviceChecklist: parseStrList(m['serviceChecklist']),
      cancellationPolicy: m['cancellationPolicy']?.toString(),
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
  final String pricingModel;
  final num? estimatedPriceFrom;
  final num? estimatedPriceTo;
  final String? productType;
  final String? usageType;
  final bool siteInspectionRequired;
  final String? installationDuration;
  final List<String> whatIncluded;
  final List<String> whatNotIncluded;
  final Map<String, dynamic> technicalSpecifications;
  final bool amcAvailable;
  final num? amcPricePerYear;

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
    this.pricingModel = 'after_inspection',
    this.estimatedPriceFrom,
    this.estimatedPriceTo,
    this.productType,
    this.usageType,
    this.siteInspectionRequired = true,
    this.installationDuration,
    this.whatIncluded = const [],
    this.whatNotIncluded = const [],
    this.technicalSpecifications = const {},
    this.amcAvailable = false,
    this.amcPricePerYear,
  });

  factory ProductModel.fromJson(dynamic j) {
    final m = asMap(j);
    final imgs = <String>[];
    for (final k in ['images', 'photos', 'productImages', 'gallery']) {
      final v = m[k];
      if (v is List) imgs.addAll(v.map((e) => e.toString()));
    }
    final img = (m['image'] ??
            m['thumbnail'] ??
            m['imageUrl'] ??
            m['productImage'] ??
            (imgs.isNotEmpty ? imgs.first : null))
        ?.toString();
    final cat = m['categoryId'] ?? m['category'];
    final catId = cat is Map
        ? str(cat['_id'] ?? cat['id'])
        : str(m['categoryId'] ?? cat);
    final catName = cat is Map
        ? str(cat['category'] ?? cat['name'] ?? cat['title'] ?? cat['categoryName'])
        : str(m['categoryName'] ?? (cat is String ? cat : null));

    final estFrom = m['estimatedPriceFrom'] is num ? m['estimatedPriceFrom'] as num : num.tryParse(str(m['estimatedPriceFrom']));
    final estTo = m['estimatedPriceTo'] is num ? m['estimatedPriceTo'] as num : num.tryParse(str(m['estimatedPriceTo']));
    final pricingModel = str(m['pricingModel'] ?? (estFrom != null ? 'starting_from' : 'after_inspection'));

    final p = m['price'] is num
        ? m['price']
        : (m['finalPrice'] is num
            ? m['finalPrice']
            : (m['rate'] is num ? m['rate'] : (num.tryParse(str(m['price'])) ?? estFrom)));

    final mrpVal = m['mrp'] is num
        ? m['mrp']
        : (m['originalPrice'] is num
            ? m['originalPrice']
            : (m['marketPrice'] is num
                ? m['marketPrice']
                : (estTo ?? (p != null ? (p * 1.2).round() : null))));

    final stock = m['stock'];
    final inStockVal = m['inStock'] != false &&
        m['isAvailable'] != false &&
        (stock == null || (stock is num ? stock > 0 : true));

    final isQuoteReq = m['quoteRequired'] == true ||
        m['isQuoteOnly'] == true ||
        pricingModel == 'after_inspection' ||
        (pricingModel == 'starting_from' && m['quoteRequired'] != false) ||
        p == null;

    final incList = <String>[];
    if (m['whatIncluded'] is List) {
      incList.addAll((m['whatIncluded'] as List).map((e) => e.toString()));
    }
    final notIncList = <String>[];
    if (m['whatNotIncluded'] is List) {
      notIncList.addAll((m['whatNotIncluded'] as List).map((e) => e.toString()));
    }

    final techSpecs = <String, dynamic>{};
    if (m['technicalSpecifications'] is Map) {
      techSpecs.addAll(asMap(m['technicalSpecifications']));
    }

    return ProductModel(
      id: str(m['_id'] ?? m['id'] ?? m['productId']),
      name: str(m['productName'] ?? m['name'] ?? m['title'] ?? 'Product'),
      description:
          m['description']?.toString() ?? m['specifications']?.toString() ?? m['details']?.toString(),
      price: p,
      mrp: mrpVal,
      rating: numD(m['rating'] ?? m['avgRating'] ?? m['ratings'], 4.8),
      ratingCount: (m['ratingCount'] is num)
          ? (m['ratingCount'] as num).toInt()
          : ((m['totalRatings'] is num)
              ? (m['totalRatings'] as num).toInt()
              : 85),
      image: img,
      images: imgs,
      categoryId: catId.isNotEmpty ? catId : null,
      categoryName: catName.isNotEmpty ? catName : null,
      brand: (m['brand'] ?? m['brandName'] ?? m['manufacturer'])?.toString() ?? 'RightTouch Pro',
      warranty: m['warranty']?.toString() ?? m['warrantyPeriod']?.toString() ?? '1 Year Brand Warranty',
      inStock: inStockVal,
      quoteRequired: isQuoteReq,
      pricingModel: pricingModel,
      estimatedPriceFrom: estFrom,
      estimatedPriceTo: estTo,
      productType: m['productType']?.toString(),
      usageType: m['usageType']?.toString(),
      siteInspectionRequired: m['siteInspectionRequired'] != false,
      installationDuration: m['installationDuration']?.toString(),
      whatIncluded: incList,
      whatNotIncluded: notIncList,
      technicalSpecifications: techSpecs,
      amcAvailable: m['amcAvailable'] == true,
      amcPricePerYear: m['amcPricePerYear'] is num ? m['amcPricePerYear'] as num : null,
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
  final String? image;
  final num? amount;
  final dynamic scheduledAt;
  final String? addressLine;
  final String? technicianName;
  final String? paymentStatus;

  BookingModel({
    required this.id,
    required this.status,
    this.serviceName,
    this.serviceId,
    this.image,
    this.amount,
    this.scheduledAt,
    this.addressLine,
    this.technicianName,
    this.paymentStatus,
  });

  factory BookingModel.fromJson(dynamic j) {
    final m = asMap(j);
    final svc = m['service'] ??
        (m['services'] is List && (m['services'] as List).isNotEmpty ? m['services'].first : null);

    String svcName = '';
    String? svcImg;
    String? svcId;

    if (svc is Map) {
      svcName = str(svc['serviceName'] ?? svc['name'] ?? svc['title'] ?? svc['service']);
      svcImg = (svc['image'] ??
              svc['thumbnail'] ??
              (svc['serviceImages'] is List && (svc['serviceImages'] as List).isNotEmpty
                  ? svc['serviceImages'].first
                  : null))
          ?.toString();
      svcId = str(svc['_id'] ?? svc['id']);
    }

    if (svcName.isEmpty) {
      svcName = str(m['serviceName'] ?? m['name'] ?? m['title'] ?? m['service']);
    }
    if (svcName.isEmpty) {
      svcName = 'Service';
    }

    svcImg ??= (m['image'] ?? m['thumbnail'] ?? m['serviceImage'])?.toString();
    svcId ??= str(m['serviceId'] ?? m['_id']);

    return BookingModel(
      id: str(m['_id'] ?? m['id'] ?? m['bookingId']),
      status: str(m['status'] ?? m['bookingStatus'] ?? 'pending'),
      serviceName: svcName,
      serviceId: svcId.isNotEmpty ? svcId : null,
      image: svcImg,
      amount: m['totalAmount'] is num
          ? m['totalAmount']
          : (m['amount'] is num ? m['amount'] : (m['cost'] is num ? m['cost'] : null)),
      scheduledAt: m['scheduledAt'] ?? m['slot'] ?? m['bookingDate'] ?? m['createdAt'],
      addressLine: str(m['addressLine'] ??
          (m['address'] is Map ? (m['address']['addressLine'] ?? m['address']['line']) : '')),
      technicianName: m['technician'] is Map
          ? str(m['technician']['name'] ?? m['technician']['fname'])
          : str(m['technicianName']),
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
  final String? duration;

  CartItemModel({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.name,
    this.image,
    this.price,
    this.originalPrice,
    this.qty = 1,
    this.duration,
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
      duration: (itObj['duration'] ?? m['duration'])?.toString(),
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
      type: str(m['label'] ?? m['addressType'] ?? m['type'], 'Home'),
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

class PaymentOrderResult {
  final String? keyId;
  final String? key;
  final String? orderId;
  final String? razorpayOrderId;
  final num amountPaise;
  final num amountInRupees;
  final String currency;
  final String? paymentId;
  final bool free;
  final Map<String, dynamic>? split;

  PaymentOrderResult({
    this.keyId,
    this.key,
    this.orderId,
    this.razorpayOrderId,
    required this.amountPaise,
    required this.amountInRupees,
    this.currency = 'INR',
    this.paymentId,
    this.free = false,
    this.split,
  });

  String? get rzpKey => key ?? keyId;
  String? get providerOrderId => orderId ?? razorpayOrderId;

  factory PaymentOrderResult.fromJson(dynamic j) {
    final m = asMap(j);
    final isFree = m['free'] == true || m['status'] == 'success' && (m['amount'] == 0 || m['amount'] == null);
    final amtPaise = m['amount'] is num ? m['amount'] as num : 0;
    final amtRupees = m['amountInRupees'] is num
        ? m['amountInRupees'] as num
        : (amtPaise > 0 ? amtPaise / 100 : 0);

    return PaymentOrderResult(
      keyId: m['keyId']?.toString(),
      key: m['key']?.toString(),
      orderId: m['orderId']?.toString() ?? m['id']?.toString(),
      razorpayOrderId: m['razorpayOrderId']?.toString() ?? m['orderId']?.toString() ?? m['id']?.toString(),
      amountPaise: amtPaise,
      amountInRupees: amtRupees,
      currency: m['currency']?.toString() ?? 'INR',
      paymentId: m['paymentId']?.toString(),
      free: isFree,
      split: m['split'] is Map ? Map<String, dynamic>.from(m['split'] as Map) : null,
    );
  }
}

class PaymentSummaryModel {
  final num amountDuePaise;
  final int dueCount;
  final num lifetimeSpentPaise;
  final num thisMonthPaise;
  final int processingCount;
  final int failedCount;
  final num refundedPaise;

  PaymentSummaryModel({
    this.amountDuePaise = 0,
    this.dueCount = 0,
    this.lifetimeSpentPaise = 0,
    this.thisMonthPaise = 0,
    this.processingCount = 0,
    this.failedCount = 0,
    this.refundedPaise = 0,
  });

  num get amountDueRupees => amountDuePaise / 100;
  num get lifetimeSpentRupees => lifetimeSpentPaise / 100;
  num get thisMonthRupees => thisMonthPaise / 100;
  num get refundedRupees => refundedPaise / 100;

  factory PaymentSummaryModel.fromJson(dynamic j) {
    final m = asMap(j);
    return PaymentSummaryModel(
      amountDuePaise: (m['amountDuePaise'] ?? m['pending'] ?? 0) as num,
      dueCount: (m['dueCount'] ?? 0) is int ? m['dueCount'] as int : int.tryParse(m['dueCount']?.toString() ?? '0') ?? 0,
      lifetimeSpentPaise: (m['lifetimeSpentPaise'] ?? m['totalPaid'] ?? m['paid'] ?? 0) as num,
      thisMonthPaise: (m['thisMonthPaise'] ?? 0) as num,
      processingCount: (m['processingCount'] ?? 0) is int ? m['processingCount'] as int : int.tryParse(m['processingCount']?.toString() ?? '0') ?? 0,
      failedCount: (m['failedCount'] ?? 0) is int ? m['failedCount'] as int : int.tryParse(m['failedCount']?.toString() ?? '0') ?? 0,
      refundedPaise: (m['refundedPaise'] ?? m['refunded'] ?? 0) as num,
    );
  }
}

class PaymentReceiptModel {
  final String receiptNumber;
  final String? invoiceHtml;
  final String? invoiceUrl;
  final dynamic issuedAt;

  PaymentReceiptModel({
    required this.receiptNumber,
    this.invoiceHtml,
    this.invoiceUrl,
    this.issuedAt,
  });

  factory PaymentReceiptModel.fromJson(dynamic j) {
    final m = asMap(j);
    return PaymentReceiptModel(
      receiptNumber: str(m['receiptNumber'] ?? m['id']),
      invoiceHtml: m['invoiceHtml']?.toString(),
      invoiceUrl: m['invoiceUrl']?.toString(),
      issuedAt: m['issuedAt'],
    );
  }
}

class PaymentRefundModel {
  final String reason;
  final num grossPaise;
  final num cancellationFeePaise;
  final num netRefundPaise;
  final String status;
  final dynamic createdAt;
  final dynamic expectedCreditBy;

  PaymentRefundModel({
    required this.reason,
    required this.grossPaise,
    required this.cancellationFeePaise,
    required this.netRefundPaise,
    required this.status,
    this.createdAt,
    this.expectedCreditBy,
  });

  num get netRefundRupees => netRefundPaise / 100;

  factory PaymentRefundModel.fromJson(dynamic j) {
    final m = asMap(j);
    return PaymentRefundModel(
      reason: str(m['reason'] ?? 'refund'),
      grossPaise: (m['grossPaise'] ?? 0) as num,
      cancellationFeePaise: (m['cancellationFeePaise'] ?? 0) as num,
      netRefundPaise: (m['netRefundPaise'] ?? 0) as num,
      status: str(m['status'] ?? 'processed'),
      createdAt: m['createdAt'],
      expectedCreditBy: m['expectedCreditBy'],
    );
  }
}

class PaymentAttemptModel {
  final String attemptId;
  final String method;
  final String state;
  final String? failureReason;
  final dynamic createdAt;

  PaymentAttemptModel({
    required this.attemptId,
    required this.method,
    required this.state,
    this.failureReason,
    this.createdAt,
  });

  factory PaymentAttemptModel.fromJson(dynamic j) {
    final m = asMap(j);
    return PaymentAttemptModel(
      attemptId: str(m['attemptId'] ?? m['_id']),
      method: str(m['method'] ?? 'razorpay'),
      state: str(m['state'] ?? 'created'),
      failureReason: m['failureReason']?.toString(),
      createdAt: m['createdAt'],
    );
  }
}

class PaymentModel {
  final String bookingId;
  final String? paymentId;
  final String status;
  final String customerState;
  final String? itemType;
  final num? amount;
  final num? amountPaise;
  final String? method;
  final String? paymentMode;
  final String? txnId;
  final String? providerOrderId;
  final String? providerPaymentId;
  final String? paymentDetailsSummary;
  final bool receiptAvailable;
  final dynamic paidAt;
  final Map<String, dynamic>? liveAttempt;
  final Map<String, dynamic>? failure;
  final Map<String, dynamic>? bookingSummary;
  final List<PaymentAttemptModel> attempts;
  final List<PaymentRefundModel> refunds;

  PaymentModel({
    required this.bookingId,
    this.paymentId,
    required this.status,
    this.customerState = 'not_due',
    this.itemType,
    this.amount,
    this.amountPaise,
    this.method,
    this.paymentMode,
    this.txnId,
    this.providerOrderId,
    this.providerPaymentId,
    this.paymentDetailsSummary,
    this.receiptAvailable = false,
    this.paidAt,
    this.liveAttempt,
    this.failure,
    this.bookingSummary,
    this.attempts = const [],
    this.refunds = const [],
  });

  bool get isPaid => customerState == 'paid' || status.toLowerCase() == 'success' || status.toLowerCase() == 'completed';
  bool get isDue => customerState == 'due' || (status.toLowerCase() == 'pending' && customerState != 'processing');
  bool get isCashDue => customerState == 'cash_due';
  bool get isProcessing => customerState == 'processing';
  bool get isUnderReview => customerState == 'under_review';
  bool get isFailed => customerState == 'failed' || status.toLowerCase() == 'failed';

  factory PaymentModel.fromJson(dynamic j) {
    final m = asMap(j);
    
    // Amount extraction: handle both paise object structure and raw rupee fields
    num? amtInRupees;
    num? amtInPaise;
    if (m['amount'] is Map) {
      final amtMap = m['amount'] as Map;
      amtInPaise = amtMap['totalPaise'] is num ? amtMap['totalPaise'] as num : (amtMap['duePaise'] is num ? amtMap['duePaise'] as num : null);
      if (amtInPaise != null) {
        amtInRupees = amtInPaise / 100;
      }
    } else if (m['amount'] is num) {
      amtInRupees = m['amount'] as num;
    } else if (m['totalAmount'] is num) {
      amtInRupees = m['totalAmount'] as num;
    } else if (m['amountInRupees'] is num) {
      amtInRupees = m['amountInRupees'] as num;
    }

    final custState = str(m['customerState'] ?? (m['status'] == 'success' ? 'paid' : (m['status'] == 'failed' ? 'failed' : 'due')));

    final rawAttempts = m['attempts'] is List ? (m['attempts'] as List).map((e) => PaymentAttemptModel.fromJson(e)).toList() : <PaymentAttemptModel>[];
    final rawRefunds = m['refunds'] is List ? (m['refunds'] as List).map((e) => PaymentRefundModel.fromJson(e)).toList() : <PaymentRefundModel>[];

    return PaymentModel(
      bookingId: str(m['bookingId'] ?? m['booking'] ?? m['_id']),
      paymentId: m['paymentId']?.toString(),
      status: str(m['status'] ?? m['paymentStatus'] ?? 'pending'),
      customerState: custState,
      itemType: m['itemType']?.toString(),
      amount: amtInRupees,
      amountPaise: amtInPaise,
      method: m['paymentMethod']?.toString() ?? m['method']?.toString(),
      paymentMode: m['paymentMode']?.toString(),
      txnId: m['transactionId']?.toString() ?? m['txnId']?.toString() ?? m['providerPaymentId']?.toString(),
      providerOrderId: m['providerOrderId']?.toString(),
      providerPaymentId: m['providerPaymentId']?.toString(),
      paymentDetailsSummary: m['paymentDetailsSummary']?.toString(),
      receiptAvailable: m['receiptAvailable'] == true,
      paidAt: m['paidAt'],
      liveAttempt: m['liveAttempt'] is Map ? Map<String, dynamic>.from(m['liveAttempt'] as Map) : null,
      failure: m['failure'] is Map ? Map<String, dynamic>.from(m['failure'] as Map) : null,
      bookingSummary: m['bookingSummary'] is Map ? Map<String, dynamic>.from(m['bookingSummary'] as Map) : null,
      attempts: rawAttempts,
      refunds: rawRefunds,
    );
  }
}

class QuotationModel {
  final String id;
  final String status;
  final String? title;
  final num? amount;
  final dynamic createdAt;
  final String? quotationNumber;
  final String? quoteRequestId;
  final int revision;
  final dynamic validFrom;
  final dynamic validUntil;
  final String? termsAndConditions;
  final String? adminNotes;
  final String? paymentStatus;
  final Map<String, dynamic>? financialSnapshot;
  final String? productId;
  final String? productName;
  final int? quantity;
  final List<Map<String, dynamic>> items;

  QuotationModel({
    required this.id,
    required this.status,
    this.title,
    this.amount,
    this.createdAt,
    this.quotationNumber,
    this.quoteRequestId,
    this.revision = 1,
    this.validFrom,
    this.validUntil,
    this.termsAndConditions,
    this.adminNotes,
    this.paymentStatus,
    this.financialSnapshot,
    this.productId,
    this.productName,
    this.quantity,
    this.items = const [],
  });

  factory QuotationModel.fromJson(dynamic j) {
    final m = asMap(j);
    final fin = m['financialSnapshot'] is Map ? asMap(m['financialSnapshot']) : null;
    final totalPaise = fin != null && fin['totalAmountPaise'] is num
        ? fin['totalAmountPaise'] as num
        : (m['totalAmountPaise'] is num ? m['totalAmountPaise'] as num : null);
    final amt = totalPaise != null
        ? (totalPaise / 100)
        : (m['amount'] is num ? m['amount'] as num : (m['quotedPrice'] is num ? m['quotedPrice'] as num : null));

    final pRaw = m['productId'];
    final pId = pRaw is Map ? str(pRaw['_id'] ?? pRaw['id']) : (pRaw != null ? str(pRaw) : null);
    final pName = pRaw is Map ? pRaw['productName']?.toString() : null;

    final itemList = <Map<String, dynamic>>[];
    if (m['items'] is List) {
      for (final it in (m['items'] as List)) {
        if (it is Map) itemList.add(asMap(it));
      }
    }

    return QuotationModel(
      id: str(m['_id'] ?? m['id']),
      status: str(m['status'] ?? 'sent'),
      title: (pName ?? m['title'] ?? m['productName'] ?? m['serviceName'])?.toString(),
      amount: amt,
      createdAt: m['createdAt'],
      quotationNumber: m['quotationNumber']?.toString(),
      quoteRequestId: str(m['quoteRequestId'] ?? m['quoteRequest']),
      revision: m['revision'] is num ? (m['revision'] as num).toInt() : 1,
      validFrom: m['validFrom'],
      validUntil: m['validUntil'],
      termsAndConditions: m['termsAndConditions']?.toString(),
      adminNotes: (m['adminNotes'] ?? m['technicianNotes'] ?? m['notes'])?.toString(),
      paymentStatus: m['paymentStatus']?.toString(),
      financialSnapshot: fin,
      productId: pId,
      productName: pName,
      quantity: m['quantity'] is num ? (m['quantity'] as num).toInt() : null,
      items: itemList,
    );
  }
}

class QuotationAcceptResult {
  final List<String> bookingIds;
  final String? paymentGroupId;
  final num? totalAmountPaise;

  QuotationAcceptResult({
    required this.bookingIds,
    this.paymentGroupId,
    this.totalAmountPaise,
  });

  factory QuotationAcceptResult.fromJson(dynamic j) {
    final m = asMap(j);
    final r = m.containsKey('result') ? asMap(m['result']) : m;
    final ids = <String>[];
    if (r['bookingIds'] is List) {
      ids.addAll((r['bookingIds'] as List).map((e) => e.toString()));
    } else if (r['bookingId'] != null) {
      ids.add(r['bookingId'].toString());
    }
    return QuotationAcceptResult(
      bookingIds: ids,
      paymentGroupId: r['paymentGroupId']?.toString(),
      totalAmountPaise: r['totalAmountPaise'] is num
          ? r['totalAmountPaise'] as num
          : (r['amountPaise'] is num ? r['amountPaise'] as num : null),
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
  final String? productId;
  final String? productName;
  final String? productType;
  final String? locationType;
  final String? requestNumber;
  final String? preferredContactMethod;
  final String? addressLine;
  final int? quantity;
  final String? additionalNotes;
  final dynamic createdAt;

  QuoteRequestModel({
    required this.id,
    required this.requirement,
    required this.status,
    this.productId,
    this.productName,
    this.productType,
    this.locationType,
    this.requestNumber,
    this.preferredContactMethod,
    this.addressLine,
    this.quantity,
    this.additionalNotes,
    this.createdAt,
  });

  factory QuoteRequestModel.fromJson(dynamic j) {
    final m = asMap(j);
    final pRaw = m['productId'];
    final pId = pRaw is Map
        ? str(pRaw['_id'] ?? pRaw['id'])
        : (pRaw != null ? str(pRaw) : null);
    final pName = pRaw is Map ? pRaw['productName']?.toString() : null;
    final pType = pRaw is Map ? pRaw['productType']?.toString() : null;

    return QuoteRequestModel(
      id: str(m['_id'] ?? m['id']),
      requirement: str(m['requirementDescription'] ?? m['requirement'] ?? m['description'] ?? (pName != null ? 'Quote for $pName' : 'Product Quote Request')),
      status: str(m['status'] ?? 'quote_requested'),
      productId: pId,
      productName: pName,
      productType: pType,
      locationType: m['locationType']?.toString(),
      requestNumber: m['requestNumber']?.toString(),
      preferredContactMethod: m['preferredContactMethod']?.toString(),
      addressLine: m['address'] is Map ? str(m['address']['addressLine']) : m['addressId']?.toString(),
      quantity: m['quantity'] is num ? (m['quantity'] as num).toInt() : null,
      additionalNotes: m['additionalNotes']?.toString(),
      createdAt: m['createdAt'],
    );
  }
}

class ProductBookingModel {
  final String id;
  final String status;
  final num? amount;
  final num? amountPaise;
  final String? quotationId;
  final String? paymentGroupId;
  final String? productId;
  final String? productName;
  final int? quantity;
  final String? paymentStatus;
  final dynamic createdAt;

  ProductBookingModel({
    required this.id,
    required this.status,
    this.amount,
    this.amountPaise,
    this.quotationId,
    this.paymentGroupId,
    this.productId,
    this.productName,
    this.quantity,
    this.paymentStatus,
    this.createdAt,
  });

  factory ProductBookingModel.fromJson(dynamic j) {
    final m = asMap(j);
    final pRaw = m['productId'];
    final pId = pRaw is Map ? str(pRaw['_id'] ?? pRaw['id']) : (pRaw != null ? str(pRaw) : null);
    final pName = pRaw is Map ? pRaw['productName']?.toString() : (m['productName'] ?? m['title'])?.toString();

    final paise = m['amountPaise'] is num ? m['amountPaise'] as num : null;
    final amt = m['amount'] is num
        ? m['amount'] as num
        : (m['finalAmount'] is num
            ? m['finalAmount'] as num
            : (paise != null ? (paise / 100) : null));

    return ProductBookingModel(
      id: str(m['_id'] ?? m['id']),
      status: str(m['status'] ?? m['bookingStatus'] ?? 'active'),
      amount: amt,
      amountPaise: paise,
      quotationId: str(m['quotationId'] ?? m['quotation']),
      paymentGroupId: m['paymentGroupId']?.toString(),
      productId: pId,
      productName: pName,
      quantity: m['quantity'] is num ? (m['quantity'] as num).toInt() : (m['qty'] is num ? (m['qty'] as num).toInt() : null),
      paymentStatus: str(m['paymentStatus'] ?? 'pending'),
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

class RatingModel {
  final String id;
  final String bookingId;
  final String bookingType; // 'service' or 'product'
  final String? serviceId;
  final String? serviceName;
  final String? productId;
  final String? productName;
  final String? technicianId;
  final String? technicianName;
  final String? userId;
  final int rates;
  final String content;
  final String comment;
  final dynamic createdAt;
  final dynamic updatedAt;
  final double? techAvg;
  final int? techCount;
  final double? svcAvg;
  final int? svcCount;
  final double? prodAvg;
  final int? prodCount;

  RatingModel({
    required this.id,
    required this.bookingId,
    this.bookingType = 'service',
    this.serviceId,
    this.serviceName,
    this.productId,
    this.productName,
    this.technicianId,
    this.technicianName,
    this.userId,
    required this.rates,
    required this.content,
    required this.comment,
    this.createdAt,
    this.updatedAt,
    this.techAvg,
    this.techCount,
    this.svcAvg,
    this.svcCount,
    this.prodAvg,
    this.prodCount,
  });

  static String computeContent(int rate) {
    if (rate >= 4) return 'Excellent';
    if (rate == 3) return 'Good';
    if (rate == 2) return 'Average';
    return 'Below Average';
  }

  factory RatingModel.fromJson(dynamic j) {
    final m = asMap(j);

    // Service ID & Name
    String? sId;
    String? sName;
    if (m['serviceId'] is Map) {
      final sMap = asMap(m['serviceId']);
      sId = str(sMap['_id'] ?? sMap['id']);
      sName = str(sMap['serviceName'] ?? sMap['name'] ?? sMap['title']);
    } else if (m['serviceId'] != null) {
      sId = str(m['serviceId']);
      sName = str(m['serviceName']);
    }

    // Product ID & Name
    String? pId;
    String? pName;
    if (m['productId'] is Map) {
      final pMap = asMap(m['productId']);
      pId = str(pMap['_id'] ?? pMap['id']);
      pName = str(pMap['productName'] ?? pMap['name'] ?? pMap['title']);
    } else if (m['productId'] != null) {
      pId = str(m['productId']);
      pName = str(m['productName']);
    }

    // Technician ID & Name
    String? tId;
    String? tName;
    if (m['technicianId'] is Map) {
      final tMap = asMap(m['technicianId']);
      tId = str(tMap['_id'] ?? tMap['id']);
      if (tMap['userId'] is Map) {
        final uMap = asMap(tMap['userId']);
        tName = str(uMap['username'] ?? uMap['name'] ?? uMap['fname']);
      } else {
        tName = str(tMap['name'] ?? tMap['fname']);
      }
    } else if (m['technicianId'] != null) {
      tId = str(m['technicianId']);
      tName = str(m['technicianName']);
    }

    final int rateVal = m['rates'] is num
        ? (m['rates'] as num).toInt()
        : (int.tryParse(m['rates']?.toString() ?? '5') ?? 5);

    final rawContent = m['content']?.toString();
    final contentVal = (rawContent != null && rawContent.isNotEmpty)
        ? rawContent
        : computeContent(rateVal);

    // Aggregate stats
    double? techA;
    int? techC;
    if (m['technician'] is Map) {
      final tStats = asMap(m['technician']);
      techA = (tStats['avg'] is num) ? (tStats['avg'] as num).toDouble() : null;
      techC = (tStats['count'] is num) ? (tStats['count'] as num).toInt() : null;
    }

    double? svcA;
    int? svcC;
    if (m['service'] is Map) {
      final sStats = asMap(m['service']);
      svcA = (sStats['avg'] is num) ? (sStats['avg'] as num).toDouble() : null;
      svcC = (sStats['count'] is num) ? (sStats['count'] as num).toInt() : null;
    }

    double? prodA;
    int? prodC;
    if (m['product'] is Map) {
      final pStats = asMap(m['product']);
      prodA = (pStats['avg'] is num) ? (pStats['avg'] as num).toDouble() : null;
      prodC = (pStats['count'] is num) ? (pStats['count'] as num).toInt() : null;
    }

    return RatingModel(
      id: str(m['_id'] ?? m['ratingId'] ?? m['id']),
      bookingId: str(m['bookingId'] ?? m['booking']),
      bookingType: str(m['bookingType'], 'service'),
      serviceId: sId,
      serviceName: sName,
      productId: pId,
      productName: pName,
      technicianId: tId,
      technicianName: tName,
      userId: str(m['userId'] is Map ? m['userId']['_id'] : m['userId']),
      rates: rateVal,
      content: contentVal,
      comment: str(m['comment'] ?? m['review']),
      createdAt: m['createdAt'],
      updatedAt: m['updatedAt'],
      techAvg: techA,
      techCount: techC,
      svcAvg: svcA,
      svcCount: svcC,
      prodAvg: prodA,
      prodCount: prodC,
    );
  }
}

class RewardBalanceModel {
  final int availableCoins;
  final int reservedCoins;
  final double rupees;
  final int lifetimeEarned;
  final int lifetimeRedeemed;
  final int lifetimeExpired;
  final int lifetimeReversed;

  const RewardBalanceModel({
    this.availableCoins = 0,
    this.reservedCoins = 0,
    this.rupees = 0.0,
    this.lifetimeEarned = 0,
    this.lifetimeRedeemed = 0,
    this.lifetimeExpired = 0,
    this.lifetimeReversed = 0,
  });

  factory RewardBalanceModel.fromJson(dynamic j) {
    final m = asMap(j);
    final data = m.containsKey('result')
        ? asMap(m['result'])
        : (m.containsKey('data') ? asMap(m['data']) : m);
    final lt = asMap(data['lifetime']);
    final coins = (data['availableCoins'] as num?)?.toInt() ?? 0;
    return RewardBalanceModel(
      availableCoins: coins,
      reservedCoins: (data['reservedCoins'] as num?)?.toInt() ?? 0,
      rupees: (data['rupees'] as num?)?.toDouble() ?? (coins / 100.0),
      lifetimeEarned: (lt['earned'] as num?)?.toInt() ?? 0,
      lifetimeRedeemed: (lt['redeemed'] as num?)?.toInt() ?? 0,
      lifetimeExpired: (lt['expired'] as num?)?.toInt() ?? 0,
      lifetimeReversed: (lt['reversed'] as num?)?.toInt() ?? 0,
    );
  }
}

class RewardTransactionModel {
  final String id;
  final String? bookingId;
  final int coins;
  final double rupees;
  final String type; // EARN, REDEEM, EXPIRE, REVERSAL
  final int balanceAfterCoins;
  final String status;
  final String note;
  final DateTime? createdAt;

  const RewardTransactionModel({
    required this.id,
    this.bookingId,
    required this.coins,
    required this.rupees,
    required this.type,
    required this.balanceAfterCoins,
    required this.status,
    required this.note,
    this.createdAt,
  });

  factory RewardTransactionModel.fromJson(dynamic j) {
    final m = asMap(j);
    final coinVal = (m['coins'] as num?)?.toInt() ?? 0;
    return RewardTransactionModel(
      id: str(m['_id'] ?? m['id']),
      bookingId: m['bookingId']?.toString(),
      coins: coinVal,
      rupees: (m['rupees'] as num?)?.toDouble() ?? (coinVal / 100.0),
      type: str(m['type'], 'EARN').toUpperCase(),
      balanceAfterCoins: (m['balanceAfterCoins'] as num?)?.toInt() ?? 0,
      status: str(m['status'], 'COMPLETED'),
      note: str(m['note']),
      createdAt: m['createdAt'] != null ? DateTime.tryParse(m['createdAt'].toString()) : null,
    );
  }
}
