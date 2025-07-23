import 'package:flutter/material.dart';

class JailbreakErrorView extends StatelessWidget {
  const JailbreakErrorView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 120, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(height: 50),
                Text('You are running root or Jailbreak.',
                    style: TextStyle(color: Theme.of(context).colorScheme.surfaceDim, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('Please contact your support.',
                    style: TextStyle(color: Theme.of(context).colorScheme.surfaceDim, fontSize: 18, fontWeight: FontWeight.w400)),
              ],
            ),
          )),
    );
  }
}