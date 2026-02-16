import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/shooting_session.dart';
import '../../providers/customer_provider.dart';
import '../../providers/group_provider.dart';
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
  final Set<String?> _expandedGroups = {}; // 펼쳐진 그룹 ID 목록
  bool _isFirstLoad = true; // 최초 로드 여부 추적

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
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
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
        title: Text(
          'Afterly',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          // 디버그: 사용자 ID 표시
          // if (currentUser != null)
          //   IconButton(
          //     icon: const Icon(Icons.info_outline),
          //     tooltip: 'User: ${currentUser.uid.substring(0, 8)}...',
          //     onPressed: () {
          //       showDialog(
          //         context: context,
          //         builder: (context) => AlertDialog(
          //           title: const Text('사용자 정보'),
          //           content: SelectableText(
          //             '인증 상태: 로그인됨\n'
          //             'User ID: ${currentUser.uid}\n'
          //             'Email: ${currentUser.email ?? "없음"}',
          //           ),
          //           actions: [
          //             TextButton(
          //               onPressed: () => Navigator.pop(context),
          //               child: const Text('확인'),
          //             ),
          //           ],
          //         ),
          //       );
          //     },
          //   ),
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
              color: _showSearch ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
            icon: const Icon(Icons.folder_outlined),
            tooltip: '그룹 관리',
            onPressed: () => context.push('/groups'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 로그아웃 확인 다이얼로그
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                // 모든 상태 초기화
                ref.invalidate(customerListProvider);
                ref.invalidate(groupListProvider);

                // 로그아웃 실행
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
              }
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
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      '고객 목록 불러오는 중...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              error: (e, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '고객 목록 로드 실패',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        e.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(customerListProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (customers) {
                // 최초 로드이고 빈 리스트면 로딩 중으로 간주
                if (_isFirstLoad && customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          '고객 목록 불러오는 중...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 데이터가 있으면 최초 로드 완료로 표시
                if (customers.isNotEmpty) {
                  _isFirstLoad = false;
                }

                // 실제로 비어있는 경우
                if (customers.isEmpty) {
                  // 최초 로드가 아니면 진짜 빈 상태
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _isFirstLoad = false);
                    }
                  });
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('새 고객 촬영'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 이름 검색
          TextField(
            controller: _searchController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: '고객 이름 검색',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.person_search,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: _filterDate != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _filterDate != null
                              ? DateFormat('yyyy.MM.dd').format(_filterDate!)
                              : '날짜로 검색',
                          style: TextStyle(
                            color: _filterDate != null
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.close,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 18),
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
          Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '전체 $totalCount명 중 일치하는 고객이 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            '아직 고객이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새 고객을 추가하고 촬영을 시작해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
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
    final groupsAsync = ref.watch(groupListProvider);

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return _CustomerCard(customer: customer);
        },
      ),
      data: (groups) {
        // 그룹별로 고객 분류
        final groupedCustomers = <String?, List<Customer>>{};

        // 그룹이 있는 고객 분류
        for (final group in groups) {
          groupedCustomers[group.id] = customers
              .where((c) => c.group == group.id)
              .toList();
        }

        // 그룹 없는 고객
        groupedCustomers[null] = customers
            .where((c) => c.group == null || !groups.any((g) => g.id == c.group))
            .toList();

        // 빈 그룹 제거
        groupedCustomers.removeWhere((key, value) => value.isEmpty);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 각 그룹별 섹션
            for (final entry in groupedCustomers.entries) ...[
              _buildExpandableGroup(
                groupId: entry.key,
                groupName: entry.key != null
                    ? groups.firstWhere((g) => g.id == entry.key).name
                    : '일반 고객',
                groupColor: entry.key != null
                    ? groups.firstWhere((g) => g.id == entry.key).color
                    : null,
                customers: entry.value,
                isExpanded: _expandedGroups.contains(entry.key),
                onToggle: () {
                  setState(() {
                    if (_expandedGroups.contains(entry.key)) {
                      _expandedGroups.remove(entry.key);
                    } else {
                      _expandedGroups.add(entry.key);
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _buildExpandableGroup({
    required String? groupId,
    required String groupName,
    required String? groupColor,
    required List<Customer> customers,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final color = groupColor != null
        ? Color(int.parse(groupColor.substring(1), radix: 16) + 0xFF000000)
        : (groupId == null ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6) : Theme.of(context).colorScheme.primary);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // 그룹 헤더 (클릭 가능)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 그룹 아이콘/색상
                  if (groupId != null)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  const SizedBox(width: 12),

                  // 그룹 이름
                  Expanded(
                    child: Text(
                      groupName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),

                  // 고객 수
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${customers.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 펼침/접힘 아이콘
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),

          // 고객 리스트 (펼쳐졌을 때만 표시)
          if (isExpanded) ...[
            const Divider(height: 1),
            ...customers.map((customer) => _CustomerCard(customer: customer)),
          ],
        ],
      ),
    );
  }


  Future<void> _showAddCustomerDialog() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => const _AddCustomerDialog(),
    );

    if (result != null && result['name'] != null && result['name']!.trim().isNotEmpty) {
      final customerId = await ref.read(customerActionsProvider).addCustomer(
            result['name']!.trim(),
            group: result['group'],
            memo: result['memo'],
          );
      if (mounted) {
        _startNewSession(customerId);
      }
    }
  }

  Future<void> _startNewSession(String customerId) async {
    try {
      final userId = ref.read(currentUserProvider)?.uid;
      if (userId == null) {
        throw Exception('로그인 정보를 찾을 수 없습니다');
      }

      final firestore = ref.read(firestoreServiceProvider);
      final session = ShootingSession(
        userId: userId,
        customerId: customerId,
      );

      final sessionId = await firestore.addSession(session);

      // 마지막 촬영 시간 업데이트
      await ref.read(customerActionsProvider).updateLastShooting(customerId);

      if (mounted) {
        context.go('/camera/$customerId/$sessionId/before');
      }
    } catch (e, stack) {
      print('❌ 촬영 시작 실패: $e');
      print('Stack trace: $stack');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('촬영 시작 실패: ${e.toString().replaceAll("Exception:", "").trim()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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

    return InkWell(
      onTap: () => _showCustomerOptions(context, ref),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            sessionsAsync.when(
              data: (sessions) {
                // 마지막 세션 가져오기
                final lastSession = sessions.isNotEmpty ? sessions.first : null;

                return Row(
                  children: [
                    // 프로필 이미지 (마지막 촬영 이미지 또는 이니셜)
                    lastSession?.beforeImageUrl != null
                        ? CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(lastSession!.beforeImageUrl!),
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          )
                        : CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                            child: Text(
                              customer.name.isNotEmpty ? customer.name[0] : '?',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
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
                          Text(
                            customer.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer.lastShootingAt != null
                                ? '최근 촬영: ${DateFormat('yyyy.MM.dd').format(customer.lastShootingAt!)}'
                                : '촬영 기록 없음',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          if (lastSession != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _getSessionStatus(lastSession),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getSessionStatusColor(context, lastSession),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '${sessions.length}회',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ],
                );
              },
              loading: () => Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0] : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
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
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.lastShootingAt != null
                              ? '최근 촬영: ${DateFormat('yyyy.MM.dd').format(customer.lastShootingAt!)}'
                              : '촬영 기록 없음',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
              error: (e, stack) => Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0] : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
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
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.lastShootingAt != null
                              ? '최근 촬영: ${DateFormat('yyyy.MM.dd').format(customer.lastShootingAt!)}'
                              : '촬영 기록 없음',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('세션 로드 오류'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '에러 내용:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                SelectableText(e.toString()),
                                const SizedBox(height: 16),
                                const Text(
                                  '가능한 원인:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '1. Firestore 인덱스 미배포\n'
                                  '2. 보안 규칙 문제\n'
                                  '3. 네트워크 연결 문제',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('확인'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ],
              ),
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
    );
  }

  Future<void> _showCustomerOptions(BuildContext context, WidgetRef ref) async {
    final sessionsAsync = ref.read(sessionListProvider(customer.id!));

    // 에러 체크
    if (sessionsAsync.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('세션 로드 실패: ${sessionsAsync.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    final sessions = sessionsAsync.valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
              title: const Text('새 촬영 시작'),
              onTap: () {
                Navigator.pop(context);
                _startNewSession(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onSurface),
              title: const Text('이름 수정'),
              onTap: () {
                Navigator.pop(context);
                _showEditNameDialog(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: const Text('고객 삭제'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteCustomer(context, ref);
              },
            ),
            if (sessions.isNotEmpty) ...[
              Divider(color: Theme.of(context).dividerColor),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '이전 촬영 기록',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error, size: 20),
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

  Future<void> _showEditNameDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController(text: customer.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고객 이름 수정'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '고객 이름',
            hintText: '새 이름을 입력하세요',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (newName != null && newName != customer.name) {
      try {
        await ref.read(customerActionsProvider).updateCustomerName(
              customer.id!,
              newName,
            );

        if (context.mounted) {
          _showToast(context, '고객 이름이 수정되었습니다');
        }
      } catch (e) {
        if (context.mounted) {
          _showToast(context, '이름 수정 실패: $e', isError: true);
        }
      }
    }

    nameController.dispose();
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _startNewSession(BuildContext context, WidgetRef ref) async {
    try {
      final userId = ref.read(currentUserProvider)?.uid;
      if (userId == null) {
        throw Exception('로그인 정보를 찾을 수 없습니다');
      }

      final firestore = ref.read(firestoreServiceProvider);
      final session = ShootingSession(
        userId: userId,
        customerId: customer.id!,
      );

      final sessionId = await firestore.addSession(session);

      // 마지막 촬영 시간 업데이트
      await ref.read(customerActionsProvider).updateLastShooting(customer.id!);

      if (context.mounted) {
        context.go('/camera/${customer.id}/$sessionId/before');
      }
    } catch (e, stack) {
      print('❌ 촬영 시작 실패 (고객 카드): $e');
      print('Stack trace: $stack');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('촬영 시작 실패: ${e.toString().replaceAll("Exception:", "").trim()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteCustomer(BuildContext context, WidgetRef ref) async {
    final sessionsAsync = ref.read(sessionListProvider(customer.id!));
    final sessions = sessionsAsync.valueOrNull ?? [];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
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
            .read(customerActionsProvider)
            .deleteCustomer(customer.id!);

        if (context.mounted) {
          _showToast(context, '${customer.name} 고객이 삭제되었습니다');
        }
      } catch (e) {
        if (context.mounted) {
          _showToast(context, '삭제 중 오류가 발생했습니다: $e', isError: true);
        }
      }
    }
  }

  Future<void> _confirmDeleteSession(
      BuildContext context, WidgetRef ref, ShootingSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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
          .read(sessionActionsProvider)
          .deleteSession(session.id!);

      if (context.mounted) {
        Navigator.pop(context);
        _showToast(context, '촬영 기록이 삭제되었습니다');
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

  String _getSessionStatus(ShootingSession session) {
    if (!session.hasBeforeImage) {
      return '촬영 전';
    } else if (!session.hasAfterImage) {
      return 'After 촬영 대기';
    } else if (session.hasAnalysis) {
      return '분석 완료';
    } else {
      return '촬영 완료';
    }
  }

  Color _getSessionStatusColor(BuildContext context, ShootingSession session) {
    if (!session.hasBeforeImage) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    } else if (!session.hasAfterImage) {
      return AppColors.warning;
    } else if (session.hasAnalysis) {
      return AppColors.success;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }
}

class _AddCustomerDialog extends ConsumerStatefulWidget {
  const _AddCustomerDialog();

  @override
  ConsumerState<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<_AddCustomerDialog> {
  final _nameController = TextEditingController();
  final _memoController = TextEditingController();
  String? _selectedGroupId;

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupListProvider);

    return AlertDialog(
      title: const Text('새 고객 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이름 입력
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '고객 이름 *',
                hintText: '이름을 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 그룹 선택
            groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const SizedBox.shrink(),
              data: (groups) {
                if (groups.isEmpty) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          '아직 그룹이 없습니다',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/groups');
                        },
                        child: const Text('그룹 추가'),
                      ),
                    ],
                  );
                }

                return DropdownButtonFormField<String>(
                  value: _selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: '그룹',
                    hintText: '그룹 선택 (선택사항)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('일반 고객'),
                    ),
                    ...groups.map((group) {
                      final color = group.color != null
                          ? Color(int.parse(group.color!.substring(1), radix: 16) + 0xFF000000)
                          : Theme.of(context).colorScheme.primary;

                      return DropdownMenuItem(
                        value: group.id,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(group.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedGroupId = value);
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // 메모 입력
            TextField(
              controller: _memoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '메모',
                hintText: '메모 입력 (선택사항)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('고객 이름을 입력해주세요')),
              );
              return;
            }

            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'group': _selectedGroupId,
              'memo': _memoController.text.trim().isEmpty
                  ? null
                  : _memoController.text.trim(),
            });
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
