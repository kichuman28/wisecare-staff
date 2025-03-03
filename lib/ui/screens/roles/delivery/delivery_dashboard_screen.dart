import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:wisecare_staff/core/models/order_model.dart';
import 'package:wisecare_staff/core/theme/app_theme.dart';
import 'package:wisecare_staff/provider/order_provider.dart';
import 'package:wisecare_staff/ui/screens/roles/delivery/order_detail_screen.dart';
import 'package:wisecare_staff/ui/widgets/custom_card.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize order provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Delivery Dashboard',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${orderProvider.errorMessage}',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      orderProvider.clearError();
                      orderProvider.init();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Section
                _buildOrderSummary(orderProvider),
                const SizedBox(height: 24),

                // Today's Deliveries Section
                Text(
                  'Today\'s Deliveries',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildTodayDeliveries(orderProvider),
                const SizedBox(height: 24),

                // Order Management Tabs
                _buildOrderTabs(orderProvider),
                const SizedBox(height: 24),

                // Performance Section
                if (orderProvider.performanceMetrics != null)
                  _buildPerformanceSection(orderProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(OrderProvider orderProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Pending',
            value: orderProvider.processingCount.toString(),
            icon: Icons.pending_outlined,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Out for Delivery',
            value: orderProvider.dispatchedCount.toString(),
            icon: Icons.local_shipping_outlined,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayDeliveries(OrderProvider orderProvider) {
    final todayOrders = orderProvider.todayOrders;

    if (todayOrders.isEmpty) {
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No deliveries scheduled for today',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: todayOrders.length,
        itemBuilder: (context, index) {
          final order = todayOrders[index];
          return Container(
            width: 280,
            margin: EdgeInsets.only(
              right: index < todayOrders.length - 1 ? 16 : 0,
            ),
            child: CustomCard(
              child: InkWell(
                onTap: () => _navigateToOrderDetails(order),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${order.id.substring(0, 8)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.text,
                                ),
                          ),
                          const Spacer(),
                          _buildStatusBadge(context, order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.patientName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.deliveryAddress,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.tertiary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.medication_outlined,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${order.medicines.length} medications',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderTabs(OrderProvider orderProvider) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Assigned',
            ),
            Tab(
              icon: Icon(Icons.local_shipping),
              text: 'In Progress',
            ),
            Tab(
              icon: Icon(Icons.task_alt),
              text: 'Completed',
            ),
            Tab(
              icon: Icon(Icons.list_alt),
              text: 'All',
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Assigned Tab
              _buildOrdersList(orderProvider.processingOrders),

              // In Progress Tab
              _buildOrdersList(orderProvider.dispatchedOrders),

              // Completed Tab
              _buildOrdersList(orderProvider.deliveredOrders),

              // All Tab
              _buildOrdersList(orderProvider.allOrders),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < orders.length - 1 ? 16 : 0),
          child: CustomCard(
            child: InkWell(
              onTap: () => _navigateToOrderDetails(order),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${order.id.substring(0, 8)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.text,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat.yMMMd().format(order.orderDate),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        _buildStatusBadge(context, order.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: order.patientPhotoUrl != null
                              ? NetworkImage(order.patientPhotoUrl!)
                              : null,
                          child: order.patientPhotoUrl == null
                              ? Text(
                                  order.patientName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.patientName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                order.deliveryAddress,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.medication_outlined,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${order.medicines.length} medications',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildOrderActionButton(order),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderActionButton(Order order) {
    switch (order.status) {
      case 'processing':
        return ElevatedButton.icon(
          icon: const Icon(Icons.local_shipping, size: 16),
          label: const Text('START DELIVERY'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _navigateToOrderDetails(order),
        );
      case 'dispatched':
        return ElevatedButton.icon(
          icon: const Icon(Icons.check_circle, size: 16),
          label: const Text('MARK AS DELIVERED'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _navigateToOrderDetails(order),
        );
      default:
        return OutlinedButton.icon(
          icon: const Icon(Icons.info_outline, size: 16),
          label: const Text('VIEW DETAILS'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _navigateToOrderDetails(order),
        );
    }
  }

  Widget _buildPerformanceSection(OrderProvider orderProvider) {
    final metrics = orderProvider.performanceMetrics!;
    final deliveryRate = (metrics['deliveryRate'] as double) * 100;
    final avgDeliveryTime = metrics['avgDeliveryTime'] as double;
    final totalDelivered = metrics['totalDelivered'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPerformanceCard(
                context,
                title: 'Delivery Rate',
                value: '${deliveryRate.toStringAsFixed(1)}%',
                icon: Icons.speed,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPerformanceCard(
                context,
                title: 'Avg. Delivery Time',
                value: _formatDeliveryTime(avgDeliveryTime),
                icon: Icons.timer,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPerformanceCard(
          context,
          title: 'Total Deliveries (30 days)',
          value: totalDelivered.toString(),
          icon: Icons.local_shipping,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
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

  Widget _buildPerformanceCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String label;

    switch (status) {
      case 'processing':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'dispatched':
        color = Colors.blue;
        label = 'In Transit';
        break;
      case 'delivered':
        color = Colors.green;
        label = 'Delivered';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _formatDeliveryTime(double minutes) {
    if (minutes < 60) {
      return '${minutes.round()} mins';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = (minutes % 60).round();
      return '$hours h ${remainingMinutes > 0 ? '$remainingMinutes m' : ''}';
    }
  }

  void _navigateToOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order),
      ),
    );
  }
}
