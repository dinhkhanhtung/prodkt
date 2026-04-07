// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class GrokService {
//   static const String _baseUrl = 'https://api.grok.ai/v1';
//   static const String _apiKey =
//       'YOUR_API_KEY'; // TODO: Replace with actual API key

//   static Future<String> generateProductPost({
//     required String productName,
//     required double price,
//     required int quantity,
//     required String style,
//     required List<Map<String, dynamic>> attributes,
//     String? phone,
//   }) async {
//     final attributesText = attributes
//         .map((attr) => '${attr['name']}: ${attr['value']}')
//         .join(', ');

//     final prompt = '''
// Viết bài $style cho sản phẩm:
// - Tên: $productName
// - Giá: ${price.toStringAsFixed(0)}đ
// - Còn: $quantity
// - Thông tin: $attributesText
// ${phone != null ? '- Liên hệ: $phone' : ''}
// ''';

//     try {
//       final response = await http.post(
//         Uri.parse('$_baseUrl/chat/completions'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_apiKey',
//         },
//         body: jsonEncode({
//           'model': 'grok-1',
//           'messages': [
//             {
//               'role': 'system',
//               'content':
//                   'Bạn là một copywriter chuyên nghiệp, viết bài quảng cáo sản phẩm.',
//             },
//             {
//               'role': 'user',
//               'content': prompt,
//             },
//           ],
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['choices'][0]['message']['content'];
//       } else {
//         throw Exception('Failed to generate post: ${response.statusCode}');
//       }
//     } catch (e) {
//       return 'Xin lỗi, không thể tạo bài viết lúc này. Vui lòng thử lại sau.';
//     }
//   }

//   static Future<String> getDailySales(double totalSales) async {
//     final prompt = '''
// Hôm nay cửa hàng đã bán được ${totalSales.toStringAsFixed(0)}đ.
// Hãy phân tích và đưa ra nhận xét ngắn gọn về doanh số này.
// ''';

//     try {
//       final response = await http.post(
//         Uri.parse('$_baseUrl/chat/completions'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_apiKey',
//         },
//         body: jsonEncode({
//           'model': 'grok-1',
//           'messages': [
//             {
//               'role': 'system',
//               'content': 'Bạn là một chuyên gia phân tích doanh số.',
//             },
//             {
//               'role': 'user',
//               'content': prompt,
//             },
//           ],
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['choices'][0]['message']['content'];
//       } else {
//         throw Exception('Failed to analyze sales: ${response.statusCode}');
//       }
//     } catch (e) {
//       return 'Xin lỗi, không thể phân tích doanh số lúc này. Vui lòng thử lại sau.';
//     }
//   }

//   static Future<String> getHelp(String question) async {
//     final prompt = '''
// Câu hỏi: $question
// Hãy trả lời ngắn gọn và hữu ích.
// ''';

//     try {
//       final response = await http.post(
//         Uri.parse('$_baseUrl/chat/completions'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_apiKey',
//         },
//         body: jsonEncode({
//           'model': 'grok-1',
//           'messages': [
//             {
//               'role': 'system',
//               'content':
//                   'Bạn là một trợ lý chuyên nghiệp, trả lời các câu hỏi về quản lý cửa hàng.',
//             },
//             {
//               'role': 'user',
//               'content': prompt,
//             },
//           ],
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['choices'][0]['message']['content'];
//       } else {
//         throw Exception('Failed to get help: ${response.statusCode}');
//       }
//     } catch (e) {
//       return 'Xin lỗi, không thể trả lời câu hỏi lúc này. Vui lòng thử lại sau.';
//     }
//   }
// }
