class InspectionReport {
  const InspectionReport({
    required this.reportId,
    required this.vehicleName,
    required this.registrationNumber,
    required this.generatedAt,
    required this.currency,
    required this.baseEstimate,
    required this.adjustedEstimate,
    required this.repairAllowance,
    required this.photosAnalyzed,
    required this.findings,
    required this.audioLabel,
    required this.audioNotice,
    required this.valuationNotice,
    required this.voiceSummary,
    this.audioAvailable = true,
    this.visualAnalysisAvailable = true,
    this.visualNotice = '',
    this.valuationAvailable = true,
    this.unavailableComponents = const [],
    this.isSimulated = false,
  });

  factory InspectionReport.fromApiResponse({
    required Map<String, dynamic> response,
    required String make,
    required String model,
    required int year,
    required String registrationNumber,
    DateTime? generatedAt,
  }) {
    final valuation = _asMap(response['valuation'], 'valuation');
    final audio = _asMap(response['audio'], 'audio');
    final damagePhotos = response['damage'];
    if (damagePhotos is! List) {
      throw const FormatException('Inspection response is missing damage data.');
    }

    final findings = <InspectionFinding>[];
    var visualAnalysisAvailable = true;
    var photosAnalyzed = 0;
    String? visualNotice;
    for (final photo in damagePhotos) {
      final photoResult = _asMap(photo, 'damage photo');
      final photoAvailable = photoResult['available'] != false;
      if (photoAvailable) {
        photosAnalyzed++;
      } else {
        visualAnalysisAvailable = false;
        visualNotice ??= _optionalString(photoResult['notice']);
      }
      final imageIndex = _asInt(photoResult['image_index'], 'image_index');
      final detections = photoResult['detections'];
      if (detections is! List) {
        throw const FormatException(
          'Inspection response contains invalid damage detections.',
        );
      }

      for (final detection in detections) {
        final item = _asMap(detection, 'damage finding');
        findings.add(
          InspectionFinding(
            imageIndex: imageIndex,
            label: _asString(item['label'], 'finding label'),
            confidence: _optionalDouble(item['confidence']),
            detail: _optionalString(item['description']) ??
                _optionalString(item['damage_type']),
          ),
        );
      }
    }

    final createdAt = generatedAt ?? DateTime.now();
    final baseEstimate = _optionalDouble(valuation['base_estimate_lkr']);
    final adjustedEstimate = _optionalDouble(
      valuation['adjusted_estimate_lkr'],
    );
    final valuationAvailable =
        valuation['available'] != false &&
        baseEstimate != null &&
        adjustedEstimate != null;
    final audioLabel = _optionalString(audio['predicted_label']);
    final audioAvailable =
        audio['available'] != false && audioLabel != null;
    final unavailable = response['unavailable_components'];

    return InspectionReport(
      reportId: 'AD-${createdAt.millisecondsSinceEpoch}',
      vehicleName: '$year $make $model',
      registrationNumber: registrationNumber,
      generatedAt: createdAt,
      currency: _optionalString(valuation['currency']) ?? 'LKR',
      baseEstimate: baseEstimate,
      adjustedEstimate: adjustedEstimate,
      repairAllowance:
          _optionalDouble(valuation['reviewed_repair_allowance_lkr']) ?? 0,
      photosAnalyzed: photosAnalyzed,
      findings: List.unmodifiable(findings),
      audioLabel: audioAvailable ? audioLabel : 'Unavailable',
      audioAvailable: audioAvailable,
      audioNotice:
          _optionalString(audio['notice']) ??
          'Audio classification was not available.',
      visualAnalysisAvailable: visualAnalysisAvailable,
      visualNotice: visualNotice ?? '',
      valuationAvailable: valuationAvailable,
      valuationNotice:
          _optionalString(valuation['notice']) ??
          'Valuation was not available.',
      voiceSummary: _asString(response['voice_summary'], 'voice summary'),
      unavailableComponents: unavailable is List
          ? List.unmodifiable(unavailable.whereType<String>())
          : const [],
    );
  }

  final String reportId;
  final String vehicleName;
  final String registrationNumber;
  final DateTime generatedAt;
  final String currency;
  final double? baseEstimate;
  final double? adjustedEstimate;
  final double repairAllowance;
  final int photosAnalyzed;
  final List<InspectionFinding> findings;
  final String audioLabel;
  final bool audioAvailable;
  final String audioNotice;
  final bool visualAnalysisAvailable;
  final String visualNotice;
  final bool valuationAvailable;
  final String valuationNotice;
  final String voiceSummary;
  final List<String> unavailableComponents;
  final bool isSimulated;

  bool get isPartial =>
      !audioAvailable || !visualAnalysisAvailable || !valuationAvailable;

  String get generatedDate {
    final date = generatedAt.toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String get adjustedEstimateLabel => adjustedEstimate == null
      ? 'Unavailable'
      : _formatCurrency(adjustedEstimate!);

  String get baseEstimateLabel =>
      baseEstimate == null ? 'Unavailable' : _formatCurrency(baseEstimate!);

  String get repairAllowanceLabel => _formatCurrency(repairAllowance);

  String get damageSummary =>
      '${findings.length} ${findings.length == 1 ? 'finding' : 'findings'}';

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final digits = parts.first;
    final formatted = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write(',');
      }
      formatted.write(digits[index]);
    }

    final decimals = parts.last == '00' ? '' : '.${parts.last}';
    return '$currency $formatted$decimals';
  }

  static Map<String, dynamic> _asMap(Object? value, String field) {
    if (value is Map<String, dynamic>) return value;
    throw FormatException('Inspection response contains invalid $field data.');
  }

  static String _asString(Object? value, String field) {
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Inspection response is missing $field.');
  }

  static int _asInt(Object? value, String field) {
    if (value is int) return value;
    throw FormatException('Inspection response contains invalid $field.');
  }

  static double? _optionalDouble(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;

  static String? _optionalString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}

class InspectionFinding {
  const InspectionFinding({
    required this.imageIndex,
    required this.label,
    required this.confidence,
    required this.detail,
  });

  final int imageIndex;
  final String label;
  final double? confidence;
  final String? detail;

  String get confidenceLabel =>
      confidence == null ? 'Confidence not provided' : '${(confidence! * 100).round()}% confidence';
}
