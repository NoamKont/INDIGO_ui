class Constants {
  // Global constants
  static const String lineSeparator = '\n'; // Dart does not use System.getProperty

  static const int refreshRate = 500;

  // Server resources locations
  static const String baseDomain = "172.20.10.14";
  static const String port = "8574";

  static const String baseUrl = "http://$baseDomain:$port";
  static const String contextPath = "/IndiGo";
  static const String fullServerPath = "$baseUrl$contextPath";

  // API Endpoints
  static const String newBuilding = "$fullServerPath/building/add";

  static const String getAllBuildingsNames = "$fullServerPath/buildings/names/get";
  static const String getBuildingData = "$fullServerPath/building/data/get";

  static const String getBuildingSvg = "$fullServerPath/building/svg/get";
  static const String getBuildingRouteSvg = "$fullServerPath/building/svg/route/get";

  static const String updateDoorsName = "$fullServerPath/building/doors/update";
}
