class VehicleData {
  String registrationNumber;
  String ownerName;
  String make;
  String model;
  String chassisNumber;
  String engineNumber;
  String registrationDate;
  String expiryDate;
  String engineCapacity;
  String modelYear;

  VehicleData({
    this.registrationNumber='',
    this.ownerName='',
    this.make='',
    this.model='',
    this.chassisNumber='',
    this .engineNumber='',
    this.registrationDate='',
    this.expiryDate='',
    this.engineCapacity='',
    this.modelYear='',

  });
}

class VehicleParser {
  static String extractEngineCapacity(String text) {
  final match = RegExp(
    r'ENGINE CAPACITY: *([0-9]+)',
    caseSensitive: false,
  ).firstMatch(text);

  return match?.group(1) ?? '';
}

  static String extractRegistrationNumber(String text){
    final match =RegExp(
      r'\b[A-Z]{2,3}\s*[A-Z]{1,3}\s*[-]?\s*[0-9]{1,4}\b',
    ).firstMatch(text);
    return match?.group(0)??'';
  }

  static String extractModelYear(String text){
    final match=RegExp(
      r'MODEL YEAR: ([0-9]+)',
      caseSensitive: false,

    ).firstMatch(text);
    return match?.group(1) ?? '';
  }

  static String extractChassisNumber(String text){
    final match = RegExp(
      r'CHASSIS NO: ([A-Z0-9-]+)',
      caseSensitive:false,
    ).firstMatch(text);
    return match?.group(1)??'';
  }

  static String extractEngineNumber(String text){
    final match = RegExp(
      r'ENGINE NO: ([A-Z0-9-]+)',
      caseSensitive:false,
    ).firstMatch(text);
    return match?.group(1)??'';
  }

  static VehicleData parse(String text) {
    final lines =text.split('\n');

    String getValue(List<String> labels) {
      for (int i=0; i < lines.length; i++) {
        final line = lines[i].trim();

        for (final label in labels) {
          if (line.toUpperCase().startsWith(label)){
            final parts = line.split(':');

            if (parts.length > 1) {
              return parts.sublist(1).join(':').trim();
            }

            if (i + 1 < lines.length){
              return lines[i+1].trim();
            }
          }
        }
      }

      return '';
    }

    return VehicleData(
      registrationNumber: extractRegistrationNumber(text),



      ownerName: getValue([
        'OWNER',
        'OWNER NAME',
      ]),

      make: getValue([
        'MAKE',
      ]),

      model: getValue([
        'MODEL',
      ]),

      engineNumber: extractEngineNumber(text),
      chassisNumber: extractChassisNumber(text),

      registrationDate: getValue([
        'DATE OF REGISTRATION',
        'REGISTRATION DATE',
      ]),

      expiryDate: getValue([
        'EXPIRY DATE',
        'DATE OF EXPIRY',
      ]),

      engineCapacity:extractEngineCapacity(text),
      modelYear: extractModelYear(text),

    );
  }
}