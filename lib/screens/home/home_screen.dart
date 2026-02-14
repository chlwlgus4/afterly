import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/shooting_session.dart';
import '../../providers/customer_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/firestore_provider.dart';
import '../../providers/storage_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _filterDate;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> _filterCustomers(List<Customer> customers) {
    var result = customers;

    // 이름 검색
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
    }

    // 날짜 필터
    if (_filterDate != null) {
      result = result.where((c) {
        if (c.lastShootingAt == null) return false;
        return c.lastShootingAt!.year == _filterDate!.year &&
            c.lastShootingAt!.month == _filterDate!.month &&
            c.lastShootingAt!.day == _filterDate!.day;
      }).toList();
    }

    return result;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _filterDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Afterly',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
              color: _showSearch ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterDate = null;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
            },
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          if (_showSearch) _buildSearchBar(),
          // 고객 목록
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('오류가 발생했습니다: $e')),
              data: (customers) {
                if (customers.isEmpty) {
                  return _buildEmptyState();
                }
                final filtered = _filterCustomers(customers);
                if (filtered.isEmpty) {
                  return _buildNoResults(customers.length);
                }
                return _buildCustomerList(filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('새 고객 촬영'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 이름 검색
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '고객 이름 검색',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.person_search,
                  color: AppColors.textSecondary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 8),
          // 날짜 필터
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: _filterDate != null
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _filterDate != null
                              ? DateFormat('yyyy.MM.dd').format(_filterDate!)
                              : '날짜로 검색',
                          style: TextStyle(
                            color: _filterDate != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_filterDate != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _filterDate = null),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 18),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(int totalCount) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('검색 결과가 없습니다', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            '전체 $totalCount명 중 일치하는 고객이 없습니다',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _filterDate = null;
              });
            },
            child: const Text('검색 초기화'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            '아직 고객이 없습니다',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          const Text(
            '새 고객을 추가하고 촬영을 시작해보세요',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddCustomerDialog,
            icon: const Icon(Icons.add),
            label: const Text('새 고객 추가'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(List<Customer> customers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _CustomerCard(customer: customer);
      },
    );
  }

  Future<void> _showAddCustomerDialog() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('새 고객 추가'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '고객 이름을 입력하세요',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      final customerId =
          await ref.read(customerListProvider.notifier).addCustomer(name.trim());
      if (mounted) {
        _startNewSession(customerId);
      }
    }
  }

  Future<void> _startNewSession(String customerId) async {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) return;

    final firestore = ref.read(firestoreServiceProvider);
    final session = ShootingSession(
      userId: userId,
      customerId: customerId,
    );
    final sessionId = await firestore.addSession(session);

    if (mounted) {
      context.go('/camera/$customerId/$sessionId/before');
    }
  }
}

