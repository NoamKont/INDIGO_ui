import 'package:file_picker/file_picker.dart';

class NewBuildingService {

  Future<PlatformFile?> pickDwgFile() async {
    final result = await FilePicker.platform.pickFiles(
    );
    if (result != null && result.files.isNotEmpty) {
      return result.files.first;
    }
    return null;
  }


}