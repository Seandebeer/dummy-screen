import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../deck/chrome.dart';
import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../theme.dart';
import '../widgets/prompt.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _projectsOpen = false;
  bool _devicesOpen = true;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final palette = paletteFor(store.appTheme);
    final project = store.selectedProject;
    return GridFill(
      palette: palette,
      child: Column(
        children: [
          _Header(palette: palette),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      children: [
                        _HomeSection(
                          palette: palette,
                          icon: Icons.movie_creation_outlined,
                          title: 'Projects',
                          subtitle: 'Production projects',
                          open: _projectsOpen,
                          onToggle: () =>
                              setState(() => _projectsOpen = !_projectsOpen),
                          child: _ProjectsBody(
                            palette: palette,
                            onPicked: () => setState(() => _devicesOpen = true),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _HomeSection(
                          palette: palette,
                          icon: Icons.phone_android,
                          title: 'Devices',
                          subtitle: 'Prop devices & stage sync',
                          open: _devicesOpen,
                          onToggle: () =>
                              setState(() => _devicesOpen = !_devicesOpen),
                          child: _DevicesBody(
                            palette: palette,
                            project: project,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _HomeSection(
                          palette: palette,
                          icon: Icons.bookmark_border,
                          title: 'Saved',
                          subtitle: 'Saved marker & screen configurations',
                          child: _SavedBody(palette: palette),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.palette});

  final DeckPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            _Brand(ink: palette.ink),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: IconButton(
                  tooltip: 'Profile & saved layouts',
                  onPressed: () => showProfileSheet(context),
                  icon: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kAccent.withValues(alpha: 0.1),
                      border: Border.all(color: kAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.person_outline, color: kAccent, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Dummy Screen',
          image: true,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0, 0, 0, 0, 255,
                0, 0, 0, 0, 255,
                0, 0, 0, 0, 255,
                0.2126, 0.7152, 0.0722, 0, 0,
              ]),
              child: Image.asset(
                'assets/brand/dummy_screen_logo.jpg',
                key: const Key('app-logo'),
                height: 52,
                excludeFromSemantics: true,
                filterQuality: FilterQuality.high,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 36, top: 2),
          child: Text(
            'PROPS MASTERTOOL',
            style: TextStyle(
              color: ink,
              fontSize: 8,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.open = false,
    this.onToggle,
  });

  final DeckPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool open;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 28, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kAccent.withValues(alpha: 0.2),
                          kAccent.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(color: kAccent.withValues(alpha: 0.2)),
                    ),
                    child: Icon(icon, color: kAccent, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(color: palette.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    color: palette.muted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: palette.line.withValues(alpha: 0.6))),
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _ProjectsBody extends StatelessWidget {
  const _ProjectsBody({required this.palette, required this.onPicked});

  final DeckPalette palette;
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final ordered = [...store.projects]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _IconTile(icon: Icons.account_tree_outlined, color: kAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Projects', style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700)),
                    Text(
                      '${ordered.length} active',
                      style: TextStyle(color: palette.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _RoundAdd(
                color: kAccent,
                onTap: () => _addProject(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ordered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No projects yet - add one above.',
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: store.reorderProjects,
              children: [
                for (var i = 0; i < ordered.length; i++)
                  _ProjectTile(
                    key: ValueKey(ordered[i].id),
                    palette: palette,
                    project: ordered[i],
                    index: i,
                    selected: ordered[i].id == store.selectedProjectId,
                    onPicked: onPicked,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _addProject(BuildContext context) async {
    final store = StoreScope.of(context);
    final name = await promptText(context, title: 'New project', confirm: 'Add project');
    if (name == null || name.trim().isEmpty) return;
    store.addProject(name);
    onPicked();
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    super.key,
    required this.palette,
    required this.project,
    required this.index,
    required this.selected,
    required this.onPicked,
  });

  final DeckPalette palette;
  final Project project;
  final int index;
  final bool selected;
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: palette.secondary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_indicator, size: 16, color: palette.muted),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (selected) {
                      store.selectProject('');
                    } else {
                      store.selectProject(project.id);
                      onPicked();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: selected ? kAccent : kAccent.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            project.name,
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 14,
                              backgroundColor: selected ? kAccent.withValues(alpha: 0.1) : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Delete project',
                onPressed: () => _confirmDelete(context),
                icon: Icon(Icons.delete_outline, size: 16, color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final store = StoreScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${project.name}?'),
        content: const Text(
          "This can't be undone. Its devices will be removed too - layouts saved as favourites stay in Saved.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) store.deleteProject(project.id);
  }
}

class _DevicesBody extends StatelessWidget {
  const _DevicesBody({required this.palette, required this.project});

  final DeckPalette palette;
  final Project? project;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final devices = project == null
        ? const <PropDevice>[]
        : (store.devicesFor(project!.id)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _IconTile(
                icon: project == null ? Icons.phone_android : Icons.folder_outlined,
                color: kSignal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project?.name ?? 'Devices',
                      style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      project == null
                          ? ''
                          : '${devices.length} ${devices.length == 1 ? 'device' : 'devices'}',
                      style: TextStyle(color: palette.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (project != null)
                _RoundAdd(color: kSignal, onTap: () => _addDevice(context, project!)),
            ],
          ),
          const SizedBox(height: 8),
          if (project == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'Add or select a project to view its devices',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            )
          else if (devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No devices linked to ${project!.name} yet - add one above.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (from, to) => store.reorderDevices(project!.id, from, to),
              children: [
                for (var i = 0; i < devices.length; i++)
                  _DeviceTile(
                    key: ValueKey(devices[i].id),
                    palette: palette,
                    device: devices[i],
                    index: i,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _addDevice(BuildContext context, Project project) async {
    final store = StoreScope.of(context);
    final result = await showDialog<_NewDevice>(
      context: context,
      builder: (context) => _AddDeviceDialog(palette: palette),
    );
    if (result == null) return;
    store.addDevice(projectId: project.id, name: result.name, kind: result.kind);
    PropDevice? created;
    for (final device in store.devices.reversed) {
      if (device.name == result.name && device.projectId == project.id) {
        created = device;
        break;
      }
    }
    if (created == null) return;
    store.updateDevice(
      created.id,
      (device) => device.copyWith(
        make: result.make,
        model: result.model,
        colour: result.colour,
        serial: result.serial,
        photo: result.photo,
      ),
    );
  }
}

class _NewDevice {
  const _NewDevice({
    required this.name,
    required this.kind,
    required this.make,
    required this.model,
    required this.colour,
    required this.serial,
    required this.photo,
  });

  final String name;
  final String kind;
  final String make;
  final String model;
  final String colour;
  final String serial;
  final String photo;
}

class _AddDeviceDialog extends StatefulWidget {
  const _AddDeviceDialog({required this.palette});

  final DeckPalette palette;

  @override
  State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _name = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _colour = TextEditingController();
  final _serial = TextEditingController();
  String _kind = 'phone';
  String _photo = '';

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _make.dispose();
    _model.dispose();
    _colour.dispose();
    _serial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return AlertDialog(
      backgroundColor: palette.surface,
      title: Text('Add device', style: TextStyle(color: palette.ink)),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _name, decoration: deckField(palette, 'New device name')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _kind,
                decoration: deckField(palette, 'Kind'),
                dropdownColor: palette.surface,
                items: const [
                  DropdownMenuItem(value: 'phone', child: Text('Phone')),
                  DropdownMenuItem(value: 'tablet', child: Text('Tablet')),
                  DropdownMenuItem(value: 'computer', child: Text('Computer')),
                  DropdownMenuItem(value: 'tv', child: Text('Smart TV')),
                  DropdownMenuItem(value: 'console', child: Text('Game console')),
                  DropdownMenuItem(value: 'atm', child: Text('ATM')),
                  DropdownMenuItem(value: 'cctv', child: Text('CCTV')),
                  DropdownMenuItem(value: 'smarthome', child: Text('Smart home')),
                  DropdownMenuItem(value: 'screen', child: Text('Screen')),
                  DropdownMenuItem(value: 'remote', child: Text('Remote')),
                ],
                onChanged: (value) => setState(() => _kind = value ?? 'phone'),
              ),
              const SizedBox(height: 8),
              TextField(controller: _make, decoration: deckField(palette, 'Make (e.g. Apple)')),
              const SizedBox(height: 8),
              TextField(controller: _model, decoration: deckField(palette, 'Model (e.g. iPhone 1)')),
              const SizedBox(height: 8),
              TextField(controller: _colour, decoration: deckField(palette, 'Colour')),
              const SizedBox(height: 8),
              TextField(controller: _serial, decoration: deckField(palette, 'Serial number')),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final file = await FilePicker.pickFile(type: FileType.image);
                    if (file == null) return;
                    final path = await persistPickedImage(file);
                    if (path != null && mounted) setState(() => _photo = path);
                  },
                  icon: const Icon(Icons.image_outlined, size: 16),
                  label: Text(_photo.isEmpty ? 'Upload photo' : 'Replace photo'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _name.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  _NewDevice(
                    name: _name.text.trim(),
                    kind: _kind,
                    make: _make.text.trim(),
                    model: _model.text.trim(),
                    colour: _colour.text.trim(),
                    serial: _serial.text.trim(),
                    photo: _photo,
                  ),
                ),
          style: FilledButton.styleFrom(backgroundColor: kSignal, foregroundColor: Colors.black),
          child: const Text('Add device'),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatefulWidget {
  const _DeviceTile({
    super.key,
    required this.palette,
    required this.device,
    required this.index,
  });

  final DeckPalette palette;
  final PropDevice device;
  final int index;

  @override
  State<_DeviceTile> createState() => _DeviceTileState();
}

class _DeviceTileState extends State<_DeviceTile> {
  bool _details = false;
  bool _folder = false;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final device = widget.device;
    final palette = widget.palette;
    final meta = [device.make, device.model, device.colour].where((part) => part.isNotEmpty).join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: palette.secondary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Column(
            children: [
              Row(
                children: [
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: Icon(Icons.drag_indicator, size: 16, color: palette.muted),
                  ),
                  IconButton(
                    tooltip: 'Toggle online/offline',
                    onPressed: () => store.updateDevice(
                      device.id,
                      (current) => current.copyWith(
                        status: current.online ? 'offline' : 'online',
                      ),
                    ),
                    icon: Icon(
                      Icons.circle,
                      size: 10,
                      color: device.online ? kSignal : palette.muted.withValues(alpha: 0.5),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        store.bindDevice(device.id);
                        store.openTab(1);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.name, style: TextStyle(color: palette.ink, fontSize: 14)),
                          Text(
                            '${_kindLabel(device.kind)}${meta.isEmpty ? '' : ' · $meta'}',
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 10,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Saved screens & markers',
                    onPressed: () => setState(() => _folder = !_folder),
                    icon: Icon(Icons.folder_outlined, size: 16, color: _folder ? kAccent : palette.muted),
                  ),
                  IconButton(
                    tooltip: 'Device info',
                    onPressed: () => setState(() => _details = !_details),
                    icon: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: device.make.isNotEmpty || device.photo.isNotEmpty ? kSignal : palette.muted,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete device',
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete ${device.name}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) store.deleteDevice(device.id);
                    },
                    icon: Icon(Icons.delete_outline, size: 16, color: palette.muted),
                  ),
                ],
              ),
              if (_details) _Details(palette: palette, device: device),
              if (_folder) _Folder(palette: palette, device: device),
            ],
          ),
        ),
      ),
    );
  }
}

class _Details extends StatefulWidget {
  const _Details({required this.palette, required this.device});

  final DeckPalette palette;
  final PropDevice device;

  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  late final TextEditingController _name;
  late final TextEditingController _make;
  late final TextEditingController _model;
  late final TextEditingController _colour;
  late final TextEditingController _serial;
  late String _photo;

  @override
  void initState() {
    super.initState();
    final device = widget.device;
    _name = TextEditingController(text: device.name);
    _make = TextEditingController(text: device.make);
    _model = TextEditingController(text: device.model);
    _colour = TextEditingController(text: device.colour);
    _serial = TextEditingController(text: device.serial);
    _photo = device.photo;
  }

  @override
  void dispose() {
    _name.dispose();
    _make.dispose();
    _model.dispose();
    _colour.dispose();
    _serial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          TextField(controller: _name, decoration: deckField(palette, 'Device name')),
          const SizedBox(height: 8),
          TextField(controller: _make, decoration: deckField(palette, 'Make (e.g. Apple)')),
          const SizedBox(height: 8),
          TextField(controller: _model, decoration: deckField(palette, 'Model (e.g. iPhone 14)')),
          const SizedBox(height: 8),
          TextField(controller: _colour, decoration: deckField(palette, 'Colour')),
          const SizedBox(height: 8),
          TextField(controller: _serial, decoration: deckField(palette, 'Serial number')),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kSignal, foregroundColor: Colors.black),
              onPressed: () {
                StoreScope.of(context).updateDevice(
                  widget.device.id,
                  (device) => device.copyWith(
                    name: _name.text.trim().isEmpty ? device.name : _name.text.trim(),
                    make: _make.text.trim(),
                    model: _model.text.trim(),
                    colour: _colour.text.trim(),
                    serial: _serial.text.trim(),
                    photo: _photo,
                  ),
                );
              },
              child: const Text('Save details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Folder extends StatelessWidget {
  const _Folder({required this.palette, required this.device});

  final DeckPalette palette;
  final PropDevice device;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final mine = store.saved.where(
      (item) =>
          item.deviceId == device.id &&
          (item.kind == 'screen' || item.kind == 'markers'),
    );
    if (mine.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'Nothing saved to ${device.name} yet - screens and marker layouts saved to this device appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted, fontSize: 11),
        ),
      );
    }
    return Column(
      children: [
        for (final item in mine)
          ListTile(
            dense: true,
            leading: Icon(
              item.kind == 'markers' ? Icons.my_location : Icons.monitor,
              size: 16,
              color: palette.muted,
            ),
            title: Text(item.name, style: TextStyle(color: palette.ink, fontSize: 13)),
            subtitle: Text(
              item.kind == 'markers' ? 'UI MARKERS' : 'SCREEN',
              style: TextStyle(color: palette.muted, fontSize: 9, letterSpacing: 0.8),
            ),
            onTap: () => store.applyLayout(item, device.id),
            trailing: IconButton(
              onPressed: () => store.deleteSaved(item.id),
              icon: const Icon(Icons.delete_outline, size: 16),
            ),
          ),
      ],
    );
  }
}

class _SavedBody extends StatefulWidget {
  const _SavedBody({required this.palette});

  final DeckPalette palette;

  @override
  State<_SavedBody> createState() => _SavedBodyState();
}

class _SavedBodyState extends State<_SavedBody> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final palette = widget.palette;
    const categories = [
      'All',
      'OS',
      'UI Markers',
      'Key Screens',
      'Socials',
      'Websites',
      'Apps',
    ];
    final favourites = store.saved.where((item) => item.deviceId.isEmpty).toList();
    final visible = favourites.where(
      (item) => _category == 'All' || item.savedCategory == _category,
    );
    return Column(
      children: [
        Row(
          children: [
            Text(
              'CATEGORY',
              style: TextStyle(color: palette.muted, fontSize: 10, letterSpacing: 1.1),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _category,
              dropdownColor: palette.surface,
              style: TextStyle(color: palette.ink, fontSize: 12),
              underline: const SizedBox.shrink(),
              items: [
                for (final category in categories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) => setState(() => _category = value ?? 'All'),
            ),
          ],
        ),
        if (store.saved.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Nothing saved yet - save marker setups, key screens, social pages or websites.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          )
        else if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Nothing in this category yet.',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          )
        else
          for (final item in visible)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_savedIcon(item), color: palette.muted, size: 16),
              title: Text(item.name, style: TextStyle(color: palette.ink, fontSize: 14)),
              subtitle: Text(
                item.savedCategory.toUpperCase(),
                style: TextStyle(color: palette.muted, fontSize: 10, letterSpacing: 0.8),
              ),
              onTap: () {
                final deviceId = store.boundDeviceId ?? store.targetDeviceId;
                if (deviceId == null && item.kind == 'os') return;
                store.applyLayout(item, deviceId ?? '');
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.kind == 'os')
                    TextButton(
                      onPressed: () => _assign(context, item),
                      child: const Text('Assign'),
                    ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => store.deleteSaved(item.id),
                    icon: const Icon(Icons.delete_outline, size: 16),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Future<void> _assign(BuildContext context, SavedLayout layout) async {
    final store = StoreScope.of(context);
    if (store.activeDevices.isEmpty) return;
    final id = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign to device'),
        children: [
          for (final device in store.activeDevices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, device.id),
              child: Text(device.name),
            ),
        ],
      ),
    );
    if (id == null) return;
    store.applyLayout(layout, id);
    store.bindDevice(id);
  }
}

IconData _savedIcon(SavedLayout item) {
  switch (item.kind) {
    case 'os':
      return Icons.smartphone;
    case 'markers':
      return Icons.my_location;
    case 'screen':
      return Icons.monitor;
    default:
      return Icons.apps;
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _RoundAdd extends StatelessWidget {
  const _RoundAdd({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Add',
      onPressed: onTap,
      icon: Icon(Icons.add, color: color, size: 18),
    );
  }
}

String _kindLabel(String kind) {
  switch (kind) {
    case 'tablet':
      return 'Tablet';
    case 'computer':
      return 'Computer';
    case 'tv':
      return 'Smart TV';
    case 'console':
      return 'Game console';
    case 'atm':
      return 'ATM';
    case 'cctv':
      return 'CCTV';
    case 'smarthome':
      return 'Smart home';
    case 'screen':
      return 'Screen';
    case 'remote':
      return 'Remote';
    default:
      return 'Phone';
  }
}

void showProfileSheet(BuildContext context) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Profile',
    pageBuilder: (context, _, _) {
      final width = MediaQuery.sizeOf(context).width;
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          child: SizedBox(
            width: width * 0.85,
            height: double.infinity,
            child: const _ProfileSheet(),
          ),
        ),
      );
    },
  );
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _title;

  @override
  void initState() {
    super.initState();
    final store = StoreScope.of(context);
    _name = TextEditingController(text: store.operatorName);
    _title = TextEditingController(text: store.operatorTitle);
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final palette = paletteFor(store.appTheme);
    final layouts = store.saved.where((item) => item.kind == 'os' && item.deviceId.isEmpty);
    return ColoredBox(
      color: palette.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text('Profile', style: TextStyle(color: palette.ink, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: deckField(palette, 'Name'),
            onSubmitted: (value) => store.setOperator(name: value),
          ),
          const SizedBox(height: 8),
          Text(
            'DESIGNATION / TITLE',
            style: TextStyle(color: palette.muted, fontSize: 10, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _title,
            decoration: deckField(palette, 'e.g. Prop Master'),
            onSubmitted: (value) => store.setOperator(title: value),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved on this device. There is no cloud sign-in.',
            style: TextStyle(color: palette.muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          for (final layout in layouts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(layout.name),
              subtitle: Text(skinDisplayName(layout.skin)),
              trailing: TextButton(
                onPressed: () {
                  final id = store.boundDeviceId ?? store.devices.firstOrNull?.id;
                  if (id == null) return;
                  store.applyLayout(layout, id);
                  store.openTab(1);
                  Navigator.pop(context);
                },
                child: const Text('Load'),
              ),
            ),
          const SizedBox(height: 18),
          Text('Settings', style: TextStyle(color: palette.ink, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('App theme', style: TextStyle(color: palette.ink)),
          Text('Colours for the whole control app', style: TextStyle(color: palette.muted, fontSize: 11)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in const [('black', 'Black'), ('grey', 'Grey'), ('white', 'Cream')])
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: store.appTheme == entry.$1,
                  onSelected: (_) => store.setAppTheme(entry.$1),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('App language', style: TextStyle(color: palette.ink)),
          Text('Interface language preference', style: TextStyle(color: palette.muted, fontSize: 11)),
          DropdownButton<String>(
            value: store.appLanguage,
            dropdownColor: palette.surface,
            items: [
              for (final language in kAppLanguages)
                DropdownMenuItem(value: language.code, child: Text(language.native)),
            ],
            onChanged: (value) {
              if (value != null) store.setAppLanguage(value);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tutorial'),
            subtitle: const Text('Guided walkthrough of the apps, step by step'),
            trailing: OutlinedButton(onPressed: () => _tutorial(context), child: const Text('Start')),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Support'),
            subtitle: const Text('Send a note about this build'),
            trailing: OutlinedButton(onPressed: () => _support(context), child: const Text('Open')),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Report a bug'),
            subtitle: const Text('Something not working? Send a report'),
            trailing: OutlinedButton(onPressed: () => _bug(context), child: const Text('Report')),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Share App'),
            subtitle: const Text('Send Dummy Screen to the rest of the crew'),
            trailing: OutlinedButton(
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(
                    text: 'Dummy Screen - coming soon to the App Store and Google Play',
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied - store links coming soon')),
                  );
                }
              },
              child: const Text('Share'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _tutorial(BuildContext context) {
    const steps = [
      ('Create a project', 'Open the Projects panel and create your production. Devices, screens and layouts are all organised per project.'),
      ('Add your devices', "With a project selected, add the prop hardware you'll be using - phones, tablets and screens, with make, model and colour."),
      ('Design the mock OS', 'Tap a device to open the OS and build its home screen: apps, wallpaper, clock and lock behaviour. Save it back to the device.'),
      ('Save & reuse setups', 'Save screens and layouts to favourites or straight to a device, then reopen or assign them from the Saved panel.'),
      ('Set up the VFX stage', 'Open the VFX stage for chroma screens and tracking markers. Pick a colour, arrange the markers, then lock - three fingers to unlock.'),
      ('Number UI markers', 'In the mock OS, the UI Markers app lays out a numbered grid - tap buttons in the order the actor should press them.'),
      ('Run it from Control', 'Link the prop screen and trigger calls, alarms and messages live from the control deck during the take.'),
    ];
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tutorial'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A guided walkthrough of Dummy Screen - follow these steps in order'),
                const SizedBox(height: 12),
                const Text('Video walkthrough coming soon'),
                const SizedBox(height: 12),
                for (var i = 0; i < steps.length; i++) ...[
                  Text('${i + 1}. ${steps[i].$1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(steps[i].$2),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _support(BuildContext context) async {
    final subject = TextEditingController();
    final message = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Send a note about this build'),
            ),
            const SizedBox(height: 8),
            TextField(controller: subject, decoration: const InputDecoration(hintText: 'Subject (optional)')),
            const SizedBox(height: 8),
            TextField(
              controller: message,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'What do you need help with?'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (message.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    final body = message.text.trim();
    final title = subject.text.trim();
    subject.dispose();
    message.dispose();
    if (sent == true && context.mounted) {
      await Clipboard.setData(
        ClipboardData(text: 'Support: $title\n$body'),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved on this device and copied. There is no cloud inbox.'),
          ),
        );
      }
    }
  }

  Future<void> _bug(BuildContext context) async {
    final text = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a bug'),
        content: TextField(
          controller: text,
          minLines: 4,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: "e.g. The saved layout didn't appear on the device…",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (text.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Copy report'),
          ),
        ],
      ),
    );
    final body = text.text.trim();
    text.dispose();
    if (sent == true) {
      await Clipboard.setData(
        ClipboardData(
          text: 'Dummy Screen bug report\n\nWhat happened:\n$body',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report copied')),
        );
      }
    }
  }
}
