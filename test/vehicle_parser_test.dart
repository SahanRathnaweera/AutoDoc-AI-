import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/vehicle_parser.dart';

void main() {
  test('Vehicle parser extracts vehicle information', () {
    const text = '''
REGISTRATION NO: WP CAA-1234
OWNER: SINALY FERNANDOPULLE
MAKE: TOYOTA
MODEL: AQUA
MODEL YEAR: 2022
CHASSIS NO: NHP10-123456
ENGINE NO: 1NZ-123456
ENGINE CAPACITY: 1496 CC
DATE OF REGISTRATION: 12/05/2022
EXPIRY DATE: 12/05/2027
''';

    final vehicle = VehicleParser.parse(text);

    expect(vehicle.registrationNumber, 'WP CAA-1234');
    expect(vehicle.ownerName, 'SINALY FERNANDOPULLE');
    expect(vehicle.make, 'TOYOTA');
    expect(vehicle.model, 'AQUA');
    expect(vehicle.modelYear, '2022');
    expect(vehicle.chassisNumber, 'NHP10-123456');
    expect(vehicle.engineNumber, '1NZ-123456');
    expect(vehicle.engineCapacity, '1496');
  });
}