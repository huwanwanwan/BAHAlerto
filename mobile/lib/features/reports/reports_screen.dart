import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data.dart';
import '../../shared/widgets.dart';
import '../settings/settings_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final form = GlobalKey<FormState>();
  final depth = TextEditingController(), description = TextEditingController();
  late int road;
  @override
  void initState() {
    super.initState();
    road = ref.read(selectedRoadProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    road = ref.read(selectedRoadProvider);
  }

  DateTime? observed;
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

  @override
  Widget build(BuildContext context) => PageBody(
    title: 'Community reports',
    subtitle:
        'Practice a report. Entries stay in memory and disappear on restart.',
    children: [
      InfoCard(
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                key: ValueKey(ref.watch(selectedRoadProvider)),
                initialValue: ref.watch(selectedRoadProvider),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sample location'),
                items: [
                  for (var i = 0; i < records.length; i++)
                    DropdownMenuItem(value: i, child: Text(records[i].road)),
                ],
                onChanged: (v) {
                  road = v!;
                  ref.read(selectedRoadProvider.notifier).select(v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: depth,
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
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: pickTime,
                icon: const Icon(Icons.schedule),
                label: Text(
                  observed == null
                      ? 'Select observation date and time'
                      : 'Observed: $observed (local)',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Optional photo upload will be available with Supabase Storage. No files are uploaded in this prototype.',
                style: TextStyle(color: mutedText, fontSize: 12),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Login Required'),
                      content: const Text(
                        'Registered users can submit flood reports for administrator review. Authentication is not connected in this demo.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            showAccountUnavailable(context, 'Log In');
                          },
                          child: const Text('Log In'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            showAccountUnavailable(context, 'Register');
                          },
                          child: const Text('Register'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Continue as Guest'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Submit Report'),
              ),
              TextButton(
                onPressed: () {
                  if (!form.currentState!.validate()) return;
                  if (observed == null || observed!.isAfter(DateTime.now())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Select an observation time that is not in the future.',
                        ),
                      ),
                    );
                    return;
                  }
                  ref
                      .read(reportsProvider.notifier)
                      .add(
                        'Submitted: ${DateTime.now().toUtc().toIso8601String()}\n${records[ref.read(selectedRoadProvider)].road}\n${depth.text} cm • $observed (local)\n${description.text.trim()}',
                      );
                  depth.clear();
                  description.clear();
                  setState(() => observed = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demo report saved locally • Unverified'),
                    ),
                  );
                },
                child: const Text('Save demo report'),
              ),
            ],
          ),
        ),
      ),
      const Text('My Reports ? Practice entries only'),
      for (final report in ref.watch(reportsProvider))
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Tag('Sample • Unverified • Pending review'),
              const SizedBox(height: 12),
              Text(report),
            ],
          ),
        ),
      if (ref.watch(reportsProvider).isEmpty)
        const InfoCard(
          child: Text(
            'No local reports yet. Your practice reports will appear here.',
          ),
        ),
    ],
  );
}
