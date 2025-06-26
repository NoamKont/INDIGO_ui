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

  // API Endpoints
  static const String newFloor = "$fullServerPath/building/add";

  static const String getBuildingData = "$fullServerPath/building/data/get";


  static const String getAllBuildingsNames = "$fullServerPath/buildings/get";

  static const String getBuildingSvg = "$fullServerPath/building/getSvgDirect";
  static const String getBuildingRouteSvg = "$fullServerPath/building/svg/route/get";

  static const String updateDoorsName = "$fullServerPath/building/doors/update";
  static const String getDoorsName = "$fullServerPath/building/doors";

  static const String calibrateFloorPlan = "$fullServerPath/building/add2";
  static const String getRoute = "$fullServerPath/building/route/get";
}
