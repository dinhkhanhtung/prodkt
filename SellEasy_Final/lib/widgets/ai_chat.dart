// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../services/grok_service.dart';
// import '../services/database_helper.dart';

// class AIChat extends StatefulWidget {
//   const AIChat({super.key});

//   @override
//   State<AIChat> createState() => _AIChatState();
// }

// class _AIChatState extends State<AIChat> {
//   final _messageController = TextEditingController();
//   final _scrollController = ScrollController();
//   List<Map<String, dynamic>> _messages = [];
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadMessages();
//   }

//   Future<void> _loadMessages() async {
//     final messages = await DatabaseHelper.instance.getAIMessages();
//     setState(() => _messages = messages);
//   }

//   Future<void> _sendMessage() async {
//     if (_messageController.text.isEmpty) return;

//     final message = _messageController.text;
//     _messageController.clear();

//     setState(() {
//       _messages.add({
//         'role': 'user',
//         'content': message,
//         'timestamp': DateTime.now().toIso8601String(),
//       });
//       _isLoading = true;
//     });

//     try {
//       final response = await GrokService.instance.generateResponse(message);
//       setState(() {
//         _messages.add({
//           'role': 'assistant',
//           'content': response,
//           'timestamp': DateTime.now().toIso8601String(),
//         });
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(
//           child: ListView.builder(
//             controller: _scrollController,
//             padding: const EdgeInsets.all(16),
//             itemCount: _messages.length,
//             itemBuilder: (context, index) {
//               final message = _messages[index];
//               final isUser = message['role'] == 'user';

//               return Align(
//                 alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//                 child: Container(
//                   margin: const EdgeInsets.symmetric(vertical: 4),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: isUser ? Colors.blue : Colors.grey[200],
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     message['content'],
//                     style: TextStyle(
//                       color: isUser ? Colors.white : Colors.black,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//         if (_isLoading)
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: CircularProgressIndicator(),
//           ),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: _messageController,
//                   decoration: const InputDecoration(
//                     hintText: 'Nhập tin nhắn...',
//                     border: OutlineInputBorder(),
//                   ),
//                   onSubmitted: (_) => _sendMessage(),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               IconButton(
//                 onPressed: _sendMessage,
//                 icon: const Icon(Icons.send),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
