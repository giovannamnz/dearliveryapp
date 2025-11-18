import 'package:flutter/material.dart';
import 'package:dear_livery/screens/entrega_monitorada_page.dart';  // Certifique-se de importar as páginas
import 'package:dear_livery/screens/criacao_pedido_page.dart';
import 'package:dear_livery/screens/avaliacao_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Página Inicial"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(  // Centraliza os widgets dentro do body
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,  // Alinha os botões verticalmente no centro
            crossAxisAlignment: CrossAxisAlignment.center, // Centraliza os botões horizontalmente
            children: [
              Text(
                "Bem-vindo ao Dear-Livery!",
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,  // Alinha o texto de boas-vindas no centro
              ),
              SizedBox(height: 40),  // Adiciona espaço entre o texto e os botões
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AcompanhamentoEntregaPage(pedidoId: '123')),  // Passe o pedidoId ou dados necessários
                  );
                },
                child: Text("Acompanhamento de Entrega"),
              ),
              SizedBox(height: 20),  // Adiciona espaço entre os botões
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CriacaoPedidoPage()),
                  );
                },
                child: Text("Criar Pedido"),
              ),
              SizedBox(height: 20),  // Adiciona espaço entre os botões
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AvaliacaoPage(pedidoId: '123')),  // Passe o pedidoId ou dados necessários
                  );
                },
                child: Text("Avaliar Entrega"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
