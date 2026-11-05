class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.year,
    required this.price,
    required this.healthScore,
    required this.location,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final int year;
  final int price;
  final int healthScore;
  final String location;
  final ColorValue color;
  final String icon;
}

class ColorValue {
  const ColorValue(this.value);

  final int value;
}

const demoVehicles = [
  Vehicle(
    id: 'tesla-model-3',
    name: 'Tesla Model 3',
    year: 2019,
    price: 25500,
    healthScore: 92,
    location: 'Colombo 03',
    color: ColorValue(0xffdbeafe),
    icon: 'TESLA',
  ),
  Vehicle(
    id: 'toyota-prius',
    name: 'Toyota Prius',
    year: 2020,
    price: 28750,
    healthScore: 88,
    location: 'Kandy',
    color: ColorValue(0xffe5e7eb),
    icon: 'PRIUS',
  ),
  Vehicle(
    id: 'honda-vitz',
    name: 'Honda Vitz',
    year: 2018,
    price: 18400,
    healthScore: 84,
    location: 'Nugegoda',
    color: ColorValue(0xffd1fae5),
    icon: 'VITZ',
  ),
];
