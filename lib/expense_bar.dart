import 'package:expense/chart/chart.dart';
import 'package:expense/expense_list.dart';
import 'package:expense/expense_model.dart';
import 'package:expense/main.dart';
import 'package:expense/new_expense.dart';
import 'package:flutter/material.dart';

class ExpenseBar extends StatefulWidget {
  const ExpenseBar({super.key});

  @override
  State<ExpenseBar> createState() => _ExpenseBarState();
}

class _ExpenseBarState extends State<ExpenseBar> {
  final List<ExpenseModel> _resgisteredExpense = [];
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

  void _removeExpense(ExpenseModel expense) {
    final expenseIndex = _resgisteredExpense.indexOf(expense);
    setState(() {
      _resgisteredExpense.remove(expense);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 3),
        content: Text('Expense Deleted'),
        action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _resgisteredExpense.insert(expenseIndex, expense);
              });
            }),
      ),
    );
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
    if (_resgisteredExpense.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _resgisteredExpense,
        onRemoveExpense: _removeExpense,
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
