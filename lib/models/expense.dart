import 'package:cloud_firestore/cloud_firestore.dart';

import 'expense_category.dart';

/// A single expense entry, stored at `users/{uid}/expenses/{id}`.
class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  /// Firestore document id; empty until saved.
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;

  /// Server timestamps; null until written.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Expense.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Expense.fromMap(doc.id, doc.data() ?? const {});
  }

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    final note = (map['note'] as String?)?.trim();
    return Expense(
      id: id,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      category: ExpenseCategory.fromName(map['category'] as String?),
      date: _toDateTime(map['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      note: (note == null || note.isEmpty) ? null : note,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  /// Fields saved to Firestore; timestamps are added by the repository.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    bool clearNote = false,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _toDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is Expense &&
        other.id == id &&
        other.title == title &&
        other.amount == amount &&
        other.category == category &&
        other.date == date &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(id, title, amount, category, date, note);

  @override
  String toString() =>
      'Expense($id, $title, $amount, ${category.name}, $date, $note)';
}
