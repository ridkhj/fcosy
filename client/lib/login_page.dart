import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    return Scaffold(
      persistentFooterAlignment: AlignmentDirectional.centerEnd,
      body: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 4,
            children: [
              Icon(Icons.wallet, size: 70),
              Text(
                "Fcosy",
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 40),
              ),
              Text(
                "Seu dinheiro no seu bolso!",
                style: theme.textTheme.titleMedium,
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(controller: emailController),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: passwordController,
                  obscuringCharacter: "*",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
