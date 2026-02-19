import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
      result =
          result.where((c) => c.name.toLowerCase().contains(query)).toList();
    }

    // 날짜 필터
    if (_filterDate != null) {
      result =
          result.where((c) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundGradient = <Color>[
      isDark ? AppColors.darkBackground : AppColors.background,
      isDark
          ? AppColors.darkSurfaceLight.withValues(alpha: 0.55)
          : AppColors.surfaceTint.withValues(alpha: 0.45),
    ];

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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                isDark
                    ? AppColors.darkSurfaceLight.withValues(alpha: 0.55)
                    : AppColors.surfaceTint.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
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
              color:
                  _showSearch
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                builder:
                    (context) => AlertDialog(
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
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backgroundGradient,
          ),
        ),
        child: Column(
          children: [
            // 검색 바
            if (_showSearch) _buildSearchBar(),
            // 고객 목록
            Expanded(
              child: customersAsync.when(
                loading:
                    () => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            '고객 목록 불러오는 중...',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                error:
                    (e, s) => Center(
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text('새 고객 촬영'),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchPanelColor =
        isDark
            ? AppColors.darkSurface.withValues(alpha: 0.9)
            : AppColors.surface.withValues(alpha: 0.85);
    final searchFieldColor =
        isDark
            ? AppColors.darkSurfaceLight.withValues(alpha: 0.75)
            : AppColors.surfaceTint.withValues(alpha: 0.8);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: searchPanelColor,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            width: 1,
          ),
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
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                Icons.person_search,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                      : null,
              filled: true,
              fillColor: searchFieldColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: searchFieldColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color:
                              _filterDate != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _filterDate != null
                              ? DateFormat('yyyy.MM.dd').format(_filterDate!)
                              : '날짜로 검색',
                          style: TextStyle(
                            color:
                                _filterDate != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.6),
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
                      color: searchFieldColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 18,
                    ),
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
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
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
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
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
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.primary.withValues(alpha: 0.16),
                  AppColors.accent.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: 54,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.65),
            ),
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
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
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
      error:
          (e, s) => ListView.builder(
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
          groupedCustomers[group.id] =
              customers.where((c) => c.group == group.id).toList();
        }

        // 그룹 없는 고객
        groupedCustomers[null] =
            customers
                .where(
                  (c) => c.group == null || !groups.any((g) => g.id == c.group),
                )
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
                groupName:
                    entry.key != null
                        ? groups.firstWhere((g) => g.id == entry.key).name
                        : '일반 고객',
                groupColor:
                    entry.key != null
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
    final color =
        groupColor != null
            ? Color(int.parse(groupColor.substring(1), radix: 16) + 0xFF000000)
            : (groupId == null
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                : Theme.of(context).colorScheme.primary);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // 그룹 헤더 (클릭 가능)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 그룹 아이콘/색상
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient:
                          groupId != null
                              ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [color, color.withValues(alpha: 0.7)],
                              )
                              : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.2),
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                ],
                              ),
                      shape: BoxShape.circle,
                      boxShadow:
                          groupId != null
                              ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Icon(
                      groupId != null ? Icons.folder : Icons.people_outline,
                      color: groupId != null ? Colors.white : color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 그룹 이름
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${customers.length}명의 고객',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 펼침/접힘 아이콘
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 고객 리스트 (펼쳐졌을 때만 표시)
          if (isExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children:
                    customers
                        .map((customer) => _CustomerCard(customer: customer))
                        .toList(),
              ),
            ),
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

    if (result != null &&
        result['name'] != null &&
        result['name']!.trim().isNotEmpty) {
      final customerId = await ref
          .read(customerActionsProvider)
          .addCustomer(
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
      final session = ShootingSession(userId: userId, customerId: customerId);

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
            content: Text(
              '촬영 시작 실패: ${e.toString().replaceAll("Exception:", "").trim()}',
            ),
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
    final pendingAfter =
        sessionsAsync.valueOrNull
            ?.where((s) => s.hasBeforeImage && !s.hasAfterImage)
            .toList();
    final hasPendingAfter = pendingAfter != null && pendingAfter.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showCustomerOptions(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              sessionsAsync.when(
                data: (sessions) {
                  // 마지막 세션 가져오기
                  final lastSession =
                      sessions.isNotEmpty ? sessions.first : null;

                  return Row(
                    children: [
                      // 프로필 이미지 (마지막 촬영 이미지 또는 이니셜)
                      Stack(
                        children: [
                          lastSession?.beforeImageUrl != null
                              ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(
                                    lastSession!.beforeImageUrl!,
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                ),
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.2),
                                      Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.transparent,
                                  child: Text(
                                    customer.name.isNotEmpty
                                        ? customer.name[0]
                                        : '?',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          // 촬영 횟수 뱃지
                          if (sessions.isNotEmpty)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '${sessions.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  customer.lastShootingAt != null
                                      ? DateFormat(
                                        'yyyy.MM.dd',
                                      ).format(customer.lastShootingAt!)
                                      : '촬영 기록 없음',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            if (lastSession != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSessionStatusColor(
                                    context,
                                    lastSession,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getSessionStatusColor(
                                      context,
                                      lastSession,
                                    ).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getSessionStatusIcon(lastSession),
                                      size: 12,
                                      color: _getSessionStatusColor(
                                        context,
                                        lastSession,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getSessionStatus(lastSession),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _getSessionStatusColor(
                                          context,
                                          lastSession,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                        size: 28,
                      ),
                    ],
                  );
                },
                loading:
                    () => Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.transparent,
                            child: Text(
                              customer.name.isNotEmpty ? customer.name[0] : '?',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    customer.lastShootingAt != null
                                        ? DateFormat(
                                          'yyyy.MM.dd',
                                        ).format(customer.lastShootingAt!)
                                        : '촬영 기록 없음',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                error:
                    (e, stack) => Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.transparent,
                            child: Text(
                              customer.name.isNotEmpty ? customer.name[0] : '?',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    customer.lastShootingAt != null
                                        ? DateFormat(
                                          'yyyy.MM.dd',
                                        ).format(customer.lastShootingAt!)
                                        : '촬영 기록 없음',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('세션 로드 오류'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '에러 내용:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SelectableText(e.toString()),
                                          const SizedBox(height: 16),
                                          const Text(
                                            '가능한 원인:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
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
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
              ),
              // After 미촬영 세션 알림
              if (hasPendingAfter) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    final session = pendingAfter.first;
                    context.go('/camera/${customer.id}/${session.id}/after');
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
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
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
                  leading: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('새 촬영 시작'),
                  onTap: () {
                    Navigator.pop(context);
                    _startNewSession(context, ref);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.upload_file,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('이미지 업로드'),
                  onTap: () {
                    Navigator.pop(context);
                    _showUploadDialog(context, ref);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.edit_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  title: const Text('이름 수정'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditNameDialog(context, ref);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  ...sessions
                      .take(5)
                      .map(
                        (session) => ListTile(
                          leading: Icon(
                            session.isComplete
                                ? Icons.check_circle
                                : Icons.pending,
                            color:
                                session.isComplete
                                    ? AppColors.success
                                    : AppColors.warning,
                          ),
                          title: Text(
                            DateFormat(
                              'yyyy.MM.dd HH:mm',
                            ).format(session.createdAt),
                          ),
                          subtitle: Text(
                            session.isComplete
                                ? (session.hasAnalysis ? '분석 완료' : '비교 가능')
                                : (session.hasBeforeImage
                                    ? 'After 촬영 필요'
                                    : 'Before 촬영 필요'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            onPressed: () {
                              _confirmDeleteSession(context, ref, session);
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToSession(context, session);
                          },
                        ),
                      ),
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
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  '고객 이름 수정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '새 이름',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '이름을 입력하세요',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(context, value.trim());
                    }
                  },
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    Navigator.pop(context, nameController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );

    if (newName != null && newName != customer.name) {
      try {
        await ref
            .read(customerActionsProvider)
            .updateCustomerName(customer.id!, newName);

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

  void _showToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      final session = ShootingSession(userId: userId, customerId: customer.id!);

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
            content: Text(
              '촬영 시작 실패: ${e.toString().replaceAll("Exception:", "").trim()}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showUploadDialog(BuildContext context, WidgetRef ref) async {
    DateTime selectedDate = DateTime.now();
    File? beforeImage;
    File? afterImage;
    final imagePicker = ImagePicker();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.upload_file,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '이미지 업로드',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 날짜 선택
                        Text(
                          '촬영 날짜',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.05),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat(
                                    'yyyy년 MM월 dd일',
                                  ).format(selectedDate),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Before 이미지 선택
                        Text(
                          'Before 이미지',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await imagePicker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (picked != null) {
                              setState(() => beforeImage = File(picked.path));
                            }
                          },
                          child: Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color:
                                  beforeImage != null
                                      ? Colors.transparent
                                      : Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    beforeImage != null
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child:
                                beforeImage != null
                                    ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.file(
                                            beforeImage!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.darkSurface
                                                  .withValues(alpha: 0.7),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  () => setState(
                                                    () => beforeImage = null,
                                                  ),
                                              padding: const EdgeInsets.all(4),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                    : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 48,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '갤러리에서 선택',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // After 이미지 선택
                        Text(
                          'After 이미지',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await imagePicker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (picked != null) {
                              setState(() => afterImage = File(picked.path));
                            }
                          },
                          child: Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color:
                                  afterImage != null
                                      ? Colors.transparent
                                      : Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    afterImage != null
                                        ? AppColors.success
                                        : Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child:
                                afterImage != null
                                    ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.file(
                                            afterImage!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.darkSurface
                                                  .withValues(alpha: 0.7),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  () => setState(
                                                    () => afterImage = null,
                                                  ),
                                              padding: const EdgeInsets.all(4),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                    : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 48,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '갤러리에서 선택',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
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
                  actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          beforeImage == null && afterImage == null
                              ? null
                              : () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '업로드',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );

    if (result == true && (beforeImage != null || afterImage != null)) {
      if (context.mounted) {
        _uploadImages(context, ref, selectedDate, beforeImage, afterImage);
      }
    }
  }

  Future<void> _uploadImages(
    BuildContext context,
    WidgetRef ref,
    DateTime shootingDate,
    File? beforeImage,
    File? afterImage,
  ) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('이미지 업로드 중...'),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final userId = ref.read(currentUserProvider)?.uid;
      if (userId == null) {
        throw Exception('로그인 정보를 찾을 수 없습니다');
      }

      final firestore = ref.read(firestoreServiceProvider);
      final storage = ref.read(storageServiceProvider);

      // 세션 생성 (날짜 지정)
      final session = ShootingSession(
        userId: userId,
        customerId: customer.id!,
        createdAt: shootingDate,
      );

      final sessionId = await firestore.addSession(session);

      // Before 이미지 업로드
      String? beforeUrl;
      if (beforeImage != null) {
        beforeUrl = await storage.uploadImage(
          imageFile: beforeImage,
          userId: userId,
          folder: 'before',
          customFileName: '${customer.id}_${sessionId}_before.jpg',
        );
      }

      // After 이미지 업로드
      String? afterUrl;
      if (afterImage != null) {
        afterUrl = await storage.uploadImage(
          imageFile: afterImage,
          userId: userId,
          folder: 'after',
          customFileName: '${customer.id}_${sessionId}_after.jpg',
        );
      }

      // 세션 업데이트
      if (beforeUrl != null || afterUrl != null) {
        await firestore.updateSession(
          session.copyWith(beforeImageUrl: beforeUrl, afterImageUrl: afterUrl),
        );
      }

      // 마지막 촬영 시간 업데이트
      await ref.read(customerActionsProvider).updateLastShooting(customer.id!);

      if (context.mounted) {
        Navigator.pop(context); // 로딩 닫기
        _showToast(context, '이미지가 업로드되었습니다');

        // 비교 화면으로 이동 (둘 다 있으면) 또는 카메라로 이동
        if (beforeUrl != null && afterUrl != null) {
          context.go('/comparison/$sessionId');
        } else if (beforeUrl != null) {
          context.go('/camera/${customer.id}/$sessionId/after');
        } else if (afterUrl != null) {
          context.go('/camera/${customer.id}/$sessionId/before');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 로딩 닫기
        _showToast(context, '업로드 실패: $e', isError: true);
      }
    }
  }

  Future<void> _confirmDeleteCustomer(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final sessionsAsync = ref.read(sessionListProvider(customer.id!));
    final sessions = sessionsAsync.valueOrNull ?? [];

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '고객 삭제',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              '${customer.name} 고객을 삭제하시겠습니까?\n\n'
              '${sessions.length}건의 촬영 기록과 이미지도 모두 삭제됩니다.',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '삭제',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
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

        await ref.read(customerActionsProvider).deleteCustomer(customer.id!);

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
    BuildContext context,
    WidgetRef ref,
    ShootingSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '촬영 기록 삭제',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              '${DateFormat('yyyy.MM.dd HH:mm').format(session.createdAt)} 기록을 삭제하시겠습니까?\n\n이미지 파일도 함께 삭제됩니다.',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '삭제',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
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

      await ref.read(sessionActionsProvider).deleteSession(session.id!);

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

  IconData _getSessionStatusIcon(ShootingSession session) {
    if (!session.hasBeforeImage) {
      return Icons.hourglass_empty;
    } else if (!session.hasAfterImage) {
      return Icons.camera_alt;
    } else if (session.hasAnalysis) {
      return Icons.analytics;
    } else {
      return Icons.check_circle;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_add, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            '새 고객 추가',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이름 입력
            Text(
              '고객 이름',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: '이름을 입력하세요',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 그룹 선택
            Text(
              '그룹 (선택사항)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const SizedBox.shrink(),
              data: (groups) {
                if (groups.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '아직 그룹이 없습니다',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/groups');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                          child: const Text('그룹 추가'),
                        ),
                      ],
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: _selectedGroupId,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '그룹 선택',
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('일반 고객'),
                    ),
                    ...groups.map((group) {
                      final color =
                          group.color != null
                              ? Color(
                                int.parse(
                                      group.color!.substring(1),
                                      radix: 16,
                                    ) +
                                    0xFF000000,
                              )
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
            const SizedBox(height: 20),

            // 메모 입력
            Text(
              '메모 (선택사항)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              maxLines: 3,
              style: TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: '메모를 입력하세요',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            '취소',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('고객 이름을 입력해주세요'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              return;
            }

            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'group': _selectedGroupId,
              'memo':
                  _memoController.text.trim().isEmpty
                      ? null
                      : _memoController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            '추가',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
