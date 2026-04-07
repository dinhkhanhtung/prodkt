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
  limit,
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

// ==================== PAYMENTS & SUBSCRIPTION ====================

export interface Subscription {
  plan: 'free' | 'pro' | 'enterprise';
  status: 'active' | 'expired' | 'pending';
  startedAt?: string;
  expiresAt?: string;
  lastPaymentId?: string;
}

export interface Payment {
  userId: string;
  storeId: string;
  amount: number;
  plan: 'monthly' | 'yearly';
  status: 'pending' | 'verified' | 'rejected' | 'expired';
  bankCode: string;
  accountNumber: string;
  accountName: string;
  transferContent: string;
  receiptImage?: string;
  receiptNote?: string;
  transferredAt?: string;
  verifiedBy?: string;
  verifiedAt?: string;
  rejectionReason?: string;
  validUntil: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface BankAccount {
  bankCode: string;
  bankName: string;
  accountNumber: string;
  accountName: string;
  isActive: boolean;
  isDefault: boolean;
  qrImageUrl?: string;
  createdAt?: string;
  updatedAt?: string;
}

// Root-level collections (not store-specific)
const PAYMENTS_COLLECTION = 'payments';
const BANK_ACCOUNTS_COLLECTION = 'bankAccounts';

export async function createPayment(
  payment: Omit<Payment, 'createdAt' | 'updatedAt'>
): Promise<string> {
  const docRef = await addDoc(collection(db, PAYMENTS_COLLECTION), {
    ...payment,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  return docRef.id;
}

export async function getUserPayments(userId: string): Promise<(Payment & WithId)[]> {
  const q = query(
    collection(db, PAYMENTS_COLLECTION),
    where('userId', '==', userId),
    orderBy('createdAt', 'desc')
  );
  const snapshot = await getDocs(q);
  return snapshot.docs.map((doc) => convertDoc<Payment>(doc));
}

export async function getPendingPayments(): Promise<(Payment & WithId)[]> {
  const q = query(
    collection(db, PAYMENTS_COLLECTION),
    where('status', '==', 'pending'),
    orderBy('createdAt', 'desc')
  );
  const snapshot = await getDocs(q);
  return snapshot.docs.map((doc) => convertDoc<Payment>(doc));
}

export async function verifyPayment(
  paymentId: string,
  adminId: string,
  validUntil: string
): Promise<void> {
  const docRef = doc(db, PAYMENTS_COLLECTION, paymentId);
  await updateDoc(docRef, {
    status: 'verified',
    verifiedBy: adminId,
    verifiedAt: new Date().toISOString(),
    validUntil,
    updatedAt: new Date().toISOString(),
  });
}

export async function rejectPayment(
  paymentId: string,
  adminId: string,
  reason: string
): Promise<void> {
  const docRef = doc(db, PAYMENTS_COLLECTION, paymentId);
  await updateDoc(docRef, {
    status: 'rejected',
    verifiedBy: adminId,
    verifiedAt: new Date().toISOString(),
    rejectionReason: reason,
    updatedAt: new Date().toISOString(),
  });
}

export async function uploadPaymentReceipt(
  paymentId: string,
  imageUrl: string,
  note?: string
): Promise<void> {
  const docRef = doc(db, PAYMENTS_COLLECTION, paymentId);
  await updateDoc(docRef, {
    receiptImage: imageUrl,
    receiptNote: note || '',
    transferredAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
}

// ==================== BANK ACCOUNTS ====================

export async function getBankAccounts(): Promise<(BankAccount & WithId)[]> {
  const q = query(
    collection(db, BANK_ACCOUNTS_COLLECTION),
    where('isActive', '==', true),
    orderBy('bankName')
  );
  const snapshot = await getDocs(q);
  return snapshot.docs.map((doc) => convertDoc<BankAccount>(doc));
}

export async function getDefaultBankAccount(): Promise<(BankAccount & WithId) | null> {
  const q = query(
    collection(db, BANK_ACCOUNTS_COLLECTION),
    where('isDefault', '==', true),
    where('isActive', '==', true),
    limit(1)
  );
  const snapshot = await getDocs(q);
  if (snapshot.empty) return null;
  return convertDoc<BankAccount>(snapshot.docs[0]);
}

export async function addBankAccount(
  account: Omit<BankAccount, 'createdAt' | 'updatedAt'>
): Promise<string> {
  const docRef = await addDoc(collection(db, BANK_ACCOUNTS_COLLECTION), {
    ...account,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  return docRef.id;
}

export async function updateBankAccount(
  accountId: string,
  account: Partial<BankAccount>
): Promise<void> {
  const docRef = doc(db, BANK_ACCOUNTS_COLLECTION, accountId);
  await updateDoc(docRef, {
    ...account,
    updatedAt: new Date().toISOString(),
  });
}

export async function deleteBankAccount(accountId: string): Promise<void> {
  const docRef = doc(db, BANK_ACCOUNTS_COLLECTION, accountId);
  await deleteDoc(docRef);
}

// ==================== USER SUBSCRIPTION ====================

export async function updateUserSubscription(
  userId: string,
  subscription: Subscription
): Promise<void> {
  const userRef = doc(db, COLLECTIONS.USERS, userId);
  await updateDoc(userRef, {
    subscription,
    updatedAt: new Date().toISOString(),
  });
}

export async function getUserSubscription(userId: string): Promise<Subscription | null> {
  const userRef = doc(db, COLLECTIONS.USERS, userId);
  const userDoc = await getDoc(userRef);
  if (!userDoc.exists()) return null;
  return userDoc.data().subscription || null;
}
