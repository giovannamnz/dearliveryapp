import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// telas do motorista
import 'package:dear_livery/screens/visualizar_pedidos_page.dart';
import 'package:dear_livery/screens/pedidos_aceitos_page.dart';
import 'package:dear_livery/screens/entrega_monitorada_page.dart';

class MotoristaHomePage extends StatelessWidget {
  const MotoristaHomePage({Key? key}) : super(key: key);

  // =====================================
  // FUNÇÃO: abrir tela de monitoramento
  // =====================================
  Future<void> _abrirMonitoramento(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar logado como motorista.'),
        ),
      );
      return;
    }

    // Busca pedido EM ANDAMENTO desse motorista
    final snapshot = await FirebaseFirestore.instance
    .collection('pedidos')
    .where('entregadorId', isEqualTo: user.uid)
    .where('status', isEqualTo: 'em_andamento')
    .limit(1)
    .get();


    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não tem nenhuma entrega em andamento.'),
        ),
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

  // =====================================
  // FUNÇÃO: logout
  // =====================================
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao sair. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página Inicial - Motorista'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Bem-vindo, Motorista!",
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Botão: Visualizar pedidos disponíveis
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisualizarPedidosPage(),
                    ),
                  );
                },
                child: const Text("Visualizar Pedidos Disponíveis"),
              ),

              const SizedBox(height: 16),

              // Botão: Monitorar entregas em andamento
              ElevatedButton(
                onPressed: () => _abrirMonitoramento(context),
                child: const Text("Monitorar Entregas em Andamento"),
              ),

              const SizedBox(height: 16),

              // Botão: Pedidos aceitos
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PedidosAceitosPage(),
                    ),
                  );
                },
                child: const Text("Pedidos Aceitos"),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text("Sair"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