class _CustomerCard extends ConsumerWidget {
  final Customer customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionListProvider(customer.id!));

    // After 미촬영 세션 찾기
    final pendingAfter = sessionsAsync.valueOrNull
        ?.where((s) => s.hasBeforeImage && !s.hasAfterImage)
        .toList();
    final hasPendingAfter = pendingAfter != null && pendingAfter.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceLight, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCustomerOptions(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0] : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name, style: AppTextStyles.heading3),
                        const SizedBox(height: 4),
                        Text(
                          customer.lastShootingAt != null
                              ? '최근 촬영: ${DateFormat('yyyy.MM.dd').format(customer.lastShootingAt!)}'
                              : '촬영 기록 없음',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  sessionsAsync.when(
                    data: (sessions) => Text(
                      '${sessions.length}회',
                      style: AppTextStyles.bodySecondary,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              // After 미촬영 세션 알림
              if (hasPendingAfter) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    final session = pendingAfter.first;
                    context.go(
                      '/camera/${customer.id}/${session.id}/after',
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'After 촬영 대기 중 (${DateFormat('MM.dd').format(pendingAfter.first.createdAt)})',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.warning,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomerOptions(BuildContext context, WidgetRef ref) async {
    final sessionsAsync = ref.read(sessionListProvider(customer.id!));
    final sessions = sessionsAsync.valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('새 촬영 시작'),
              onTap: () {
                Navigator.pop(context);
                _startNewSession(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('고객 삭제'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteCustomer(context, ref);
              },
            ),
            if (sessions.isNotEmpty) ...[
              const Divider(color: AppColors.surfaceLight),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('이전 촬영 기록', style: AppTextStyles.bodySecondary),
              ),
              ...sessions.take(5).map((session) => ListTile(
                    leading: Icon(
                      session.isComplete
                          ? Icons.check_circle
                          : Icons.pending,
                      color: session.isComplete
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    title: Text(
                      DateFormat('yyyy.MM.dd HH:mm').format(session.createdAt),
                    ),
                    subtitle: Text(
                      session.isComplete
                          ? (session.hasAnalysis ? '분석 완료' : '비교 가능')
                          : (session.hasBeforeImage ? 'After 촬영 필요' : 'Before 촬영 필요'),
                      style: AppTextStyles.caption,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 20),
                      onPressed: () {
                        _confirmDeleteSession(context, ref, session);
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToSession(context, session);
                    },
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startNewSession(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) return;

    final firestore = ref.read(firestoreServiceProvider);
    final session = ShootingSession(
      userId: userId,
      customerId: customer.id!,
    );
    final sessionId = await firestore.addSession(session);

    await ref
        .read(customerListProvider.notifier)
        .updateLastShooting(customer.id!);

    if (context.mounted) {
      context.go('/camera/${customer.id}/$sessionId/before');
    }
  }

  Future<void> _confirmDeleteCustomer(BuildContext context, WidgetRef ref) async {
    final sessionsAsync = ref.read(sessionListProvider(customer.id!));
    final sessions = sessionsAsync.valueOrNull ?? [];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('고객 삭제'),
        content: Text(
          '${customer.name} 고객을 삭제하시겠습니까?\n'
          '${sessions.length}건의 촬영 기록과 이미지도 모두 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storage = ref.read(storageServiceProvider);

      // Delete images from Firebase Storage
      for (final session in sessions) {
        await storage.deleteSessionImages(
          beforeImageUrl: session.beforeImageUrl,
          afterImageUrl: session.afterImageUrl,
          alignedBeforeUrl: session.alignedBeforeUrl,
          alignedAfterUrl: session.alignedAfterUrl,
        );
      }

      await ref
          .read(customerListProvider.notifier)
          .deleteCustomer(customer.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${customer.name} 고객이 삭제되었습니다')),
        );
      }
    }
  }

  Future<void> _confirmDeleteSession(
      BuildContext context, WidgetRef ref, ShootingSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('촬영 기록 삭제'),
        content: Text(
          '${DateFormat('yyyy.MM.dd HH:mm').format(session.createdAt)} 기록을 삭제하시겠습니까?\n이미지 파일도 함께 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storage = ref.read(storageServiceProvider);

      // Delete images from Firebase Storage
      await storage.deleteSessionImages(
        beforeImageUrl: session.beforeImageUrl,
        afterImageUrl: session.afterImageUrl,
        alignedBeforeUrl: session.alignedBeforeUrl,
        alignedAfterUrl: session.alignedAfterUrl,
      );

      await ref
          .read(sessionListProvider(customer.id!).notifier)
          .deleteSession(session.id!);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('촬영 기록이 삭제되었습니다')),
        );
      }
    }
  }

  void _navigateToSession(BuildContext context, ShootingSession session) {
    if (!session.hasBeforeImage) {
      context.go('/camera/${session.customerId}/${session.id}/before');
    } else if (!session.hasAfterImage) {
      context.go('/camera/${session.customerId}/${session.id}/after');
    } else if (session.hasAnalysis) {
      context.go('/analysis/${session.id}');
    } else {
      context.go('/comparison/${session.id}');
    }
  }
}
