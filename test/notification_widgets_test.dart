import 'package:eduvara/components/notifications/notification_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('notification header places back and mark-all action together', (
    tester,
  ) async {
    var markedAllRead = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationHeader(
            busy: false,
            onMarkAllRead: () => markedAllRead = true,
          ),
        ),
      ),
    );

    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Tandai semua dibaca'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    await tester.tap(find.text('Tandai semua dibaca'));
    expect(markedAllRead, isTrue);
  });

  testWidgets('notification feed groups and displays unread notifications', (
    tester,
  ) async {
    final today = DateTime.now().toIso8601String();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationFeed(
            rows: [
              {
                'title': 'Quiz Baru',
                'message': 'Quiz matematika tersedia.',
                'created_at': today,
                'is_read': false,
              },
            ],
            onTapNotification: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Quiz Baru'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });
}
