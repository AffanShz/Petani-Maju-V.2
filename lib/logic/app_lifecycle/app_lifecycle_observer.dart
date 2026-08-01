import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:petani_maju/logic/app_lifecycle/app_bloc.dart';

/// Memantau lifecycle aplikasi dan memicu revalidasi sesi saat resume
/// agar deteksi logout jarak jauh / sesi kedaluwarsa tetap bekerja.
class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppBloc>().add(AppResumed());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
