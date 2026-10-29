import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend.dart';
import '../../core/data.dart';
import '../../shared/widgets.dart';
import '../../shared/backend_list.dart';
import '../settings/settings_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final form = GlobalKey<FormState>();
  final depth = TextEditingController(), description = TextEditingController();
  DateTime? observed;
  XFile? photo;
  String? photoPath, message;
  bool busy = false;
  @override
  void dispose() {
    depth.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pickTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null && mounted) {
      setState(
        () => observed = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> submit() async {
    if (ref.read(userProvider) == null) {
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text(
            'Sign in to send a report for administrator review.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialog);
                showAccount(context);
              },
              child: const Text('Log In'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Continue as Guest'),
            ),
          ],
        ),
      );
      return;
    }
    if (!form.currentState!.validate()) return;
    final roads = ref.read(roadsProvider).asData?.value ?? [];
    final selected = ref.read(selectedRoadProvider);
    if (selected >= roads.length || roads.isEmpty) {
      setState(() => message = 'Choose a published road.');
      return;
    }
    if (observed == null || observed!.isAfter(DateTime.now())) {
      setState(
        () => message = 'Choose an observation time that is not in the future.',
      );
      return;
    }
    final road = roads[selected];
    final db = ref.read(clientProvider);
    final owner = ref.read(userProvider)!.id;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (photo != null && photoPath == null) {
        final bytes = await photo!.readAsBytes();
        if (bytes.length > 10485760) {
          throw const FormatException('Photo must be at most 10 MB.');
        }
        String? type;
        if (bytes.length > 12) {
          if (bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) {
            type = 'jpeg';
          }
          if (bytes[0] == 137 &&
              bytes[1] == 80 &&
              bytes[2] == 78 &&
              bytes[3] == 71) {
            type = 'png';
          }
          if (String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
              String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
            type = 'webp';
          }
        }
        if (type == null) {
          throw const FormatException('Choose a JPEG, PNG or WebP photo.');
        }
        final path = '$owner/${DateTime.now().microsecondsSinceEpoch}.$type';
        await db.storage
            .from('flood-photos')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: 'image/$type',
                upsert: false,
              ),
            );
        photoPath = path;
      }
      await db.from('flood_reports').insert({
        'owner_id': owner, 'road_id': road.id,
        // These are the selected road coordinates, not a claimed GPS fix.
        'latitude': road.latitude, 'longitude': road.longitude,
        'depth_cm': double.parse(depth.text),
        'description': description.text.trim(),
        'observed_at': observed!.toUtc().toIso8601String(),
        'photo_path': photoPath,
      });
      depth.clear();
      description.clear();
      if (mounted) {
        setState(() {
          observed = null;
          photo = null;
          photoPath = null;
          message = 'Report submitted. Pending administrator review.';
        });
      }
      ref.invalidate(myReportsProvider);
    } catch (e) {
      if (mounted) {
        setState(
          () => message = e is FormatException ? e.message : backendError(e),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userProvider, (previous, next) {
      if (previous?.id != next?.id) {
        depth.clear();
        description.clear();
        setState(() {
          photo = null;
          photoPath = null;
          observed = null;
          message = null;
        });
      }
    });
    final roads = ref.watch(roadsProvider).asData?.value ?? [];
    final selected = ref.watch(selectedRoadProvider);
    final user = ref.watch(userProvider);
    return PageBody(
      title: 'Community reports',
      subtitle:
          'Reports are private until reviewed. They do not automatically become published flood observations.',
      children: [
        InfoCard(
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (roads.isEmpty)
                  const Text(
                    'No published roads available. An administrator must publish a road before reports can be submitted.',
                  ),
                if (roads.isNotEmpty)
                  DropdownButtonFormField<int>(
                    key: ValueKey('$selected-${roads.length}'),
                    initialValue: selected < roads.length ? selected : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Road location',
                    ),
                    items: [
                      for (var i = 0; i < roads.length; i++)
                        DropdownMenuItem(value: i, child: Text(roads[i].road)),
                    ],
                    onChanged: busy
                        ? null
                        : (v) {
                            if (v != null) {
                              ref.read(selectedRoadProvider.notifier).select(v);
                            }
                          },
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Location uses the selected road coordinates. GPS is not requested.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: depth,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estimated depth (cm)',
                  ),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return n == null || !n.isFinite || n < 0 || n > 1000
                        ? 'Enter a depth from 0 to 1000 cm.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: description,
                  enabled: !busy,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'What did you observe?',
                  ),
                  validator: (v) => (v?.trim().length ?? 0) < 10
                      ? 'Add at least 10 characters.'
                      : null,
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : pickTime,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    observed == null
                        ? 'Select observation date and time'
                        : 'Observed: $observed (local)',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          try {
                            final file = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );
                            if (mounted && file != null) {
                              setState(() {
                                photo = file;
                                photoPath = null;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(
                                () => message =
                                    'Photo could not be selected. Try again.',
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(
                    photo?.name ?? 'Attach optional photo (max 10 MB)',
                  ),
                ),
                if (photo != null)
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            photo = null;
                            photoPath = null;
                          }),
                    child: const Text('Remove photo'),
                  ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(message!),
                  ),
                FilledButton(
                  onPressed: busy || !backendConfigured ? null : submit,
                  child: Text(busy ? 'Submitting...' : 'Submit Report'),
                ),
              ],
            ),
          ),
        ),
        if (user != null) ...[
          const Text('My reports - Latest 100'),
          BackendList(
            value: ref.watch(myReportsProvider),
            refresh: () => ref.invalidate(myReportsProvider),
            empty: 'No reports submitted yet.',
            item: (row) => InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tag(row['status'] as String),
                  const SizedBox(height: 8),
                  Text(
                    roads
                            .where((r) => r.id == row['road_id'])
                            .firstOrNull
                            ?.road ??
                        'Road unavailable',
                  ),
                  Text('${row['depth_cm']} cm ? ${row['observed_at']}'),
                  Text(row['description'] as String),
                  if (row['review_reason'] != null)
                    Text('Administrator: ${row['review_reason']}'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
