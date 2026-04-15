// ════════════════════════════════════════════════════════════════
// FILE: lib/services/expense_sync_service.dart
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/models/expense_model.dart';
import '../data/local/database_helper.dart';
import '../data/repositories/expense_repository.dart';

class ExpenseSyncService {
  // ← Your API gateway base URL (same host as group service)
  static String baseUrl =
      'https://nonsterile-smudgeless-candace.ngrok-free.dev/api/expenses';

  static void setBaseUrl(String url) {
    baseUrl = url;
    debugPrint('🔧 ExpenseSyncService baseUrl: $baseUrl');
  }

  final ExpenseRepository _repo;
  final DatabaseHelper _db;
  final String? userId;

  ExpenseSyncService({ExpenseRepository? repo, DatabaseHelper? db, this.userId})
    : _repo = repo ?? ExpenseRepository(),
      _db = db ?? DatabaseHelper.instance;

  void _log(String msg) => debugPrint('💸 ExpenseSync: $msg');
  void _err(String msg) => debugPrint('❌ ExpenseSync: $msg');

  Future<bool> _isConnected() async {
    try {
      final r = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return r.isNotEmpty && r[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── PUSH ONE PENDING EXPENSE TO BACKEND ───────────────────
  Future<Map<String, dynamic>> _pushExpense(
    Expense expense,
    String authToken,
  ) async {
    try {
      _log('Pushing expense: ${expense.title} for group ${expense.groupId}');

      final body = jsonEncode({
        'title': expense.title,
        'amount': expense.amount,
        'category': expense.category,
        'notes': expense.notes,
        'date': expense.date.toIso8601String(),
        'splitType': expense.splitType,
        // selectedMembers: only involved members
        'selectedMembers': expense.memberShares
            .where((s) => s.isInvolved)
            .map((s) => s.toMap())
            .toList(),
      });

      final response = await http.post(
        Uri.parse('$baseUrl/add/${expense.groupId}'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      _log('Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          // Delete local PENDING copy — backend gave it a real MongoDB _id
          await _db.deleteExpense(expense.id);
          _log('Pushed and deleted local PENDING copy: ${expense.id}');
          return {'success': true};
        } else {
          _err('Push failed: ${result['message']}');
          return {'success': false, 'message': result['message']};
        }
      } else {
        _err('HTTP error: ${response.statusCode} — ${response.body}');
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      _err('Push exception: $e');
      return {'success': false, 'message': '$e'};
    }
  }

  // ── SYNC ALL PENDING EXPENSES FOR USER ────────────────────
  Future<void> syncPendingExpenses(String authToken) async {
    if (!await _isConnected()) {
      _log('Offline — skipping pending sync');
      return;
    }
    if (userId == null) return;

    final pending = await _repo.fetchPendingByUser(userId!);
    if (pending.isEmpty) {
      _log('No pending expenses');
      return;
    }

    _log('Syncing ${pending.length} pending expense(s)');
    for (final e in pending) {
      await _pushExpense(e, authToken);
    }
  }

  // ── FETCH ALL EXPENSES FOR A GROUP FROM BACKEND ───────────
  Future<List<Expense>> fetchAndSyncGroupExpenses(
    String groupId,
    String authToken,
  ) async {
    if (!await _isConnected()) {
      _log('Offline — cannot fetch expenses');
      return [];
    }

    try {
      _log('Fetching expenses for group $groupId');
      final response = await http.get(
        Uri.parse('$baseUrl/group/$groupId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final list = result['data'] as List;
          _log('Got ${list.length} expenses from backend');

          final synced = <Expense>[];
          for (final e in list) {
            try {
              final expense = Expense(
                id: e['_id'] ?? e['id'],
                groupId: e['groupId'] ?? groupId,
                userId: userId ?? '',
                title: e['title'] ?? '',
                amount: (e['amount'] is num)
                    ? (e['amount'] as num).toDouble()
                    : 0.0,
                category: e['category'] ?? 'Other',
                notes: e['notes'] ?? '',
                date: e['date'] != null
                    ? DateTime.parse(e['date'])
                    : DateTime.now(),
                paidByUserId: e['paidBy']?['userId'] ?? '',
                paidByName: e['paidBy']?['name'] ?? '',
                splitType: e['splitType'] ?? 'equal',
                memberShares: (e['memberShares'] as List? ?? [])
                    .map((s) => MemberShare.fromMap(s as Map<String, dynamic>))
                    .toList(),
                syncStatus: 'SYNCED',
              );
              await _db.insertOrUpdateExpense(expense);
              synced.add(expense);
            } catch (err) {
              _err('Error processing expense: $err');
            }
          }
          return synced;
        }
      }
      _err('Fetch failed: ${response.statusCode}');
      return [];
    } catch (e) {
      _err('Fetch exception: $e');
      return [];
    }
  }

  /// Push a single expense immediately (called right after create)
  Future<Map<String, dynamic>> syncImmediately(
    Expense expense,
    String authToken,
  ) async {
    return await _pushExpense(expense, authToken);
  }

  /// Delete expense from backend
  Future<bool> deleteFromBackend(String expenseId, String authToken) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$expenseId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _err('Delete error: $e');
      return false;
    }
  }
}
