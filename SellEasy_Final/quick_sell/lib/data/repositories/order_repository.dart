import 'dart:async';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/customer_model.dart';
import '../models/product_model.dart';
import '../../services/database_helper.dart';

class OrderRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Get all orders
  Future<List<Order>> getAllOrders() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('orders', orderBy: 'date DESC');
    
    List<Order> orders = [];
    for (var map in maps) {
      Customer? customer;
      if (map['customer_id'] != null) {
        final customerMaps = await db.query(
          'customers',
          where: 'id = ?',
          whereArgs: [map['customer_id']],
        );
        if (customerMaps.isNotEmpty) {
          customer = Customer.fromMap(customerMaps.first);
        }
      }
      
      final itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [map['id']],
      );
      
      List<OrderItem> items = [];
      for (var itemMap in itemMaps) {
        Product? product;
        final productMaps = await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [itemMap['product_id']],
        );
        if (productMaps.isNotEmpty) {
          product = Product.fromMap(productMaps.first);
        }
        
        items.add(OrderItem.fromMap(itemMap, product: product));
      }
      
      orders.add(Order.fromMap(map, customer: customer, items: items));
    }
    
    return orders;
  }

  // Get order by id
  Future<Order?> getOrderById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      Customer? customer;
      if (maps.first['customer_id'] != null) {
        final customerMaps = await db.query(
          'customers',
          where: 'id = ?',
          whereArgs: [maps.first['customer_id']],
        );
        if (customerMaps.isNotEmpty) {
          customer = Customer.fromMap(customerMaps.first);
        }
      }
      
      final itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [id],
      );
      
      List<OrderItem> items = [];
      for (var itemMap in itemMaps) {
        Product? product;
        final productMaps = await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [itemMap['product_id']],
        );
        if (productMaps.isNotEmpty) {
          product = Product.fromMap(productMaps.first);
        }
        
        items.add(OrderItem.fromMap(itemMap, product: product));
      }
      
      return Order.fromMap(maps.first, customer: customer, items: items);
    }
    
    return null;
  }

  // Insert an order with items
  Future<int> insertOrder(Order order, List<OrderItem> items) async {
    final db = await _databaseHelper.database;
    
    return await db.transaction((txn) async {
      // Insert order
      final orderId = await txn.insert('orders', order.toMap());
      
      // Insert order items
      for (var item in items) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price': item.price,
          'cost': item.cost,
          'is_exchanged': item.isExchanged ? 1 : 0,
        });
        
        // Update product quantity
        if (!item.isExchanged) {
          final productMaps = await txn.query(
            'products',
            columns: ['quantity'],
            where: 'id = ?',
            whereArgs: [item.productId],
          );
          
          if (productMaps.isNotEmpty) {
            final currentQuantity = productMaps.first['quantity'] as int;
            await txn.update(
              'products',
              {'quantity': currentQuantity - item.quantity},
              where: 'id = ?',
              whereArgs: [item.productId],
            );
          }
        }
      }
      
      // Update customer debt if applicable
      if (order.customerId != null && order.debt > 0) {
        final customerMaps = await txn.query(
          'customers',
          columns: ['debt'],
          where: 'id = ?',
          whereArgs: [order.customerId],
        );
        
        if (customerMaps.isNotEmpty) {
          final currentDebt = customerMaps.first['debt'] as double;
          await txn.update(
            'customers',
            {'debt': currentDebt + order.debt},
            where: 'id = ?',
            whereArgs: [order.customerId],
          );
        }
      }
      
      return orderId;
    });
  }

  // Update an order
  Future<int> updateOrder(Order order) async {
    final db = await _databaseHelper.database;
    
    return await db.transaction((txn) async {
      // Get original order to calculate debt difference
      final originalOrderMaps = await txn.query(
        'orders',
        where: 'id = ?',
        whereArgs: [order.id],
      );
      
      if (originalOrderMaps.isNotEmpty) {
        final originalOrder = Order.fromMap(originalOrderMaps.first);
        final debtDifference = order.debt - originalOrder.debt;
        
        // Update order
        await txn.update(
          'orders',
          order.toMap(),
          where: 'id = ?',
          whereArgs: [order.id],
        );
        
        // Update customer debt if applicable
        if (order.customerId != null && debtDifference != 0) {
          final customerMaps = await txn.query(
            'customers',
            columns: ['debt'],
            where: 'id = ?',
            whereArgs: [order.customerId],
          );
          
          if (customerMaps.isNotEmpty) {
            final currentDebt = customerMaps.first['debt'] as double;
            await txn.update(
              'customers',
              {'debt': currentDebt + debtDifference},
              where: 'id = ?',
              whereArgs: [order.customerId],
            );
          }
        }
        
        return 1;
      }
      
      return 0;
    });
  }

  // Delete an order
  Future<int> deleteOrder(int id) async {
    final db = await _databaseHelper.database;
    
    return await db.transaction((txn) async {
      // Get order to calculate debt
      final orderMaps = await txn.query(
        'orders',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (orderMaps.isNotEmpty) {
        final order = Order.fromMap(orderMaps.first);
        
        // Get order items to restore product quantities
        final itemMaps = await txn.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [id],
        );
        
        // Restore product quantities
        for (var itemMap in itemMaps) {
          final item = OrderItem.fromMap(itemMap);
          
          if (!item.isExchanged) {
            final productMaps = await txn.query(
              'products',
              columns: ['quantity'],
              where: 'id = ?',
              whereArgs: [item.productId],
            );
            
            if (productMaps.isNotEmpty) {
              final currentQuantity = productMaps.first['quantity'] as int;
              await txn.update(
                'products',
                {'quantity': currentQuantity + item.quantity},
                where: 'id = ?',
                whereArgs: [item.productId],
              );
            }
          }
        }
        
        // Update customer debt if applicable
        if (order.customerId != null && order.debt > 0) {
          final customerMaps = await txn.query(
            'customers',
            columns: ['debt'],
            where: 'id = ?',
            whereArgs: [order.customerId],
          );
          
          if (customerMaps.isNotEmpty) {
            final currentDebt = customerMaps.first['debt'] as double;
            await txn.update(
              'customers',
              {'debt': currentDebt - order.debt},
              where: 'id = ?',
              whereArgs: [order.customerId],
            );
          }
        }
        
        // Delete order items
        await txn.delete(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [id],
        );
        
        // Delete order
        return await txn.delete(
          'orders',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      
      return 0;
    });
  }

  // Get orders by date range
  Future<List<Order>> getOrdersByDateRange(String startDate, String endDate) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    
    List<Order> orders = [];
    for (var map in maps) {
      orders.add(Order.fromMap(map));
    }
    
    return orders;
  }

  // Get orders by customer
  Future<List<Order>> getOrdersByCustomer(int customerId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    
    List<Order> orders = [];
    for (var map in maps) {
      orders.add(Order.fromMap(map));
    }
    
    return orders;
  }

  // Get orders by status
  Future<List<Order>> getOrdersByStatus(String status) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'date DESC',
    );
    
    List<Order> orders = [];
    for (var map in maps) {
      orders.add(Order.fromMap(map));
    }
    
    return orders;
  }

  // Get total sales by date range
  Future<double> getTotalSalesByDateRange(String startDate, String endDate) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(total) as total_sales FROM orders WHERE date BETWEEN ? AND ?',
      [startDate, endDate],
    );
    
    return result.first['total_sales'] as double? ?? 0.0;
  }

  // Get total profit by date range
  Future<double> getTotalProfitByDateRange(String startDate, String endDate) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(o.total - SUM(oi.cost * oi.quantity)) as total_profit 
      FROM orders o 
      JOIN order_items oi ON o.id = oi.order_id 
      WHERE o.date BETWEEN ? AND ? 
      GROUP BY o.id
    ''', [startDate, endDate]);
    
    double totalProfit = 0.0;
    for (var row in result) {
      totalProfit += row['total_profit'] as double? ?? 0.0;
    }
    
    return totalProfit;
  }

  // Get order count by date range
  Future<int> getOrderCountByDateRange(String startDate, String endDate) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE date BETWEEN ? AND ?',
      [startDate, endDate],
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get top selling products by date range
  Future<List<Map<String, dynamic>>> getTopSellingProductsByDateRange(
    String startDate, 
    String endDate, 
    int limit
  ) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT p.id, p.name, SUM(oi.quantity) as sold_quantity, 
             SUM(oi.price * oi.quantity) as revenue, 
             SUM((oi.price - oi.cost) * oi.quantity) as profit 
      FROM order_items oi 
      JOIN orders o ON oi.order_id = o.id 
      JOIN products p ON oi.product_id = p.id 
      WHERE o.date BETWEEN ? AND ? 
      GROUP BY p.id 
      ORDER BY sold_quantity DESC 
      LIMIT ?
    ''', [startDate, endDate, limit]);
    
    return result;
  }
}
