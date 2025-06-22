import 'Floor.dart';

class Room {
  final int id;
  final double x;
  final double y;
  String? name;
  Floor? floor;

  Room({required this.id, required this.x, required this.y, this.name, this.floor});

  int get floorId {
    return floor?.id ?? 0; // Return 0 if floor is null
  }

  String get floorName {
    return floor?.name ?? 'Unknown'; // Return 'Unknown' if floor is null
  }

  int get buildingId {
    return floor?.building?.buildingId ?? 0; // Return 0 if building is null
  }

  String get buildingName {
    return floor?.building?.name ?? 'Unknown'; // Return 'Unknown' if building is null
  }
}