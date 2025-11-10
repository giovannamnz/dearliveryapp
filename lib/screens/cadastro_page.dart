import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastroPage extends StatefulWidget {
  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController(); // Para determinar se é lojista ou entregador

  Future<void> _register() async {
    try {
      // Criando usuário no Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Adicionando dados no Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text,
        'role': _roleController.text, // Lojista ou Entregador
        'email': _emailController.text,
        'createdAt': Timestamp.now(),
      });

      // Navegar para outra página (pode ser uma tela de boas-vindas ou a tela inicial)
      Navigator.pushReplacementNamed(context, '/home'); // Exemplo de navegação
    } catch (e) {
      print("Erro: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao criar conta. Tente novamente.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cadastro")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Senha'),
            ),
            TextField(
              controller: _roleController,
              decoration: InputDecoration(labelText: 'Cargo (Lojista ou Entregador)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text("Cadastrar"),
            ),
          ],
        ),
      ),
    );
  }
}
