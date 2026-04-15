// ════════════════════════════════════════════════════════════════
// FILE: lib/data/repositories/expense_repository.dart
// ════════════════════════════════════════════════════════════════

import '../local/database_helper.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final DatabaseHelper _db;

  ExpenseRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  Future<Expense> addExpense(Expense expense) async {
    return await _db.insertExpense(expense);
  }

  Future<List<Expense>> fetchExpensesByGroup(String groupId) async {
    return await _db.getExpensesByGroup(groupId);
  }

  Future<List<Expense>> fetchPendingByUser(String userId) async {
    return await _db.getPendingExpensesByUser(userId);
  }

  Future<int> updateExpense(Expense expense) async {
    return await _db.updateExpense(expense);
  }

  Future<int> deleteExpense(String id) async {
    return await _db.deleteExpense(id);
  }

  Future<void> insertOrUpdate(Expense expense) async {
    return await _db.insertOrUpdateExpense(expense);
  }
}
