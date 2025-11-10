import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CriacaoPedidoPage extends StatefulWidget {
  @override
  _CriacaoPedidoPageState createState() => _CriacaoPedidoPageState();
}

class _CriacaoPedidoPageState extends State<CriacaoPedidoPage> {
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  
  Future<void> _criarPedido() async {
    try {
      final pedidoRef = FirebaseFirestore.instance.collection('pedidos');
      await pedidoRef.add({
        'descricao': _descricaoController.text,
        'endereco': _enderecoController.text,
        'status': 'Aguardando entrega',
        'dataCriacao': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pedido criado com sucesso!')));
      Navigator.pop(context); // Voltar para a tela anterior
    } catch (e) {
      print("Erro: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao criar pedido. Tente novamente.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Criar Pedido")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _descricaoController,
              decoration: InputDecoration(labelText: 'Descrição do pedido'),
            ),
            TextField(
              controller: _enderecoController,
              decoration: InputDecoration(labelText: 'Endereço para entrega'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _criarPedido,
              child: Text("Criar Pedido"),
            ),
          ],
        ),
      ),
    );
  }
}
