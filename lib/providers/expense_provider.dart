// ════════════════════════════════════════════════════════════════
// FILE: lib/providers/expense_provider.dart
// ════════════════════════════════════════════════════════════════
//
// OFFLINE-FIRST FLOW:
//
// loadExpenses()
//   Step 1 → SQLite → UI immediately
//   Step 2 → background backend sync
//
// createExpense()
//   Step 1 → SQLite (PENDING) → UI immediately
//   Step 2 → push to backend if online → SYNCED
//
// updateExpense()
//   Step 1 → SQLite (PENDING_UPDATE) → UI immediately
//   Step 2 → push to backend if online → SYNCED
//
// deleteExpense()
//   Step 1 → SQLite delete → UI immediately
//   Step 2 → delete backend if online (SYNCED expenses only)
//
// Offline → ConnectivityService detects reconnect → syncWithBackend() auto-called
// ════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import '../data/models/expense_model.dart';
import '../data/repositories/expense_repository.dart';
import '../services/expense_sync_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseRepository _repo;

  // Keyed by groupId
  final Map<String, List<Expense>> _expensesByGroup = {};
  final Map<String, bool> _loadingByGroup = {};

  String? _authToken;
  String? _userId;
  ExpenseSyncService? _sync;

  ExpenseProvider({ExpenseRepository? repo})
    : _repo = repo ?? ExpenseRepository();

  void _log(String m) => debugPrint('💰 ExpenseProvider: $m');
  void _err(String m) => debugPrint('❌ ExpenseProvider: $m');

  // ─────────────────────────────────────────────────────────
  // AUTH SETUP
  // ─────────────────────────────────────────────────────────

  void setAuthToken(String token) {
    _authToken = token;
    _rebuildSync();
    _log('Auth token set ✅');
  }

  void setUserId(String userId) {
    _userId = userId;
    _rebuildSync();
    _log('UserId set: $userId ✅');
  }

  void _rebuildSync() {
    if (_userId != null && _userId!.isNotEmpty) {
      _sync = ExpenseSyncService(userId: _userId);
      _log('ExpenseSyncService ready for user: $_userId');
    }
  }

  // ─────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────

  void clearForLogout() {
    _expensesByGroup.clear();
    _loadingByGroup.clear();
    _authToken = null;
    _userId = null;
    _sync = null;
    notifyListeners();
    _log('Cleared for logout ✅');
  }

  // ─────────────────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────────────────

  List<Expense> getExpenses(String groupId) => _expensesByGroup[groupId] ?? [];

  List<Expense> getAllExpenses() {
    final all = <Expense>[];
    for (final list in _expensesByGroup.values) {
      all.addAll(list);
    }
    return all;
  }

  bool isLoading(String groupId) => _loadingByGroup[groupId] ?? false;

  double totalExpensesForGroup(String groupId) =>
      getExpenses(groupId).fold(0.0, (s, e) => s + e.amount);

  List<Expense> getPendingExpenses(String groupId) => getExpenses(groupId)
      .where(
        (e) => e.syncStatus == 'PENDING' || e.syncStatus == 'PENDING_UPDATE',
      )
      .toList();

  // ─────────────────────────────────────────────────────────
  // LOAD EXPENSES
  // ─────────────────────────────────────────────────────────

  Future<void> loadExpenses(String groupId) async {
    if (_userId == null) {
      _err('loadExpenses skipped — userId not set');
      return;
    }

    _log('loadExpenses($groupId)');
    _loadingByGroup[groupId] = true;
    notifyListeners();

    try {
      // Step 1: SQLite → show immediately
      final local = await _repo.fetchExpensesByGroup(groupId);
      _expensesByGroup[groupId] = local;
      _loadingByGroup[groupId] = false;
      notifyListeners();
      _log('SQLite: ${local.length} expenses loaded ✅');

      // Step 2: Background sync (non-blocking)
      _backgroundSync(groupId);
    } catch (e) {
      _loadingByGroup[groupId] = false;
      notifyListeners();
      _err('loadExpenses SQLite error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // BACKGROUND SYNC
  // ─────────────────────────────────────────────────────────

  void _backgroundSync(String groupId) {
    if (_authToken == null || _sync == null) return;
    _syncFromBackend(groupId).catchError((e) {
      _err('Background sync failed (offline OK): $e');
    });
  }

  Future<void> _syncFromBackend(String groupId) async {
    if (_sync == null || _authToken == null) return;

    final online = await _isConnected();
    if (!online) {
      _log('Offline — background sync skipped');
      return;
    }

    _log('Online — syncing group $groupId from backend...');

    // Push ALL pending (new + updates) first
    await _sync!.syncPendingExpenses(_authToken!);

    // Pull from backend
    final backend = await _sync!.fetchAndSyncGroupExpenses(
      groupId,
      _authToken!,
    );
    _log('Pulled ${backend.length} from backend');

    // Remove stale
    await _removeStaleExpenses(groupId, backend);

    // Reload SQLite → update UI
    _expensesByGroup[groupId] = await _repo.fetchExpensesByGroup(groupId);
    notifyListeners();
    _log('UI refreshed → ${getExpenses(groupId).length} expenses');
  }

  Future<void> _removeStaleExpenses(
    String groupId,
    List<Expense> backendExpenses,
  ) async {
    final backendIds = backendExpenses.map((e) => e.id).toSet();
    final local = await _repo.fetchExpensesByGroup(groupId);
    for (final e in local) {
      if (e.syncStatus == 'SYNCED' && !backendIds.contains(e.id)) {
        await _repo.deleteExpense(e.id);
        _log('Removed stale: ${e.title}');
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // PUBLIC: called by ConnectivityService when back online
  // ─────────────────────────────────────────────────────────

  Future<void> syncWithBackend(String groupId) async {
    _log('syncWithBackend($groupId) — connectivity restored');
    await _syncFromBackend(groupId);
  }

  /// Sync ALL groups that are currently loaded (called by ConnectivityService)
  Future<void> syncAllGroupsWithBackend() async {
    for (final groupId in _expensesByGroup.keys) {
      await _syncFromBackend(groupId);
    }
  }

  // ─────────────────────────────────────────────────────────
  // CREATE EXPENSE
  // ─────────────────────────────────────────────────────────

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
      _err('createExpense skipped — no userId');
      return null;
    }

    _log('createExpense: "$title" ₹$amount');

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

      // Step 1: SQLite + UI
      await _repo.addExpense(expense);
      final current = _expensesByGroup[groupId] ?? [];
      _expensesByGroup[groupId] = [expense, ...current];
      notifyListeners();
      _log('Saved PENDING to SQLite ✅');

      // Step 2: Backend (non-blocking)
      final online = await _isConnected();
      if (!online) {
        _log('Offline — stays PENDING, auto-syncs when online');
        return expense;
      }

      if (_authToken != null && _sync != null) {
        final result = await _sync!.syncImmediately(expense, _authToken!);
        if (result['success'] == true) {
          _log('Pushed to backend ✅ — refreshing...');
          await _syncFromBackend(groupId);
        } else {
          _err('Backend push failed: ${result['message']} — stays PENDING');
        }
      }

      return expense;
    } catch (e) {
      _err('createExpense error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────
  // UPDATE EXPENSE
  // ─────────────────────────────────────────────────────────

  Future<Expense?> updateExpense(Expense updatedExpense) async {
    _log('updateExpense(${updatedExpense.id})');

    try {
      // Step 1: Mark PENDING_UPDATE in SQLite → UI immediately
      final pendingExpense = updatedExpense.copyWith(
        syncStatus: updatedExpense.syncStatus == 'SYNCED'
            ? 'PENDING_UPDATE'
            : updatedExpense.syncStatus, // keep PENDING if never synced
      );

      await _repo.updateExpense(pendingExpense);

      // Update in-memory list
      final groupId = pendingExpense.groupId;
      final list = _expensesByGroup[groupId] ?? [];
      final idx = list.indexWhere((e) => e.id == pendingExpense.id);
      if (idx != -1) {
        list[idx] = pendingExpense;
        _expensesByGroup[groupId] = List.from(list);
      }
      notifyListeners();
      _log('Updated in SQLite (PENDING_UPDATE) + UI ✅');

      // Step 2: Push to backend if online
      final online = await _isConnected();
      if (!online) {
        _log('Offline — stays PENDING_UPDATE, auto-syncs when online');
        return pendingExpense;
      }

      if (_authToken != null && _sync != null) {
        bool ok = false;

        if (pendingExpense.syncStatus == 'PENDING') {
          // Never pushed before — use create endpoint
          final result = await _sync!.syncImmediately(
            pendingExpense,
            _authToken!,
          );
          ok = result['success'] == true;
        } else {
          // Already on backend — use update endpoint
          ok = await _sync!.updateInBackend(pendingExpense, _authToken!);
        }

        if (ok) {
          _log('Backend updated ✅ — refreshing...');
          await _syncFromBackend(groupId);
          // Return the refreshed version from memory
          final refreshed = (_expensesByGroup[groupId] ?? []).firstWhere(
            (e) => e.id == updatedExpense.id,
            orElse: () => pendingExpense,
          );
          return refreshed;
        } else {
          _err('Backend update failed — stays PENDING_UPDATE');
          return pendingExpense;
        }
      }

      return pendingExpense;
    } catch (e) {
      _err('updateExpense error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────
  // DELETE EXPENSE
  // ─────────────────────────────────────────────────────────

  Future<bool> deleteExpense(String expenseId, String groupId) async {
    _log('deleteExpense($expenseId)');

    try {
      final expenses = getExpenses(groupId);
      final expense = expenses.firstWhere(
        (e) => e.id == expenseId,
        orElse: () => throw Exception('Expense not found locally'),
      );

      final wasSynced = expense.syncStatus == 'SYNCED';

      // Step 1: Delete from SQLite + UI
      await _repo.deleteExpense(expenseId);
      _expensesByGroup[groupId]?.removeWhere((e) => e.id == expenseId);
      notifyListeners();
      _log('Deleted from SQLite + UI ✅');

      // Step 2: Delete from backend only if was synced
      if (wasSynced && _authToken != null && _sync != null) {
        final online = await _isConnected();
        if (online) {
          final ok = await _sync!.deleteFromBackend(expenseId, _authToken!);
          _log(
            ok ? 'Deleted from backend ✅' : 'Backend delete failed (local OK)',
          );
        } else {
          // Backend delete will NOT auto-retry (expense already removed from UI)
          // This is acceptable — orphaned backend record gets cleaned on next full sync
          _log('Offline — backend delete skipped (stale cleanup on next sync)');
        }
      }

      return true;
    } catch (e) {
      _err('deleteExpense error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // INTERNET CHECK
  // ─────────────────────────────────────────────────────────

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
}

// // ════════════════════════════════════════════════════════════════
// // FILE: lib/providers/expense_provider.dart
// // ════════════════════════════════════════════════════════════════
// //
// // OFFLINE-FIRST FLOW:
// //  loadExpenses()
// //    Step 1 → Load SQLite → show UI IMMEDIATELY (no network needed)
// //    Step 2 → Fire background sync (silent fail if offline)
// //
// // createExpense()
// //    Step 1 → Save SQLite → show in UI immediately
// //    Step 2 → Try backend (stays PENDING if offline, auto-syncs later)
// //
// // ════════════════════════════════════════════════════════════════

// import 'dart:io';
// import 'package:flutter/material.dart';
// import '../data/models/expense_model.dart';
// import '../data/repositories/expense_repository.dart';
// import '../services/expense_sync_service.dart';

// class ExpenseProvider with ChangeNotifier {
//   final ExpenseRepository _repo;

//   // Keyed by groupId
//   final Map<String, List<Expense>> _expensesByGroup = {};
//   final Map<String, bool> _loadingByGroup = {};

//   String? _authToken;
//   String? _userId;
//   ExpenseSyncService? _sync;

//   ExpenseProvider({ExpenseRepository? repo})
//     : _repo = repo ?? ExpenseRepository();

//   // ─────────────────────────────────────────────────────────
//   void _log(String m) => debugPrint('💰 ExpenseProvider: $m');
//   void _err(String m) => debugPrint('❌ ExpenseProvider: $m');

//   // ─────────────────────────────────────────────────────────
//   // AUTH SETUP
//   // ─────────────────────────────────────────────────────────

//   void setAuthToken(String token) {
//     _authToken = token;
//     _rebuildSync();
//     _log('Auth token set ✅');
//   }

//   void setUserId(String userId) {
//     _userId = userId;
//     _rebuildSync();
//     _log('UserId set: $userId ✅');
//   }

//   void _rebuildSync() {
//     if (_userId != null && _userId!.isNotEmpty) {
//       _sync = ExpenseSyncService(userId: _userId);
//       _log('ExpenseSyncService ready for user: $_userId');
//     }
//   }

//   // ─────────────────────────────────────────────────────────
//   // LOGOUT
//   // ─────────────────────────────────────────────────────────

//   void clearForLogout() {
//     _log('Clearing for logout...');
//     _expensesByGroup.clear();
//     _loadingByGroup.clear();
//     _authToken = null;
//     _userId = null;
//     _sync = null;
//     notifyListeners();
//     _log('Cleared ✅');
//   }

//   // ─────────────────────────────────────────────────────────
//   // GETTERS
//   // ─────────────────────────────────────────────────────────

//   List<Expense> getExpenses(String groupId) => _expensesByGroup[groupId] ?? [];

//   /// All expenses across all groups — used by BalanceCard dashboard
//   List<Expense> getAllExpenses() {
//     final all = <Expense>[];
//     for (final list in _expensesByGroup.values) {
//       all.addAll(list);
//     }
//     _log(
//       'getAllExpenses() → ${all.length} total across ${_expensesByGroup.length} group(s)',
//     );
//     return all;
//   }

//   bool isLoading(String groupId) => _loadingByGroup[groupId] ?? false;

//   double totalExpensesForGroup(String groupId) =>
//       getExpenses(groupId).fold(0.0, (s, e) => s + e.amount);

//   // ─────────────────────────────────────────────────────────
//   // LOAD EXPENSES
//   //
//   // ✅ KEY FIX: SQLite shown BEFORE any network call.
//   // Server down / offline → data still shows immediately.
//   // ─────────────────────────────────────────────────────────

//   Future<void> loadExpenses(String groupId) async {
//     if (_userId == null) {
//       _err('loadExpenses skipped — userId not set yet');
//       return;
//     }

//     _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//     _log('loadExpenses($groupId) started');

//     _loadingByGroup[groupId] = true;
//     notifyListeners();

//     try {
//       // ── STEP 1: SQLite (offline-safe, instant) ────────────
//       _log('[1/2] Loading SQLite...');
//       final local = await _repo.fetchExpensesByGroup(groupId);
//       _expensesByGroup[groupId] = local;
//       _loadingByGroup[groupId] = false;
//       notifyListeners(); // ← UI shows data NOW
//       _log(
//         '[1/2] ✅ SQLite → ${local.length} expenses → UI updated immediately',
//       );

//       // ── STEP 2: Background backend sync (non-blocking) ────
//       _log('[2/2] Firing background sync (non-blocking)...');
//       _backgroundSync(groupId); // NOT awaited
//     } catch (e) {
//       _loadingByGroup[groupId] = false;
//       notifyListeners();
//       _err('loadExpenses SQLite error: $e');
//     }
//   }

//   // ─────────────────────────────────────────────────────────
//   // BACKGROUND SYNC — fire and forget, never blocks UI
//   // ─────────────────────────────────────────────────────────

//   void _backgroundSync(String groupId) {
//     if (_authToken == null || _sync == null) {
//       _log('[2/2] No auth/sync — offline mode, SQLite data shown ✅');
//       return;
//     }

//     _syncFromBackend(groupId).catchError((e) {
//       _err('[2/2] Background sync failed (offline is OK): $e');
//       // SQLite data already showing — nothing to do
//     });
//   }

//   Future<void> _syncFromBackend(String groupId) async {
//     if (_sync == null || _authToken == null) return;

//     final online = await _isConnected();
//     if (!online) {
//       _log('[2/2] 📴 No internet — background sync skipped, local data shown');
//       return;
//     }

//     _log('[2/2] 🌐 Online — syncing expenses for group $groupId...');

//     // Push PENDING expenses first
//     _log('[2/2] 📤 Pushing pending expenses...');
//     await _sync!.syncPendingExpenses(_authToken!);

//     // Pull from backend
//     _log('[2/2] 📥 Fetching from backend...');
//     final backend = await _sync!.fetchAndSyncGroupExpenses(
//       groupId,
//       _authToken!,
//     );
//     _log('[2/2] 📥 Got ${backend.length} expenses from backend');

//     // Cleanup stale
//     await _removeStaleExpenses(groupId, backend);

//     // Reload SQLite → update UI
//     _expensesByGroup[groupId] = await _repo.fetchExpensesByGroup(groupId);
//     notifyListeners();
//     _log('[2/2] ✅ UI refreshed → ${getExpenses(groupId).length} expenses');
//   }

//   Future<void> _removeStaleExpenses(
//     String groupId,
//     List<Expense> backendExpenses,
//   ) async {
//     final backendIds = backendExpenses.map((e) => e.id).toSet();
//     final local = await _repo.fetchExpensesByGroup(groupId);
//     int removed = 0;
//     for (final e in local) {
//       if (e.syncStatus == 'SYNCED' && !backendIds.contains(e.id)) {
//         await _repo.deleteExpense(e.id);
//         removed++;
//         _log('🗑️ Removed stale: ${e.title}');
//       }
//     }
//     if (removed > 0) _log('🗑️ Total stale removed: $removed');
//   }

//   // ─────────────────────────────────────────────────────────
//   // PUBLIC SYNC — called by ConnectivityService back-online
//   // ─────────────────────────────────────────────────────────

//   Future<void> syncWithBackend(String groupId) async {
//     _log('🔁 syncWithBackend($groupId) — connectivity restored');
//     await _syncFromBackend(groupId);
//   }

//   // ─────────────────────────────────────────────────────────
//   // CREATE EXPENSE
//   // ─────────────────────────────────────────────────────────

//   Future<Expense?> createExpense({
//     required String groupId,
//     required String title,
//     required double amount,
//     String category = 'Other',
//     String notes = '',
//     DateTime? date,
//     required String paidByUserId,
//     required String paidByName,
//     required String splitType,
//     required List<MemberShare> memberShares,
//   }) async {
//     if (_userId == null) {
//       _err('createExpense skipped — no userId');
//       return null;
//     }

//     _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//     _log('createExpense(): "$title" ₹$amount → group $groupId');

//     try {
//       final expense = Expense.create(
//         groupId: groupId,
//         userId: _userId!,
//         title: title,
//         amount: amount,
//         category: category,
//         notes: notes,
//         date: date ?? DateTime.now(),
//         paidByUserId: paidByUserId,
//         paidByName: paidByName,
//         splitType: splitType,
//         memberShares: memberShares,
//       );

//       // ── Step 1: SQLite + UI ───────────────────────────────
//       await _repo.addExpense(expense);
//       final current = _expensesByGroup[groupId] ?? [];
//       _expensesByGroup[groupId] = [expense, ...current];
//       notifyListeners();
//       _log('📱 Saved PENDING to SQLite → UI updated immediately ✅');

//       // ── Step 2: Backend (non-blocking if offline) ─────────
//       final online = await _isConnected();
//       if (!online) {
//         _log('📴 Offline — expense stays PENDING, will auto-sync when online');
//         return expense;
//       }

//       if (_authToken != null && _sync != null) {
//         _log('🌐 Online — pushing expense to backend...');
//         final result = await _sync!.syncImmediately(expense, _authToken!);

//         if (result['success'] == true) {
//           _log('✅ Pushed to backend — refreshing from backend...');
//           await _syncFromBackend(groupId);
//         } else {
//           _err('Backend push failed: ${result['message']} — stays PENDING');
//         }
//       }

//       return expense;
//     } catch (e) {
//       _err('createExpense error: $e');
//       return null;
//     }
//   }

//   // ─────────────────────────────────────────────────────────
//   // UPDATE EXPENSE
//   // ─────────────────────────────────────────────────────────

//   Future<bool> updateExpense(Expense updatedExpense) async {
//     _log('✏️ updateExpense(${updatedExpense.id})');
//     try {
//       // Step 1: Update local SQLite first
//       await _repo.updateExpense(updatedExpense.copyWith(syncStatus: 'PENDING'));

//       // Update in memory list
//       final groupId = updatedExpense.groupId;
//       final index =
//           _expensesByGroup[groupId]?.indexWhere(
//             (e) => e.id == updatedExpense.id,
//           ) ??
//           -1;
//       if (index != -1) {
//         _expensesByGroup[groupId]![index] = updatedExpense.copyWith(
//           syncStatus: 'PENDING',
//         );
//         notifyListeners();
//       }
//       _log('📱 Updated in SQLite + UI ✅');

//       // Step 2: Try backend if online
//       final online = await _isConnected();
//       if (online && _authToken != null && _sync != null) {
//         _log('🌐 Online — pushing update to backend...');
//         final ok = await _sync!.updateInBackend(updatedExpense, _authToken!);
//         if (ok) {
//           _log('✅ Updated successfully on backend');
//           await _syncFromBackend(groupId);
//         } else {
//           _log('⚠️ Backend update failed — stays PENDING');
//         }
//       } else {
//         _log('📴 Offline — expense stays PENDING, will auto-sync when online');
//       }

//       return true;
//     } catch (e) {
//       _err('updateExpense error: $e');
//       return false;
//     }
//   }

//   // ─────────────────────────────────────────────────────────
//   // DELETE EXPENSE
//   // ─────────────────────────────────────────────────────────

//   Future<bool> deleteExpense(String expenseId, String groupId) async {
//     _log('🗑️ deleteExpense($expenseId)');
//     try {
//       final expense = getExpenses(groupId).firstWhere(
//         (e) => e.id == expenseId,
//         orElse: () => throw Exception('Expense not found'),
//       );

//       await _repo.deleteExpense(expenseId);
//       _expensesByGroup[groupId]?.removeWhere((e) => e.id == expenseId);
//       notifyListeners();
//       _log('📱 Deleted from SQLite + UI ✅');

//       if (expense.syncStatus == 'SYNCED' &&
//           _authToken != null &&
//           _sync != null) {
//         final ok = await _sync!.deleteFromBackend(expenseId, _authToken!);
//         _log(
//           ok ? '✅ Deleted from backend' : '⚠️ Backend delete failed (local OK)',
//         );
//       }
//       return true;
//     } catch (e) {
//       _err('deleteExpense error: $e');
//       return false;
//     }
//   }

//   // ─────────────────────────────────────────────────────────
//   // INTERNET CHECK
//   // ─────────────────────────────────────────────────────────

//   Future<bool> _isConnected() async {
//     try {
//       final r = await InternetAddress.lookup(
//         'google.com',
//       ).timeout(const Duration(seconds: 3));
//       return r.isNotEmpty && r[0].rawAddress.isNotEmpty;
//     } catch (_) {
//       return false;
//     }
//   }

//   List<Expense> getPendingExpenses(String groupId) =>
//       getExpenses(groupId).where((e) => e.syncStatus == 'PENDING').toList();
// }
