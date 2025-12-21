import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controller/contacts_list_controller.dart';
import '../data/models.dart';
import '../data/contacts_repository.dart';
import 'contact_detail_modal.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key, this.openContactId});

  final int? openContactId;

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _qCtrl = TextEditingController();
  Timer? _debounce;
  final LayerLink _sortLink = LayerLink();
  OverlayEntry? _sortEntry;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  Contact? _selectedContact; // Add selected contact for web view

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(contactsListControllerProvider.notifier).load();
      }
    });

    _qCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          // Scroll to top when searching
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
          ref
              .read(contactsListControllerProvider.notifier)
              .setQuery(_qCtrl.text);
        }
      });
    });

    // Infinite scroll listener
    _scrollController.addListener(_onScroll);

    // Auto-open contact detail modal if openContactId is provided
    if (widget.openContactId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openContactById(widget.openContactId!);
      });
    }
  }

  @override
  void dispose() {
    _hideSortPopover();
    _qCtrl.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0; // Trigger khi còn cách 200px từ cuối

    if (maxScroll - currentScroll <= delta) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final state = ref.read(contactsListControllerProvider);
    if (state.page >= state.last) return; // Đã hết data

    setState(() => _isLoadingMore = true);
    await ref.read(contactsListControllerProvider.notifier).loadMore();
    setState(() => _isLoadingMore = false);
  }

  Future<void> _openViewModal(Contact c) async {
    // On web/large screen, show in right panel instead of modal
    if (MediaQuery.of(context).size.width >= 768) {
      setState(() => _selectedContact = c);
      return;
    }

    final updated = await showDialog<Contact?>(
      context: context,
      builder: (_) => ContactDetailModal.initialView(contact: c),
    );

    if (updated != null && mounted) {
      await ref.read(contactsListControllerProvider.notifier).load();
    }
  }

  Future<void> _openCreateModal() async {
    final created = await showDialog<Contact?>(
      context: context,
      builder: (_) => const ContactDetailModal.initialCreate(),
    );

    if (created != null && mounted) {
      // Invalidate and reload immediately
      ref.invalidate(contactsListControllerProvider);

      // Wait a frame for rebuild
      await Future.delayed(Duration.zero);

      if (mounted) {
        await ref.read(contactsListControllerProvider.notifier).load();
      }
    }
  }

  Future<void> _openSortMenu(BuildContext buttonContext) async {
    final current = ref.read(contactsListControllerProvider).sort;

    final buttonBox = buttonContext.findRenderObject() as RenderBox;
    final overlayBox = Navigator.of(buttonContext)
        .overlay!
        .context
        .findRenderObject() as RenderBox;
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
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: const {'name': 'A→Z', '-id': 'Newest'}.entries.map((e) {
        final isCurrent = e.key == current;
        return PopupMenuItem<String>(
          value: e.key,
          child: Row(
            children: [
              if (isCurrent)
                const Icon(Icons.check, size: 18, color: Color(0xFF3B82F6)),
              if (isCurrent) const SizedBox(width: 8),
              Text(
                e.value,
                style: TextStyle(
                  fontSize: 14,
                  color: isCurrent
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF374151),
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
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
    '-id': 'Newest',
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
                elevation: 4,
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: StatefulBuilder(
                      builder: (_, setLocal) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Sort by',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._sortOptions.entries.map(
                            (e) => RadioListTile<String>(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              value: e.key,
                              groupValue: temp,
                              activeColor: const Color(0xFF3B82F6),
                              title: Text(
                                e.value,
                                style: const TextStyle(fontSize: 14),
                              ),
                              onChanged: (v) => setLocal(() => temp = v!),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _hideSortPopover,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6B7280),
                                    side: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
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
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
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

  Future<void> _openContactById(int contactId) async {
    if (contactId == -1) {
      // Open create modal
      await _openCreateModal();
      return;
    }

    try {
      final repo = ref.read(contactsRepositoryProvider);
      final contact = await repo.getContact(contactId);

      if (!mounted) return;

      await showDialog<Contact?>(
        context: context,
        builder: (_) => ContactDetailModal.initialView(contact: contact),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load contact: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(contactsListControllerProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 768;

    final toolbar = SizedBox(
      height: 64,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLargeScreen ? 400 : double.infinity,
                ),
                child: TextField(
                  controller: _qCtrl,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: 'Search name, email, phone…',
                    hintStyle: const TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF9CA3AF),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 1.5,
                      ),
                    ),
                    isDense: true,
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              height: 40,
              child: Builder(
                builder: (btnCtx) => Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openSortMenu(btnCtx),
                    child: const Center(
                      child: Icon(
                        Icons.filter_list,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              height: 40,
              child: FilledButton(
                onPressed: _openCreateModal,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.add, size: 20),
              ),
            ),
          ],
        ),
      ),
    );

    final list = Column(
      children: [
        // Header
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
        // List body
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: state.loading && state.items.isEmpty
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
                    : _buildGroupedList(state),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            toolbar,
            Expanded(
              child: Row(
                children: [
                  // Left panel - Contact list
                  SizedBox(
                    width: isLargeScreen ? 420 : screenWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: isLargeScreen
                            ? const Border(
                                right: BorderSide(color: Color(0xFFE5E7EB)),
                              )
                            : null,
                      ),
                      child: list,
                    ),
                  ),
                  // Right panel - Detail view (only on large screens)
                  if (isLargeScreen)
                    Expanded(
                      child: _selectedContact != null
                          ? _buildDetailView(_selectedContact!)
                          : Container(
                              color: const Color(0xFFF8FAFC),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 64,
                                      color: Color(0xFFD1D5DB),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Select a contact to view details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView(Contact contact) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: contact.name ?? ''),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (contact.jobTitle != null || contact.company != null)
                      Text(
                        [contact.jobTitle, contact.company]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' at '),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                onPressed: () => setState(() => _selectedContact = null),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 24),
          if (contact.email != null && contact.email!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: contact.email!,
            ),
            const SizedBox(height: 16),
          ],
          if (contact.phone != null && contact.phone!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: contact.phone!,
            ),
            const SizedBox(height: 16),
          ],
          if (contact.company != null && contact.company!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.business_outlined,
              label: 'Company',
              value: contact.company!,
            ),
            const SizedBox(height: 16),
          ],
          if (contact.tags != null && contact.tags!.isNotEmpty) ...[
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: contact.tags!.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    '#${tag.name ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final updated = await showDialog<Contact?>(
                      context: context,
                      builder: (_) => ContactDetailModal.initialView(
                        contact: contact,
                      ),
                    );
                    if (updated != null && mounted) {
                      setState(() => _selectedContact = updated);
                      await ref
                          .read(contactsListControllerProvider.notifier)
                          .load();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.white,
                        contentPadding: const EdgeInsets.all(24),
                        title: const Text(
                          'Delete Contact',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        content: const Text(
                          'Are you sure you want to delete this contact?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        actions: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (ok == true && mounted) {
                      await ref
                          .read(contactsListControllerProvider.notifier)
                          .deleteContact(contact.id);
                      setState(() => _selectedContact = null);
                      if (mounted) {
                        await ref
                            .read(contactsListControllerProvider.notifier)
                            .load();
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(ContactsListState state) {
    final groupedItems = <String, List<Contact>>{};

    for (final contact in state.items) {
      final header = _getGroupHeader(contact, state.sort);
      if (!groupedItems.containsKey(header)) {
        groupedItems[header] = [];
      }
      groupedItems[header]!.add(contact);
    }

    final sections = groupedItems.entries.toList();
    int totalItemCount = 0;
    for (final section in sections) {
      totalItemCount += 1 + section.value.length; // header + items
    }
    if (_isLoadingMore) totalItemCount += 1;

    return ListView.builder(
      controller: _scrollController,
      itemCount: totalItemCount,
      itemBuilder: (_, index) {
        int currentIndex = 0;

        for (final section in sections) {
          // Header
          if (index == currentIndex) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                section.key,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            );
          }
          currentIndex++;

          // Items in this section
          final sectionItems = section.value;
          if (index < currentIndex + sectionItems.length) {
            final itemIndex = index - currentIndex;
            final c = sectionItems[itemIndex];
            return _buildContactCard(c);
          }
          currentIndex += sectionItems.length;
        }

        // Loading indicator at the end
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  String _getGroupHeader(Contact contact, String sort) {
    if (sort == 'name') {
      final firstChar =
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '#';
      return firstChar;
    } else {
      // Group by date (-id for newest)
      final dateStr = contact.createdAt;
      if (dateStr == null || dateStr.isEmpty) return 'Unknown';

      final date = DateTime.tryParse(dateStr);
      if (date == null) return 'Unknown';

      final now = DateTime.now();
      final diff = now.difference(date).inDays;

      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff < 7) return 'This Week';
      if (diff < 30) return 'This Month';

      final month = date.month;
      final year = date.year;
      return '$month/$year';
    }
  }

  Widget _buildContactCard(Contact c) {
    final tags = (c.tags ?? []).take(2).toList();
    final totalTags = c.tags?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
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
              _Avatar(name: c.name ?? ''),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.jobTitle ?? c.company ?? c.email ?? c.phone ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          ...tags.map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Text(
                                '#${t.name ?? ''}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          if (totalTags > 2)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${totalTags - 2}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.white,
                      contentPadding: const EdgeInsets.all(24),
                      title: const Text(
                        'Delete Contact',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this contact? This action cannot be undone.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                      actions: [
                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6B7280),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 44,
                          child: FilledButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (ok == true && mounted) {
                    await ref
                        .read(contactsListControllerProvider.notifier)
                        .deleteContact(c.id);

                    // Reload after delete
                    if (mounted) {
                      await ref
                          .read(contactsListControllerProvider.notifier)
                          .load();
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                child: const Text('Delete', style: TextStyle(fontSize: 12)),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
