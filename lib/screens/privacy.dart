import 'package:flutter/material.dart';

import '../ui/palette.dart';
import '../widgets/stitch.dart';

/// In-game privacy summary. Deliberately carries no publisher details: for
/// questions, players use the developer contact on the Google Play listing.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const sections = <(String, String)>[
    (
      'No data collected',
      'Thimble Trail does not collect, store, send or share any personal information. There is no account and nothing to sign in to.',
    ),
    (
      'Works offline',
      'The game never connects to the internet. There are no analytics, no tracking and no third-party services inside it.',
    ),
    (
      'What stays on your phone',
      'Your sewn blocks, stars, ribbons, hints, daily streak and Quiet Room choices are saved only on this device so you can pick up where you left off.',
    ),
    (
      'Clearing it',
      'Use Quiet Room › Unpick everything to clear your progress, or uninstall the game or clear its storage in your phone\'s settings. Nothing is kept anywhere else.',
    ),
    ('Permissions', 'The game asks for no permissions.'),
    (
      'Children',
      'The game is not directed at children under 13, and it collects no data from anyone.',
    ),
    (
      'Questions',
      'For questions or help, use the developer contact shown on this game\'s Google Play store listing.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Our promise'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Text('Privacy Policy', style: Txt.small),
                  const SizedBox(height: 6),
                  Text(
                    'We collect no data, and you never need an account.',
                    style: Txt.title.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 18),
                  for (final (t, b) in sections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t, style: Txt.label),
                          const SizedBox(height: 3),
                          Text(b, style: Txt.body),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
