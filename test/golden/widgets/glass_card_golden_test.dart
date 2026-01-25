import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:silni_app/shared/widgets/glass_card.dart';
import '../golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await goldenTestSetUp();
  });

  group('GlassCard Golden Tests', () {
    testGoldens('GlassCard - default appearance', (tester) async {
      final widget = SizedBox(
        width: 300,
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Test Content',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );

      await multiDeviceGoldenTest(
        tester,
        widget,
        'glass_card_default',
      );
    });

    testGoldens('GlassCard - with custom padding', (tester) async {
      final widget = SizedBox(
        width: 300,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Custom Padding',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

      await multiDeviceGoldenTest(
        tester,
        widget,
        'glass_card_custom_padding',
      );
    });

    testGoldens('GlassCard - with explicit dimensions', (tester) async {
      final widget = GlassCard(
        width: 200,
        height: 150,
        child: Center(
          child: Text(
            'Fixed Size',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

      await multiDeviceGoldenTest(
        tester,
        widget,
        'glass_card_fixed_size',
      );
    });

    testGoldens('GlassCard - with custom border radius', (tester) async {
      final widget = SizedBox(
        width: 300,
        child: GlassCard(
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Rounded Corners',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );

      await multiDeviceGoldenTest(
        tester,
        widget,
        'glass_card_rounded',
      );
    });

    testGoldens('GlassCard - with tap handler (interactive)', (tester) async {
      final widget = SizedBox(
        width: 300,
        child: GlassCard(
          onTap: () {},
          semanticsLabel: 'Interactive Card',
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Tap Me',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );

      await multiDeviceGoldenTest(
        tester,
        widget,
        'glass_card_interactive',
      );
    });

    testGoldens('GlassCard - with complex content', (tester) async {
      final widget = SizedBox(
        width: 350,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Card Title',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Subtitle text',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'This is a more complex card with multiple elements to test layout.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      await multiDeviceGoldenTest(
        tester,
        widget,
        'glass_card_complex_content',
      );
    });
  });

  group('DramaticGlassCard Golden Tests', () {
    testGoldens('DramaticGlassCard - default appearance', (tester) async {
      final widget = SizedBox(
        width: 300,
        child: DramaticGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Dramatic Glass',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

      await multiDeviceGoldenTest(
        tester,
        widget,
        'dramatic_glass_card_default',
      );
    });

    testGoldens('DramaticGlassCard - with explicit dimensions', (tester) async {
      final widget = DramaticGlassCard(
        width: 280,
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 48),
              SizedBox(height: 12),
              Text(
                'Featured',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

      await multiDeviceGoldenTest(
        tester,
        widget,
        'dramatic_glass_card_featured',
      );
    });
  });
}
