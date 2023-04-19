import 'package:chatapp/providers/auth_provider.dart';
import 'package:chatapp/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: 'SignIn Failed');
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: 'SignIn Cancelled');
        break;

      case Status.authenticated:
        Fluttertoast.showToast(msg: 'SignIn Successfully');
        break;
      default:
        break;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Welcome to smartchat",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              "Login to countinue",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Image.asset(
              "assets/images/back.png",
            ),
            InkWell(
              onTap: () async {
                bool isSuccess = await authProvider.handleGoogleSignIn();
                if (isSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                }
              },
              child: Image.asset(
                "assets/images/google_login.jpg",
                height: 64,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
