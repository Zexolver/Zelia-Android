import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/memory_service.dart';
import '../services/settings_service.dart';
import '../services/zelia_api.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  late final MemoryService _service;
  List<Memory>? _memories;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = MemoryService(SettingsService());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final memories = await _service.fetchRecent();
      setState(() {
        _memories = memories;
        _loading = false;
      });
    } on ZeliaApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Brain'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refresh'),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final memories = _memories ?? [];
    if (memories.isEmpty) {
      return const Center(child: Text('No memories yet.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: memories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _MemoryTile(memory: memories[index]),
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  final Memory memory;
  const _MemoryTile({required this.memory});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUser = memory.role == 'user';
    final formatted = DateFormat('MMM d, h:mm a').format(memory.time);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser ? colors.primaryContainer.withValues(alpha: 0.4) : colors.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isUser ? 'You' : 'ZELIA',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(formatted, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(memory.text),
        ],
      ),
    );
  }
}
