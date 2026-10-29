import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/backend.dart';
import 'widgets.dart';

class BackendList extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> value;
  final VoidCallback refresh;
  final Widget Function(Map<String, dynamic>) item;
  final String empty;
  const BackendList({
    super.key,
    required this.value,
    required this.refresh,
    required this.item,
    required this.empty,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ),
      value.when(
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => InfoCard(child: Text(backendError(e))),
        data: (rows) => Column(
          children: rows.isEmpty
              ? [InfoCard(child: Text(empty))]
              : rows.map(item).toList(),
        ),
      ),
    ],
  );
}
