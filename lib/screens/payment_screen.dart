/*import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:pfe/service/project_service.dart';

class PaymentScreen extends StatefulWidget {
  final String projectId;
  final int amount;

  const PaymentScreen({
    super.key,
    required this.projectId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool loading = false;

  Future<void> makePayment() async {
    setState(() => loading = true);

    try {
      await Stripe.instance.resetPaymentSheetCustomer();
      // 1️⃣ نطلب clientSecret من backend
      final data = await ProjectService().createPaymentIntent(widget.projectId);

      final clientSecret = data["clientSecret"];
      if (clientSecret == null) {
        throw Exception("Client secret manquant");
      }
      // 2️⃣ نهيّئ Stripe PaymentSheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: "LANCY",
        ),
      );

      // 3️⃣ نعرض Payment UI
      await Stripe.instance.presentPaymentSheet();

      // 4️⃣ نأكد escrow (blocage des fonds)
      await ProjectService().confirmPayment(widget.projectId);

      Get.snackbar("Succès", "Paiement effectué ✅");

      Navigator.pop(context, true);
    } catch (e) {
      Get.snackbar("Erreur", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paiement")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            Text("Montant à payer", style: TextStyle(fontSize: 18)),

            const SizedBox(height: 10),

            Text(
              "${widget.amount} DT",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : makePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.purple,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Payer maintenant 💳"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/