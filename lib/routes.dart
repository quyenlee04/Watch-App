import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:watch_store/presentation/pages/cart_page.dart';
import 'package:watch_store/presentation/pages/checkout_page.dart';
import 'package:watch_store/presentation/pages/login_page.dart';
import 'package:watch_store/presentation/pages/product_list_page.dart';
import 'package:watch_store/presentation/pages/profile_page.dart';
import 'package:watch_store/presentation/pages/registration_page.dart';
import 'package:watch_store/presentation/pages/order_history_page.dart';

import 'presentation/pages/product_detail_page.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => RegistrationPage());
      case '/products':
        return MaterialPageRoute(builder: (_) => ProductListPage());
      case '/cart':
        return MaterialPageRoute(builder: (_) => CartPage());
      case '/checkout':
        return MaterialPageRoute(builder: (_) => CheckoutPage());
      case '/profile':
        return MaterialPageRoute(builder: (_) => ProfilePage());
      case '/orders':
        return MaterialPageRoute(builder: (_) => OrderHistoryPage());
      default:
        return MaterialPageRoute(builder: (_) => LoginPage());
    }
  }
}
