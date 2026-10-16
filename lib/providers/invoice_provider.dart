import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';

class InvoiceState {
  final bool isLoading;
  final String? errorMessage;
  final InvoiceModel? currentInvoice;
  final List<InvoiceModel> userInvoices;
  final int totalInvoices;

  InvoiceState({
    this.isLoading = false,
    this.errorMessage,
    this.currentInvoice,
    this.userInvoices = const [],
    this.totalInvoices = 0,
  });

  InvoiceState copyWith({
    bool? isLoading,
    String? errorMessage,
    InvoiceModel? currentInvoice,
    List<InvoiceModel>? userInvoices,
    int? totalInvoices,
  }) {
    return InvoiceState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentInvoice: currentInvoice ?? this.currentInvoice,
      userInvoices: userInvoices ?? this.userInvoices,
      totalInvoices: totalInvoices ?? this.totalInvoices,
    );
  }
}

class InvoiceNotifier extends Notifier<InvoiceState> {
  late InvoiceService _invoiceService;

  @override
  InvoiceState build() {
    _invoiceService = ref.watch(invoiceServiceProvider);
    return InvoiceState();
  }

  Future<bool> createInvoice({
    required String bookingId,
    required dynamic booking,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _invoiceService.createInvoice(
        bookingId: bookingId,
        booking: booking,
      );

      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          currentInvoice: result['invoice'],
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error creating invoice: $e',
      );
      return false;
    }
  }

  Future<bool> getInvoiceByBookingId(String bookingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _invoiceService.getInvoiceByBookingId(bookingId);

      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          currentInvoice: result['invoice'],
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error getting invoice: $e',
      );
      return false;
    }
  }

  Future<bool> loadUserInvoices({
    String? status,
    int limit = 20,
    int skip = 0,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _invoiceService.getUserInvoices(
        status: status,
        limit: limit,
        skip: skip,
      );

      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          userInvoices: result['invoices'],
          totalInvoices: result['total'],
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading invoices: $e',
      );
      return false;
    }
  }

  Future<void> downloadAndPrintInvoice(InvoiceModel invoice) async {
    try {
      await _invoiceService.downloadAndPrintInvoice(invoice);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error downloading invoice: $e');
    }
  }

  Future<String> saveInvoiceToDevice(InvoiceModel invoice) async {
    try {
      return await _invoiceService.saveInvoiceToDevice(invoice);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error saving invoice: $e');
      return '';
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void clearCurrentInvoice() {
    state = state.copyWith(currentInvoice: null);
  }
}

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService();
});

final invoiceProvider = NotifierProvider<InvoiceNotifier, InvoiceState>(
  InvoiceNotifier.new,
);
