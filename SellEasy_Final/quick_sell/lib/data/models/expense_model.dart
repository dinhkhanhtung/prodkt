class Expense {
  final int? id;
  final String date;
  final double amount;
  final String category;
  final String? description;

  Expense({
    this.id,
    required this.date,
    required this.amount,
    required this.category,
    this.description,
  });

  // Create an Expense from a Map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      date: map['date'],
      amount: map['amount'],
      category: map['category'],
      description: map['description'],
    );
  }

  // Convert an Expense to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'amount': amount,
      'category': category,
      'description': description,
    };
  }

  // Create a copy of Expense with some fields changed
  Expense copyWith({
    int? id,
    String? date,
    double? amount,
    String? category,
    String? description,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'Expense{id: $id, date: $date, amount: $amount, category: $category}';
  }
}
