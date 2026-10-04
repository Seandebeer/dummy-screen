import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../theme.dart';
import '../widgets/prompt.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final project = store.selectedProject;
    final devices = store.devicesFor(project?.id);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const Text(
          'Dummy Phone',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const Text(
          'PROPS MASTERTOOL',
          style: TextStyle(color: kMuted, fontSize: 11, letterSpacing: 2.2),
        ),
        const SizedBox(height: 22),
        _Section(
          title: 'Projects',
          subtitle: 'Production projects',
          trailing: IconButton(
            tooltip: 'Add project',
            onPressed: () async {
              final name = await promptText(
                context,
                title: 'New project',
                confirm: 'Add',
              );
              if (name == null || name.isEmpty) return;
              store.addProject(name);
            },
            icon: const Icon(Icons.add),
          ),
          child: Column(
            children: [
              if (store.projects.isEmpty)
                const _Empty('Add a project to hold its prop devices.'),
              for (final item in store.projects)
                _ProjectRow(project: item, selected: item.id == project?.id),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Devices',
          subtitle: 'Prop devices & stage sync',
          trailing: IconButton(
            tooltip: 'Add device',
            onPressed: project == null
                ? null
                : () async {
                    final name = await promptText(
                      context,
                      title: 'New device',
                      confirm: 'Add',
                    );
                    if (name == null || name.isEmpty || !context.mounted) {
                      return;
                    }
                    final kind = await _pickKind(context);
                    if (kind == null) return;
                    store.addDevice(
                      projectId: project.id,
                      name: name,
                      kind: kind,
                    );
                  },
            icon: const Icon(Icons.add),
          ),
          child: project == null
              ? const _Empty('Select a project first.')
              : Column(
                  children: [
                    if (devices.isEmpty)
                      const _Empty('No devices on this project yet.'),
                    for (final device in devices) _DeviceRow(device: device),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Saved',
          subtitle: 'Saved marker & screen configurations',
          trailing: IconButton(
            tooltip: 'Save current layout',
            onPressed: () async {
              final name = await promptText(
                context,
                title: 'Save layout',
                confirm: 'Save',
              );
              if (name == null || name.isEmpty) return;
              store.saveLayout(name);
            },
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
          child: Column(
            children: [
              if (store.saved.isEmpty)
                const _Empty('Save a layout from the phone you are using.'),
              for (final layout in store.saved) _SavedRow(layout: layout),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: kMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
    child: Text(text, style: const TextStyle(color: kMuted)),
  );
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project, required this.selected});

  final Project project;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      selected: selected,
      title: Text(project.name),
      leading: Icon(
        selected ? Icons.folder_open : Icons.folder_outlined,
        color: selected ? kAccent : kMuted,
      ),
      onTap: () => store.selectProject(project.id),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'rename') {
            final name = await promptText(
              context,
              title: 'Rename project',
              initial: project.name,
            );
            if (name == null || name.isEmpty) return;
            store.renameProject(project.id, name);
          } else if (value == 'delete') {
            store.deleteProject(project.id);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device});

  final PropDevice device;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final bound = store.boundDeviceId == device.id;
    final target = store.targetDeviceId == device.id;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(device.name),
      subtitle: Text(
        '${_kindLabel(device.kind)} · ${bound ? 'this phone' : 'standby'}${target ? ' · deck target' : ''}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'phone') {
            store.bindDevice(device.id);
            store.openTab(1);
          } else if (value == 'steer') {
            store.setTarget(device.id);
            store.openTab(5);
          } else if (value == 'rename') {
            final name = await promptText(
              context,
              title: 'Rename device',
              initial: device.name,
            );
            if (name == null || name.isEmpty) return;
            store.renameDevice(device.id, name);
          } else if (value == 'delete') {
            store.deleteDevice(device.id);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'phone', child: Text('Use as this phone')),
          PopupMenuItem(value: 'steer', child: Text('Steer from the deck')),
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.layout});

  final SavedLayout layout;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(layout.name),
      subtitle: Text(skinDisplayName(layout.skin)),
      onTap: () {
        final deviceId = store.boundDeviceId ?? store.targetDeviceId;
        if (deviceId == null) return;
        store.applyLayout(layout, deviceId);
      },
      trailing: IconButton(
        tooltip: 'Delete',
        onPressed: () => store.deleteSaved(layout.id),
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}

Future<String?> _pickKind(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Device kind'),
      children: [
        for (final kind in ['phone', 'tablet', 'screen'])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, kind),
            child: Text(_kindLabel(kind)),
          ),
      ],
    ),
  );
}

String _kindLabel(String kind) {
  switch (kind) {
    case 'tablet':
      return 'Tablet';
    case 'screen':
      return 'Screen';
    default:
      return 'Phone';
  }
}
