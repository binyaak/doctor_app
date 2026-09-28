import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

void main(List<String> args) {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Homescreen(),
    );
  }
}

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  late Razorpay _razorpay;
  var txtcontrol = TextEditingController();
  void opencheckout(amount) async {
    amount = amount * 100;
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': amount,
      'name': 'Irohub.',
      'description': 'Payment',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': '8888888888', 'email': 'test@razorpay.com'},
      'external': {
        'wallets': ['paytm']
      }
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('error:e');
    }
  }

  void handlePaymentsuccess(PaymentSuccessResponse response) {
    Fluttertoast.showToast(
        msg: "Payment successful" + response.paymentId!,
        toastLength: Toast.LENGTH_SHORT);
  }

  void handlepaymenterror(PaymentSuccessResponse response) {
    Fluttertoast.showToast(
        msg: "Payment failed" + response.paymentId!,
        toastLength: Toast.LENGTH_SHORT);
  }

  void handleExternalwallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
        msg: "Payment failed" + response.walletName!,
        toastLength: Toast.LENGTH_SHORT);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _razorpay.clear();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentsuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlepaymenterror);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalwallet);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          SizedBox(
            height: 100,
          ),
          // Image.network(
          //   'data:image/png;base64,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',
          //   height: 50,
          //   width: 100,
          // ),
          SizedBox(
            height: 10,
          ),
          Text("Irohub Infotech"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              cursorColor: Colors.white,
              autofocus: false,
              controller: txtcontrol,
              decoration: InputDecoration(
                  border: OutlineInputBorder(), label: Text("enter amount")),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          ElevatedButton(
              onPressed: () {
                if (txtcontrol.text.isNotEmpty) {
                  setState(() {
                    int amount = int.parse(txtcontrol.text);
                    opencheckout(amount);
                  });
                }
                ;
              },
              child: Text("Pay Now"))
        ],
      ),
    );
  }
}
