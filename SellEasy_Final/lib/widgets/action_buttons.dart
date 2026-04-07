import 'package:flutter/material.dart';
import '../utils/dialog_helper.dart';
import 'animated_form_dialog.dart';
import 'expense_form.dart';
import 'inventory_form.dart';
import 'order_form.dart';

class ActionButtons extends StatefulWidget {
  final Function()? onAddExpense;
  final Function()? onAddInventory;
  final Function()? onCreateOrder;

  const ActionButtons({
    Key? key,
    this.onAddExpense,
    this.onAddInventory,
    this.onCreateOrder,
  }) : super(key: key);

  @override
  State<ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _showExpenseForm() async {
    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (context) => AnimatedFormDialog(
        title: 'Ghi chi tiêu',
        child: ExpenseForm(
          onSave: () {
            if (widget.onAddExpense != null) {
              widget.onAddExpense!();
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _showInventoryForm() async {
    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (context) => AnimatedFormDialog(
        title: 'Nhập hàng',
        child: InventoryForm(
          onSave: () {
            if (widget.onAddInventory != null) {
              widget.onAddInventory!();
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _showOrderForm() async {
    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (context) => AnimatedFormDialog(
        title: 'Tạo đơn hàng',
        child: OrderForm(
          onSave: () {
            if (widget.onCreateOrder != null) {
              widget.onCreateOrder!();
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Nút Ghi chi tiêu
        DialogHelper.buildAnimatedScale(
          visible: _isExpanded,
          child: DialogHelper.buildAnimatedOpacity(
            visible: _isExpanded,
            child: Positioned(
              bottom: 160,
              right: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'expense',
                    onPressed: _showExpenseForm,
                    backgroundColor: Colors.red,
                    label: const Text('Ghi chi tiêu'),
                    icon: const Icon(Icons.money_off),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Nút Nhập hàng
        DialogHelper.buildAnimatedScale(
          visible: _isExpanded,
          child: DialogHelper.buildAnimatedOpacity(
            visible: _isExpanded,
            child: Positioned(
              bottom: 90,
              right: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'inventory',
                    onPressed: _showInventoryForm,
                    backgroundColor: Colors.green,
                    label: const Text('Nhập hàng'),
                    icon: const Icon(Icons.add_shopping_cart),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Nút Tạo đơn
        DialogHelper.buildAnimatedScale(
          visible: _isExpanded,
          child: DialogHelper.buildAnimatedOpacity(
            visible: _isExpanded,
            child: Positioned(
              bottom: 20,
              right: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'order',
                    onPressed: _showOrderForm,
                    backgroundColor: Colors.blue,
                    label: const Text('Tạo đơn'),
                    icon: const Icon(Icons.receipt),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Nút toggle chính
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'toggle',
            onPressed: _toggleExpand,
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}
