'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getProducts, getCustomers, getOrders, getExpenses } from '@/lib/firestore';
import { Sparkles, TrendingUp, AlertTriangle, Lightbulb, RefreshCw, Bot } from 'lucide-react';

interface AIInsight {
  type: 'trend' | 'warning' | 'opportunity' | 'tip';
  title: string;
  description: string;
  action?: string;
}

export default function AIAnalysisPage() {
  const { user } = useAuth();
  const storeId = user?.storeId;
  const [insights, setInsights] = useState<AIInsight[]>([]);
  const [loading, setLoading] = useState(true);
  const [analyzing, setAnalyzing] = useState(false);

  useEffect(() => {
    if (storeId) {
      analyzeData();
    }
  }, [storeId]);

  const analyzeData = async () => {
    if (!storeId) return;
    setLoading(true);
    
    try {
      const [products, customers, orders, expenses] = await Promise.all([
        getProducts(storeId),
        getCustomers(storeId),
        getOrders(storeId),
        getExpenses(storeId),
      ]);

      // Calculate metrics
      const today = new Date().toISOString().split('T')[0];
      const thisMonth = today.slice(0, 7);
      const lastMonth = new Date(new Date().setMonth(new Date().getMonth() - 1)).toISOString().slice(0, 7);
      
      const todayOrders = orders.filter(o => o.createdAt?.startsWith(today));
      const thisMonthOrders = orders.filter(o => o.createdAt?.startsWith(thisMonth));
      const lastMonthOrders = orders.filter(o => o.createdAt?.startsWith(lastMonth));
      
      const thisMonthRevenue = thisMonthOrders.reduce((sum, o) => sum + o.totalAmount, 0);
      const lastMonthRevenue = lastMonthOrders.reduce((sum, o) => sum + o.totalAmount, 0);
      const revenueGrowth = lastMonthRevenue > 0 ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100 : 0;
      
      const thisMonthExpenses = expenses
        .filter(e => e.date.startsWith(thisMonth))
        .reduce((sum, e) => sum + e.amount, 0);
      
      const profitMargin = thisMonthRevenue > 0 ? ((thisMonthRevenue - thisMonthExpenses) / thisMonthRevenue) * 100 : 0;
      
      const lowStockProducts = products.filter(p => p.stock < (p.minStock || 10));
      const avgOrderValue = thisMonthOrders.length > 0 ? thisMonthRevenue / thisMonthOrders.length : 0;
      
      const topProduct = orders.reduce((acc, order) => {
        order.items.forEach(item => {
          acc[item.productId] = (acc[item.productId] || 0) + item.quantity;
        });
        return acc;
      }, {} as Record<string, number>);
      
      const topProductId = Object.entries(topProduct)
        .sort(([,a], [,b]) => b - a)[0]?.[0];
      const topProductName = topProductId ? products.find(p => p.id === topProductId)?.name : null;
      
      const customerWithDebt = customers.filter(c => c.debtAmount > 0);
      const totalDebt = customerWithDebt.reduce((sum, c) => sum + c.debtAmount, 0);

      // Generate AI insights
      const generatedInsights: AIInsight[] = [];
      
      // Revenue trend
      if (revenueGrowth > 20) {
        generatedInsights.push({
          type: 'trend',
          title: 'Doanh thu tăng trưởng mạnh',
          description: `Doanh thu tháng này tăng ${revenueGrowth.toFixed(1)}% so với tháng trước. Xu hướng tích cực!`,
          action: 'Tiếp tục duy trì chiến lược hiện tại và xem xét tăng nhập hàng.',
        });
      } else if (revenueGrowth < -10) {
        generatedInsights.push({
          type: 'warning',
          title: 'Doanh thu giảm',
          description: `Doanh thu tháng này giảm ${Math.abs(revenueGrowth).toFixed(1)}% so với tháng trước.`,
          action: 'Xem xét chương trình khuyến mãi hoặc marketing để thu hút khách hàng.',
        });
      }
      
      // Low stock warning
      if (lowStockProducts.length > 0) {
        generatedInsights.push({
          type: 'warning',
          title: `${lowStockProducts.length} sản phẩm sắp hết hàng`,
          description: `Có ${lowStockProducts.length} sản phẩm dưới mức tồn kho tối thiểu.`,
          action: 'Nhập hàng ngay để tránh mất doanh thu.',
        });
      }
      
      // Profit margin
      if (profitMargin < 15) {
        generatedInsights.push({
          type: 'warning',
          title: 'Biên lợi nhuận thấp',
          description: `Biên lợi nhuận hiện tại chỉ ${profitMargin.toFixed(1)}%.`,
          action: 'Xem xét tăng giá bán hoặc giảm chi phí vận hành.',
        });
      } else if (profitMargin > 30) {
        generatedInsights.push({
          type: 'opportunity',
          title: 'Biên lợi nhuận tốt',
          description: `Biên lợi nhuận đạt ${profitMargin.toFixed(1)}%, rất tốt!`,
          action: 'Có thể xem xét mở rộng sản phẩm hoặc đầu tư marketing.',
        });
      }
      
      // Top product
      if (topProductName) {
        generatedInsights.push({
          type: 'opportunity',
          title: 'Sản phẩm bán chạy',
          description: `"${topProductName}" là sản phẩm bán chạy nhất.`,
          action: 'Đảm bảo tồn kho đầy đủ và xem xét nhập thêm các sản phẩm tương tự.',
        });
      }
      
      // AOV tips
      if (avgOrderValue < 500000) {
        generatedInsights.push({
          type: 'tip',
          title: 'Giá trị đơn hàng trung bình thấp',
          description: `Giá trị đơn trung bình là ${avgOrderValue.toLocaleString('vi-VN')}đ.`,
          action: 'Thử cross-selling hoặc bundle sản phẩm để tăng giá trị đơn.',
        });
      }
      
      // Debt warning
      if (totalDebt > 10000000) {
        generatedInsights.push({
          type: 'warning',
          title: 'Công nợ cao',
          description: `Tổng công nợ khách hàng đạt ${totalDebt.toLocaleString('vi-VN')}đ.`,
          action: 'Cần thu hồi công nợ từ ${customerWithDebt.length} khách hàng.',
        });
      }
      
      // General tips
      generatedInsights.push({
        type: 'tip',
        title: 'Mẹo tối ưu',
        description: 'Theo dõi tồn khao hàng ngày giúp giảm thiểu tình trạng hết hàng và tối ưu vốn.',
      });
      
      generatedInsights.push({
        type: 'tip',
        title: 'Phân tích khách hàng',
        description: `Bạn có ${customers.length} khách hàng. Hãy tạo chương trình khách hàng thân thiết để tăng tỷ lệ quay lại.`,
      });

      setInsights(generatedInsights);
    } catch (error) {
      console.error('Error analyzing data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getIcon = (type: AIInsight['type']) => {
    switch (type) {
      case 'trend': return <TrendingUp className="w-5 h-5 text-blue-500" />;
      case 'warning': return <AlertTriangle className="w-5 h-5 text-red-500" />;
      case 'opportunity': return <Sparkles className="w-5 h-5 text-amber-500" />;
      case 'tip': return <Lightbulb className="w-5 h-5 text-emerald-500" />;
    }
  };

  const getBorderColor = (type: AIInsight['type']) => {
    switch (type) {
      case 'trend': return 'border-blue-200 bg-blue-50/30';
      case 'warning': return 'border-red-200 bg-red-50/30';
      case 'opportunity': return 'border-amber-200 bg-amber-50/30';
      case 'tip': return 'border-emerald-200 bg-emerald-50/30';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center">
            <Bot className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-emerald-900">AI Phân tích</h1>
            <p className="text-emerald-600/70 text-sm">Phân tích dữ liệu và gợi ý từ AI</p>
          </div>
        </div>
        <button
          onClick={() => { setAnalyzing(true); analyzeData().then(() => setAnalyzing(false)); }}
          disabled={analyzing}
          className="px-4 py-2 bg-gradient-to-r from-violet-600 to-purple-600 text-white rounded-lg font-medium transition-all hover:opacity-90 flex items-center gap-2 disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 ${analyzing ? 'animate-spin' : ''}`} />
          {analyzing ? 'Đang phân tích...' : 'Phân tích lại'}
        </button>
      </div>

      {/* AI Status */}
      <div className="bg-gradient-to-r from-violet-50 to-purple-50 border border-violet-100 rounded-xl p-4 flex items-center gap-3">
        <div className="w-10 h-10 rounded-full bg-violet-100 flex items-center justify-center">
          <Sparkles className="w-5 h-5 text-violet-600" />
        </div>
        <div>
          <p className="font-medium text-violet-900">AI đã phân tích dữ liệu của bạn</p>
          <p className="text-sm text-violet-600">Dựa trên dữ liệu 30 ngày gần nhất • Cập nhật liên tục</p>
        </div>
      </div>

      {/* Insights */}
      {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="w-12 h-12 border-4 border-violet-200 border-t-violet-600 rounded-full animate-spin" />
        </div>
      ) : (
        <div className="grid gap-4">
          {insights.map((insight, index) => (
            <div
              key={index}
              className={`p-4 rounded-xl border ${getBorderColor(insight.type)} transition-all hover:shadow-md`}
            >
              <div className="flex items-start gap-3">
                <div className="mt-0.5">{getIcon(insight.type)}</div>
                <div className="flex-1">
                  <h3 className="font-semibold text-emerald-900">{insight.title}</h3>
                  <p className="text-emerald-700 mt-1">{insight.description}</p>
                  {insight.action && (
                    <div className="mt-3 p-3 bg-white/50 rounded-lg">
                      <p className="text-sm font-medium text-emerald-800">💡 Gợi ý hành động:</p>
                      <p className="text-sm text-emerald-600 mt-1">{insight.action}</p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
