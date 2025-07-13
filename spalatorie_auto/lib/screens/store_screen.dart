import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

class StoreTab extends StatelessWidget {
  const StoreTab({super.key});

  final List<Map<String, dynamic>> packages = const [
    {'title': '1 Jeton', 'price': '4 RON', 'tokens': 1, 'icon': Icons.radio_button_checked, 'amountRon': 4},
    {'title': '3 Jetoane', 'price': '10 RON', 'tokens': 3, 'icon': Icons.radio_button_checked, 'amountRon': 10},
    {'title': '7 Jetoane', 'price': '20 RON', 'tokens': 7, 'icon': Icons.radio_button_checked, 'amountRon': 20},
    {'title': '10 Jetoane', 'price': '27 RON', 'tokens': 10, 'icon': Icons.radio_button_checked, 'amountRon': 27},

  ];

  Future<void> startPayment(BuildContext context, int amountRon, int tokens) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.6:5000/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amountRon': amountRon,
          'tokens': tokens,
          'uid': FirebaseAuth.instance.currentUser?.uid,
        }),
      );

      final jsonResponse = jsonDecode(response.body);

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: jsonResponse['clientSecret'],
          merchantDisplayName: 'JetWash',
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plata efectuată cu succes!')),
      );
    } on stripe.StripeException catch (e) {
      if (e.error.code == 'Canceled') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plata a fost anulată.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare Stripe: ${e.error.localizedMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare generală: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      appBar: AppBar(
        title: const Text('Magazin Jetoane'),
        backgroundColor: Colors.blueAccent,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final item = packages[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(item['icon'], color: Colors.blue.shade700),
                ),
                title: Text(
                  item['title'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${item['price']} • ${item['tokens']} jetoane',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: ElevatedButton(
                  onPressed: () => startPayment(context, item['amountRon'], item['tokens']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: const Text('Cumpără'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}