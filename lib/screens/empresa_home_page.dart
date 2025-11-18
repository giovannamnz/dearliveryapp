import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dear_livery/screens/criacao_pedido_page.dart';
import 'package:dear_livery/screens/entrega_monitorada_page.dart';
import 'package:dear_livery/screens/login_page.dart';

class EmpresaHomePage extends StatelessWidget {
  const EmpresaHomePage({Key? key}) : super(key: key);

  // Função para deslogar o usuário
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print("Erro ao sair: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao sair. Tente novamente.")),
      );
    }
  }

  // Função para abrir a tela de acompanhamento
  Future<void> _abrirAcompanhamento(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado.')),
      );
      return;
    }

    // Busca um pedido em andamento
    final snapshot = await FirebaseFirestore.instance
        .collection('pedidos')
        .where('status', isEqualTo: 'em_andamento')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma entrega em andamento no momento.')),
      );
      return;
    }

    final pedidoId = snapshot.docs.first.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AcompanhamentoEntregaPage(
          pedidoId: pedidoId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Página Inicial - Empresa'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Bem-vindo, Empresa!",
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 20),

              // Botão cadastrar pedido
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CriacaoPedidoPage()),
                  );
                },
                child: Text("Cadastrar Novo Pedido"),
              ),

              SizedBox(height: 20),

              // Botão acompanhar entrega
              ElevatedButton(
                onPressed: () => _abrirAcompanhamento(context),
                child: Text("Acompanhar Entregas"),
              ),

              SizedBox(height: 40),

              // Botão sair
              ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text("Sair"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
