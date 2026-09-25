import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/service_api.dart';

class ServiceState {
  final List<UserModel> providers;
  final bool isLoading;
  final String? error;

  ServiceState({this.providers = const [], this.isLoading = false, this.error});
}

class ServiceNotifier extends Notifier<ServiceState> {
  @override
  ServiceState build() {
    load();
    return ServiceState(isLoading: true);
  }

  Future<void> load({String? category}) async {
    state = ServiceState(isLoading: true);
    try {
      final list = await ServiceApi().getProviders(category: category);
      state = ServiceState(isLoading: false, providers: list);
    } catch (e) {
      state = ServiceState(isLoading: false, error: e.toString());
    }
  }
}

final serviceListProvider = NotifierProvider<ServiceNotifier, ServiceState>(ServiceNotifier.new);
