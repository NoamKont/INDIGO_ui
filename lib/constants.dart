class Constants {
  // Global constants
  static const String lineSeparator = '\n'; // Dart does not use System.getProperty

  static const int refreshRate = 500;

  // Server resources locations
  static const String baseDomain = "indoor-navigation-server.onrender.com";
  static const String port = "8574";

  static const String baseUrl = "https://$baseDomain";
  static const String contextPath = "/IndiGo";
  static const String fullServerPath = "$baseUrl";//$contextPath";
  //static const String fullServerPath = "http://192.168.161.171:8574";

  // API Endpoints
  static const String newFloor = "$fullServerPath/floor/add";
  static const String newBuilding = "$fullServerPath/building/add";

  static const String getBuildingData = "$fullServerPath/building/data/get";

  static const String getAllBuildingsNames = "$fullServerPath/buildings/get";

  static const String getBuildingSvg = "$fullServerPath/building/getSvgDirect";
  //static const String getBuildingRouteSvg = "$fullServerPath/building/svg/route/get";

  static const String getDoorsName = "$fullServerPath/doors/getAll";
  static const String updateDoorsName = "$fullServerPath/building/doors/update";

  static const String calibrateFloorPlan = "$fullServerPath/floor/calibrate";
  static const String getRoute = "$fullServerPath/building/route/get";

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add authentication headers if needed
    // 'Authorization': 'Bearer $token',
  };

}
