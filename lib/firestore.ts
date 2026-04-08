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
  limitToLast,
  serverTimestamp,
  DocumentData,
  QueryDocumentSnapshot,
} from 'firebase/firestore';
import { db } from './firebase';

// Generic type for data with id
export type WithId<T = Record<string, any>> = T & { id: string };

// Collection names
const COLLECTIONS = {
  PRODUCTS: 'products',
  CUSTOMERS: 'customers',
  SUPPLIERS: 'suppliers',
  ORDERS: 'orders',
  USERS: 'users',
  STORES: 'stores',
} as const;

// User Profile type
export interface UserProfile {
  id?: string;
  uid: string;
  email: string;
  storeName: string;
  phone?: string;
  address?: string;
  role: 'owner' | 'admin' | 'staff';
  createdAt: string;
  updatedAt: string;
}

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

// ==================== EXPENSES ====================

export interface Expense {
  id?: string;
  userId: string;
  storeId: string;
  category: 'rent' | 'salary' | 'utilities' | 'marketing' | 'inventory' | 'equipment' | 'maintenance' | 'other';
  amount: number;
  description: string;
  date: string; // YYYY-MM-DD
  notes?: string;
  attachments?: string[];
  createdAt: string;
  updatedAt: string;
}

const EXPENSES_COLLECTION = 'expenses';

function getExpensesCollection(storeId: string) {
  return collection(db, 'stores', storeId, EXPENSES_COLLECTION);
}

export async function getExpenses(storeId: string, startDate?: string, endDate?: string): Promise<WithId<Expense>[]> {
  const expensesCol = getExpensesCollection(storeId);
  let q = query(expensesCol, orderBy('date', 'desc'));
  
  if (startDate && endDate) {
    q = query(q, where('date', '>=', startDate), where('date', '<=', endDate));
  }
  
  const querySnapshot = await getDocs(q);
  return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as WithId<Expense>));
}

export async function getExpensesByCategory(storeId: string, month: string): Promise<{ category: string; total: number }[]> {
  const expensesCol = getExpensesCollection(storeId);
  const startOfMonth = `${month}-01`;
  const endOfMonth = `${month}-31`;
  
  const q = query(
    expensesCol,
    where('date', '>=', startOfMonth),
    where('date', '<=', endOfMonth)
  );
  
  const querySnapshot = await getDocs(q);
  const expenses = querySnapshot.docs.map(doc => doc.data() as Expense);
  
  const grouped = expenses.reduce((acc, expense) => {
    acc[expense.category] = (acc[expense.category] || 0) + expense.amount;
    return acc;
  }, {} as Record<string, number>);
  
  return Object.entries(grouped).map(([category, total]) => ({ category, total }));
}

export async function addExpense(userId: string, storeId: string, data: Omit<Expense, 'id' | 'userId' | 'storeId' | 'createdAt' | 'updatedAt'>): Promise<string> {
  const expenseData: Expense = {
    ...data,
    userId,
    storeId,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  
  const docRef = await addDoc(getExpensesCollection(storeId), expenseData);
  return docRef.id;
}

// ==================== CUSTOM FIELDS ====================

export interface CustomField {
  id?: string;
  userId: string;
  storeId: string;
  entityType: 'product' | 'customer' | 'supplier';
  name: string;
  label: string;
  type: 'text' | 'number' | 'date' | 'select' | 'checkbox';
  options?: string[]; // For select type
  required: boolean;
  order: number;
  createdAt: string;
  updatedAt: string;
}

const CUSTOM_FIELDS_COLLECTION = 'customFields';

function getCustomFieldsCollection(storeId: string) {
  return collection(db, 'stores', storeId, CUSTOM_FIELDS_COLLECTION);
}

export async function getCustomFields(storeId: string, entityType?: 'product' | 'customer' | 'supplier'): Promise<WithId<CustomField>[]> {
  const fieldsCol = getCustomFieldsCollection(storeId);
  let q = query(fieldsCol, orderBy('order', 'asc'));
  
  if (entityType) {
    q = query(q, where('entityType', '==', entityType));
  }
  
  const querySnapshot = await getDocs(q);
  return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as WithId<CustomField>));
}

