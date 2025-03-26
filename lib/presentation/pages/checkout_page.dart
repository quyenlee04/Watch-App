import 'package:flutter/material.dart';
import 'package:watch_store/data/services/api_service.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Structure the orderData to match what the API service expects
      final orderData = {
        'shipping_address': {
          'recipient_name': _nameController.text,
          'street_address': _addressController.text,
          'city': _cityController.text,
          'postal_code': _zipController.text,
          'country': 'US',
        },
        // No need to add items or total_amount here - the API service will handle that
      };

      final response = await _apiService.createOrder(orderData);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(Duration(seconds: 1));
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacementNamed(context, '/orders');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to place order'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/cart');
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error during checkout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text('Shipping Information',
                style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Full Name'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter your name' : null,
            ),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Address'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter your address' : null,
            ),
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(labelText: 'City'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter your city' : null,
            ),
            TextFormField(
              controller: _zipController,
              decoration: InputDecoration(labelText: 'ZIP Code'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter ZIP code' : null,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processOrder,
              child: _isProcessing
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Place Order'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}