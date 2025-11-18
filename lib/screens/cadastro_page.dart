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
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  String _role = 'empresa'; // Valor inicial para o campo "role"

  // Função de registro
  Future<void> _register() async {
    // Validação de campos vazios
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Todos os campos são obrigatórios")));
      return;
    }

    // Verificar se as senhas são iguais
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("As senhas não coincidem")));
      return;
    }

    try {
      // Criação do usuário no Firebase Authentication
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Salvar dados adicionais no Firestore, criando a coleção 'users'
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text,
        'role': _role, // Lojista ou Entregador
        'email': _emailController.text,
        'createdAt': Timestamp.now(),
      });

      // Navegar para a página inicial após o cadastro
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      String errorMessage = "Falha ao criar conta. Tente novamente.";

      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          errorMessage = "Esse email já está em uso. Tente outro.";
        } else if (e.code == 'weak-password') {
          errorMessage = "A senha deve ser mais forte. Tente novamente.";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Email inválido. Verifique o formato.";
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
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
            // Nome do usuário
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            // Email
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            // Senha
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Senha'),
            ),
            // Confirmar Senha
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirmar Senha'),
            ),
            SizedBox(height: 20),
            // Seleção do tipo de usuário
            DropdownButton<String>(
              value: _role,
              onChanged: (String? newValue) {
                setState(() {
                  _role = newValue!;
                });
              },
              items: <String>['empresa', 'motorista']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'empresa' ? 'Lojista' : 'Entregador'),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // Botão de cadastro
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
