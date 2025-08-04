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

  static const String getAllFloorsInBuilding = "$fullServerPath/building/getFloors";

  static const String getFloorData = "$fullServerPath/floor/getData";

  static const String getAllBuildingsNames = "$fullServerPath/building/get";

  static const String getFloorSvg = "$fullServerPath/floor/getSvgDirect";

  static const String getDoorsName = "$fullServerPath/floor/getDoors";
  static const String updateDoorsName = "$fullServerPath/floor/updateDoorsNames";

  static const String calibrateFloorPlan = "$fullServerPath/floor/calibrate";
  static const String getRoute = "$fullServerPath/floor/route/get";


  static const String train = "$fullServerPath/floor/scan";

  static const String getGridSvg = "$fullServerPath/floor/getGridSvg";

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add authentication headers if needed
    // 'Authorization': 'Bearer $token',
  };

}
