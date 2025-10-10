import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfHelper {
  /// 🔹 Télécharge le fichier depuis Firebase Storage et le renvoie en File
  static Future<File> downloadPdf(String storagePath) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    final url = await ref.getDownloadURL();

    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${ref.name}');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  /// 🔹 Ouvre le fichier PDF (sur iOS, Android, Desktop)
  static Future<void> openPdf(String storagePath) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    final url = await ref.getDownloadURL();
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw Exception("Impossible d'ouvrir le lien PDF");
    }
  }

  /// 🔹 Partage le fichier PDF par mail ou autre app
  static Future<void> sharePdf(String storagePath) async {
    final file = await downloadPdf(storagePath);
    await Share.shareXFiles([XFile(file.path)], text: "Voici le rapport PDF 📄");
  }
}
