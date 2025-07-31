class Building {
  final String name;
  final String city;
  final String address;
  final int buildingId;
  final List<String> floorList = [];
  int numberOfFloors = 5;

  Building({required this.name,required this.city,required this.address, required this.buildingId,});
}