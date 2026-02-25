import 'package:get/get.dart';
import '../controllers/cv_analysis_controller.dart';

class CvAnalysisBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CvAnalysisController(maxPdfMb: 3));
  }
}
