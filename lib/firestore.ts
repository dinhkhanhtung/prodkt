import {
  collection,
  doc,
  addDoc,
  updateDoc,
  deleteDoc,
  getDocs,
  getDoc,
  query,
  where,
  orderBy,
  serverTimestamp,
  DocumentData,
  QueryDocumentSnapshot,
} from 'firebase/firestore';
import { db } from './firebase';

// Generic type for data with id
export interface WithId {
  id: string;
}

// Collection names
const COLLECTIONS = {
  PRODUCTS: 'products',
  CUSTOMERS: 'customers',
  SUPPLIERS: 'suppliers',
  ORDERS: 'orders',
  USERS: 'users',
  STORES: 'stores',
} as const;

// Helper to get store-specific collection reference
function getStoreCollection(storeId: string, collectionName: string) {
  return collection(db, 'stores', storeId, collectionName);
}

// Helper to convert Firestore document to typed object
function convertDoc<T>(doc: QueryDocumentSnapshot<DocumentData>): T & WithId {
  return { id: doc.id, ...(doc.data() as T) };
}

// ==================== PRODUCTS ====================

export interface Product {
  name: string;
  price: number;
  cost: number;
  stock: number;
  imageURL?: string;
  categoryId?: string;
  description?: string;
  createdAt?: string;
  updatedAt?: string;
}

export async function getProducts(storeId: string): Promise<(Product & WithId)[]> {
  const q = query(
    getStoreCollection(storeId, COLLECTIONS.PRODUCTS),
    orderBy('name')
  );
  const snapshot = await getDocs(q);
  return snapshot.docs.map((doc) => convertDoc<Product>(doc));
}

