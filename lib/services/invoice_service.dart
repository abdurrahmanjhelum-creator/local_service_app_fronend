import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/invoice_model.dart';
import '../models/booking_model.dart';
import '../utils/api_constants.dart';
import '../utils/token_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InvoiceService {
  final String _baseUrl = ApiConstants.baseUrl;

  // Generate invoice PDF
  Future<Uint8List> generateInvoicePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LocalServe',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Invoice #${invoice.invoiceNumber}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Status: ${invoice.status.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: invoice.isPaid
                              ? PdfColors.green700
                              : PdfColors.orange700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: ${_formatDate(invoice.createdAt)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),

              // Bill To
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill To:',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      invoice.customerName,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      invoice.customerEmail,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      invoice.customerPhone,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Service Provider
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Service Provider:',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      invoice.providerName,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      invoice.providerEmail,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      invoice.providerPhone,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Service Details Table
              pw.Text(
                'Service Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              invoice.serviceName,
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                            pw.Text(
                              invoice.serviceCategory,
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          _formatDate(invoice.bookingDate),
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${invoice.currency} ${invoice.amount.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Address
              pw.Text(
                'Service Address:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(invoice.address, style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 24),

              // Totals
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildTotalRow('Subtotal', invoice.amount),
                    if (invoice.taxAmount != null)
                      _buildTotalRow('Tax', invoice.taxAmount!),
                    if (invoice.discountAmount != null)
                      _buildTotalRow(
                        'Discount',
                        invoice.discountAmount!,
                        isDiscount: true,
                      ),
                    pw.Divider(color: PdfColors.grey400),
                    _buildTotalRow(
                      'Total',
                      invoice.totalAmount ?? invoice.amount,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Payment Details
              if (invoice.paymentMethod != null) ...[
                pw.Text(
                  'Payment Details',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Payment Method: ${invoice.paymentMethod}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                if (invoice.transactionId != null)
                  pw.Text(
                    'Transaction ID: ${invoice.transactionId}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                if (invoice.paidAt != null)
                  pw.Text(
                    'Paid On: ${_formatDate(invoice.paidAt!)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                pw.SizedBox(height: 24),
              ],

              // Notes
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.Text(
                  'Notes',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  invoice.notes!,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 24),
              ],

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTotalRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isDiscount = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '${isDiscount ? '-' : ''}${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDiscount ? PdfColors.red700 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Create invoice from booking (cash payment)
  Future<Map<String, dynamic>> createInvoice({
    required String bookingId,
    required BookingModel booking,
  }) async {
    try {
      final token = await TokenManager.getToken();

      // Generate invoice number
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      final invoiceData = {
        'invoiceNumber': invoiceNumber,
        'bookingId': bookingId,
        'customerId': booking.customerId,
        'customerName': booking.customerData?['name'] ?? 'Customer',
        'customerEmail': booking.customerData?['email'] ?? '',
        'customerPhone': booking.customerData?['phone'] ?? '',
        'providerId': booking.providerId,
        'providerName': booking.providerData?['name'] ?? 'Provider',
        'providerEmail': booking.providerData?['email'] ?? '',
        'providerPhone': booking.providerData?['phone'] ?? '',
        'serviceName': booking.categoryName,
        'serviceCategory': booking.categoryName,
        'amount': booking.bookedPrice,
        'currency': 'PKR',
        'status': booking.status == 'completed' ? 'paid' : 'pending',
        'bookingDate': booking.bookingDate,
        'address': booking.address,
        'paymentMethod': 'Cash',
        'totalAmount': booking.bookedPrice,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/invoices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(invoiceData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'invoice': InvoiceModel.fromJson(data)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to create invoice',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error creating invoice: $e'};
    }
  }

  // Get invoice by booking ID
  Future<Map<String, dynamic>> getInvoiceByBookingId(String bookingId) async {
    try {
      final token = await TokenManager.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/invoices/booking/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'invoice': InvoiceModel.fromJson(data)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get invoice',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error getting invoice: $e'};
    }
  }

  // Get user invoices
  Future<Map<String, dynamic>> getUserInvoices({
    String? status,
    int limit = 20,
    int skip = 0,
  }) async {
    try {
      final token = await TokenManager.getToken();
      final queryParams = <String, String>{
        ...status != null ? {'status': status} : {},
        'limit': limit.toString(),
        'skip': skip.toString(),
      };

      final uri = Uri.parse(
        '$_baseUrl/invoices',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final invoices = (data['invoices'] as List)
            .map((json) => InvoiceModel.fromJson(json))
            .toList();

        return {'success': true, 'invoices': invoices, 'total': data['total']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get invoices',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error getting invoices: $e'};
    }
  }

  // Download and print invoice
  Future<void> downloadAndPrintInvoice(InvoiceModel invoice) async {
    final pdfData = await generateInvoicePdf(invoice);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  // Save invoice to device
  Future<String> saveInvoiceToDevice(InvoiceModel invoice) async {
    final pdfData = await generateInvoicePdf(invoice);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(pdfData);

    return file.path;
  }
}
