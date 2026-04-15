// ════════════════════════════════════════════════════════════════
// FILE: lib/providers/expense_provider.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../data/models/expense_model.dart';
import '../data/repositories/expense_repository.dart';
import '../services/expense_sync_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseRepository _repo;

  // expenses keyed by groupId so multiple group screens can coexist
  final Map<String, List<Expense>> _expensesByGroup = {};
  final Map<String, bool> _loadingByGroup = {};

  String? _authToken;
  String? _userId;
  ExpenseSyncService? _sync;

  ExpenseProvider({ExpenseRepository? repo})
    : _repo = repo ?? ExpenseRepository();

  void _log(String m) => debugPrint('💰 ExpenseProvider: $m');
  void _err(String m) => debugPrint('❌ ExpenseProvider: $m');

  // ── AUTH SETUP ────────────────────────────────────────────
  void setAuthToken(String token) {
    _authToken = token;
    _rebuildSync();
  }

  void setUserId(String userId) {
    _userId = userId;
    _rebuildSync();
  }

  void _rebuildSync() {
    if (_userId != null && _userId!.isNotEmpty) {
      _sync = ExpenseSyncService(userId: _userId);
    }
  }

  void clearForLogout() {
    _expensesByGroup.clear();
    _loadingByGroup.clear();
    _authToken = null;
    _userId = null;
    _sync = null;
    notifyListeners();
  }

  // ── GETTERS ───────────────────────────────────────────────
  List<Expense> getExpenses(String groupId) => _expensesByGroup[groupId] ?? [];

  bool isLoading(String groupId) => _loadingByGroup[groupId] ?? false;

  double totalExpenses(String groupId) =>
      getExpenses(groupId).fold(0.0, (sum, e) => sum + e.amount);

  // ── LOAD EXPENSES FOR A GROUP ─────────────────────────────
  Future<void> loadExpenses(String groupId) async {
    if (_userId == null) return;

    _loadingByGroup[groupId] = true;
    notifyListeners();

    try {
      // Step 1: SQLite first (instant)
      _expensesByGroup[groupId] = await _repo.fetchExpensesByGroup(groupId);
      _loadingByGroup[groupId] = false;
      notifyListeners();
      _log(
        'SQLite has ${_expensesByGroup[groupId]!.length} expenses for $groupId',
      );

      // Step 2: Backend sync in background
      if (_authToken != null && _sync != null) {
        await _fetchFromBackendAndRefresh(groupId);
      }
    } catch (e) {
      _loadingByGroup[groupId] = false;
      notifyListeners();
      _err('loadExpenses error: $e');
    }
  }

  // ── CORE: fetch backend → save SQLite → refresh UI ────────
  Future<void> _fetchFromBackendAndRefresh(String groupId) async {
    if (_sync == null || _authToken == null) return;
    try {
      // Push pending first
      await _sync!.syncPendingExpenses(_authToken!);

      // Pull from backend
      final backendExpenses = await _sync!.fetchAndSyncGroupExpenses(
        groupId,
        _authToken!,
      );
      _log('Got ${backendExpenses.length} expenses from backend for $groupId');

      // Remove stale (deleted from backend)
      await _removeStaleExpenses(groupId, backendExpenses);

      // Reload SQLite
      _expensesByGroup[groupId] = await _repo.fetchExpensesByGroup(groupId);
      notifyListeners();
      _log('UI updated: ${_expensesByGroup[groupId]!.length} expenses');
    } catch (e) {
      _err('Backend sync failed — using cache: $e');
    }
  }

  Future<void> _removeStaleExpenses(
    String groupId,
    List<Expense> backendExpenses,
  ) async {
    final backendIds = backendExpenses.map((e) => e.id).toSet();
    final local = await _repo.fetchExpensesByGroup(groupId);
    final stale = local.where(
      (e) => e.syncStatus == 'SYNCED' && !backendIds.contains(e.id),
    );
    for (final e in stale) {
      await _repo.deleteExpense(e.id);
      _log('Removed stale expense: ${e.title}');
    }
  }

  // ── PUBLIC SYNC (called by ConnectivityService) ───────────
  Future<void> syncWithBackend(String groupId) async {
    if (_authToken == null || _sync == null) return;
    await _fetchFromBackendAndRefresh(groupId);
  }

  // ── CREATE EXPENSE ────────────────────────────────────────
  Future<Expense?> createExpense({
    required String groupId,
    required String title,
    required double amount,
    String category = 'Other',
    String notes = '',
    DateTime? date,
    required String paidByUserId,
    required String paidByName,
    required String splitType,
    required List<MemberShare> memberShares,
  }) async {
    if (_userId == null) {
      _err('No userId — cannot create expense');
      return null;
    }

    try {
      final expense = Expense.create(
        groupId: groupId,
        userId: _userId!,
        title: title,
        amount: amount,
        category: category,
        notes: notes,
        date: date,
        paidByUserId: paidByUserId,
        paidByName: paidByName,
        splitType: splitType,
        memberShares: memberShares,
      );

      // Save to SQLite immediately
      await _repo.addExpense(expense);
      final current = _expensesByGroup[groupId] ?? [];
      _expensesByGroup[groupId] = [expense, ...current];
      notifyListeners();
      _log('Saved expense locally: ${expense.id}');

      // Try immediate backend sync
      if (_authToken != null && _sync != null) {
        final result = await _sync!.syncImmediately(expense, _authToken!);
        if (result['success'] == true) {
          // Pull fresh data from backend (gets real MongoDB _id)
          await _fetchFromBackendAndRefresh(groupId);
          _log('Expense synced to backend ✅');
        } else {
          _err('Expense sync failed — stays PENDING');
        }
      } else {
        _log('Offline — expense stays PENDING until internet returns');
      }

      return expense;
    } catch (e) {
      _err('createExpense error: $e');
      return null;
    }
  }

  // ── DELETE EXPENSE ────────────────────────────────────────
  Future<bool> deleteExpense(String expenseId, String groupId) async {
    try {
      final expense = getExpenses(groupId).firstWhere((e) => e.id == expenseId);

      await _repo.deleteExpense(expenseId);
      _expensesByGroup[groupId]?.removeWhere((e) => e.id == expenseId);
      notifyListeners();

      if (expense.syncStatus == 'SYNCED' &&
          _authToken != null &&
          _sync != null) {
        await _sync!.deleteFromBackend(expenseId, _authToken!);
      }
      return true;
    } catch (e) {
      _err('deleteExpense error: $e');
      return false;
    }
  }

  List<Expense> getPendingExpenses(String groupId) =>
      getExpenses(groupId).where((e) => e.syncStatus == 'PENDING').toList();
}
