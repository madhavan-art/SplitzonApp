// ════════════════════════════════════════════════════════════════
// FILE: lib/providers/expense_provider.dart
// ════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import '../data/models/expense_model.dart';
import '../data/repositories/expense_repository.dart';
import '../services/expense_sync_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseRepository _repo;

  final Map<String, List<Expense>> _expensesByGroup = {};
  final Map<String, bool> _loadingByGroup = {};

  String? _authToken;
  String? _userId;
  ExpenseSyncService? _sync;

  ExpenseProvider({ExpenseRepository? repo})
    : _repo = repo ?? ExpenseRepository();

  void _log(String m) => debugPrint('💰 ExpenseProvider: $m');
  void _err(String m) => debugPrint('❌ ExpenseProvider: $m');

  // ── AUTH SETUP ───────────────────────────────────────────────
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
      _log('ExpenseSyncService ready');
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

  // ── GETTERS ──────────────────────────────────────────────────
  List<Expense> getExpenses(String groupId) => _expensesByGroup[groupId] ?? [];

  /// NEW METHOD: Get ALL expenses across all groups (used by BalanceCard / Dashboard)
  List<Expense> getAllExpenses() {
    List<Expense> all = [];
    for (var list in _expensesByGroup.values) {
      all.addAll(list);
    }
    return all;
  }

  bool isLoading(String groupId) => _loadingByGroup[groupId] ?? false;

  // ── LOAD EXPENSES ────────────────────────────────────────────
  Future<void> loadExpenses(String groupId) async {
    if (_userId == null) return;

    _loadingByGroup[groupId] = true;
    notifyListeners();

    try {
      final local = await _repo.fetchExpensesByGroup(groupId);
      _expensesByGroup[groupId] = local;
      notifyListeners();

      _backgroundSync(groupId);
    } catch (e) {
      _err('loadExpenses error: $e');
    } finally {
      _loadingByGroup[groupId] = false;
      notifyListeners();
    }
  }

  void _backgroundSync(String groupId) {
    if (_authToken == null || _sync == null) return;
    _syncFromBackend(
      groupId,
    ).catchError((e) => _err('Background sync failed: $e'));
  }

  // ── FIXED SYNC - PROTECTS OFFLINE EDITS ──────────────────────
  Future<void> _syncFromBackend(String groupId) async {
    if (_sync == null || _authToken == null) return;

    final online = await _isConnected();
    if (!online) return;

    _log('🔄 Syncing group $groupId...');

    // 1. Push pending changes first
    await _sync!.syncPendingExpenses(_authToken!);

    // 2. Pull from backend
    final backendExpenses = await _sync!.fetchAndSyncGroupExpenses(
      groupId,
      _authToken!,
    );

    // 3. Smart Merge - Protect local PENDING / PENDING_UPDATE
    final currentLocal = _expensesByGroup[groupId] ?? [];
    final merged = <Expense>[];

    for (var be in backendExpenses) {
      merged.add(be);
    }

    for (var localExpense in currentLocal) {
      if (localExpense.syncStatus == 'PENDING' ||
          localExpense.syncStatus == 'PENDING_UPDATE') {
        merged.removeWhere((e) => e.id == localExpense.id);
        merged.add(localExpense);
      }
    }

    merged.sort((a, b) => b.date.compareTo(a.date));

    _expensesByGroup[groupId] = merged;
    notifyListeners();

    _log(
      '✅ Sync completed - ${merged.length} expenses (offline edits protected)',
    );
  }

  // ── CREATE ───────────────────────────────────────────────────
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
    if (_userId == null) return null;

    try {
      final expense = Expense.create(
        groupId: groupId,
        userId: _userId!,
        title: title,
        amount: amount,
        category: category,
        notes: notes,
        date: date ?? DateTime.now(),
        paidByUserId: paidByUserId,
        paidByName: paidByName,
        splitType: splitType,
        memberShares: memberShares,
      );

      await _repo.addExpense(expense);

      final current = _expensesByGroup[groupId] ?? [];
      _expensesByGroup[groupId] = [expense, ...current];
      notifyListeners();

      if (await _isConnected() && _authToken != null && _sync != null) {
        final result = await _sync!.syncImmediately(expense, _authToken!);
        if (result['success'] == true) {
          await _syncFromBackend(groupId);
        }
      }
      return expense;
    } catch (e) {
      _err('createExpense error: $e');
      return null;
    }
  }

  // ── UPDATE ───────────────────────────────────────────────────
  Future<Expense?> updateExpense(Expense updatedExpense) async {
    _log('updateExpense(${updatedExpense.id})');

    try {
      final pendingExpense = updatedExpense.copyWith(
        syncStatus: updatedExpense.syncStatus == 'SYNCED'
            ? 'PENDING_UPDATE'
            : updatedExpense.syncStatus,
      );

      await _repo.updateExpense(pendingExpense);

      final groupId = pendingExpense.groupId;
      final list = _expensesByGroup[groupId] ?? [];
      final idx = list.indexWhere((e) => e.id == pendingExpense.id);
      if (idx != -1) list[idx] = pendingExpense;

      notifyListeners();

      if (await _isConnected() && _authToken != null && _sync != null) {
        final ok = await _sync!.updateInBackend(pendingExpense, _authToken!);
        if (ok) await _syncFromBackend(groupId);
      }

      return pendingExpense;
    } catch (e) {
      _err('updateExpense error: $e');
      return null;
    }
  }

  // ── DELETE ───────────────────────────────────────────────────
  Future<bool> deleteExpense(String expenseId, String groupId) async {
    try {
      await _repo.deleteExpense(expenseId);
      _expensesByGroup[groupId]?.removeWhere((e) => e.id == expenseId);
      notifyListeners();

      if (_authToken != null && _sync != null) {
        final online = await _isConnected();
        if (online) {
          await _sync!.deleteFromBackend(expenseId, _authToken!);
        }
      }
      return true;
    } catch (e) {
      _err('deleteExpense error: $e');
      return false;
    }
  }

  Future<bool> _isConnected() async {
    try {
      final r = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return r.isNotEmpty && r[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncWithBackend(String groupId) async =>
      _syncFromBackend(groupId);

  Future<void> syncAllGroupsWithBackend() async {
    for (final groupId in _expensesByGroup.keys) {
      await _syncFromBackend(groupId);
    }
  }
}
