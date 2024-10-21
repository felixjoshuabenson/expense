import 'dart:convert';

import 'package:expense/chart/chart.dart';
import 'package:expense/expense_list.dart';
import 'package:expense/expense_model.dart';
import 'package:expense/main.dart';
import 'package:expense/new_expense.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExpenseBar extends StatefulWidget {
  const ExpenseBar({super.key});

  @override
  State<ExpenseBar> createState() => _ExpenseBarState();
}

class _ExpenseBarState extends State<ExpenseBar> {
  List<ExpenseModel> _resgisteredExpense = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExpense();
  }

  void _loadExpense() async {
    final url =
        Uri.https('expense-d9f44-default-rtdb.firebaseio.com', 'Expenses.json');

    try {
      final response = await http.get(url);
      // print(response.body);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Unable to load Expenses. Please try again later';
        });
      }
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listExpense = json.decode(response.body);
      final List<ExpenseModel> loadedExpense = [];

      for (final expense in listExpense.entries) {
        loadedExpense.add(ExpenseModel(
          id: expense.key,
          title: expense.value['title'],
          amount: double.parse(expense.value['amount']),
          date: DateTime.parse(expense.value['date']),
          category: parseCategory(expense.value['category']),
        ));
      }
      setState(() {
        _resgisteredExpense = loadedExpense;
        _isLoading = false;
      });
    } catch (error) {
      // print(error);
      setState(() {
        _error = 'Something went wrong. Please try againg later';
      });
    }
  }

  void _onClickAddButton() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => NewExpense(onAddExpense: _addExpense),
    );
  }

  void _addExpense(ExpenseModel expense) {
    setState(() {
      _resgisteredExpense.add(expense);
    });
  }

  void _removeExpense(ExpenseModel expense) async {
    final expenseIndex = _resgisteredExpense.indexOf(expense);
    final removedExpense = _resgisteredExpense[expenseIndex];

    // Optimistically remove the expense from the list
    setState(() {
      _resgisteredExpense.removeAt(expenseIndex);
    });

    // Show a Snackbar with an Undo option
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Expense deleted.'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Undo deletion by reinserting the expense at the same index
            setState(() {
              _resgisteredExpense.insert(expenseIndex, removedExpense);
            });
          },
        ),
      ),
    );

    // Send a delete request to Firebase
    final url = Uri.https('expense-d9f44-default-rtdb.firebaseio.com',
        'Expenses/${expense.id}.json');
    final response = await http.delete(url);

    // If the deletion failed, reinsert the expense back into the list
    if (response.statusCode >= 400) {
      setState(() {
        _resgisteredExpense.insert(expenseIndex, removedExpense);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete the expense.')),
      );
    }
  }

  Category parseCategory(String category) {
    switch (category) {
      case 'food':
        return Category.food;
      case 'travel':
        return Category.travel;
      case 'leisure':
        return Category.leisure;
      case 'work':
        return Category.work;
      case 'charity':
        return Category.charity;
      default:
        throw Exception('Unknown category: $category');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = Center(
      child: Column(
        children: [
          Text(
            'No expenses Found. Start adding some!',
            style:
                TextStyle(color: kColorScheme.onPrimaryContainer, fontSize: 18),
          ),
          Spacer(),
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(80),
              color: kColorScheme.secondaryContainer,
            ),
            child: IconButton(
              onPressed: _onClickAddButton,
              icon: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );

    if (_isLoading) {
      mainContent = Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_resgisteredExpense.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _resgisteredExpense,
        onRemoveExpense: _removeExpense,
      );
    }

    if (_error != null) {
      mainContent = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker'),
        actions: [
          IconButton(
            onPressed: _onClickAddButton,
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Chart(expenses: _resgisteredExpense),
          ),
          Expanded(child: mainContent),
        ],
      ),
    );
  }
}
