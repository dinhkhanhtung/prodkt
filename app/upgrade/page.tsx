'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Check, X, Crown, Zap, Building2, ArrowRight, CreditCard } from 'lucide-react';

const PRICING_PLANS = [
  {
    name: 'FREE',
    description: 'Dành cho người mới bắt đầu',
    price: 0,
    period: '',
    features: [
      { text: '100 sản phẩm', included: true },
      { text: '500 đơn hàng/tháng', included: true },
      { text: '1 cửa hàng', included: true },
      { text: 'Báo cáo cơ bản', included: true },
      { text: 'Không giới hạn sản phẩm', included: false },
      { text: 'Multi-store', included: false },
      { text: 'Báo cáo nâng cao', included: false },
      { text: 'Hỗ trợ ưu tiên', included: false },
    ],
    cta: 'Dùng miễn phí',
    popular: false,
    disabled: false,
  },
  {
    name: 'PRO',
    description: 'Dành cho cửa hàng phát triển',
    price: 99000,
    period: '/tháng',
    features: [
      { text: 'Không giới hạn sản phẩm', included: true },
      { text: 'Không giới hạn đơn hàng', included: true },
      { text: '5 cửa hàng', included: true },
      { text: 'Báo cáo cơ bản', included: true },
      { text: 'Báo cáo nâng cao + Excel', included: true },
      { text: 'Multi-user (5 người)', included: true },
      { text: 'Hỗ trợ ưu tiên (24h)', included: true },
      { text: 'API access', included: false },
    ],
    cta: 'Nâng cấp PRO',
    popular: true,
    disabled: false,
  },
  {
    name: 'ENTERPRISE',
    description: 'Dành cho chuỗi cửa hàng',
    price: null,
    period: '',
    features: [
      { text: 'Tất cả tính năng PRO', included: true },
      { text: 'Không giới hạn cửa hàng', included: true },
      { text: 'Self-hosted option', included: true },
      { text: 'API access', included: true },
      { text: 'Custom integration', included: true },
      { text: 'SLA 99.99%', included: true },
      { text: 'Hỗ trợ 24/7', included: true },
      { text: 'Dedicated manager', included: true },
    ],
    cta: 'Liên hệ',
    popular: false,
    disabled: false,
  },
];