export async function addCustomField(userId: string, storeId: string, data: Omit<CustomField, 'id' | 'userId' | 'storeId' | 'createdAt' | 'updatedAt'>): Promise<string> {
  const fieldData: CustomField = {
    ...data,
    userId,
    storeId,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  
  const docRef = await addDoc(getCustomFieldsCollection(storeId), fieldData);
  return docRef.id;
}

export async function updateCustomField(storeId: string, fieldId: string, data: Partial<Omit<CustomField, 'id' | 'userId' | 'storeId' | 'createdAt'>>): Promise<void> {
  const fieldRef = doc(db, 'stores', storeId, CUSTOM_FIELDS_COLLECTION, fieldId);
  await updateDoc(fieldRef, {
    ...data,
    updatedAt: new Date().toISOString(),
  });
}

export async function deleteCustomField(storeId: string, fieldId: string): Promise<void> {
  const fieldRef = doc(db, 'stores', storeId, CUSTOM_FIELDS_COLLECTION, fieldId);
  await deleteDoc(fieldRef);
}

// Store custom field values on entities
export function applyCustomFields<T extends Record<string, any>>(
  entity: T,
  customFields: Record<string, any>
): T & { customFields: Record<string, any> } {
  return {
    ...entity,
    customFields: customFields || {},
  };
}

export async function updateExpense(storeId: string, expenseId: string, data: Partial<Omit<Expense, 'id' | 'userId' | 'storeId' | 'createdAt'>>): Promise<void> {
  const expenseRef = doc(db, 'stores', storeId, EXPENSES_COLLECTION, expenseId);
  await updateDoc(expenseRef, {
    ...data,
    updatedAt: new Date().toISOString(),
  });
}

export async function deleteExpense(storeId: string, expenseId: string): Promise<void> {
  const expenseRef = doc(db, 'stores', storeId, EXPENSES_COLLECTION, expenseId);
  await deleteDoc(expenseRef);
}

export const EXPENSE_CATEGORIES = {
  rent: 'Tiền thuê mặt bằng',
  salary: 'Lương nhân viên',
  utilities: 'Điện nước internet',
  marketing: 'Marketing quảng cáo',
  inventory: 'Nhập hàng',
  equipment: 'Mua sắm thiết bị',
  maintenance: 'Sửa chữa bảo trì',
  other: 'Chi phí khác',
} as const;

// ==================== NOTIFICATIONS ====================

export interface Notification {
  id?: string;
  userId: string;
  storeId: string;
  type: 'order' | 'expense' | 'inventory' | 'system' | 'admin';
  title: string;
  message: string;
  read: boolean;
  link?: string;
  metadata?: Record<string, any>;
  createdAt: string;
}

const NOTIFICATIONS_COLLECTION = 'notifications';

function getNotificationsCollection(userId: string) {
  return collection(db, 'users', userId, NOTIFICATIONS_COLLECTION);
}

export async function getNotifications(userId: string, unreadOnly = false): Promise<WithId<Notification>[]> {
  const notifCol = getNotificationsCollection(userId);
  let q = query(notifCol, orderBy('createdAt', 'desc'), limit(50));
  
  if (unreadOnly) {
    q = query(notifCol, where('read', '==', false), orderBy('createdAt', 'desc'));
  }
  
  const querySnapshot = await getDocs(q);
  return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as WithId<Notification>));
}

export async function getUnreadCount(userId: string): Promise<number> {
  const notifCol = getNotificationsCollection(userId);
  const q = query(notifCol, where('read', '==', false));
  const querySnapshot = await getDocs(q);
  return querySnapshot.size;
}

export async function addNotification(userId: string, storeId: string, data: Omit<Notification, 'id' | 'userId' | 'createdAt'>): Promise<string> {
  const notifData: Notification = {
    ...data,
    userId,
    createdAt: new Date().toISOString(),
  };
  
  const docRef = await addDoc(getNotificationsCollection(userId), notifData);
  return docRef.id;
}

export async function markNotificationAsRead(userId: string, notificationId: string): Promise<void> {
  const notifRef = doc(db, 'users', userId, NOTIFICATIONS_COLLECTION, notificationId);
  await updateDoc(notifRef, { read: true });
}

export async function markAllAsRead(userId: string): Promise<void> {
  const notifCol = getNotificationsCollection(userId);
  const q = query(notifCol, where('read', '==', false));
  const querySnapshot = await getDocs(q);
  
  const batch = querySnapshot.docs.map(docSnapshot => 
    updateDoc(doc(db, 'users', userId, NOTIFICATIONS_COLLECTION, docSnapshot.id), { read: true })
  );
  
  await Promise.all(batch);
}

