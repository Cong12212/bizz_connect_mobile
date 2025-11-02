import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tags/data/tags_repository.dart';
import '../../../tags/data/tag_models.dart' as tagm;
import '../../data/contacts_repository.dart';

enum TagSheetResult { updated, manage, closed }

/// Bottom sheet to select, attach, and detach tags; includes "Manage" button
class SelectTagsSheet extends ConsumerStatefulWidget {
  const SelectTagsSheet({
    required this.contactId,
    required this.initialIds,
    super.key,
  });

  final int contactId;
  final List<int> initialIds;

  @override
  ConsumerState<SelectTagsSheet> createState() => _SelectTagsSheetState();
}

class _SelectTagsSheetState extends ConsumerState<SelectTagsSheet> {
  final _searchCtrl = TextEditingController();
  final Set<int> _selected = {};
  List<tagm.Tag> _available = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialIds);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String q = ''}) async {
    setState(() => _loading = true);
    final repo = ref.read(tagsRepositoryProvider);
    final res = await repo.listTags(q: q, page: 1);
    setState(() {
      _available = res.data;
      _loading = false;
    });
  }

  Future<void> _apply() async {
    final contactsRepo = ref.read(contactsRepositoryProvider);

    final initial = widget.initialIds.toSet();
    final now = _selected.toSet();
    final toAdd = now.difference(initial).toList();
    final toRemove = initial.difference(now).toList();

    if (toAdd.isNotEmpty) {
      await contactsRepo.attachTags(widget.contactId, ids: toAdd);
    }
    for (final id in toRemove) {
      await contactsRepo.detachTag(widget.contactId, id);
    }
    if (mounted) {
      Navigator.pop<TagSheetResult>(context, TagSheetResult.updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _loading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            itemCount: _available.length,
            itemBuilder: (_, i) {
              final t = _available[i];
              final checked = _selected.contains(t.id);
              return CheckboxListTile(
                value: checked,
                title: Text(t.name),
                subtitle: Text('${t.contactsCount} contacts'),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(t.id);
                    } else {
                      _selected.remove(t.id);
                    }
                  });
                },
              );
            },
          );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Select tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Manage'),
                      onPressed: () {
                        Navigator.pop<TagSheetResult>(
                          context,
                          TagSheetResult.manage,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search tags…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => _load(q: _searchCtrl.text),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (v) => _load(q: v),
                ),
              ),
              const SizedBox(height: 8),

              // List with limited height
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: list,
              ),

              const Divider(height: 1),
              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop<TagSheetResult>(
                          context,
                          TagSheetResult.closed,
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _apply,
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
