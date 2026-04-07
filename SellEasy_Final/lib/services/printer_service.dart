// import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
// import 'package:esc_pos_utils/esc_pos_utils.dart';
// import '../models/order.dart';
// import '../models/customer.dart';

// class PrinterService {
//   static final PrinterService instance = PrinterService._internal();
//   PrinterService._internal();

//   PrinterBluetoothManager? _printerManager;
//   PrinterBluetooth? _printer;

//   Future<void> init() async {
//     _printerManager = PrinterBluetoothManager();
//   }

//   Future<List<PrinterBluetooth>> scanDevices() async {
//     if (_printerManager == null) await init();
//     return await _printerManager!.scanResults;
//   }

//   Future<void> startScan() async {
//     if (_printerManager == null) await init();
//     await _printerManager!.startScan(Duration(seconds: 4));
//   }

//   Future<void> stopScan() async {
//     if (_printerManager == null) await init();
//     await _printerManager!.stopScan();
//   }

//   Future<void> connectToPrinter(PrinterBluetooth printer) async {
//     if (_printerManager == null) await init();
//     _printer = printer;
//     await _printerManager!.connect(_printer!);
//   }

//   Future<void> disconnect() async {
//     if (_printerManager == null) await init();
//     await _printerManager!.disconnect();
//     _printer = null;
//   }

//   Future<void> printOrder(Order order, Customer customer) async {
//     if (_printer == null) {
//       throw Exception('No printer connected');
//     }

//     final profile = await CapabilityProfile.load();
//     final generator = Generator(PaperSize.mm80, profile);

//     List<int> bytes = [];

//     // Header
//     bytes += generator.text(
//       'SELLEASY',
//       styles: const PosStyles(
//         align: PosAlign.center,
//         bold: true,
//         height: PosTextSize.size2,
//       ),
//     );
//     bytes += generator.text(
//       'HÓA ĐƠN BÁN HÀNG',
//       styles: const PosStyles(
//         align: PosAlign.center,
//         bold: true,
//       ),
//     );
//     bytes += generator.text(
//       '--------------------------------',
//       styles: const PosStyles(align: PosAlign.center),
//     );

//     // Order info
//     bytes += generator.text(
//       'Mã đơn: ${order.id}',
//       styles: const PosStyles(align: PosAlign.left),
//     );
//     bytes += generator.text(
//       'Ngày: ${order.date}',
//       styles: const PosStyles(align: PosAlign.left),
//     );
//     bytes += generator.text(
//       'Khách hàng: ${customer.name}',
//       styles: const PosStyles(align: PosAlign.left),
//     );
//     bytes += generator.text(
//       '--------------------------------',
//       styles: const PosStyles(align: PosAlign.center),
//     );

//     // Items
//     for (var item in order.items) {
//       bytes += generator.text(
//         item.name,
//         styles: const PosStyles(align: PosAlign.left),
//       );
//       bytes += generator.text(
//         '${item.quantity} x ${item.price}đ = ${item.quantity * item.price}đ',
//         styles: const PosStyles(align: PosAlign.right),
//       );
//     }

//     // Total
//     bytes += generator.text(
//       '--------------------------------',
//       styles: const PosStyles(align: PosAlign.center),
//     );
//     bytes += generator.text(
//       'Tổng cộng: ${order.total}đ',
//       styles: const PosStyles(
//         align: PosAlign.right,
//         bold: true,
//       ),
//     );

//     // Footer
//     bytes += generator.text(
//       '--------------------------------',
//       styles: const PosStyles(align: PosAlign.center),
//     );
//     bytes += generator.text(
//       'Cảm ơn quý khách!',
//       styles: const PosStyles(align: PosAlign.center),
//     );
//     bytes += generator.text(
//       '--------------------------------',
//       styles: const PosStyles(align: PosAlign.center),
//     );
//     bytes += generator.feed(2);
//     bytes += generator.cut();

//     await _printerManager!.writeBytes(bytes);
//   }
// }
