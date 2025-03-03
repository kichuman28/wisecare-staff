import 'package:flutter/material.dart';
import 'package:wisecare_staff/ui/screens/roles/responder/responder_dashboard_screen.dart';
import 'package:wisecare_staff/ui/screens/roles/delivery/delivery_dashboard_screen.dart';

class RoleBasedRouter {
  static Widget getHomeScreenForRole(String role) {
    switch (role.toLowerCase()) {
      case 'responders':
        return const ResponderDashboardScreen();
      case 'delivery':
        return const DeliveryDashboardScreen();
      default:
        // For future roles, add more cases here
        return const Center(
          child: Text('Role not implemented yet'),
        );
    }
  }
}
