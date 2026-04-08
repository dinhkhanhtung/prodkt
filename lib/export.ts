// CSV Export Utilities

export function convertToCSV(data: any[], headers: string[]): string {
  const csvRows = [];
  
  // Add headers
  csvRows.push(headers.join(','));
  
  // Add data rows
  for (const row of data) {
    const values = headers.map(header => {
      const value = row[header] ?? '';
      // Escape values with commas or quotes
      const escaped = String(value).replace(/"/g, '""');
      return `"${escaped}"`;
    });
    csvRows.push(values.join(','));
  }
  
  return csvRows.join('\n');
}

export function downloadCSV(csvContent: string, filename: string) {
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  link.style.visibility = 'hidden';
  
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

// Export configurations for different data types
export const EXPORT_CONFIGS = {
  products: {
    filename: 'products.csv',
    headers: ['id', 'name', 'sku', 'category', 'price', 'cost', 'stock', 'minStock', 'unit', 'createdAt'],
    labels: ['ID', 'Tên sản phẩm', 'Mã SKU', 'Danh mục', 'Giá bán', 'Giá vốn', 'Tồn kho', 'Tồn tối thiểu', 'Đơn vị', 'Ngày tạo'],
  },
  customers: {
    filename: 'customers.csv',
    headers: ['id', 'name', 'phone', 'email', 'address', 'notes', 'totalOrders', 'totalSpent', 'createdAt'],
    labels: ['ID', 'Tên khách hàng', 'Số điện thoại', 'Email', 'Địa chỉ', 'Ghi chú', 'Tổng đơn', 'Tổng chi tiêu', 'Ngày tạo'],
  },
  orders: {
    filename: 'orders.csv',
    headers: ['id', 'customerId', 'customerName', 'totalAmount', 'discount', 'paymentMethod', 'status', 'createdAt'],
    labels: ['ID', 'Mã KH', 'Tên KH', 'Tổng tiền', 'Giảm giá', 'Phương thức', 'Trạng thái', 'Ngày tạo'],
  },
  expenses: {
    filename: 'expenses.csv',
    headers: ['id', 'category', 'amount', 'description', 'date', 'notes', 'createdAt'],
    labels: ['ID', 'Danh mục', 'Số tiền', 'Mô tả', 'Ngày', 'Ghi chú', 'Ngày tạo'],
  },
  suppliers: {
    filename: 'suppliers.csv',
    headers: ['id', 'name', 'phone', 'email', 'address', 'contactPerson', 'notes', 'createdAt'],
    labels: ['ID', 'Tên NCC', 'Số điện thoại', 'Email', 'Địa chỉ', 'Người liên hệ', 'Ghi chú', 'Ngày tạo'],
  },
};

// Helper to format data for export
export function formatProductsForExport(products: any[]) {
  return products.map(p => ({
    id: p.id,
    name: p.name,
    sku: p.sku || '',
    category: p.category || '',
    price: p.price,
    cost: p.cost || 0,
    stock: p.stock || 0,
    minStock: p.minStock || 0,
    unit: p.unit || 'cái',
    createdAt: p.createdAt ? new Date(p.createdAt).toLocaleDateString('vi-VN') : '',
  }));
}

export function formatCustomersForExport(customers: any[]) {
  return customers.map(c => ({
    id: c.id,
    name: c.name,
    phone: c.phone || '',
    email: c.email || '',
    address: c.address || '',
    notes: c.notes || '',
    totalOrders: c.totalOrders || 0,
    totalSpent: c.totalSpent || 0,
    createdAt: c.createdAt ? new Date(c.createdAt).toLocaleDateString('vi-VN') : '',
  }));
}

export function formatOrdersForExport(orders: any[]) {
  return orders.map(o => ({
    id: o.id,
    customerId: o.customerId || '',
    customerName: o.customerName || 'Khách vãng lai',
    totalAmount: o.totalAmount,
    discount: o.discount || 0,
    paymentMethod: o.paymentMethod || 'cash',
    status: o.status || 'completed',
    createdAt: o.createdAt ? new Date(o.createdAt).toLocaleDateString('vi-VN') : '',
  }));
}

export function formatExpensesForExport(expenses: any[]) {
  const categoryNames: Record<string, string> = {
    rent: 'Tiền thuê mặt bằng',
    salary: 'Lương nhân viên',
    utilities: 'Điện nước internet',
    marketing: 'Marketing quảng cáo',
    inventory: 'Nhập hàng',
    equipment: 'Mua sắm thiết bị',
    maintenance: 'Sửa chữa bảo trì',
    other: 'Chi phí khác',
  };

  return expenses.map(e => ({
    id: e.id,
    category: categoryNames[e.category] || e.category,
    amount: e.amount,
    description: e.description,
    date: e.date ? new Date(e.date).toLocaleDateString('vi-VN') : '',
    notes: e.notes || '',
    createdAt: e.createdAt ? new Date(e.createdAt).toLocaleDateString('vi-VN') : '',
  }));
}

export function formatSuppliersForExport(suppliers: any[]) {
  return suppliers.map(s => ({
    id: s.id,
    name: s.name,
    phone: s.phone || '',
    email: s.email || '',
    address: s.address || '',
    contactPerson: s.contactPerson || '',
    notes: s.notes || '',
    createdAt: s.createdAt ? new Date(s.createdAt).toLocaleDateString('vi-VN') : '',
  }));
}

// Export all data as a complete backup
export function exportAllDataAsJSON(data: {
  products: any[];
  customers: any[];
  orders: any[];
  expenses: any[];
  suppliers: any[];
}) {
  const backupData = {
    exportedAt: new Date().toISOString(),
    version: '1.0',
    ...data,
  };
  
  const jsonContent = JSON.stringify(backupData, null, 2);
  const blob = new Blob([jsonContent], { type: 'application/json' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  
  const timestamp = new Date().toISOString().split('T')[0];
  link.setAttribute('href', url);
  link.setAttribute('download', `backup-${timestamp}.json`);
  link.style.visibility = 'hidden';
  
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
