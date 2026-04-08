'use client';

import { useEffect, useState, useRef } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { 
  getUserChatRooms, 
  getChatMessages, 
  sendMessage, 
  markMessagesAsRead,
  getOrCreateChatRoom,
  searchUsers,
  ChatRoom,
  ChatMessage,
  WithId 
} from '@/lib/firestore';
import { 
  MessageCircle, 
  Search, 
  Send, 
  ArrowLeft,
  MoreVertical,
  Phone,
  User
} from 'lucide-react';
import { format } from 'date-fns';
import { vi } from 'date-fns/locale';

export default function ChatPage() {
  const { user } = useAuth();
  const [rooms, setRooms] = useState<WithId<ChatRoom>[]>([]);
  const [activeRoom, setActiveRoom] = useState<string | null>(null);
  const [messages, setMessages] = useState<WithId<ChatMessage>[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [showSearch, setShowSearch] = useState(false);
  const [loading, setLoading] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (user?.uid) {
      loadRooms();
      // Poll for new messages
      const interval = setInterval(() => {
        if (activeRoom) {
          loadMessages(activeRoom);
        }
        loadRooms();
      }, 3000);
      return () => clearInterval(interval);
    }
  }, [user?.uid, activeRoom]);

  const loadRooms = async () => {
    if (!user?.uid) return;
    try {
      const data = await getUserChatRooms(user.uid);
      setRooms(data);
    } catch (error) {
      console.error('Error loading rooms:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadMessages = async (roomId: string) => {
    try {
      const data = await getChatMessages(roomId, 50);
      setMessages(data);
      // Mark messages as read
      if (user?.uid) {
        await markMessagesAsRead(roomId, user.uid);
      }
    } catch (error) {
      console.error('Error loading messages:', error);
    }
  };

  const handleRoomSelect = async (roomId: string) => {
    setActiveRoom(roomId);
    await loadMessages(roomId);
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || !activeRoom || !user) return;

    try {
      await sendMessage(activeRoom, user.uid, user.storeName || 'Unknown', newMessage.trim());
      setNewMessage('');
      await loadMessages(activeRoom);
      await loadRooms(); // Update last message in room list
    } catch (error) {
      console.error('Error sending message:', error);
    }
  };

  const handleSearch = async () => {
    if (!searchQuery.trim() || !user) return;
    try {
      const results = await searchUsers(searchQuery, user.uid);
      setSearchResults(results);
    } catch (error) {
      console.error('Error searching users:', error);
    }
  };

  const handleStartChat = async (otherUser: any) => {
    if (!user) return;
    try {
      const roomId = await getOrCreateChatRoom(
        user.uid,
        otherUser.id,
        user.storeName || 'Bạn',
        otherUser.storeName || 'Người dùng'
      );
      setShowSearch(false);
      setSearchQuery('');
      setSearchResults([]);
      await loadRooms();
      setActiveRoom(roomId);
      await loadMessages(roomId);
    } catch (error) {
      console.error('Error starting chat:', error);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const activeRoomData = rooms.find(r => r.id === activeRoom);
  const otherParticipantName = activeRoomData && user 
    ? activeRoomData.participantNames[activeRoomData.participants.find(p => p !== user.uid) || '']
    : '';

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="w-8 h-8 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="h-[calc(100vh-8rem)] bg-white rounded-xl border border-emerald-100 overflow-hidden shadow-sm">
      <div className="flex h-full">
        {/* Sidebar - Room List */}
        <div className={`w-full md:w-80 border-r border-emerald-100 flex flex-col ${activeRoom ? 'hidden md:flex' : 'flex'}`}>
          {/* Header */}
          <div className="p-4 border-b border-emerald-100">
            <div className="flex items-center justify-between mb-4">
              <h1 className="text-xl font-bold text-emerald-900 flex items-center gap-2">
                <MessageCircle className="w-6 h-6" />
                Tin nhắn
              </h1>
            </div>
            <button
              onClick={() => setShowSearch(true)}
              className="w-full flex items-center gap-2 px-4 py-2.5 bg-emerald-50 text-emerald-700 rounded-lg hover:bg-emerald-100 transition-colors"
            >
              <Search className="w-4 h-4" />
              <span className="text-sm">Tìm đối tác để chat...</span>
            </button>
          </div>

          {/* Room List */}
          <div className="flex-1 overflow-y-auto">
            {rooms.length === 0 ? (
              <div className="p-8 text-center">
                <MessageCircle className="w-12 h-12 text-emerald-300 mx-auto mb-3" />
                <p className="text-emerald-600">Chưa có cuộc trò chuyện nào</p>
                <p className="text-sm text-emerald-500 mt-1">Tìm đối tác để bắt đầu chat</p>
              </div>
            ) : (
              rooms.map((room) => {
                const otherId = room.participants.find(p => p !== user?.uid);
                const otherName = room.participantNames[otherId || ''];
                const isActive = activeRoom === room.id;
                
                return (
                  <button
                    key={room.id}
                    onClick={() => handleRoomSelect(room.id)}
                    className={`w-full p-4 flex items-center gap-3 hover:bg-emerald-50/50 transition-colors border-b border-emerald-50 ${isActive ? 'bg-emerald-50' : ''}`}
                  >
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center text-white font-semibold">
                      {otherName?.charAt(0).toUpperCase() || 'U'}
                    </div>
                    <div className="flex-1 text-left">
                      <p className="font-medium text-emerald-900">{otherName}</p>
                      <p className="text-sm text-emerald-600/70 truncate">
                        {room.lastMessage?.text || 'Bắt đầu cuộc trò chuyện'}
                      </p>
                    </div>
                    {room.lastMessage && (
                      <span className="text-xs text-emerald-400">
                        {format(new Date(room.lastMessage.timestamp), 'HH:mm', { locale: vi })}
                      </span>
                    )}
                  </button>
                );
              })
            )}
          </div>
        </div>

        {/* Chat Area */}
        <div className={`flex-1 flex flex-col ${!activeRoom ? 'hidden md:flex' : 'flex'}`}>
          {!activeRoom ? (
            <div className="flex-1 flex items-center justify-center">
              <div className="text-center">
                <MessageCircle className="w-16 h-16 text-emerald-200 mx-auto mb-4" />
                <p className="text-emerald-600">Chọn một cuộc trò chuyện để bắt đầu</p>
              </div>
            </div>
          ) : (
            <>
              {/* Chat Header */}
              <div className="p-4 border-b border-emerald-100 flex items-center gap-3">
                <button 
                  onClick={() => setActiveRoom(null)}
                  className="md:hidden p-2 text-emerald-600 hover:bg-emerald-50 rounded-lg"
                >
                  <ArrowLeft className="w-5 h-5" />
                </button>
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center text-white font-semibold">
                  {otherParticipantName?.charAt(0).toUpperCase() || 'U'}
                </div>
                <div className="flex-1">
                  <p className="font-semibold text-emerald-900">{otherParticipantName}</p>
                  <p className="text-xs text-emerald-500">Đối tác</p>
                </div>
                <button className="p-2 text-emerald-600 hover:bg-emerald-50 rounded-lg">
                  <MoreVertical className="w-5 h-5" />
                </button>
              </div>

              {/* Messages */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {messages.map((msg, index) => {
                  const isMe = msg.senderId === user?.uid;
                  const showDate = index === 0 || 
                    new Date(msg.createdAt).toDateString() !== 
                    new Date(messages[index - 1].createdAt).toDateString();

                  return (
                    <div key={msg.id}>
                      {showDate && (
                        <div className="flex justify-center my-4">
                          <span className="text-xs text-emerald-400 bg-emerald-50 px-3 py-1 rounded-full">
                            {format(new Date(msg.createdAt), 'EEEE, dd/MM/yyyy', { locale: vi })}
                          </span>
                        </div>
                      )}
                      <div className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}>
                        <div className={`max-w-[70%] px-4 py-2 rounded-2xl ${
                          isMe 
                            ? 'bg-emerald-600 text-white rounded-br-none' 
                            : 'bg-emerald-100 text-emerald-900 rounded-bl-none'
                        }`}>
                          <p>{msg.text}</p>
                          <p className={`text-xs mt-1 ${isMe ? 'text-emerald-200' : 'text-emerald-500'}`}>
                            {format(new Date(msg.createdAt), 'HH:mm')}
                          </p>
                        </div>
                      </div>
                    </div>
                  );
                })}
                <div ref={messagesEndRef} />
              </div>

              {/* Input */}
              <form onSubmit={handleSendMessage} className="p-4 border-t border-emerald-100">
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    placeholder="Nhập tin nhắn..."
                    className="flex-1 border border-emerald-200 rounded-full px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                  />
                  <button
                    type="submit"
                    disabled={!newMessage.trim()}
                    className="p-2.5 bg-emerald-600 text-white rounded-full hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <Send className="w-5 h-5" />
                  </button>
                </div>
              </form>
            </>
          )}
        </div>
      </div>

      {/* Search Modal */}
      {showSearch && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-4 border-b border-emerald-100 flex items-center gap-3">
              <Search className="w-5 h-5 text-emerald-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                placeholder="Tìm theo tên cửa hàng..."
                className="flex-1 outline-none text-emerald-900"
                autoFocus
              />
              <button 
                onClick={() => setShowSearch(false)}
                className="text-emerald-400 hover:text-emerald-600"
              >
                ✕
              </button>
            </div>
            <div className="max-h-80 overflow-y-auto">
              {searchResults.length > 0 ? (
                searchResults.map((result) => (
                  <button
                    key={result.id}
                    onClick={() => handleStartChat(result)}
                    className="w-full p-4 flex items-center gap-3 hover:bg-emerald-50 transition-colors border-b border-emerald-50"
                  >
                    <div className="w-10 h-10 rounded-full bg-emerald-100 flex items-center justify-center">
                      <User className="w-5 h-5 text-emerald-600" />
                    </div>
                    <div className="flex-1 text-left">
                      <p className="font-medium text-emerald-900">{result.storeName}</p>
                      <p className="text-sm text-emerald-500">{result.email}</p>
                    </div>
                    <MessageCircle className="w-5 h-5 text-emerald-400" />
                  </button>
                ))
              ) : searchQuery && !searchResults.length ? (
                <div className="p-8 text-center text-emerald-500">
                  Không tìm thấy đối tác nào
                </div>
              ) : (
                <div className="p-8 text-center text-emerald-400">
                  Nhập tên cửa hàng để tìm đối tác
                </div>
              )}
            </div>
            <div className="p-3 bg-emerald-50 text-center">
              <button 
                onClick={handleSearch}
                className="text-sm text-emerald-600 font-medium hover:text-emerald-800"
              >
                Tìm kiếm
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
