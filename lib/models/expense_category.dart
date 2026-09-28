import 'package:flutter/material.dart';

/// Fixed set of expense categories. Stored in Firestore by [name].
enum ExpenseCategory {
  food('Food', Icons.restaurant, Color(0xFFEF6C00)),
  transport('Transport', Icons.directions_bus, Color(0xFF1E88E5)),
  shopping('Shopping', Icons.shopping_bag, Color(0xFF8E24AA)),
  bills('Bills', Icons.receipt_long, Color(0xFFE53935)),
  entertainment('Entertainment', Icons.movie, Color(0xFFD81B60)),
  health('Health', Icons.favorite, Color(0xFF43A047)),
  education('Education', Icons.school, Color(0xFF3949AB)),
  other('Other', Icons.category, Color(0xFF757575));

  const ExpenseCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  /// Parses a stored category name, falling back to [other] for unknown or
  /// missing values so a bad document never crashes the list.
  static ExpenseCategory fromName(String? name) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.name == name,
      orElse: () => ExpenseCategory.other,
    );
  }
}
