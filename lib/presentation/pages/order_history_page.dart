import 'package:flutter/material.dart';
import 'package:watch_store/presentation/widgets/bottom_nav_bar.dart';

class OrderHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order History')),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: 0, // Replace with actual order count
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #12345',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Processing',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                  Divider(),
                  Text('Date: 2023-12-01'),
                  Text('Total: \$299.99'),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/products');
          if (index == 2) Navigator.pushReplacementNamed(context, '/profile');
        },
      ),
    );
  }
}
