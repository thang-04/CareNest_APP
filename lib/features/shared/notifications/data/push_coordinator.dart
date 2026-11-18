import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';

abstract interface class PushProvider {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<String?> token();
  Future<int?> initialNotification();
  Stream<String> get tokenChanges;
  Stream<int> get opened;
  Stream<int> get foreground;
}

class FirebasePushProvider implements PushProvider {
  int? _id(RemoteMessage message) =>
      int.tryParse(message.data['notificationId']?.toString() ?? '');
  Stream<int> _ids(Stream<RemoteMessage> messages) =>
      messages.map(_id).where((id) => id != null && id > 0).cast<int>();
  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  @override
  Future<bool> requestPermission() async =>
      (await FirebaseMessaging.instance.requestPermission())
          .authorizationStatus !=
      AuthorizationStatus.denied;
  @override
  Future<String?> token() => FirebaseMessaging.instance.getToken();
  @override
  Future<int?> initialNotification() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message == null ? null : _id(message);
  }

  @override
  Stream<String> get tokenChanges => FirebaseMessaging.instance.onTokenRefresh;
  @override
  Stream<int> get opened => _ids(FirebaseMessaging.onMessageOpenedApp);
  @override
  Stream<int> get foreground => _ids(FirebaseMessaging.onMessage);
}

class PushCoordinator {
  PushCoordinator(
    this.session,
    this.api,
    this.onOpen, {
    this.onForeground,
    FlutterSecureStorage? storage,
    PushProvider? provider,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _provider = provider ?? FirebasePushProvider();
  final MobileSession session;
  final MobileApi api;
  final void Function(int notificationId) onOpen;
  final void Function(int notificationId)? onForeground;
  final FlutterSecureStorage _storage;
  final PushProvider _provider;
  bool _ready = false;
  StreamSubscription<String>? _tokens;
  StreamSubscription<int>? _opens;
  StreamSubscription<int>? _foreground;
  String? _registeredToken;
  int? _owner;
  int? _ownerGeneration;
  int? _pendingId;
  final Set<String> _processing = {};
  Future<void> _operations = Future.value();

  Future<bool> initialize() async {
    try {
      await _provider.initialize();
      _ready = true;
      _opens = _provider.opened.listen(open);
      _foreground = _provider.foreground.listen((id) {
        if (session.signedIn) {
          unawaited(_showForeground(id));
        }
      });
      final initial = await _provider.initialNotification();
      if (initial != null && initial > 0) open(initial);
      return true;
    } catch (_) {
      return false;
    }
  }

  void open(int id) {
    if (id <= 0) return;
    _pendingId = id;
    unawaited(_openPending());
  }

  Future<void> receiveForeground(int id) => _showForeground(id);

  Future<void> _showForeground(int id) async {
    final owner = session.userId;
    if (owner == null) return;
    final key = 'push.display.$owner.$id';
    if (!_processing.add(key)) return;
    try {
      if (await _storage.read(key: key) == '1' || session.userId != owner) {
        return;
      }
      await _storage.write(key: key, value: '1');
      if (session.userId == owner) onForeground?.call(id);
    } finally {
      _processing.remove(key);
    }
  }

  Future<void> _openPending() async {
    final id = _pendingId;
    final owner = session.userId;
    if (id == null || owner == null) return;
    final key = 'push.open.$owner.$id';
    if (!_processing.add(key)) return;
    try {
      if (await _storage.read(key: key) == '1') {
        _pendingId = null;
        return;
      }
      if (session.userId != owner || _pendingId != id) return;
      await _storage.write(key: key, value: '1');
      if (session.userId != owner || _pendingId != id) return;
      _pendingId = null;
      onOpen(id);
    } finally {
      _processing.remove(key);
    }
  }

  Future<void> startSession() async {
    final owner = session.userId;
    if (!_ready || owner == null) {
      await _openPending();
      return;
    }
    await _tokens?.cancel();
    _owner = owner;
    _ownerGeneration = session.generation;
    try {
      final permission = await _provider.requestPermission();
      final token = await _provider.token();
      if (!permission) {
        _registeredToken = token;
      } else {
        _tokens = _provider.tokenChanges.listen(
          (value) =>
              unawaited(_enqueueRegister(owner, value).catchError((_) {})),
        );
        if (token != null) await _enqueueRegister(owner, token);
      }
    } finally {
      await _openPending();
    }
  }

  Future<void> _enqueueRegister(int owner, String token) {
    _operations = _operations.catchError((_) {}).then((_) async {
      if (_owner != owner ||
          session.userId != owner ||
          session.generation != _ownerGeneration) {
        return;
      }
      final previous = _registeredToken;
      if (previous != null && previous != token) {
        try {
          await api.unregisterDevice(previous);
        } catch (_) {
          /* Token cũ sẽ hết hiệu lực ở FCM. */
        }
      }
      _registeredToken = token;
      await api.registerDevice(token);
    });
    return _operations;
  }

  Future<bool> stopSession() async {
    await _tokens?.cancel();
    _tokens = null;
    await _operations.catchError((_) {});
    final token = _registeredToken;
    var removed = true;
    if (token != null &&
        _owner == session.userId &&
        _ownerGeneration == session.generation) {
      try {
        await api.unregisterDevice(token);
      } catch (_) {
        removed = false;
      }
    }
    _owner = null;
    _ownerGeneration = null;
    _registeredToken = null;
    return removed;
  }

  Future<void> dispose() async {
    await _tokens?.cancel();
    await _opens?.cancel();
    await _foreground?.cancel();
  }
}
