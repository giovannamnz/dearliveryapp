import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:dear_livery/screens/entrega_monitorada_page.dart';

class VisualizarPedidosPage extends StatefulWidget {
  @override
  _VisualizarPedidosPageState createState() => _VisualizarPedidosPageState();
}

class _VisualizarPedidosPageState extends State<VisualizarPedidosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para aceitar o pedido e mudar o status
Future<void> _aceitarPedido(String pedidoDocId) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Você precisa estar logado como motorista.')),
    );
    return;
  }

  try {
    await _firestore.collection('pedidos').doc(pedidoDocId).update({
      'status': 'em_andamento',          // 🔴 MESMO TEXTO da MotoristaHomePage
      'entregadorId': user.uid,          // 🔴 Vínculo com o motorista
      'entregadorEmail': user.email ?? '',
      'dataAceito': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido aceito com sucesso!')),
    );
  } catch (e) {
    print("Erro ao aceitar pedido: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Falha ao aceitar pedido. Tente novamente.')),
    );
  }
}


  // Função para recusar o pedido e mudar o status
  Future<void> _recusarPedido(String pedidoDocId) async {
    try {
      await _firestore.collection('pedidos').doc(pedidoDocId).update({
        'status': 'recusado',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido recusado com sucesso!')),
      );
    } catch (e) {
      print("Erro ao recusar pedido: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao recusar pedido. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pedidos Disponíveis"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('pedidos')
            .where('status', isEqualTo: 'disponível') // só pedidos livres
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data!.docs;

          if (pedidos.isEmpty) {
            return const Center(
              child: Text('Nenhum pedido disponível no momento.'),
            );
          }

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedidoDoc = pedidos[index];
              final docId = pedidoDoc.id;                // id do documento
              final pedidoId = pedidoDoc['pedidoId'];    // código do pedido
              final destinatario = pedidoDoc['destinatario']['nome'];
              final valorEntrega =
                  double.tryParse(pedidoDoc['valorEntrega'].toString()) ?? 0.0;

              String statusDropdown = 'Aceitar';

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text('Pedido: $pedidoId'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Destinatário: $destinatario'),
                      const SizedBox(height: 8.0),
                      Text(
                        'Valor: R\$ ${valorEntrega.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  trailing: DropdownButton<String>(
                    value: statusDropdown,
                    items: <String>['Aceitar', 'Recusar']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue == null) return;

                      if (newValue == 'Aceitar') {
                        _aceitarPedido(docId);
                      } else if (newValue == 'Recusar') {
                        _recusarPedido(docId);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
