import 'package:flutter/material.dart';

class DialogHelper extends ChangeNotifier{

  Future<bool> confirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = "Confirmer",
  String cancelText = "Annuler",
  Color confirmColor = Colors.red,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmText, style: TextStyle(color: confirmColor)),
            ),
          ],
        ),
      ) ??
      false;
}

}