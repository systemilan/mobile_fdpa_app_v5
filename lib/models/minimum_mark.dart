class MinimumMarkSet {
  final String id;
  final String displayName;
  final String? description;
  final String? dateStart;
  final String? dateEnd;
  final String? location;
  final String? fileUrl;
  final String? fileType;
  final String? updatedAt;

  const MinimumMarkSet({
    required this.id,
    required this.displayName,
    this.description,
    this.dateStart,
    this.dateEnd,
    this.location,
    this.fileUrl,
    this.fileType,
    this.updatedAt,
  });

  factory MinimumMarkSet.fromJson(Map<String, dynamic> json) {
    return MinimumMarkSet(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? '',
      description: json['description'] as String?,
      dateStart: json['dateStart'] as String?,
      dateEnd: json['dateEnd'] as String?,
      location: json['location'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileType: json['fileType'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

class MinimumMarkTest {
  final String id;
  final String officialName;
  final String? commonName;
  final String? type;

  const MinimumMarkTest({
    required this.id,
    required this.officialName,
    this.commonName,
    this.type,
  });

  factory MinimumMarkTest.fromJson(Map<String, dynamic> json) {
    return MinimumMarkTest(
      id: json['id'] as String,
      officialName: json['officialName'] as String? ?? '',
      commonName: json['commonName'] as String?,
      type: json['type'] as String?,
    );
  }
}

class MinimumMark {
  final String id;
  final MinimumMarkTest test;
  final String? varones;
  final String? damas;
  final int rowOrder;

  const MinimumMark({
    required this.id,
    required this.test,
    this.varones,
    this.damas,
    required this.rowOrder,
  });

  factory MinimumMark.fromJson(Map<String, dynamic> json) {
    return MinimumMark(
      id: json['id'] as String,
      test: MinimumMarkTest.fromJson(json['test'] as Map<String, dynamic>),
      varones: json['varones'] as String?,
      damas: json['damas'] as String?,
      rowOrder: json['rowOrder'] as int? ?? 0,
    );
  }
}

class MinimumMarkDetail extends MinimumMarkSet {
  final List<MinimumMark> marks;

  const MinimumMarkDetail({
    required super.id,
    required super.displayName,
    super.description,
    super.dateStart,
    super.dateEnd,
    super.location,
    super.fileUrl,
    super.fileType,
    super.updatedAt,
    required this.marks,
  });

  factory MinimumMarkDetail.fromJson(Map<String, dynamic> json) {
    final marksList = (json['marks'] as List<dynamic>? ?? [])
        .map((m) => MinimumMark.fromJson(m as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.rowOrder.compareTo(b.rowOrder));

    return MinimumMarkDetail(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? '',
      description: json['description'] as String?,
      dateStart: json['dateStart'] as String?,
      dateEnd: json['dateEnd'] as String?,
      location: json['location'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileType: json['fileType'] as String?,
      updatedAt: json['updatedAt'] as String?,
      marks: marksList,
    );
  }
}
