import 'package:flutter/material.dart';

class CheckoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipping Information', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Address'),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'City'),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Zip Code'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement the logic to process the order
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order placed successfully!')),
                );
                Navigator.pop(context); // Go back to the cart page
              },
              child: Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}