export async function deleteNotification(userId: string, notificationId: string): Promise<void> {
  const notifRef = doc(db, 'users', userId, NOTIFICATIONS_COLLECTION, notificationId);
  await deleteDoc(notifRef);
}

// ==================== CHAT SYSTEM ====================

export interface ChatRoom {
  id?: string;
  participants: string[];
  participantNames: Record<string, string>;
  lastMessage?: {
    text: string;
    senderId: string;
    timestamp: string;
  };
  createdAt: string;
  updatedAt: string;
}

export interface ChatMessage {
  id?: string;
  roomId: string;
  senderId: string;
  senderName: string;
  text: string;
  read: boolean;
  createdAt: string;
}

const CHAT_ROOMS_COLLECTION = 'chatRooms';
const CHAT_MESSAGES_COLLECTION = 'messages';

export function getChatRoomsCollection() {
  return collection(db, CHAT_ROOMS_COLLECTION);
}

export function getChatMessagesCollection(roomId: string) {
  return collection(db, CHAT_ROOMS_COLLECTION, roomId, CHAT_MESSAGES_COLLECTION);
}

export async function getUserChatRooms(userId: string): Promise<WithId<ChatRoom>[]> {
  const roomsCol = getChatRoomsCollection();
  const q = query(roomsCol, where('participants', 'array-contains', userId), orderBy('updatedAt', 'desc'));
  const querySnapshot = await getDocs(q);
  return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as WithId<ChatRoom>));
}

export async function getOrCreateChatRoom(userId: string, otherUserId: string, userName: string, otherUserName: string): Promise<string> {
  const roomsCol = getChatRoomsCollection();
  const q = query(roomsCol, where('participants', 'array-contains', userId));
  const querySnapshot = await getDocs(q);
  
  // Check if room already exists
  const existingRoom = querySnapshot.docs.find(doc => {
    const data = doc.data() as ChatRoom;
    return data.participants.includes(otherUserId);
  });
  
  if (existingRoom) {
    return existingRoom.id;
  }
  
  // Create new room
  const roomData: Omit<ChatRoom, 'id'> = {
    participants: [userId, otherUserId],
    participantNames: {
      [userId]: userName,
      [otherUserId]: otherUserName,
    },
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  
  const docRef = await addDoc(roomsCol, roomData);
  return docRef.id;
}

export async function getChatMessages(roomId: string, limit = 50): Promise<WithId<ChatMessage>[]> {
  const messagesCol = getChatMessagesCollection(roomId);
  const q = query(messagesCol, orderBy('createdAt', 'desc'), limitToLast(limit));
  const querySnapshot = await getDocs(q);
  return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as WithId<ChatMessage>)).reverse();
}

export async function sendMessage(roomId: string, senderId: string, senderName: string, text: string): Promise<void> {
  const messageData: Omit<ChatMessage, 'id'> = {
    roomId,
    senderId,
    senderName,
    text,
    read: false,
    createdAt: new Date().toISOString(),
  };
  
  await addDoc(getChatMessagesCollection(roomId), messageData);
  
  // Update room last message
  const roomRef = doc(db, CHAT_ROOMS_COLLECTION, roomId);
  await updateDoc(roomRef, {
    lastMessage: {
      text,
      senderId,
      timestamp: new Date().toISOString(),
    },
    updatedAt: new Date().toISOString(),
  });
}

export async function markMessagesAsRead(roomId: string, userId: string): Promise<void> {
  const messagesCol = getChatMessagesCollection(roomId);
  const q = query(messagesCol, where('senderId', '!=', userId), where('read', '==', false));
  const querySnapshot = await getDocs(q);
  
  const batch = querySnapshot.docs.map(docSnapshot =>
    updateDoc(doc(db, CHAT_ROOMS_COLLECTION, roomId, CHAT_MESSAGES_COLLECTION, docSnapshot.id), { read: true })
  );
  
  await Promise.all(batch);
}

export async function searchUsers(searchTerm: string, excludeUserId: string): Promise<WithId<UserProfile>[]> {
  const usersCol = collection(db, COLLECTIONS.USERS);
  const q = query(
    usersCol,
    where('storeName', '>=', searchTerm),
    where('storeName', '<=', searchTerm + '\uf8ff'),
    limit(20)
  );
  const querySnapshot = await getDocs(q);
  return querySnapshot.docs
    .filter(doc => doc.id !== excludeUserId)
    .map(doc => ({ id: doc.id, ...doc.data() } as WithId<UserProfile>));
}
