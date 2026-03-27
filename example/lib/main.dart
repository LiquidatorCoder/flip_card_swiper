import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flip Card Swiper Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExamplesHome(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Home screen
// ─────────────────────────────────────────────────────────────

class ExamplesHome extends StatelessWidget {
  const ExamplesHome({super.key});

  static const _examples = [
    _ExampleEntry(
      title: 'Basic',
      subtitle: 'Default setup · simple coloured cards',
      icon: Icons.layers,
      color: Color(0xFF546E7A),
      page: BasicExample(),
    ),
    _ExampleEntry(
      title: 'Credit Cards',
      subtitle: 'Rounded corners · gradient · edge colour',
      icon: Icons.credit_card,
      color: Color(0xFF1A237E),
      page: CreditCardsExample(),
    ),
    _ExampleEntry(
      title: 'Flash Cards',
      subtitle: 'Fast flip · high perspective · quiz feel',
      icon: Icons.school,
      color: Color(0xFF1B5E20),
      page: FlashCardsExample(),
    ),
    _ExampleEntry(
      title: 'Travel Destinations',
      subtitle: 'Dramatic 3-D · thick edge · slow reveal',
      icon: Icons.flight_takeoff,
      color: Color(0xFF4A148C),
      page: TravelCardsExample(),
    ),
    _ExampleEntry(
      title: 'Profile Cards',
      subtitle: 'Social / dating style · avatar · tags',
      icon: Icons.person,
      color: Color(0xFF880E4F),
      page: ProfileCardsExample(),
    ),
    _ExampleEntry(
      title: 'Minimal News',
      subtitle: 'Flat design · snappy animation · no edge',
      icon: Icons.article,
      color: Color(0xFF212121),
      page: MinimalCardsExample(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Flip Card Swiper'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _examples.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final e = _examples[i];
          return _ExampleTile(entry: e);
        },
      ),
    );
  }
}

class _ExampleEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
  const _ExampleEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}

