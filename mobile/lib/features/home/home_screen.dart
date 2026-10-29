import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/phone_viewport.dart';
import '../../core/backend.dart';
import '../evacuation/evacuation_screen.dart';
import '../alerts/alerts_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final user = ref.watch(userProvider);
    final profile = ref.watch(profileProvider).asData?.value;
    final displayName =
        profile?['full_name'] as String? ??
        user?.userMetadata?['full_name'] as String? ??
        'Guest';
    final address = (profile?['preferred_area'] as String?)?.trim();
    final displayAddress = address != null && address.isNotEmpty
        ? address
        : 'No address saved';
    const cardTopOffset = 146.0;
    final headerHeight = topInset + cardTopOffset + 80;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF6),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: headerHeight,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(38),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/green-riverside-town-header.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) => const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: loginHeaderGradient,
                              ),
                            ),
                          ),
                          // Soft gradient overlay to ensure top brand readability
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0x99003822),
                                  Color(0x33003822),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            top: topInset + 72,
                            left: 16,
                            right: 16,
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Color(0xFFEAF5EE),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: Color(0xFF005C38),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            color: Colors.white,
                                            size: 15,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              displayAddress,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Branded Header Top Bar
                          Positioned(
                            top: topInset + 6,
                            left: 16,
                            right: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Logo + Two-tone BAHAlerto (matching login page)
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Image.asset(
                                              'assets/mobile-logo.png',
                                              width: 30,
                                              height: 30,
                                              fit: BoxFit.contain,
                                              excludeFromSemantics: true,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text.rich(
                                            TextSpan(
                                              style: TextStyle(
                                                fontSize: 22,
                                                letterSpacing: -0.6,
                                                fontWeight: FontWeight.w900,
                                                shadows: [
                                                  Shadow(
                                                    color: Color(0x88000000),
                                                    offset: Offset(0, 1.5),
                                                    blurRadius: 3,
                                                  ),
                                                ],
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'BAHA',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'lerto',
                                                  style: TextStyle(
                                                    color: Color(0xFFF05A28),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Circular Notification Bell Button
                                GestureDetector(
                                  onTap: () => openInfo(
                                    context,
                                    'Flood Advisories',
                                    const AlertsScreen(),
                                  ),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(
                                          Icons.notifications_active_rounded,
                                          color: Color(0xFF005C38),
                                          size: 25,
                                        ),
                                        Positioned(
                                          top: 7,
                                          right: 8,
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF3B30),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: topInset + cardTopOffset),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Top Location & Map Card (Overlapping the bottom curve of the green header)
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Left Details Column
                                  Expanded(
                                    flex: 13,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Location header
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.location_on_rounded,
                                              color: Color(0xFF2E7D32),
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Your Location',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Color(0xFF2E7D32),
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        const Text(
                                          '12 Ibayo, Manzano',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1B3322),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        const Text(
                                          'Marilao, Bulacan',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B8272),
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Moderate Flooding Status Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE3F2FD),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF42A5F5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.waves_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 7),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: const [
                                                    Text(
                                                      'Moderate Flooding',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Color(
                                                          0xFF1565C0,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'Last update: Oct 29, 2026 09:30 AM',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 8.5,
                                                        color: Color(
                                                          0xFF64748B,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'Source: LGU Marilao',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 8.5,
                                                        color: Color(
                                                          0xFF64748B,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // View on Map Button
                                        GestureDetector(
                                          key: const ValueKey(
                                            'home-view-map-button',
                                          ),
                                          onTap: () =>
                                              widget.onNavigate?.call(1),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 7.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0F7533),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(
                                                    Icons.explore_rounded,
                                                    color: Colors.white,
                                                    size: 15,
                                                  ),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    'View on Map',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  SizedBox(width: 3),
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Right Map Preview Box
                                  Expanded(
                                    flex: 11,
                                    child: GestureDetector(
                                      onTap: () => widget.onNavigate?.call(1),
                                      child: SizedBox.expand(
                                        key: const ValueKey(
                                          'home-location-map',
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE2EBE5),
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.asset(
                                                  'assets/home-map-preview.png',
                                                  fit: BoxFit.cover,
                                                  excludeFromSemantics: true,
                                                  errorBuilder: (_, _, _) =>
                                                      Container(
                                                        color: const Color(
                                                          0xFFE8F5E9,
                                                        ),
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons
                                                                .explore_rounded,
                                                            color: Color(
                                                              0xFF2E7D32,
                                                            ),
                                                            size: 32,
                                                          ),
                                                        ),
                                                      ),
                                                ),
                                                Positioned(
                                                  top: 6,
                                                  right: 6,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.90,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Color(
                                                            0x1A000000,
                                                          ),
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.fullscreen_rounded,
                                                      size: 17,
                                                      color: Color(0xFF2E7D32),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 3. Quick Actions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Quick Actions',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B3322),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onNavigate?.call(2),
                      child: const Text(
                        'See All >',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Quick Action Tiles (Check Flood, Report Flood, Share Location, Emergency SOS)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.map_rounded,
                        iconColor: const Color(0xFF2E7D32),
                        bgColor: const Color(0xFFE8F5E9),
                        label: 'Check\nFlood',
                        onTap: () => widget.onNavigate?.call(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.camera_alt_rounded,
                        iconColor: const Color(0xFF0288D1),
                        bgColor: const Color(0xFFE1F5FE),
                        label: 'Report\nFlood',
                        onTap: () => widget.onNavigate?.call(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.navigation_rounded,
                        iconColor: const Color(0xFFEF6C00),
                        bgColor: const Color(0xFFFFF3E0),
                        label: 'Share\nLocation',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Location coordinates shared: Marilao, Bulacan',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.emergency_rounded,
                        iconColor: const Color(0xFFD32F2F),
                        bgColor: const Color(0xFFFFEBEE),
                        label: 'Emergency\nSOS',
                        onTap: () => openInfo(
                          context,
                          'Emergency Contacts',
                          const EvacuationScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. Nearby Flood Reports Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Nearby Flood Reports',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B3322),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onNavigate?.call(2),
                      child: const Text(
                        'View More >',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FloodReportCard(
                        imagePath: 'assets/flood-report-1.png',
                        status: 'Verified',
                        statusColor: const Color(0xFF1976D2),
                        statusBgColor: const Color(0xFFE3F2FD),
                        road: 'Tambubong Road',
                        area: 'Marilao, Bulacan',
                        depth: 'Knee level',
                        time: '2 hours ago',
                        onTap: () => widget.onNavigate?.call(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FloodReportCard(
                        imagePath: 'assets/flood-report-2.png',
                        status: 'Pending',
                        statusColor: const Color(0xFFF57C00),
                        statusBgColor: const Color(0xFFFFF3E0),
                        road: 'Loma de Gato',
                        area: 'Marilao, Bulacan',
                        depth: 'Ankle level',
                        time: '5 hours ago',
                        onTap: () => widget.onNavigate?.call(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 2. Vehicle Passability Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: const [
                          Icon(
                            Icons.directions_car_rounded,
                            color: Color(0xFF2E7D32),
                            size: 19,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Vehicle Passability',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B3322),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onNavigate?.call(2),
                      child: const Text(
                        'See Details >',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Vehicle Passability Cards (Motorcycle, Sedan, SUV, Truck)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _VehicleCard(
                        icon: Icons.two_wheeler_rounded,
                        name: 'Motorcycle',
                        status: 'Can pass',
                        statusColor: const Color(0xFF2E7D32),
                        badgeIcon: Icons.check_circle_rounded,
                        badgeColor: const Color(0xFF2E7D32),
                        subtitle: 'Up to knee level',
                        onTap: () => widget.onNavigate?.call(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _VehicleCard(
                        icon: Icons.directions_car_filled_rounded,
                        name: 'Sedan',
                        status: 'Use caution',
                        statusColor: const Color(0xFFF57C00),
                        badgeIcon: Icons.warning_rounded,
                        badgeColor: const Color(0xFFF57C00),
                        subtitle: 'Up to knee level',
                        onTap: () => widget.onNavigate?.call(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _VehicleCard(
                        icon: Icons.airport_shuttle_rounded,
                        name: 'SUV',
                        status: 'Not advised',
                        statusColor: const Color(0xFFD32F2F),
                        badgeIcon: Icons.cancel_rounded,
                        badgeColor: const Color(0xFFD32F2F),
                        subtitle: 'Risk at knee level',
                        onTap: () => widget.onNavigate?.call(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _VehicleCard(
                        icon: Icons.local_shipping_rounded,
                        name: 'Truck',
                        status: 'Not advised',
                        statusColor: const Color(0xFFD32F2F),
                        badgeIcon: Icons.cancel_rounded,
                        badgeColor: const Color(0xFFD32F2F),
                        subtitle: 'High risk',
                        onTap: () => widget.onNavigate?.call(2),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Active Alerts & Advisories Section (Premium, human-crafted emergency design)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Active Alerts & Advisories',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B3322),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => openInfo(
                        context,
                        'Flood Advisories',
                        const AlertsScreen(),
                      ),
                      child: const Text(
                        'View All >',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // High-Impact Official Weather & Flood Advisory Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => openInfo(
                    context,
                    'Flood Advisories',
                    const AlertsScreen(),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF6F4), Color(0xFFFEEDE9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD1C7),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10D32F2F),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Advisory badges wrap on narrow screens.
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFCDD2),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD32F2F),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'ACTIVE FLOOD ADVISORY',
                                      style: TextStyle(
                                        color: Color(0xFFC62828),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'HIGH RISK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Middle Content Row with Glowing Hazard Icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5252),
                                    Color(0xFFD32F2F),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33D32F2F),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Moderate to Heavy Rainfall',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1B3322),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 13,
                                        color: Color(0xFFD32F2F),
                                      ),
                                      SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          'Marilao, Bulacan & nearby areas',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4A6052),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Issued by PAGASA • Oct 29, 2026 9:30 AM',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF7E9486),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF88A090),
                              size: 22,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Bottom Warning Guidance Action Bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECE8),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: Color(0xFFD32F2F),
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Expect street flooding in low-lying roads. Stay safe.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8A2424),
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: Color(0xFFD32F2F),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Published data disclosure footer
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Center(
                  child: Text(
                    'Published data - Missing information does not mean safe passage.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF88A090),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Component: Vehicle Passability Card
// -------------------------------------------------------------
class _VehicleCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String status;
  final Color statusColor;
  final IconData badgeIcon;
  final Color badgeColor;
  final String subtitle;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.icon,
    required this.name,
    required this.status,
    required this.statusColor,
    required this.badgeIcon,
    required this.badgeColor,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9F0E7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 26, color: const Color(0xFF37474F)),
                Positioned(
                  top: -2,
                  right: -6,
                  child: Icon(badgeIcon, color: badgeColor, size: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B3322),
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 9, color: Color(0xFF789080)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Component: Quick Action Tile
// -------------------------------------------------------------
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B3322),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Component: Nearby Flood Report Card
// -------------------------------------------------------------
class _FloodReportCard extends StatelessWidget {
  final String imagePath;
  final String status;
  final Color statusColor;
  final Color statusBgColor;
  final String road;
  final String area;
  final String depth;
  final String time;
  final VoidCallback onTap;

  const _FloodReportCard({
    required this.imagePath,
    required this.status,
    required this.statusColor,
    required this.statusBgColor,
    required this.road,
    required this.area,
    required this.depth,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Semantics(
      label: "$road, $status, $depth, $time",
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0EAE2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 2.2,
              // These supplied 90px thumbnails include UI below the photo.
              // Display only the photo region, without altering the source files.
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: 86,
                    height: 34,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minWidth: 90,
                        maxWidth: 90,
                        minHeight: 90,
                        maxHeight: 90,
                        child: Image.asset(
                          imagePath,
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFE8F5E9),
                            child: Center(
                              child: Icon(
                                Icons.water_rounded,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    road,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B3322),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    area,
                    style: const TextStyle(
                      color: Color(0xFF6B8272),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      Text(
                        depth,
                        style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void openInfo(BuildContext context, String title, Widget body) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: body,
      ),
    ),
  );
}
