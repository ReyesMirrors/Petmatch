import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 👇 IMPORT CLAVE (AJUSTA SI TU RUTA ES DIFERENTE)
import '../router/app_router.dart';

class NotificationService {
  final FirebaseMessaging _fcm;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._fcm, this._db, this._auth);

  Future<void> initialize() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);
    _fcm.onTokenRefresh.listen(_saveTokenForCurrentUser);

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedApp(initialMessage);
    }

    await _saveTokenForCurrentUser();
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'petmatch_channel',
          'PetMatch',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _handleOpenedApp(RemoteMessage message) async {
    final data = message.data;

    final type = data['type'] as String?;
    final petId = data['petId'] as String?;
    final chatId = data['chatId'] as String?;
    final senderId = data['senderId'] as String?;

    if (type == 'chat_message' && chatId != null && senderId != null) {
      AppRouter.router.push('/chat/$chatId/$senderId');

    } else if (type == 'adoption_request' || type == 'adoption_response') {
      AppRouter.router.push(AppRouter.requests);

    } else if ((type == 'donation_confirmed' || type == 'donation_rejected') &&
        petId != null &&
        petId.isNotEmpty) {
      AppRouter.router.push('/pet/$petId');

    } else if (petId != null && petId.isNotEmpty) {
      AppRouter.router.push('/pet/$petId');

    } else {
      AppRouter.router.push(AppRouter.notifications);
    }

    await _handleMessage(message);
  }

  Future<void> _saveTokenForCurrentUser([String? token]) async {
    final deviceToken = token ?? await getToken();
    if (deviceToken == null) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).set(
      {'fcmToken': deviceToken},
      SetOptions(merge: true),
    );
  }

  Future<void> saveTokenForCurrentUser() => _saveTokenForCurrentUser();

  Future<String?> getToken() => _fcm.getToken();

  Future<void> sendPushToTopic(String topic, String title, String body) async {
    // Se maneja desde backend (Firebase Functions)
  }
}