class _ExampleTile extends StatelessWidget {
  final _ExampleEntry entry;
  const _ExampleTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => entry.page),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: entry.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(entry.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(entry.subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// 0. Basic (original)
// ─────────────────────────────────────────────────────────────

class BasicExample extends StatelessWidget {
  const BasicExample({super.key});

  static final List<Map<String, dynamic>> _cards = [
    {'color': Colors.blue, 'text': 'Card 1'},
    {'color': Colors.red, 'text': 'Card 2'},
    {'color': Colors.green, 'text': 'Card 3'},
    {'color': Colors.purple, 'text': 'Card 4'},
    {'color': Colors.orange, 'text': 'Card 5'},
    {'color': Colors.teal, 'text': 'Card 6'},
    {'color': Colors.pink, 'text': 'Card 7'},
    {'color': Colors.amber, 'text': 'Card 8'},
    {'color': Colors.indigo, 'text': 'Card 9'},
    {'color': Colors.brown, 'text': 'Card 10'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Basic'),
        backgroundColor: const Color(0xFF546E7A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: FlipCardSwiper(
          cardData: _cards,
          animationDuration: const Duration(milliseconds: 600),
          downDragDuration: const Duration(milliseconds: 200),
          onCardChange: (index) {},
          cardEdgeColorBuilder: (index) =>
              darken(_cards[index]['color'] as Color, 0.1),
          cardBuilder: (context, index, visibleIndex) {
            if (index < 0 || index >= _cards.length) {
              return const SizedBox.shrink();
            }
            final card = _cards[index];
            return Container(
              key: ValueKey<int>(index),
              decoration: BoxDecoration(
                color: card['color'] as Color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 40,
                  )
                ],
              ),
              width: 300,
              height: 200,
              alignment: Alignment.center,
              child: Text(
                card['text'] as String,
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            );
          },
        ),
      ),
    );
  }
}

Color darken(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

// ─────────────────────────────────────────────────────────────
// 1. Credit Cards
// ─────────────────────────────────────────────────────────────

class CreditCardsExample extends StatelessWidget {
  const CreditCardsExample({super.key});

  static const _cards = [
    _CreditCard(
      name: 'Abhay Maurya',
      number: '4532 •••• •••• 7821',
      expiry: '08 / 27',
      gradient: [Color(0xFF1A237E), Color(0xFF283593)],
      network: 'VISA',
    ),
    _CreditCard(
      name: 'Abhay Maurya',
      number: '5412 •••• •••• 3340',
      expiry: '03 / 26',
      gradient: [Color(0xFF880E4F), Color(0xFFAD1457)],
      network: 'MC',
    ),
    _CreditCard(
      name: 'Abhay Maurya',
      number: '3782 •••••• 10005',
      expiry: '11 / 28',
      gradient: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
      network: 'AMEX',
    ),
    _CreditCard(
      name: 'Abhay Maurya',
      number: '6011 •••• •••• 1117',
      expiry: '06 / 25',
      gradient: [Color(0xFFE65100), Color(0xFFF57C00)],
      network: 'DISC',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Credit Cards'),
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: FlipCardSwiper(
          cardData: _cards,
          animationDuration: const Duration(milliseconds: 700),
          completionPhaseScale: 1.2,
          cardEdgeThickness: 0,
          cardBorderRadius: BorderRadius.circular(20),
          cardBuilder: (context, index, visibleIndex) {
            if (index < 0 || index >= _cards.length) {
              return const SizedBox.shrink();
            }
            final card = _cards[index];
            return Container(
              key: ValueKey(index),
              width: 320,
              height: 195,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: card.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: card.gradient.first.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('BANK',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w600)),
                      Text(card.network,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 2)),
                    ],
                  ),
                  const Spacer(),
                  // Chip
                  Container(
                    width: 36,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade300,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(card.number,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          letterSpacing: 2,
                          fontFamily: 'monospace')),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CARD HOLDER',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 9,
                                  letterSpacing: 1)),
                          Text(card.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('EXPIRES',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 9,
                                  letterSpacing: 1)),
                          Text(card.expiry,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CreditCard {
  final String name;
  final String number;
  final String expiry;
  final List<Color> gradient;
  final String network;
  const _CreditCard({
    required this.name,
    required this.number,
    required this.expiry,
    required this.gradient,
    required this.network,
  });
}

// ─────────────────────────────────────────────────────────────
// 2. Flash Cards
// ─────────────────────────────────────────────────────────────

class FlashCardsExample extends StatelessWidget {
  const FlashCardsExample({super.key});

  static const _cards = [
    _FlashCard(
      question: 'What is the time\ncomplexity of\nbinary search?',
      answer: 'O(log n)',
      category: 'Algorithms',
      color: Color(0xFF1B5E20),
    ),
    _FlashCard(
      question: 'What does\nDRY stand for?',
      answer: "Don't Repeat\nYourself",
      category: 'Principles',
      color: Color(0xFF0D47A1),
    ),
    _FlashCard(
      question: 'What is a\nclosure?',
      answer: 'A function that\ncaptures its\nsurrounding scope',
      category: 'Concepts',
      color: Color(0xFF4A148C),
    ),
    _FlashCard(
      question: 'Name the four\npillars of OOP',
      answer: 'Encapsulation\nAbstraction\nInheritance\nPolymorphism',
      category: 'OOP',
      color: Color(0xFF880E4F),
    ),
    _FlashCard(
      question: 'What is a\ndeadlock?',
      answer: 'Two or more threads\nwaiting on each\nother indefinitely',
      category: 'Concurrency',
      color: Color(0xFFBF360C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Flash Cards'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: FlipCardSwiper(
          cardData: _cards,
          animationDuration: const Duration(milliseconds: 450),
          downDragDuration: const Duration(milliseconds: 150),
          cardEdgeThickness: 0,
          cardEdgeColorBuilder: (i) => darken(_cards[i].color, 0.2),
          cardBuilder: (context, index, visibleIndex) {
            if (index < 0 || index >= _cards.length) {
              return const SizedBox.shrink();
            }
            final card = _cards[index];
            return Container(
              key: ValueKey(index),
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: card.color,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Text(card.category,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(card.question,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                                height: 1.5)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text('Swipe up to reveal →',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FlashCard {
  final String question;
  final String answer;
  final String category;
  final Color color;
  const _FlashCard({
    required this.question,
    required this.answer,
    required this.category,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────
// 3. Travel Destinations
// ─────────────────────────────────────────────────────────────

class TravelCardsExample extends StatelessWidget {
  const TravelCardsExample({super.key});

  static const _destinations = [
    _Destination(
      city: 'Kyoto',
      country: 'Japan',
      emoji: '⛩️',
      tagline: 'Ancient temples & bamboo forests',
      gradient: [Color(0xFFB71C1C), Color(0xFF880E4F)],
    ),
    _Destination(
      city: 'Santorini',
      country: 'Greece',
      emoji: '🏛️',
      tagline: 'White-washed villages & Aegean sunsets',
      gradient: [Color(0xFF0277BD), Color(0xFF01579B)],
    ),
    _Destination(
      city: 'Machu Picchu',
      country: 'Peru',
      emoji: '🏔️',
      tagline: 'Lost city of the Incas',
      gradient: [Color(0xFF33691E), Color(0xFF1B5E20)],
    ),
    _Destination(
      city: 'Marrakech',
      country: 'Morocco',
      emoji: '🕌',
      tagline: 'Vibrant souks & riads',
      gradient: [Color(0xFFE65100), Color(0xFFBF360C)],
    ),
    _Destination(
      city: 'Reykjavik',
      country: 'Iceland',
      emoji: '🌌',
      tagline: 'Northern lights & volcanic landscapes',
      gradient: [Color(0xFF1A237E), Color(0xFF4527A0)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Travel Destinations'),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: FlipCardSwiper(
          cardData: _destinations,
          animationDuration: const Duration(milliseconds: 900),
          completionPhaseScale: 1.35,
          downDragDuration: const Duration(milliseconds: 250),
          cardEdgeColorBuilder: (i) =>
              darken(_destinations[i].gradient.first, 0.25),
          cardBuilder: (context, index, visibleIndex) {
            if (index < 0 || index >= _destinations.length) {
              return const SizedBox.shrink();
            }
            final dest = _destinations[index];
            return Container(
              key: ValueKey(index),
              width: 320,
              height: 210,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dest.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: dest.gradient.first.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dest.emoji, style: const TextStyle(fontSize: 40)),
                  const Spacer(),
                  Text(dest.city,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.1)),
                  Text(dest.country,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(dest.tagline,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Destination {
  final String city;
  final String country;
  final String emoji;
  final String tagline;
  final List<Color> gradient;
  const _Destination({
    required this.city,
    required this.country,
    required this.emoji,
    required this.tagline,
    required this.gradient,
  });
}

// ─────────────────────────────────────────────────────────────
// 4. Profile Cards
// ─────────────────────────────────────────────────────────────

class ProfileCardsExample extends StatelessWidget {
  const ProfileCardsExample({super.key});

  static const _profiles = [
    _Profile(
      name: 'Alex Kim',
      role: 'Product Designer',
      initials: 'AK',
      tags: ['Figma', 'Motion', 'iOS'],
      avatarColor: Color(0xFF6200EA),
      bgColor: Color(0xFFF3E5F5),
    ),
    _Profile(
      name: 'Sara Chen',
      role: 'Backend Engineer',
      initials: 'SC',
      tags: ['Go', 'Postgres', 'k8s'],
      avatarColor: Color(0xFF00695C),
      bgColor: Color(0xFFE0F2F1),
    ),
    _Profile(
      name: 'Jordan Lee',
      role: 'ML Researcher',
      initials: 'JL',
      tags: ['PyTorch', 'LLMs', 'RLHF'],
      avatarColor: Color(0xFFBF360C),
      bgColor: Color(0xFFFBE9E7),
    ),
    _Profile(
      name: 'Maya Patel',
      role: 'iOS Developer',
      initials: 'MP',
      tags: ['Swift', 'SwiftUI', 'Flutter'],
      avatarColor: Color(0xFF0D47A1),
      bgColor: Color(0xFFE3F2FD),
    ),
    _Profile(
      name: 'Luca Rossi',
      role: 'DevOps Engineer',
      initials: 'LR',
      tags: ['AWS', 'Terraform', 'CI/CD'],
      avatarColor: Color(0xFF37474F),
      bgColor: Color(0xFFECEFF1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Profile Cards'),
        backgroundColor: const Color(0xFF880E4F),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: FlipCardSwiper(
          cardData: _profiles,
          animationDuration: const Duration(milliseconds: 600),
          cardEdgeThickness: 0,
          perspectiveDepth: 0.002,
          cardEdgeColorBuilder: (i) =>
              darken(_profiles[i].avatarColor, 0.1),
          cardBuilder: (context, index, visibleIndex) {
            if (index < 0 || index >= _profiles.length) {
              return const SizedBox.shrink();
            }
            final p = _profiles[index];
            return Container(
              key: ValueKey(index),
              width: 310,
              height: 195,
              decoration: BoxDecoration(
                color: p.bgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: p.avatarColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(p.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 3),
                        Text(p.role,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: p.tags
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: p.avatarColor
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(t,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: p.avatarColor,
                                            fontWeight: FontWeight.w700)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Profile {
  final String name;
  final String role;
  final String initials;
  final List<String> tags;
  final Color avatarColor;
  final Color bgColor;
  const _Profile({
    required this.name,
    required this.role,
    required this.initials,
    required this.tags,
    required this.avatarColor,
    required this.bgColor,
  });
}

// ─────────────────────────────────────────────────────────────
// 5. Minimal News
// ─────────────────────────────────────────────────────────────

class MinimalCardsExample extends StatelessWidget {
  const MinimalCardsExample({super.key});

  static const _articles = [
    _Article(
      tag: 'TECHNOLOGY',
      headline: 'Flutter 4.0 ships\nImpeller on all platforms',
      source: 'Flutter Blog',
      time: '2 min read',
      tagColor: Color(0xFF1565C0),
    ),
    _Article(
      tag: 'SCIENCE',
      headline: "Webb telescope spots\nwater on exoplanet's surface",
      source: 'Nature',
      time: '4 min read',
      tagColor: Color(0xFF2E7D32),
    ),
    _Article(
      tag: 'DESIGN',
      headline: 'Why spatial computing\nchanges everything',
      source: 'UX Collective',
      time: '3 min read',
      tagColor: Color(0xFF6A1B9A),
    ),
    _Article(
      tag: 'BUSINESS',
      headline: 'Open source models\novertake proprietary rivals',
      source: 'The Information',
      time: '5 min read',
      tagColor: Color(0xFFBF360C),
    ),
    _Article(
      tag: 'HEALTH',
      headline: 'Sleep and productivity:\nwhat new data shows',
      source: 'Harvard Health',
      time: '3 min read',
      tagColor: Color(0xFF00695C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('Minimal News'),
        backgroundColor: const Color(0xFF212121),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: FlipCardSwiper(
          cardData: _articles,
          animationDuration: const Duration(milliseconds: 400),
          downDragDuration: const Duration(milliseconds: 120),
          completionPhaseScale: 0.9,
          perspectiveDepth: 0.001,
          cardEdgeThickness: 0,
          cardBorderRadius: BorderRadius.circular(12),
          cardBuilder: (context, index, visibleIndex) {
            if (index < 0 || index >= _articles.length) {
              return const SizedBox.shrink();
            }
            final a = _articles[index];
            return Container(
              key: ValueKey(index),
              width: 320,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: a.tagColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(a.tag,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 12),
                  Text(a.headline,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: Color(0xFF111111))),
                  const Spacer(),
                  Row(
                    children: [
                      Text(a.source,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(a.time,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Article {
  final String tag;
  final String headline;
  final String source;
  final String time;
  final Color tagColor;
  const _Article({
    required this.tag,
    required this.headline,
    required this.source,
    required this.time,
    required this.tagColor,
  });
}
