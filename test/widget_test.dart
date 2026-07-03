import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader_app/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const VideoDownloaderApp());
    expect(find.text('Video Downloader'), findsOneWidget);
  });
}
