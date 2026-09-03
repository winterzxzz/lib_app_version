import 'package:flutter/material.dart';
import 'package:lib_app_version/lib_app_version.dart';

void main() {
  // Optional. Without it the running app's own bundle id / application id is
  // used. A numeric iosId gives a store link even when the lookup fails.
  AppVersion.init(
    // androidId: 'com.plant.identification.care',
    // iosId: '6762586391',
    // iosCountry: 'vn',
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'lib_app_version example',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  LocalAppInfo? _local;
  AppVersionStatus? _status;
  bool _busy = false;
  bool _simulateUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadLocal();
    // Typical usage: check once the first screen is up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppVersion.showUpdateDialogIfNeeded(context);
    });
  }

  Future<void> _loadLocal() async {
    final LocalAppInfo local = await AppVersion.getLocalInfo();
    if (mounted) setState(() => _local = local);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() => _run(() async {
    final AppVersionStatus status = await AppVersion.check(refresh: true);
    if (mounted) setState(() => _status = status);
  });

  Future<void> _showDialog({bool force = false}) => _run(() async {
    final AppVersionStatus status = await AppVersion.showUpdateDialogIfNeeded(
      context,
      force: force,
      showReleaseNotes: true,
    );
    if (mounted) setState(() => _status = status);
  });

  void _toggleSimulation(bool value) {
    setState(() => _simulateUpdate = value);
    // Re-configure the shared checker. `forceStoreVersion` pretends the store
    // has version 99.0.0 so the dialog can be tried without publishing.
    AppVersion.init(forceStoreVersion: value ? '99.0.0' : null);
  }

  @override
  Widget build(BuildContext context) {
    final LocalAppInfo? local = _local;
    final AppVersionStatus? status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('lib_app_version')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Section(
            title: 'This build',
            rows: <MapEntry<String, String>>[
              MapEntry('Version', local?.version ?? '...'),
              MapEntry('Build', local?.buildNumber ?? '...'),
              MapEntry('Package', local?.packageName ?? '...'),
              MapEntry('Install source', local?.installSource.name ?? '...'),
              MapEntry('TestFlight', '${local?.isTestFlight ?? '...'}'),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Store',
            rows: <MapEntry<String, String>>[
              MapEntry('Store version', status?.storeVersion ?? '-'),
              MapEntry(
                'Update available',
                '${status?.isUpdateAvailable ?? '-'}',
              ),
              MapEntry('Update type', status?.updateType.name ?? '-'),
              MapEntry('Ahead of store', '${status?.isAheadOfStore ?? '-'}'),
              MapEntry('Store URL', status?.storeUrl ?? '-'),
              MapEntry('Error', status?.error?.toString() ?? '-'),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Simulate a newer store version (99.0.0)'),
            value: _simulateUpdate,
            onChanged: _toggleSimulation,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _check,
            child: const Text('Check now'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _busy ? null : () => _showDialog(),
            child: const Text('Show update dialog if needed'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _busy ? null : () => _showDialog(force: true),
            child: const Text('Show FORCE update dialog if needed'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => _run(AppVersion.openStore),
            child: const Text('Open store'),
          ),
          if (_busy) ...<Widget>[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final MapEntry<String, String> row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(width: 130, child: Text(row.key)),
                    Expanded(child: SelectableText(row.value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
