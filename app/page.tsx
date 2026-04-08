'use client';

import { useState } from 'react';
import Link from 'next/link';
import { 
  Check, 
  ChevronDown, 
  ChevronUp,
  ShoppingCart, 
  Package, 
  Users, 
  TrendingUp, 
  Receipt, 
  Image as ImageIcon, 
  Shield,
  ArrowRight,
  Menu,
  X,
  Play,
  Star,
  Sparkles,
  MessageCircle,
  Trophy,
  Store,
  Wallet,
  HandCoins,
  Repeat,
  Quote,
  Newspaper,
  Calendar,
  ArrowUpRight
} from 'lucide-react';

export default function LandingPage() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  const toggleFaq = (index: number) => {
    setOpenFaq(openFaq === index ? null : index);
  };

  const features = [
    {
      icon: <ShoppingCart className="w-6 h-6" />,
      title: 'Bán Hàng POS',
      description: 'Giao diện bán hàng trực quan, xử lý đơn hàng nhanh chóng chỉ với vài click chuột.'
    },
    {
      icon: <Package className="w-6 h-6" />,
      title: 'Quản Lý Tồn Kho',
      description: 'Theo dõi số lượng tồn kho real-time, cảnh báo khi sản phẩm sắp hết.'
    },
    {
      icon: <ImageIcon className="w-6 h-6" />,
      title: 'Lưu Trữ Ảnh Miễn Phí',
      description: 'Upload ảnh sản phẩm không giới hạn qua ImgBB, không tốn phí hosting.'
    },
    {
      icon: <Users className="w-6 h-6" />,
      title: 'Quản Lý Công Nợ',
      description: 'Theo dõi công nợ khách hàng và nhà cung cấp, tự động cập nhật sau mỗi giao dịch.'
    },
    {
      icon: <TrendingUp className="w-6 h-6" />,
      title: 'Báo Cáo Thuế',
      description: 'Xuất báo cáo doanh thu, chi phí, lợi nhuận theo chuẩn Hộ Kinh Doanh.'
    },
    {
      icon: <Shield className="w-6 h-6" />,
      title: 'An Toàn Dữ Liệu',
      description: 'Dữ liệu được lưu trữ trên Firebase Google, backup tự động, bảo mật cao.'
    },
    {
      icon: <Sparkles className="w-6 h-6" />,
      title: 'AI Phân Tích',
      description: 'Phân tích dữ liệu bằng AI, đưa ra insights và gợi ý cải thiện doanh thu.'
    },
    {
      icon: <MessageCircle className="w-6 h-6" />,
      title: 'Chat & Đánh Giá',
      description: 'Nhắn tin trực tiếp với đối tác, hệ thống đánh giá uy tín dựa trên giao dịch.'
    },
    {
      icon: <Trophy className="w-6 h-6" />,
      title: 'Hall of Fame',
      description: 'Bảng xếp hạng đối tác uy tín nhất, giúp tìm kiếm đối tác đáng tin cậy.'
    },
    {
      icon: <Store className="w-6 h-6" />,
      title: 'Cộng Đồng B2B',
      description: 'Mua bán sỉ giữa các đối tác, tìm nguồn hàng giá tốt trong cộng đồng.'
    },
    {
      icon: <Wallet className="w-6 h-6" />,
      title: 'Tài Chính Cá Nhân',
      description: 'Quản lý thu chi cá nhân, theo dõi ngân sách riêng biệt với tài khoản shop.'
    },
    {
      icon: <HandCoins className="w-6 h-6" />,
      title: 'Quản Lý Nợ Cá Nhân',
      description: 'Theo dõi nợ vay/cho vay cá nhân, nhắc nhở ngày đến hạn.'
    },
    {
      icon: <Repeat className="w-6 h-6" />,
      title: 'Giao Dịch Định Kỳ',
      description: 'Tự động hóa các giao dịch định kỳ như thuê bao, trả góp, lương.'
    }
  ];

  const testimonials = [
    {
      name: 'Nguyễn Văn A',
      role: 'Chủ shop thời trang',
      content: 'ProDKT giúp mình quản lý shop dễ dàng hơn rất nhiều. Giao diện đẹp, dễ dùng, mà lại miễn phí!',
      avatar: 'A'
    },
    {
      name: 'Trần Thị B',
      role: 'Chủ cửa hàng điện tử',
      content: 'Tính năng quản lý công nợ và báo cáo thuế rất hữu ích cho shop nhỏ như mình. Recommend!',
      avatar: 'B'
    },
    {
      name: 'Lê Văn C',
      role: 'Đại lý sỉ',
      content: 'Hall of Fame và cộng đồng B2B giúp mình tìm được nhiều đối tác uy tín. Tuyệt vời!',
      avatar: 'C'
    }
  ];

  const blogPosts = [
    {
      id: 1,
      title: '10 Mẹo Quản Lý Kho Hiệu Quả Cho Shop Nhỏ',
      excerpt: 'Hướng dẫn chi tiết cách tối ưu hóa quy trình quản lý tồn kho, giảm thiểu hàng tồn và tăng doanh thu.',
      category: 'Quản lý kho',
      date: '15/03/2024',
      readTime: '5 phút',
      image: '📦'
    },
    {
      id: 2,
      title: 'Cách Sử Dụng AI Phân Tích Để Tăng Doanh Thu',
      excerpt: 'Khám phá tính năng AI Phân Tích của ProDKT và cách áp dụng insights để cải thiện kinh doanh.',
      category: 'AI & Công nghệ',
      date: '10/03/2024',
      readTime: '7 phút',
      image: '🤖'
    },
    {
      id: 3,
      title: 'Hướng Dẫn Bán Hàng Sỉ Trên Cộng Đồng B2B',
      excerpt: 'Tìm hiểu cách tìm kiếm đối tác uy tín và mở rộng kênh bán hàng qua Hall of Fame.',
      category: 'Bán hàng',
      date: '05/03/2024',
      readTime: '6 phút',
      image: '🤝'
    }
  ];

  const steps = [
    {
      number: '01',
      title: 'Đăng Ký Miễn Phí',
      description: 'Tạo tài khoản chỉ với email, không cần thẻ tín dụng. Cửa hàng của bạn sẵn sàng sau 30 giây.'
    },
    {
      number: '02',
      title: 'Thêm Sản Phẩm',
      description: 'Nhập sản phẩm thủ công hoặc import từ Excel. Upload ảnh miễn phí qua ImgBB.'
    },
    {
      number: '03',
      title: 'Bán Hàng Ngay',
      description: 'Mở giao diện POS, thêm sản phẩm vào giỏ, thanh toán tiền mặt hoặc chuyển khoản.'
    }
  ];

  const faqs = [
    {
      question: 'ProDKT có thực sự miễn phí không?',
      answer: 'Có! Gói FREE cho phép bạn sử dụng đầy đủ tính năng cơ bản với 100 sản phẩm và 500 đơn hàng/tháng. Không có phí ẩn, không thu thập thẻ tín dụng. Chúng tôi kiếm tiền từ gói PRO dành cho cửa hàng lớn hơn.'
    },
    {
      question: 'Dữ liệu của tôi có an toàn không?',
      answer: 'Hoàn toàn an toàn. Dữ liệu được lưu trữ trên Firebase (Google Cloud) với mã hóa SSL, backup tự động. Mỗi cửa hàng có "storeId" riêng biệt, dữ liệu được cách ly hoàn toàn với các cửa hàng khác.'
    },
    {
      question: 'Tôi có thể xuất dữ liệu ra không?',
      answer: 'Có, bạn có thể xuất dữ liệu sản phẩm, đơn hàng ra Excel/CSV bất cứ lúc nào. Gói PRO hỗ trợ xuất báo cáo chi tiết với định dạng chuẩn cho kế toán.'
    },
    {
      question: 'Có hỗ trợ nhiều cửa hàng không?',
      answer: 'Gói FREE hỗ trợ 1 cửa hàng. Gói PRO cho phép quản lý không giới hạn cửa hàng, phù hợp với chuỗi cửa hàng hoặc đại lý có nhiều điểm bán.'
    },
    {
      question: 'Tôi cần Internet để sử dụng không?',
      answer: 'Có, ProDKT là ứng dụng web-based nên cần kết nối Internet. Ưu điểm là bạn có thể truy cập từ bất kỳ thiết bị nào (máy tính, tablet, điện thoại) mà không cần cài đặt.'
    }
  ];

  return (
    <div className="min-h-screen bg-white">
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <Link href="/" className="flex items-center gap-2">
              <div className="w-8 h-8 bg-gradient-to-br from-primary-600 to-primary-700 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-lg">P</span>
              </div>
              <span className="text-xl font-bold text-emerald-900">ProDKT</span>
            </Link>

            {/* Desktop Nav */}
            <div className="hidden md:flex items-center gap-8">
              <a href="#features" className="text-emerald-700 hover:text-emerald-900 font-medium">Tính năng</a>
              <a href="#pricing" className="text-emerald-700 hover:text-emerald-900 font-medium">Bảng giá</a>
              <a href="#faq" className="text-emerald-700 hover:text-emerald-900 font-medium">FAQ</a>
            </div>

            {/* Auth Buttons */}
            <div className="hidden md:flex items-center gap-4">
              <Link href="/login" className="text-emerald-700 hover:text-emerald-900 font-medium">
                Đăng nhập
              </Link>
              <Link href="/register" className="btn-primary">
                Dùng miễn phí
              </Link>
            </div>

            {/* Mobile Menu Button */}
            <button 
              className="md:hidden p-2"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className="md:hidden bg-white border-t border-gray-100">
            <div className="px-4 py-4 space-y-3">
              <a href="#features" className="block text-emerald-700 hover:text-emerald-900 font-medium">Tính năng</a>
              <a href="#pricing" className="block text-emerald-700 hover:text-emerald-900 font-medium">Bảng giá</a>
              <a href="#faq" className="block text-emerald-700 hover:text-emerald-900 font-medium">FAQ</a>
              <hr className="border-gray-100" />
              <Link href="/login" className="block text-emerald-700 hover:text-emerald-900 font-medium">Đăng nhập</Link>
              <Link href="/register" className="block btn-primary text-center">Dùng miễn phí</Link>
            </div>
          </div>
        )}
      </nav>

      {/* Hero Section */}
      <section className="pt-32 pb-20 bg-gradient-to-br from-primary-50 via-white to-secondary-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <div className="inline-flex items-center gap-2 px-4 py-2 bg-primary-100 text-primary-700 rounded-full text-sm font-medium mb-6">
                <Star className="w-4 h-4 fill-current" />
                Miễn phí vĩnh viễn cho Hộ Kinh Doanh
              </div>
              <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-emerald-900 leading-tight mb-6">
                Phần mềm quản lý bán hàng{' '}
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-600 to-secondary-600">
                  0đ chi phí
                </span>
              </h1>
              <p className="text-lg sm:text-xl text-emerald-700 mb-8 max-w-lg">
                Tất cả trong một: Bán hàng POS, quản lý kho, công nợ, báo cáo thuế. 
                Không giới hạn thời gian dùng thử - hoàn toàn miễn phí.
              </p>
              <div className="flex flex-col sm:flex-row gap-4">
                <Link href="/register" className="btn-primary text-lg px-8 py-4 flex items-center justify-center gap-2">
                  Bắt đầu miễn phí ngay
                  <ArrowRight className="w-5 h-5" />
                </Link>
                <a 
                  href="#demo" 
                  className="btn-secondary text-lg px-8 py-4 flex items-center justify-center gap-2"
                >
                  <Play className="w-5 h-5" />
                  Xem demo
                </a>
              </div>
              <div className="mt-8 flex items-center gap-4 text-sm text-emerald-700">
                <div className="flex -space-x-2">
                  {[1,2,3,4].map(i => (
                    <div key={i} className="w-8 h-8 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 border-2 border-white flex items-center justify-center text-white text-xs font-bold">
                      {String.fromCharCode(64 + i)}
                    </div>
                  ))}
                </div>
                <p>1,000+ cửa hàng đang tin dùng</p>
              </div>
            </div>
            <div className="relative">
              <div className="absolute inset-0 bg-gradient-to-r from-primary-500/20 to-secondary-500/20 rounded-3xl blur-3xl" />
              <div className="relative bg-white rounded-2xl shadow-2xl p-6 border border-gray-100">
                <div className="flex items-center gap-3 mb-4 pb-4 border-b border-gray-100">
                  <div className="flex gap-2">
                    <div className="w-3 h-3 rounded-full bg-red-400" />
                    <div className="w-3 h-3 rounded-full bg-yellow-400" />
                    <div className="w-3 h-3 rounded-full bg-green-400" />
                  </div>
                  <span className="text-sm text-emerald-700 font-medium">ProDKT POS</span>
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between items-center p-3 bg-emerald-50/50 rounded-lg">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-primary-100 rounded-lg flex items-center justify-center">
                        <Package className="w-5 h-5 text-primary-600" />
                      </div>
                      <div>
                        <p className="font-medium text-emerald-900">Áo thun nam</p>
                        <p className="text-sm text-emerald-600">x2</p>
                      </div>
                    </div>
                    <span className="font-semibold text-emerald-900">300.000đ</span>
                  </div>
                  <div className="flex justify-between items-center p-3 bg-emerald-50/50 rounded-lg">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-primary-100 rounded-lg flex items-center justify-center">
                        <Package className="w-5 h-5 text-primary-600" />
                      </div>
                      <div>
                        <p className="font-medium text-emerald-900">Quần jean</p>
                        <p className="text-sm text-emerald-600">x1</p>
                      </div>
                    </div>
                    <span className="font-semibold text-emerald-900">450.000đ</span>
                  </div>
                  <div className="pt-3 border-t border-emerald-100">
                    <div className="flex justify-between text-lg font-bold text-emerald-900">
                      <span>Tổng cộng</span>
                      <span>750.000đ</span>
                    </div>
                  </div>
                  <button className="w-full btn-primary py-3">
                    Thanh toán
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-12 bg-white border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
            <div>
              <p className="text-3xl sm:text-4xl font-bold text-emerald-900">0đ</p>
              <p className="text-emerald-700 mt-1">Chi phí vận hành</p>
            </div>
            <div>
              <p className="text-3xl sm:text-4xl font-bold text-emerald-900">1,000+</p>
              <p className="text-emerald-700 mt-1">Cửa hàng tin dùng</p>
            </div>
            <div>
              <p className="text-3xl sm:text-4xl font-bold text-emerald-900">50K+</p>
              <p className="text-emerald-700 mt-1">Đơn hàng/tháng</p>
            </div>
            <div>
              <p className="text-3xl sm:text-4xl font-bold text-emerald-900">99.9%</p>
              <p className="text-emerald-700 mt-1">Uptime</p>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 bg-emerald-50/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold text-emerald-900 mb-4">
              Tất cả tính năng bạn cần
            </h2>
            <p className="text-lg text-emerald-700">
              Không giới hạn tính năng cơ bản. Chỉ nâng cấp khi bạn thực sự cần nhiều hơn.
            </p>
          </div>
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {features.map((feature, idx) => (
              <div key={idx} className="bg-white rounded-2xl p-6 shadow-sm hover:shadow-md transition-shadow">
                <div className="w-12 h-12 bg-primary-100 rounded-xl flex items-center justify-center text-primary-600 mb-4">
                  {feature.icon}
                </div>
                <h3 className="text-xl font-semibold text-emerald-900 mb-2">{feature.title}</h3>
                <p className="text-emerald-700">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold text-emerald-900 mb-4">
              Bắt đầu trong 3 bước đơn giản
            </h2>
            <p className="text-lg text-emerald-700">
              Không cần cài đặt phần mềm, không cần học sử dụng phức tạp.
            </p>
          </div>
          <div className="grid md:grid-cols-3 gap-8">
            {steps.map((step, idx) => (
              <div key={idx} className="relative">
                <div className="text-5xl font-bold text-primary-100 mb-4">{step.number}</div>
                <h3 className="text-xl font-semibold text-emerald-900 mb-3">{step.title}</h3>
                <p className="text-emerald-700">{step.description}</p>
                {idx < 2 && (
                  <div className="hidden md:block absolute top-8 left-full w-full h-0.5 bg-gradient-to-r from-primary-200 to-transparent ml-4" />
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-20 bg-gradient-to-br from-gray-50 to-primary-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold text-emerald-900 mb-4">
              Chọn gói phù hợp với bạn
            </h2>
            <p className="text-lg text-emerald-700">
              Miễn phí vĩnh viễn cho người mới bắt đầu. Nâng cấp khi bạn sẵn sàng.
            </p>
          </div>
          <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
            {/* Free Plan */}
            <div className="bg-white rounded-2xl p-8 shadow-sm">
              <h3 className="text-xl font-semibold text-emerald-900 mb-2">FREE</h3>
              <p className="text-emerald-600/70 mb-6">Dành cho người mới bắt đầu</p>
              <div className="mb-6">
                <span className="text-4xl font-bold text-emerald-900">0đ</span>
                <span className="text-emerald-600/70">/tháng</span>
              </div>
              <ul className="space-y-3 mb-8">
                {[
                  '100 sản phẩm',
                  '500 đơn hàng/tháng',
                  '1 cửa hàng',
                  'ImgBB upload ảnh',
                  'Báo cáo cơ bản',
                  'Hỗ trợ cộng đồng'
                ].map((item, i) => (
                  <li key={i} className="flex items-center gap-3 text-emerald-700">
                    <Check className="w-5 h-5 text-green-500 flex-shrink-0" />
                    {item}
                  </li>
                ))}
              </ul>
              <Link href="/register" className="block w-full btn-secondary text-center">
                Đăng ký miễn phí
              </Link>
            </div>

            {/* Pro Plan */}
            <div className="bg-white rounded-2xl p-8 shadow-xl border-2 border-primary-500 relative transform scale-105">
              <div className="absolute -top-4 left-1/2 -translate-x-1/2">
                <span className="bg-gradient-to-r from-primary-600 to-secondary-600 text-white px-4 py-1 rounded-full text-sm font-medium">
                  Phổ biến nhất
                </span>
              </div>
              <h3 className="text-xl font-semibold text-emerald-900 mb-2">PRO</h3>
              <p className="text-emerald-600/70 mb-6">Dành cho cửa hàng phát triển</p>
              <div className="mb-6">
                <span className="text-4xl font-bold text-emerald-900">99.000đ</span>
                <span className="text-emerald-600/70">/tháng</span>
              </div>
              <ul className="space-y-3 mb-8">
                {[
                  'Không giới hạn sản phẩm',
                  'Không giới hạn đơn hàng',
                  'Không giới hạn cửa hàng',
                  'ImgBB upload ảnh',
                  'Báo cáo nâng cao + Excel',
                  'Hỗ trợ ưu tiên (24h)',
                  'Multi-user (5 người)'
                ].map((item, i) => (
                  <li key={i} className="flex items-center gap-3 text-emerald-700">
                    <Check className="w-5 h-5 text-primary-500 flex-shrink-0" />
                    {item}
                  </li>
                ))}
              </ul>
              <Link href="/register" className="block w-full btn-primary text-center">
                Dùng thử 14 ngày
              </Link>
            </div>

            {/* Enterprise Plan */}
            <div className="bg-white rounded-2xl p-8 shadow-sm">
              <h3 className="text-xl font-semibold text-emerald-900 mb-2">ENTERPRISE</h3>
              <p className="text-emerald-600/70 mb-6">Dành cho chuỗi cửa hàng</p>
              <div className="mb-6">
                <span className="text-4xl font-bold text-emerald-900">Liên hệ</span>
              </div>
              <ul className="space-y-3 mb-8">
                {[
                  'Tất cả tính năng PRO',
                  'Self-hosted option',
                  'API access',
                  'Custom integration',
                  'SLA 99.99%',
                  'Hỗ trợ 24/7 phone',
                  'Dedicated account manager'
                ].map((item, i) => (
                  <li key={i} className="flex items-center gap-3 text-emerald-700">
                    <Check className="w-5 h-5 text-secondary-500 flex-shrink-0" />
                    {item}
                  </li>
                ))}
              </ul>
              <a href="mailto:sales@prodkt.vn" className="block w-full btn-secondary text-center">
                Liên hệ bán hàng
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-20 bg-gradient-to-br from-primary-50 to-emerald-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold text-emerald-900 mb-4">
              Khách hàng nói gì về ProDKT
            </h2>
            <p className="text-lg text-emerald-700">
              Hơn 1,000+ cửa hàng đang tin dùng và hài lòng.
            </p>
          </div>
          <div className="grid md:grid-cols-3 gap-8">
            {testimonials.map((item, idx) => (
              <div key={idx} className="bg-white rounded-2xl p-6 shadow-sm">
                <Quote className="w-8 h-8 text-primary-400 mb-4" />
                <p className="text-emerald-700 mb-6">{item.content}</p>
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center text-white font-bold">
                    {item.avatar}
                  </div>
                  <div>
                    <p className="font-semibold text-emerald-900">{item.name}</p>
                    <p className="text-sm text-emerald-600">{item.role}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Blog Section */}
      <section id="blog" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-primary-100 text-primary-700 rounded-full text-sm font-medium mb-4">
              <Newspaper className="w-4 h-4" />
              Blog & Tin tức
            </div>
            <h2 className="text-3xl sm:text-4xl font-bold text-emerald-900 mb-4">
              Kiến thức kinh doanh
            </h2>
            <p className="text-lg text-emerald-700">
              Hướng dẫn, mẹo hay và tin tức cập nhật để giúp shop của bạn phát triển.
            </p>
          </div>
          <div className="grid md:grid-cols-3 gap-8">
            {blogPosts.map((post) => (
              <article key={post.id} className="bg-white rounded-2xl border border-emerald-100 shadow-sm hover:shadow-lg transition-shadow overflow-hidden group">
                <div className="h-48 bg-gradient-to-br from-primary-50 to-emerald-50 flex items-center justify-center text-6xl">
                  {post.image}
                </div>
                <div className="p-6">
                  <div className="flex items-center gap-3 mb-3">
                    <span className="px-3 py-1 bg-primary-100 text-primary-700 text-xs font-medium rounded-full">
                      {post.category}
                    </span>
                    <span className="text-sm text-emerald-600 flex items-center gap-1">
                      <Calendar className="w-4 h-4" />
                      {post.date}
                    </span>
                  </div>
                  <h3 className="font-bold text-xl text-emerald-900 mb-2 group-hover:text-primary-600 transition-colors line-clamp-2">
                    {post.title}
                  </h3>
                  <p className="text-emerald-700 mb-4 line-clamp-3">
                    {post.excerpt}
                  </p>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-emerald-600">{post.readTime} đọc</span>
                    <button className="text-primary-600 font-medium flex items-center gap-1 hover:gap-2 transition-all">
                      Đọc thêm <ArrowUpRight className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </article>
            ))}
          </div>
          <div className="text-center mt-12">
            <Link 
              href="/blog" 
              className="inline-flex items-center gap-2 px-6 py-3 bg-emerald-50 text-emerald-700 rounded-lg font-medium hover:bg-emerald-100 transition-colors"
            >
              Xem tất cả bài viết <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </section>

      {/* FAQ Section */}
      <section id="faq" className="py-20 bg-white">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-emerald-900 mb-4">
              Câu hỏi thường gặp
            </h2>
          </div>
          <div className="space-y-4">
            {faqs.map((faq, idx) => (
              <div key={idx} className="border border-emerald-100 rounded-xl overflow-hidden">
                <button
                  className="w-full flex items-center justify-between p-5 text-left hover:bg-emerald-50/50 transition-colors"
                  onClick={() => toggleFaq(idx)}
                >
                  <span className="font-medium text-emerald-900 pr-4">{faq.question}</span>
                  {openFaq === idx ? (
                    <ChevronUp className="w-5 h-5 text-emerald-600/70 flex-shrink-0" />
                  ) : (
                    <ChevronDown className="w-5 h-5 text-emerald-600/70 flex-shrink-0" />
                  )}
                </button>
                {openFaq === idx && (
                  <div className="px-5 pb-5">
                    <p className="text-emerald-700 leading-relaxed">{faq.answer}</p>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-gradient-to-br from-primary-600 to-secondary-600">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-6">
            Sẵn sàng quản lý cửa hàng thông minh hơn?
          </h2>
          <p className="text-xl text-primary-100 mb-8 max-w-2xl mx-auto">
            Tham gia 1,000+ cửa hàng đang tiết kiệm thời gian và tăng doanh thu với ProDKT.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link 
              href="/register" 
              className="inline-flex items-center justify-center gap-2 bg-white text-primary-600 px-8 py-4 rounded-xl font-semibold hover:bg-primary-50 transition-colors"
            >
              Bắt đầu miễn phí ngay
              <ArrowRight className="w-5 h-5" />
            </Link>
            <a 
              href="mailto:support@prodkt.vn" 
              className="inline-flex items-center justify-center gap-2 border-2 border-white text-white px-8 py-4 rounded-xl font-semibold hover:bg-white/10 transition-colors"
            >
              Liên hệ tư vấn
            </a>
          </div>
          <p className="text-sm text-primary-200 mt-4">
            Không cần thẻ tín dụng. Hủy bất cứ lúc nào.
          </p>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-gray-300 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid md:grid-cols-4 gap-8 mb-8">
            <div>
              <div className="flex items-center gap-2 mb-4">
                <div className="w-8 h-8 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold">P</span>
                </div>
                <span className="text-xl font-bold text-white">ProDKT</span>
              </div>
              <p className="text-sm text-emerald-400">
                Phần mềm quản lý bán hàng miễn phí cho Hộ Kinh Doanh Việt Nam.
              </p>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Sản phẩm</h4>
              <ul className="space-y-2 text-sm">
                <li><a href="#features" className="hover:text-white transition-colors">Tính năng</a></li>
                <li><a href="#pricing" className="hover:text-white transition-colors">Bảng giá</a></li>
                <li><Link href="/login" className="hover:text-white transition-colors">Đăng nhập</Link></li>
                <li><Link href="/register" className="hover:text-white transition-colors">Đăng ký</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Hỗ trợ</h4>
              <ul className="space-y-2 text-sm">
                <li><a href="#faq" className="hover:text-white transition-colors">FAQ</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Hướng dẫn sử dụng</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Video tutorial</a></li>
                <li><a href="mailto:support@prodkt.vn" className="hover:text-white transition-colors">Liên hệ</a></li>
              </ul>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Liên hệ</h4>
              <ul className="space-y-2 text-sm">
                <li>Email: support@prodkt.vn</li>
                <li>Hotline: 1900 1234</li>
                <li>HCM: Quận 1, TP.HCM</li>
                <li>HN: Quận Hoàn Kiếm, Hà Nội</li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
            <p className="text-sm text-emerald-600/70">
              © 2024 ProDKT. All rights reserved.
            </p>
            <div className="flex gap-6 text-sm">
              <a href="#" className="hover:text-white transition-colors">Điều khoản</a>
              <a href="#" className="hover:text-white transition-colors">Chính sách bảo mật</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
