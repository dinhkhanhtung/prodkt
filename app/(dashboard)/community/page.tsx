'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { 
  getCommunityPosts, 
  addCommunityPost,
  likeCommunityPost,
  CommunityPost,
  PARTNER_CATEGORIES,
  WithId 
} from '@/lib/firestore';
import { 
  Users, 
  Plus, 
  Heart,
  MessageCircle,
  Eye,
  Search,
  Filter,
  Share2,
  HelpCircle,
  ShoppingBag,
  BookOpen
} from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { vi } from 'date-fns/locale';

export default function CommunityPage() {
  const { user } = useAuth();
  const [posts, setPosts] = useState<WithId<CommunityPost>[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [filterType, setFilterType] = useState<string>('all');
  const [formData, setFormData] = useState({
    type: 'experience' as CommunityPost['type'],
    title: '',
    content: '',
    category: '',
  });

  useEffect(() => {
    loadPosts();
    // Poll for new posts every 30 seconds
    const interval = setInterval(loadPosts, 30000);
    return () => clearInterval(interval);
  }, [filterType]);

  const loadPosts = async () => {
    try {
      const type = filterType === 'all' ? undefined : filterType;
      const data = await getCommunityPosts(type, undefined, 20);
      setPosts(data);
    } catch (error) {
      console.error('Error loading posts:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user?.uid || !formData.title || !formData.content) return;

    try {
      await addCommunityPost(
        user.uid,
        user.storeName || 'Người dùng',
        user.storeName || 'Cửa hàng',
        {
          type: formData.type,
          title: formData.title,
          content: formData.content,
          category: formData.category,
        }
      );
      
      setShowModal(false);
      setFormData({ type: 'experience', title: '', content: '', category: '' });
      loadPosts();
    } catch (error) {
      console.error('Error adding post:', error);
    }
  };

  const handleLike = async (postId: string) => {
    if (!user?.uid) return;
    try {
      await likeCommunityPost(postId, user.uid);
      loadPosts();
    } catch (error) {
      console.error('Error liking:', error);
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'looking_for': return <Search className="w-4 h-4" />;
      case 'selling': return <ShoppingBag className="w-4 h-4" />;
      case 'experience': return <BookOpen className="w-4 h-4" />;
      case 'question': return <HelpCircle className="w-4 h-4" />;
      default: return <Share2 className="w-4 h-4" />;
    }
  };

  const getTypeLabel = (type: string) => {
    const labels: Record<string, string> = {
      looking_for: 'Tìm nguồn',
      selling: 'Bán sỉ',
      experience: 'Chia sẻ',
      question: 'Hỏi đáp',
    };
    return labels[type] || type;
  };

  const getTypeColor = (type: string) => {
    const colors: Record<string, string> = {
      looking_for: 'bg-blue-100 text-blue-700',
      selling: 'bg-emerald-100 text-emerald-700',
      experience: 'bg-amber-100 text-amber-700',
      question: 'bg-purple-100 text-purple-700',
    };
    return colors[type] || 'bg-gray-100 text-gray-700';
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center">
            <Users className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-emerald-900">Cộng đồng</h1>
            <p className="text-emerald-600/70 text-sm">Chia sẻ kinh nghiệm, tìm nguồn hàng</p>
          </div>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="px-4 py-2 bg-gradient-to-r from-indigo-600 to-purple-600 text-white rounded-lg font-medium transition-all hover:opacity-90 flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Đăng bài
        </button>
      </div>

      {/* Filter */}
      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => setFilterType('all')}
          className={`px-4 py-2 rounded-lg font-medium transition-colors ${
            filterType === 'all'
              ? 'bg-indigo-600 text-white'
              : 'bg-white text-indigo-700 hover:bg-indigo-50 border border-indigo-200'
          }`}
        >
          Tất cả
        </button>
        {[
          { key: 'looking_for', label: 'Tìm nguồn', icon: Search },
          { key: 'selling', label: 'Bán sỉ', icon: ShoppingBag },
          { key: 'experience', label: 'Chia sẻ', icon: BookOpen },
          { key: 'question', label: 'Hỏi đáp', icon: HelpCircle },
        ].map(({ key, label, icon: Icon }) => (
          <button
            key={key}
            onClick={() => setFilterType(key)}
            className={`px-4 py-2 rounded-lg font-medium transition-colors flex items-center gap-2 ${
              filterType === key
                ? 'bg-indigo-600 text-white'
                : 'bg-white text-indigo-700 hover:bg-indigo-50 border border-indigo-200'
            }`}
          >
            <Icon className="w-4 h-4" />
            {label}
          </button>
        ))}
      </div>

      {/* Posts Feed */}
      <div className="space-y-4">
        {loading ? (
          <div className="p-8 text-center bg-white rounded-xl border border-emerald-100">
            <div className="w-8 h-8 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin mx-auto" />
          </div>
        ) : posts.length === 0 ? (
          <div className="p-8 text-center bg-white rounded-xl border border-emerald-100">
            <Users className="w-12 h-12 text-emerald-300 mx-auto mb-3" />
            <p className="text-emerald-600">Chưa có bài đăng nào</p>
            <p className="text-sm text-emerald-500 mt-1">Hãy là người đầu tiên chia sẻ!</p>
          </div>
        ) : (
          posts.map((post) => (
            <div key={post.id} className="bg-white rounded-xl border border-emerald-100 shadow-sm p-4 hover:shadow-md transition-shadow">
              {/* Header */}
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-indigo-400 to-purple-500 flex items-center justify-center text-white font-semibold">
                    {post.authorName.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <p className="font-semibold text-emerald-900">{post.authorStoreName}</p>
                    <p className="text-xs text-emerald-500">
                      {formatDistanceToNow(new Date(post.createdAt), { addSuffix: true, locale: vi })}
                    </p>
                  </div>
                </div>
                <span className={`px-3 py-1 rounded-full text-xs font-medium flex items-center gap-1 ${getTypeColor(post.type)}`}>
                  {getTypeIcon(post.type)}
                  {getTypeLabel(post.type)}
                </span>
              </div>

              {/* Content */}
              <div className="mb-4">
                <h3 className="font-bold text-lg text-emerald-900 mb-2">{post.title}</h3>
                <p className="text-emerald-700 whitespace-pre-wrap">{post.content}</p>
              </div>

              {/* Category Tag */}
              {post.category && (
                <div className="mb-3">
                  <span className="px-3 py-1 bg-emerald-50 text-emerald-600 text-sm rounded-full">
                    {PARTNER_CATEGORIES[post.category as keyof typeof PARTNER_CATEGORIES] || post.category}
                  </span>
                </div>
              )}

              {/* Actions */}
              <div className="flex items-center gap-6 pt-3 border-t border-emerald-50">
                <button
                  onClick={() => handleLike(post.id!)}
                  className={`flex items-center gap-2 text-sm transition-colors ${
                    post.likedBy?.includes(user?.uid || '') 
                      ? 'text-red-500' 
                      : 'text-emerald-600 hover:text-red-500'
                  }`}
                >
                  <Heart className={`w-5 h-5 ${post.likedBy?.includes(user?.uid || '') ? 'fill-current' : ''}`} />
                  <span>{post.likes || 0}</span>
                </button>
                <button className="flex items-center gap-2 text-sm text-emerald-600 hover:text-emerald-800">
                  <MessageCircle className="w-5 h-5" />
                  <span>{post.comments || 0}</span>
                </button>
                <div className="flex items-center gap-2 text-sm text-emerald-400">
                  <Eye className="w-5 h-5" />
                  <span>{post.views || 0}</span>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="p-4 border-b border-emerald-100">
              <h3 className="font-semibold text-emerald-900">Đăng bài mới</h3>
            </div>
            <form onSubmit={handleSubmit} className="p-4 space-y-4">
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Loại bài đăng</label>
                <div className="grid grid-cols-2 gap-2">
                  {[
                    { key: 'looking_for', label: 'Tìm nguồn hàng', icon: Search },
                    { key: 'selling', label: 'Bán sỉ', icon: ShoppingBag },
                    { key: 'experience', label: 'Chia sẻ KN', icon: BookOpen },
                    { key: 'question', label: 'Hỏi đáp', icon: HelpCircle },
                  ].map(({ key, label, icon: Icon }) => (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setFormData({ ...formData, type: key as CommunityPost['type'] })}
                      className={`p-3 rounded-lg border text-sm font-medium flex items-center gap-2 ${
                        formData.type === key
                          ? 'bg-indigo-50 border-indigo-500 text-indigo-700'
                          : 'border-emerald-200 text-emerald-700 hover:bg-emerald-50'
                      }`}
                    >
                      <Icon className="w-4 h-4" />
                      {label}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Danh mục</label>
                <select
                  value={formData.category}
                  onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  required
                >
                  <option value="">Chọn danh mục</option>
                  {Object.entries(PARTNER_CATEGORIES).map(([key, label]) => (
                    <option key={key} value={key}>{label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Tiêu đề</label>
                <input
                  type="text"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder="VD: Cần tìm nguồn hàng điện thoại giá sỉ..."
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Nội dung</label>
                <textarea
                  value={formData.content}
                  onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500 h-32 resize-none"
                  placeholder="Mô tả chi tiết..."
                  required
                />
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="flex-1 px-4 py-2 border border-emerald-200 text-emerald-700 rounded-lg hover:bg-emerald-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
                >
                  Đăng bài
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