export async function addProduct(
  storeId: string,
  product: Omit<Product, 'createdAt' | 'updatedAt'>
): Promise<string> {
  const docRef = await addDoc(getStoreCollection(storeId, COLLECTIONS.PRODUCTS), {
    ...product,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  return docRef.id;
}

export async function updateProduct(
  storeId: string,
  productId: string,
  product: Partial<Product>
): Promise<void> {
  const docRef = doc(db, 'stores', storeId, COLLECTIONS.PRODUCTS, productId);
  await updateDoc(docRef, {
    ...product,
    updatedAt: new Date().toISOString(),
  });
}

export async function deleteProduct(storeId: string, productId: string): Promise<void> {
  const docRef = doc(db, 'stores', storeId, COLLECTIONS.PRODUCTS, productId);
  await deleteDoc(docRef);
}

// ==================== CUSTOMERS ====================

export interface Customer {
  name: string;
  phone?: string;
  email?: string;
  address?: string;
  debtAmount: number;
  note?: string;
  createdAt?: string;
  updatedAt?: string;
}

export async function getCustomers(storeId: string): Promise<(Customer & WithId)[]> {
  const q = query(
    getStoreCollection(storeId, COLLECTIONS.CUSTOMERS),
    orderBy('name')
  );
  const snapshot = await getDocs(q);
  return snapshot.docs.map((doc) => convertDoc<Customer>(doc));
}

export async function addCustomer(
  storeId: string,
  customer: Omit<Customer, 'createdAt' | 'updatedAt'>
): Promise<string> {
  const docRef = await addDoc(getStoreCollection(storeId, COLLECTIONS.CUSTOMERS), {
    ...customer,
    debtAmount: customer.debtAmount || 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  return docRef.id;
}

export async function updateCustomer(
  storeId: string,
  customerId: string,
  customer: Partial<Customer>
): Promise<void> {
  const docRef = doc(db, 'stores', storeId, COLLECTIONS.CUSTOMERS, customerId);
  await updateDoc(docRef, {
    ...customer,
    updatedAt: new Date().toISOString(),
  });
}

export async function deleteCustomer(storeId: string, customerId: string): Promise<void> {
  const docRef = doc(db, 'stores', storeId, COLLECTIONS.CUSTOMERS, customerId);
  await deleteDoc(docRef);
}

// ==================== SUPPLIERS ====================

export interface Supplier {
  name: string;
  phone?: string;
  email?: string;
  address?: string;
  debtAmount: number;
  note?: string;
  createdAt?: string;
  updatedAt?: string;
}

export async function getSuppliers(storeId: string): Promise<(Supplier & WithId)[]> {
  const q = query(
    getStoreCollection(storeId, COLLECTIONS.SUPPLIERS),
    orderBy('name')
  );
  const snapshot = await getDocs(q);
  return snapshot.docs.map((doc) => convertDoc<Supplier>(doc));
}

export async function addSupplier(
  storeId: string,
  supplier: Omit<Supplier, 'createdAt' | 'updatedAt'>
): Promise<string> {
  const docRef = await addDoc(getStoreCollection(storeId, COLLECTIONS.SUPPLIERS), {
    ...supplier,
    debtAmount: supplier.debtAmount || 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  return docRef.id;
}

export async function updateSupplier(
  storeId: string,
  supplierId: string,
  supplier: Partial<Supplier>
): Promise<void> {
  const docRef = doc(db, 'stores', storeId, COLLECTIONS.SUPPLIERS, supplierId);
  await updateDoc(docRef, {
    ...supplier,
    updatedAt: new Date().toISOString(),
  });
}

export async function deleteSupplier(storeId: string, supplierId: string): Promise<void> {
  const docRef = doc(db, 'stores', storeId, COLLECTIONS.SUPPLIERS, supplierId);
  await deleteDoc(docRef);
}

// ==================== ORDERS ====================

export interface OrderItem {
  productId: string;
  name: string;
  price: number;
  quantity: number;
  subtotal: number;
}

export interface Order {
  customerId: string | null;
  customerName: string;
  items: OrderItem[];
  totalAmount: number;
  discount: number;
  finalAmount: number;
  paymentMethod: 'cash' | 'transfer' | 'debt';
  paidAmount: number;
  debtAmount: number;
  note?: string;
  status: 'completed' | 'pending' | 'cancelled';
  createdAt?: string;
  updatedAt?: string;
}

export async function getOrders(storeId: string): Promise<(Order & WithId)[]> {
  const q = query(
    getStoreCollection(storeId, COLLECTIONS.ORDERS),
    orderBy('createdAt', 'desc')
  );
  const snapshot = await getDocs(q);
  return snapshot.docs.map((doc) => convertDoc<Order>(doc));
}

export async function addOrder(
  storeId: string,
  order: Omit<Order, 'createdAt' | 'updatedAt'>
): Promise<string> {
  const docRef = await addDoc(getStoreCollection(storeId, COLLECTIONS.ORDERS), {
    ...order,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });

  // Update customer debt if applicable
  if (order.customerId && order.debtAmount > 0) {
    const customerRef = doc(db, 'stores', storeId, COLLECTIONS.CUSTOMERS, order.customerId);
    const customerDoc = await getDoc(customerRef);
    if (customerDoc.exists()) {
      const currentDebt = customerDoc.data().debtAmount || 0;
      await updateDoc(customerRef, {
        debtAmount: currentDebt + order.debtAmount,
        updatedAt: new Date().toISOString(),
      });
    }
  }

  // Update product stock
  for (const item of order.items) {
    const productRef = doc(db, 'stores', storeId, COLLECTIONS.PRODUCTS, item.productId);
    const productDoc = await getDoc(productRef);
    if (productDoc.exists()) {
      const currentStock = productDoc.data().stock || 0;
      await updateDoc(productRef, {
        stock: Math.max(0, currentStock - item.quantity),
        updatedAt: new Date().toISOString(),
      });
    }
  }

  return docRef.id;
}

export async function updateOrder(
  storeId: string,
  orderId: string,
  order: Partial<Order>
): Promise<void> {
  const docRef = doc(db, 'stores', storeId, COLLECTIONS.ORDERS, orderId);
  await updateDoc(docRef, {
    ...order,
    updatedAt: new Date().toISOString(),
  });
}

export async function deleteOrder(storeId: string, orderId: string): Promise<void> {
  const docRef = doc(db, 'stores', storeId, COLLECTIONS.ORDERS, orderId);
  await deleteDoc(docRef);
}
