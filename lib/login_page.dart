import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        body: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(
              image: AssetImage('images/luffy-flag/luffy-flag-2.png'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Welcome to OnePiece!',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.blue),
            ),
            const SizedBox(height: 120),
            const SizedBox(
              width: 300,
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                    labelText: "User Name",
                    hintText: "User name or Email",
                    prefixIcon: Icon(Icons.person)),
              ),
            ),
            const SizedBox(
              width: 300,
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Your password",
                    prefixIcon: Icon(Icons.lock)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/');
                },
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 17),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Don\'t have a account?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      'Register now!',
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic),
                    ))
              ],
            )
          ],
        )));
  }
}
