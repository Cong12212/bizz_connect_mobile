import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/contacts_list_controller.dart';
import '../data/models.dart';
import 'contact_detail_modal.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  final _qCtrl = TextEditingController();
  Timer? _debounce;
  final LayerLink _sortLink = LayerLink();
  OverlayEntry? _sortEntry;

  @override
  void initState() {
    super.initState();
    // load lần đầu
    Future.microtask(() {
      ref.read(contactsListControllerProvider.notifier).load();
    });

    _qCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        ref.read(contactsListControllerProvider.notifier).setQuery(_qCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _hideSortPopover();
    _qCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _openViewModal(Contact c) async {
    final updated = await showModalBottomSheet<Contact?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactDetailModal.initialView(contact: c),
    );

    // Chỉ refresh item thay vì reload toàn bộ
    if (updated != null && mounted) {
      ref.read(contactsListControllerProvider.notifier).refreshContact(updated);
    }
  }

  Future<void> _openCreateModal() async {
    final created = await showModalBottomSheet<Contact?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ContactDetailModal.initialCreate(),
    );

    if (created != null && mounted) {
      await ref.read(contactsListControllerProvider.notifier).load();
    }
  }

  Future<void> _openSortMenu(BuildContext buttonContext) async {
    final current = ref.read(contactsListControllerProvider).sort;

    final buttonBox = buttonContext.findRenderObject() as RenderBox;
    final overlayBox =
        Navigator.of(buttonContext).overlay!.context.findRenderObject()
            as RenderBox;
    final buttonTopLeft = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );

    final left = buttonTopLeft.dx;
    final top = buttonTopLeft.dy + buttonBox.size.height + 6;
    final right = overlayBox.size.width - left - buttonBox.size.width;
    final bottom = overlayBox.size.height - top;

    final selected = await showMenu<String>(
      context: buttonContext,
      position: RelativeRect.fromLTRB(left, top, right, bottom),
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items:
          const {
            'name': 'A→Z',
            '-name': 'Z→A',
            '-id': 'Newest',
            'id': 'Oldest',
          }.entries.map((e) {
            final isCurrent = e.key == current;
            return PopupMenuItem<String>(
              value: e.key,
              child: Row(
                children: [
                  if (isCurrent) const Icon(Icons.check, size: 18),
                  if (isCurrent) const SizedBox(width: 6),
                  Text(e.value),
                ],
              ),
            );
          }).toList(),
    );

    if (selected != null && selected != current) {
      ref.read(contactsListControllerProvider.notifier).setSort(selected);
    }
  }

  static const Map<String, String> _sortOptions = {
    'name': 'A→Z',
    '-name': 'Z→A',
    '-id': 'Newest',
    'id': 'Oldest',
  };

  void _hideSortPopover() {
    _sortEntry?.remove();
    _sortEntry = null;
  }

  void _showSortPopover() {
    if (_sortEntry != null) return;

    final current = ref.read(contactsListControllerProvider).sort;
    String temp = current;

    _sortEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideSortPopover,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _sortLink,
              showWhenUnlinked: false,
              offset: const Offset(-160, 44),
              child: Material(
                elevation: 10,
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: StatefulBuilder(
                      builder: (_, setLocal) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Sort by',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          ..._sortOptions.entries.map(
                            (e) => RadioListTile<String>(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              value: e.key,
                              groupValue: temp,
                              title: Text(e.value),
                              onChanged: (v) => setLocal(() => temp = v!),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _hideSortPopover,
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    _hideSortPopover();
                                    if (temp != current) {
                                      ref
                                          .read(
                                            contactsListControllerProvider
                                                .notifier,
                                          )
                                          .setSort(temp);
                                    }
                                  },
                                  child: const Text('Apply'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_sortEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsListControllerProvider);

    final toolbar = SizedBox(
      height: 60,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _qCtrl,
                decoration: InputDecoration(
                  hintText: 'Search name, email, phone…',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              height: 40,
              child: Builder(
                builder: (btnCtx) => SizedBox(
                  width: 40,
                  height: 40,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(
                      side: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _openSortMenu(btnCtx),
                      child: const Center(
                        child: Icon(
                          Icons.filter_list,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _openCreateModal,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ],
        ),
      ),
    );

    final list = Column(
      children: [
        // header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${state.total} contacts',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
        ),
        // list body
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: state.loading
                ? ListView.separated(
                    itemCount: 8,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, __) => Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : state.items.isEmpty
                ? const Center(
                    child: Text(
                      'No results',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = state.items[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openViewModal(c),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              _Avatar(name: c.name),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c.jobTitle ??
                                          c.company ??
                                          c.email ??
                                          c.phone ??
                                          '—',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogCtx) => AlertDialog(
                                      title: const Text('Delete this contact?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            dialogCtx,
                                          ).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(dialogCtx).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (ok == true && mounted) {
                                    await ref
                                        .read(
                                          contactsListControllerProvider
                                              .notifier,
                                        )
                                        .deleteContact(c.id);
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        // pager
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: _CompactPager(
                current: state.page,
                total: state.last,
                onPage: (p) => ref
                    .read(contactsListControllerProvider.notifier)
                    .setPage(p),
                maxNumbers: 4,
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            children: [
              toolbar,
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, cts) {
                    final maxW = cts.maxWidth;
                    final leftW = maxW < 768 ? maxW : 420.0;
                    return Row(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints.tightFor(width: leftW),
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                right: BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            child: list,
                          ),
                        ),
                        if (maxW >= 768)
                          const Expanded(child: SizedBox.expand()),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  String get initials {
    final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((s) => s[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE2E8F0),
      ),
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _NumberPager extends StatelessWidget {
  const _NumberPager({
    required this.current,
    required this.total,
    required this.onPage,
  });
  final int current;
  final int total;
  final ValueChanged<int> onPage;

  List<dynamic> _visiblePages(int current, int total, {int max = 7}) {
    if (total <= max) return List.generate(total, (i) => i + 1);
    final half = max ~/ 2;
    var start = (current - half).clamp(1, total);
    var end = (start + max - 1).clamp(1, total);
    start = (end - max + 1).clamp(1, total);
    final pages = <dynamic>[];
    if (start > 1) {
      pages.add(1);
      if (start > 2) pages.add('...');
    }
    for (var i = start; i <= end; i++) pages.add(i);
    if (end < total) {
      if (end < total - 1) pages.add('...');
      pages.add(total);
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _visiblePages(current, total);
    final btn = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      foregroundColor: Colors.black87,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: current > 1 ? () => onPage(1) : null,
          style: btn,
          child: const Text('«'),
        ),
        TextButton(
          onPressed: current > 1 ? () => onPage(current - 1) : null,
          style: btn,
          child: const Text('‹'),
        ),
        ...pages.map(
          (n) => n == '...'
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('…', style: TextStyle(color: Color(0xFF64748B))),
                )
              : TextButton(
                  onPressed: n == current ? null : () => onPage(n as int),
                  style: n == current
                      ? btn.merge(
                          ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              const Color(0xFFEFF6FF),
                            ),
                          ),
                        )
                      : btn,
                  child: Text('$n'),
                ),
        ),
        TextButton(
          onPressed: current < total ? () => onPage(current + 1) : null,
          style: btn,
          child: const Text('›'),
        ),
        TextButton(
          onPressed: current < total ? () => onPage(total) : null,
          style: btn,
          child: const Text('»'),
        ),
      ],
    );
  }
}

class _CompactPager extends StatelessWidget {
  const _CompactPager({
    required this.current,
    required this.total,
    required this.onPage,
    this.maxNumbers = 3,
  });

  final int current;
  final int total;
  final ValueChanged<int> onPage;
  final int maxNumbers;

  List<int> _numbers() {
    if (total <= 0) return const [];
    final half = maxNumbers ~/ 2;
    var start = (current - half).clamp(1, total);
    var end = (start + maxNumbers - 1).clamp(1, total);
    start = (end - maxNumbers + 1).clamp(1, total);
    return [for (var i = start; i <= end; i++) i];
  }

  @override
  Widget build(BuildContext context) {
    final nums = _numbers();
    ButtonStyle numStyle(bool active) => TextButton.styleFrom(
      minimumSize: const Size(36, 36),
      padding: EdgeInsets.zero,
      foregroundColor: active ? const Color(0xFF2563EB) : Colors.black87,
      backgroundColor: active ? const Color(0xFFEFF6FF) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: current > 1 ? () => onPage(1) : null,
          icon: const Icon(Icons.first_page),
          tooltip: 'First',
        ),
        IconButton(
          onPressed: current > 1 ? () => onPage(current - 1) : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Prev',
        ),
        ...nums.map(
          (n) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: TextButton(
              style: numStyle(n == current),
              onPressed: n == current ? null : () => onPage(n),
              child: Text('$n'),
            ),
          ),
        ),
        IconButton(
          onPressed: current < total ? () => onPage(current + 1) : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next',
        ),
        IconButton(
          onPressed: current < total ? () => onPage(total) : null,
          icon: const Icon(Icons.last_page),
          tooltip: 'Last',
        ),
      ],
    );
  }
}
