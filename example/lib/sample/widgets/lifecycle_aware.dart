part of 'rapid_kit_sample_widget.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

abstract class LifecycleAwareState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver, RouteAware {
  @protected
  // ignore: non_constant_identifier_names
  bool get lifecycle_enabled => true;

  static const String _tag = 'LifecycleAware';

  late final int _instanceId = identityHashCode(this);

  bool _isSubscribed = false;
  bool isResumed = false;
  bool _appForeground = true;
  bool _routeVisible = false;

  PageRoute? _pageRoute;

  void _log(String message) {
    Logging.i(_tag, '[${widget.runtimeType}#$_instanceId] $message');
  }

  String _lifecycleSnapshot() {
    return 'foreground=$_appForeground, routeVisible=$_routeVisible, isCurrent=${_isCurrentRoute()}';
  }

  bool _isCurrentRoute() {
    return _pageRoute?.isCurrent ?? false;
  }

  @override
  void initState() {
    super.initState();
    if (lifecycle_enabled) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!lifecycle_enabled) return;

    if (!_isSubscribed) {
      final ModalRoute? modalRoute = ModalRoute.of(context);
      if (modalRoute is PageRoute) {
        _pageRoute = modalRoute;
        _routeVisible = modalRoute.isCurrent;
        routeObserver.subscribe(this, modalRoute);
        _isSubscribed = true;
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _pageRoute = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _appForeground = false;
      _syncLifecycle('app_paused');
    } else if (state == AppLifecycleState.resumed) {
      _appForeground = true;
      _syncLifecycle('app_resumed');
    }
  }

  @override
  void didPush() {
    _routeVisible = true;
    _syncLifecycle('route_didPush');
  }

  @override
  void didPop() {
    _routeVisible = false;
    _syncLifecycle('route_didPop');
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _syncLifecycle('route_didPopNext');
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _syncLifecycle('route_didPushNext');
  }

  void _syncLifecycle(String reason) {
    final shouldStart = _appForeground && _routeVisible;
    if (shouldStart) {
      if (!isResumed) {
        isResumed = true;
        _log('start(): $reason, ${_lifecycleSnapshot()}');
        start();
      } else {
        _log(
            'start(): blocked $reason (already started), ${_lifecycleSnapshot()}');
      }
      return;
    }

    if (isResumed) {
      isResumed = false;
      _log('stop(): $reason, ${_lifecycleSnapshot()}');
      stop();
    } else {
      _log(
          'stop(): blocked $reason (already stopped), ${_lifecycleSnapshot()}');
    }
  }

  @protected
  void stop() {}

  @protected
  void start() {}
}
