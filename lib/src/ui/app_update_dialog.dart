import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_version_status.dart';

/// Builds a fully custom update dialog.
///
/// [mandatory] is `true` when the user must not be able to dismiss it.
/// Call [openStore] from your "Update" button.
typedef AppUpdateDialogBuilder =
    Widget Function(
      BuildContext context,
      AppVersionStatus status,
      bool mandatory,
      Future<bool> Function() openStore,
    );

/// Texts shown by [AppUpdateDialog]. Pass localized strings from your app.
class AppUpdateDialogTexts {
  const AppUpdateDialogTexts({
    this.title = 'Update available',
    this.message,
    this.updateButton = 'Update',
    this.laterButton = 'Later',
  });

  final String title;

  /// Body text. When `null`, a default sentence with both versions is used.
  final String? message;

  final String updateButton;
  final String laterButton;

  /// The body text for [status].
  String messageFor(AppVersionStatus status) {
    final String? custom = message;
    if (custom != null) return custom;
    final String? store = status.storeVersion;
    if (store == null) return 'A new version of the app is available.';
    return 'Version $store is available. You are using ${status.localVersion}.';
  }

  AppUpdateDialogTexts copyWith({
    String? title,
    String? message,
    String? updateButton,
    String? laterButton,
  }) {
    return AppUpdateDialogTexts(
      title: title ?? this.title,
      message: message ?? this.message,
      updateButton: updateButton ?? this.updateButton,
      laterButton: laterButton ?? this.laterButton,
    );
  }
}

/// Default, platform-adaptive update dialog.
///
/// With [mandatory] set, the dialog has no "Later" button and cannot be
/// dismissed with the back gesture; it stays open after the store is opened.
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({
    super.key,
    required this.status,
    this.mandatory = false,
    this.texts = const AppUpdateDialogTexts(),
    this.onUpdate,
    this.onLater,
    this.showReleaseNotes = false,
  });

  final AppVersionStatus status;
  final bool mandatory;
  final AppUpdateDialogTexts texts;

  /// Called when the user taps "Update" (typically opens the store).
  final VoidCallback? onUpdate;

  /// Called when the user taps "Later".
  final VoidCallback? onLater;

  /// Show [AppVersionStatus.releaseNotes] under the message when available.
  final bool showReleaseNotes;

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    final bool cupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final String? notes = status.releaseNotes?.trim();

    Widget action(
      String label,
      VoidCallback onPressed, {
      bool primary = false,
    }) {
      if (cupertino) {
        return CupertinoDialogAction(
          onPressed: onPressed,
          isDefaultAction: primary,
          child: Text(label),
        );
      }
      return primary
          ? FilledButton(onPressed: onPressed, child: Text(label))
          : TextButton(onPressed: onPressed, child: Text(label));
    }

    return PopScope(
      canPop: !mandatory,
      child: AlertDialog.adaptive(
        title: Text(texts.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(texts.messageFor(status)),
              if (showReleaseNotes && notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(notes, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          if (!mandatory)
            action(texts.laterButton, () {
              onLater?.call();
              Navigator.of(context).pop();
            }),
          action(texts.updateButton, () {
            onUpdate?.call();
            if (!mandatory) Navigator.of(context).pop();
          }, primary: true),
        ],
      ),
    );
  }
}