export default function UpgradePage() {
  const [billingPeriod, setBillingPeriod] = useState<'monthly' | 'yearly'>('monthly');

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-white py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Nâng cấp lên <span className="text-primary-600">PRO</span>
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Mở khóa tất cả tính năng cao cấp để quản lý cửa hàng hiệu quả hơn
          </p>
        </div>

        {/* Billing Toggle */}
        <div className="flex items-center justify-center gap-4 mb-12">
          <span className={`text-sm font-medium ${billingPeriod === 'monthly' ? 'text-gray-900' : 'text-gray-500'}`}>
            Tháng
          </span>
          <button
            onClick={() => setBillingPeriod(billingPeriod === 'monthly' ? 'yearly' : 'monthly')}
            className="relative w-14 h-7 bg-primary-600 rounded-full transition-colors"
          >
            <span
              className={`absolute top-1 w-5 h-5 bg-white rounded-full transition-transform ${
                billingPeriod === 'yearly' ? 'translate-x-8' : 'translate-x-1'
              }`}
            />
          </button>
          <span className={`text-sm font-medium ${billingPeriod === 'yearly' ? 'text-gray-900' : 'text-gray-500'}`}>
            Năm
          </span>
          {billingPeriod === 'yearly' && (
            <span className="text-sm text-green-600 font-medium">Tiết kiệm 20%</span>
          )}
        </div>

        {/* Pricing Cards */}
        <div className="grid md:grid-cols-3 gap-8">
          {PRICING_PLANS.map((plan) => (
            <div
              key={plan.name}
              className={`relative rounded-2xl p-8 ${
                plan.popular
                  ? 'bg-white border-2 border-primary-500 shadow-xl scale-105 z-10'
                  : 'bg-white border border-gray-200 shadow-sm'
              }`}
            >
              {plan.popular && (
                <div className="absolute -top-4 left-1/2 -translate-x-1/2">
                  <span className="bg-gradient-to-r from-primary-600 to-secondary-600 text-white px-4 py-1 rounded-full text-sm font-medium">
                    Phổ biến nhất
                  </span>
                </div>
              )}

              {/* Plan Header */}
              <div className="text-center mb-6">
                <h3 className="text-xl font-bold text-gray-900">{plan.name}</h3>
                <p className="text-sm text-gray-500 mt-1">{plan.description}</p>
                <div className="mt-4">
                  {plan.price !== null ? (
                    <div className="flex items-baseline justify-center gap-1">
                      <span className="text-4xl font-bold text-gray-900">
                        {new Intl.NumberFormat('vi-VN').format(
                          billingPeriod === 'yearly' && plan.name === 'PRO' 
                            ? plan.price * 10  // 2 tháng free
                            : plan.price
                        )}
                      </span>
                      <span className="text-gray-500">đ</span>
                      <span className="text-gray-500 text-sm">{plan.period}</span>
                    </div>
                  ) : (
                    <span className="text-3xl font-bold text-gray-900">Liên hệ</span>
                  )}
                  {billingPeriod === 'yearly' && plan.name === 'PRO' && (
                    <p className="text-sm text-green-600 mt-1">Tiết kiệm 198,000đ</p>
                  )}
                </div>
              </div>

              {/* Features */}
              <ul className="space-y-3 mb-8">
                {plan.features.map((feature, idx) => (
                  <li key={idx} className="flex items-start gap-3">
                    {feature.included ? (
                      <Check className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" />
                    ) : (
                      <X className="w-5 h-5 text-gray-300 flex-shrink-0 mt-0.5" />
                    )}
                    <span className={feature.included ? 'text-gray-700' : 'text-gray-400'}>
                      {feature.text}
                    </span>
                  </li>
                ))}
              </ul>

              {/* CTA */}
              {plan.name === 'FREE' ? (
                <button disabled className="w-full py-3 px-4 bg-gray-100 text-gray-400 rounded-xl font-medium cursor-default">
                  Đang sử dụng
                </button>
              ) : plan.name === 'ENTERPRISE' ? (
                <a 
                  href="mailto:sales@prodkt.vn?subject=Yêu%20cầu%20báo%20giá%20Enterprise"
                  className="block w-full py-3 px-4 text-center bg-gray-900 text-white rounded-xl font-medium hover:bg-gray-800 transition-colors"
                >
                  {plan.cta}
                </a>
              ) : (
                <Link
                  href={`/payment?plan=${billingPeriod}`}
                  className={`block w-full py-3 px-4 text-center rounded-xl font-medium transition-colors ${
                    plan.popular
                      ? 'bg-gradient-to-r from-primary-600 to-secondary-600 text-white hover:opacity-90'
                      : 'bg-primary-600 text-white hover:bg-primary-700'
                  }`}
                >
                  <span className="flex items-center justify-center gap-2">
                    {plan.cta}
                    <ArrowRight className="w-4 h-4" />
                  </span>
                </Link>
              )}
            </div>
          ))}
        </div>

        {/* FAQ */}
        <div className="mt-16 max-w-3xl mx-auto">
          <h2 className="text-2xl font-bold text-gray-900 text-center mb-8">Câu hỏi thường gặp</h2>
          <div className="space-y-4">
            {[
              {
                q: 'Tôi có thể hủy subscription bất cứ lúc nào?',
                a: 'Có, bạn có thể hủy bất cứ lúc nào. Tài khoản PRO sẽ hoạt động đến hết chu kỳ đã thanh toán.',
              },
              {
                q: 'Làm sao để thanh toán?',
                a: 'Bạn chuyển khoản ngân hàng và upload ảnh chụp màn hình. Admin sẽ duyệt trong vòng 24h.',
              },
              {
                q: 'Có hoàn tiền không?',
                a: 'Có thể hoàn tiền trong 7 ngày đầu nếu không hài lòng. Liên hệ admin để được hỗ trợ.',
              },
            ].map((faq, idx) => (
              <div key={idx} className="bg-white rounded-xl p-6 border border-gray-100">
                <h3 className="font-semibold text-gray-900 mb-2">{faq.q}</h3>
                <p className="text-gray-600">{faq.a}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Back to Dashboard */}
        <div className="text-center mt-12">
          <Link href="/dashboard" className="text-primary-600 hover:text-primary-700 font-medium">
            ← Quay lại Dashboard
          </Link>
        </div>
      </div>
    </div>
  );
}
