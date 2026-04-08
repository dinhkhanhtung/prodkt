'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getHallOfFame, PartnerProfile, PARTNER_CATEGORIES } from '@/lib/firestore';
import { Trophy, Star, Users, Award, TrendingUp, Store } from 'lucide-react';

export default function HallOfFamePage() {
  const { user } = useAuth();
  const [partners, setPartners] = useState<PartnerProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  useEffect(() => {
    loadPartners();
  }, []);

  const loadPartners = async () => {
    try {
      const data = await getHallOfFame(20);
      setPartners(data);
    } catch (error) {
      console.error('Error loading hall of fame:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredPartners = selectedCategory === 'all' 
    ? partners 
    : partners.filter(p => p.categories.includes(selectedCategory));

  const getRankColor = (index: number) => {
    if (index === 0) return 'from-yellow-400 to-amber-500'; // Gold
    if (index === 1) return 'from-gray-300 to-gray-400';     // Silver
    if (index === 2) return 'from-amber-600 to-amber-700';  // Bronze
    return 'from-emerald-400 to-teal-500';                   // Others
  };

  const getRankIcon = (index: number) => {
    if (index === 0) return <Trophy className="w-6 h-6 text-yellow-600" />;
    if (index === 1) return <Award className="w-6 h-6 text-gray-600" />;
    if (index === 2) return <Award className="w-6 h-6 text-amber-700" />;
    return <TrendingUp className="w-5 h-5 text-emerald-600" />;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="text-center py-8 bg-gradient-to-r from-emerald-50 to-teal-50 rounded-2xl border border-emerald-100">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-br from-yellow-400 to-amber-500 mb-4">
          <Trophy className="w-8 h-8 text-white" />
        </div>
        <h1 className="text-3xl font-bold text-emerald-900">Hall of Fame</h1>
        <p className="text-emerald-600 mt-2">Top đối tác uy tín nhất cộng đồng</p>
      </div>

      {/* Category Filter */}
      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => setSelectedCategory('all')}
          className={`px-4 py-2 rounded-lg font-medium transition-colors ${
            selectedCategory === 'all'
              ? 'bg-emerald-600 text-white'
              : 'bg-white text-emerald-700 hover:bg-emerald-50 border border-emerald-200'
          }`}
        >
          Tất cả
        </button>
        {Object.entries(PARTNER_CATEGORIES).map(([key, label]) => (
          <button
            key={key}
            onClick={() => setSelectedCategory(key)}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              selectedCategory === key
                ? 'bg-emerald-600 text-white'
                : 'bg-white text-emerald-700 hover:bg-emerald-50 border border-emerald-200'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {/* Top 3 Podium */}
      {!loading && filteredPartners.length >= 3 && (
        <div className="flex justify-center items-end gap-4 py-8">
          {/* #2 */}
          <div className="flex flex-col items-center">
            <div className="w-20 h-20 rounded-full bg-gradient-to-br from-gray-300 to-gray-400 flex items-center justify-center text-white text-2xl font-bold mb-2">
              2
            </div>
            <div className="bg-white rounded-xl border border-gray-200 p-4 w-48 text-center shadow-lg">
              <p className="font-semibold text-gray-900 truncate">{filteredPartners[1].storeName}</p>
              <div className="flex items-center justify-center gap-1 mt-1">
                <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                <span className="font-bold text-gray-900">{filteredPartners[1].averageRating.toFixed(1)}</span>
              </div>
              <p className="text-sm text-gray-500">{filteredPartners[1].totalReviews} đánh giá</p>
            </div>
            <div className="h-24 w-full bg-gray-200 rounded-t-lg mt-2" />
          </div>

          {/* #1 */}
          <div className="flex flex-col items-center -mt-8">
            <div className="w-24 h-24 rounded-full bg-gradient-to-br from-yellow-400 to-amber-500 flex items-center justify-center text-white text-3xl font-bold mb-2 shadow-lg">
              1
            </div>
            <div className="bg-white rounded-xl border-2 border-yellow-400 p-4 w-56 text-center shadow-xl">
              <p className="font-bold text-gray-900 truncate text-lg">{filteredPartners[0].storeName}</p>
              <div className="flex items-center justify-center gap-1 mt-1">
                <Star className="w-5 h-5 text-yellow-500 fill-yellow-500" />
                <span className="font-bold text-xl text-gray-900">{filteredPartners[0].averageRating.toFixed(1)}</span>
              </div>
              <p className="text-sm text-gray-500">{filteredPartners[0].totalReviews} đánh giá</p>
              <div className="flex flex-wrap gap-1 mt-2 justify-center">
                {filteredPartners[0].categories.slice(0, 2).map((cat) => (
                  <span key={cat} className="px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs rounded-full">
                    {PARTNER_CATEGORIES[cat as keyof typeof PARTNER_CATEGORIES] || cat}
                  </span>
                ))}
              </div>
            </div>
            <div className="h-32 w-full bg-gradient-to-t from-yellow-200 to-yellow-100 rounded-t-lg mt-2" />
          </div>

          {/* #3 */}
          <div className="flex flex-col items-center">
            <div className="w-20 h-20 rounded-full bg-gradient-to-br from-amber-600 to-amber-700 flex items-center justify-center text-white text-2xl font-bold mb-2">
              3
            </div>
            <div className="bg-white rounded-xl border border-amber-200 p-4 w-48 text-center shadow-lg">
              <p className="font-semibold text-gray-900 truncate">{filteredPartners[2].storeName}</p>
              <div className="flex items-center justify-center gap-1 mt-1">
                <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                <span className="font-bold text-gray-900">{filteredPartners[2].averageRating.toFixed(1)}</span>
              </div>
              <p className="text-sm text-gray-500">{filteredPartners[2].totalReviews} đánh giá</p>
            </div>
            <div className="h-16 w-full bg-amber-100 rounded-t-lg mt-2" />
          </div>
        </div>
      )}

      {/* Ranking List */}
      <div className="bg-white rounded-xl border border-emerald-100 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-emerald-100 flex items-center justify-between">
          <h2 className="font-semibold text-emerald-900">Bảng xếp hạng</h2>
          <span className="text-sm text-emerald-600">{filteredPartners.length} đối tác</span>
        </div>

        {loading ? (
          <div className="p-8 text-center">
            <div className="w-8 h-8 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin mx-auto" />
          </div>
        ) : filteredPartners.length === 0 ? (
          <div className="p-8 text-center">
            <Trophy className="w-12 h-12 text-emerald-300 mx-auto mb-3" />
            <p className="text-emerald-600">Chưa có đối tác nào trong danh sách</p>
          </div>
        ) : (
          <div className="divide-y divide-emerald-50">
            {filteredPartners.map((partner, index) => (
              <div key={partner.userId} className="p-4 flex items-center gap-4 hover:bg-emerald-50/50">
                {/* Rank */}
                <div className={`w-10 h-10 rounded-full flex items-center justify-center bg-gradient-to-br ${getRankColor(index)}`}>
                  {index < 3 ? getRankIcon(index) : <span className="text-white font-bold">{index + 1}</span>}
                </div>

                {/* Avatar placeholder */}
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center text-white font-semibold">
                  {partner.storeName.charAt(0).toUpperCase()}
                </div>

                {/* Info */}
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <p className="font-semibold text-emerald-900">{partner.storeName}</p>
                    {partner.isVerified && (
                      <span className="px-2 py-0.5 bg-blue-100 text-blue-700 text-xs rounded-full flex items-center gap-1">
                        <Store className="w-3 h-3" />
                        Verified
                      </span>
                    )}
                  </div>
                  <div className="flex flex-wrap gap-1 mt-1">
                    {partner.categories.map((cat) => (
                      <span key={cat} className="px-2 py-0.5 bg-emerald-50 text-emerald-600 text-xs rounded-full">
                        {PARTNER_CATEGORIES[cat as keyof typeof PARTNER_CATEGORIES] || cat}
                      </span>
                    ))}
                  </div>
                </div>

                {/* Stats */}
                <div className="text-right">
                  <div className="flex items-center gap-1 justify-end">
                    <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                    <span className="font-bold text-emerald-900">{partner.averageRating.toFixed(1)}</span>
                  </div>
                  <p className="text-sm text-emerald-600">{partner.totalReviews} đánh giá</p>
                  <p className="text-xs text-emerald-400">{partner.totalTransactions} giao dịch</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
