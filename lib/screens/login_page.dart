import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dear_livery/screens/empresa_home_page.dart'; // Página de empresas
import 'package:dear_livery/screens/motorista_home_page.dart'; // Página de motoristas
import 'package:dear_livery/screens/cadastro_page.dart'; // Página de cadastro
import 'package:dear_livery/services/firebase_service.dart'; // Serviço que lida com Firebase
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar para ler do Firestore

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Função de login
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Chama o método de login do Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Buscar o tipo de usuário (empresa ou motorista) no Firestore
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        // Verificar o campo 'role' para determinar se é uma empresa ou motorista
        String userRole = userDoc['role'] ?? '';

        if (userRole == 'empresa') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => EmpresaHomePage()),  // Página inicial da empresa
          );
        } else if (userRole == 'motorista') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MotoristaHomePage()),  // Página inicial do motorista
          );
        } else {
          // Caso não seja identificado como empresa ou motorista
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tipo de usuário inválido')));
        }
      } else {
        // Se o login falhar, exibe uma mensagem de erro
        _showError("Falha no login. Verifique suas credenciais.");
      }
    } catch (e) {
      _showError("Erro: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para mostrar uma mensagem de erro
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Campo de email
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            // Campo de senha
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Senha'),
            ),
            SizedBox(height: 20),
            // Botão de login ou carregamento
            _isLoading
                ? CircularProgressIndicator()  // Mostra a animação de carregamento enquanto faz login
                : ElevatedButton(
                    onPressed: _login,
                    child: Text("Entrar"),
                  ),
            SizedBox(height: 20),
            // Link para a página de cadastro
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CadastroPage()),  // Navegação para CadastroPage
                );
              },
              child: Text("Criar conta"),
            ),
          ],
        ),
      ),
    );
  }
}
