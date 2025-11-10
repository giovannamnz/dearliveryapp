import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_livery/models/usuario.dart'; // Verifique se a importação está correta!

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método de registro de usuário
  Future<User?> cadastrarUsuario(String email, String senha, String nome, String tipo) async {
    try {
      // Cria o usuário com email e senha
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: senha);

      if (userCredential.user != null) {
        // Salva os dados do usuário no Firestore
        Usuario usuario = Usuario(
          id: userCredential.user!.uid,
          nome: nome,
          email: email,
          tipo: tipo,
        );

        // Salva o usuário no Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set(usuario.toMap());
        return userCredential.user;
      } else {
        return null;
      }
    } catch (e) {
      print("Erro ao cadastrar usuário: $e");
      return null;
    }
  }

  // Método de login
  Future<User?> loginUsuario(String email, String senha) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: senha);
      
      if (userCredential.user != null) {
        return userCredential.user;
      } else {
        return null;
      }
    } catch (e) {
      print("Erro ao fazer login: $e");
      return null;
    }
  }

  // Método para obter os dados do usuário atual
  Future<Usuario?> obterUsuarioAtual() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return Usuario.fromMap(userDoc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print("Erro ao obter usuário: $e");
      return null;
    }
  }

  // Método para criar um pedido no Firebase
  Future<void> criarPedido(String descricao, String endereco) async {
    try {
      await _firestore.collection('pedidos').add({
        'descricao': descricao,
        'endereco': endereco,
        'status': 'Aguardando entrega',
        'dataCriacao': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Erro ao criar pedido: $e");
    }
  }
}
