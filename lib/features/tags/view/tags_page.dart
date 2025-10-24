import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/tags_list_controller.dart';
import '../data/tag_models.dart';

class TagsPage extends ConsumerStatefulWidget {
  const TagsPage({super.key});

  @override
  ConsumerState<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends ConsumerState<TagsPage> {
  final _createCtrl = TextEditingController();
  int? _editingId;
  final _editCtrl = TextEditingController();

  @override
  void dispose() {
    _createCtrl.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tagsListControllerProvider);
    final notifier = ref.read(tagsListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tags'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search + Create
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search tags…',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: notifier.setQuery,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _createCtrl,
                    decoration: const InputDecoration(
                      hintText: 'New tag name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _create(notifier),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: state.loading ? null : () => _create(notifier),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List
            Expanded(
              child: Card(
                child: state.loading && state.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error: ${state.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              // Option 1:
                              onPressed: () => notifier.reload(),
                              // Option 2 (completely rebuild):
                              // onPressed: () => ref.invalidate(tagsListControllerProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildList(state.items, notifier),
              ),
            ),

            // Pagination
            if (state.last > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 6,
                  children: List.generate(state.last, (i) {
                    final page = i + 1;
                    final active = page == state.page;
                    return OutlinedButton(
                      onPressed: () => notifier.setPage(page),
                      style: active
                          ? OutlinedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                            )
                          : null,
                      child: Text('$page'),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Tag> items, TagsListController notifier) {
    if (items.isEmpty) {
      return const Center(child: Text('No tags yet'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final t = items[i];
        final editing = _editingId == t.id;

        // Separate edit mode and view mode
        if (editing) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('#${t.id}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _editCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _commitEdit(t, notifier),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _commitEdit(t, notifier),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    setState(() => _editingId = null);
                  },
                ),
              ],
            ),
          );
        }

        // View mode - normal ListTile
        return ListTile(
          leading: Text('#${t.id}', style: const TextStyle(color: Colors.grey)),
          title: Text(
            t.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${t.contactsCount} contacts'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _editingId = t.id;
                    _editCtrl.text = t.name;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteTag(t, notifier),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _create(TagsListController notifier) async {
    final name = _createCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter tag name')));
      return;
    }

    try {
      await notifier.create(name);
      _createCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Created tag "$name"')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _commitEdit(Tag t, TagsListController notifier) async {
    final name = _editCtrl.text.trim();
    setState(() => _editingId = null);

    if (name.isEmpty || name == t.name) return;

    try {
      await notifier.rename(t.id, name);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Renamed to "$name"')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteTag(Tag t, TagsListController notifier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Do you want to delete tag "${t.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await notifier.remove(t.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted tag "${t.name}"')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
