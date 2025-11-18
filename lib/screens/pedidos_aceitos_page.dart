import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PedidosAceitosPage extends StatefulWidget {
  @override
  _PedidosAceitosPageState createState() => _PedidosAceitosPageState();
}

class _PedidosAceitosPageState extends State<PedidosAceitosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para atualizar o status do pedido
  Future<void> _aceitarPedido(String pedidoId, String status) async {
    try {
      await _firestore.collection('pedidos').doc(pedidoId).update({
        'status': status,  // Atualiza o status para "em andamento" ou "finalizado"
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status atualizado para $status')));
    } catch (e) {
      print("Erro ao atualizar status: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar status. Tente novamente.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pedidos Aceitos"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              // Filtra para pegar apenas os pedidos com status "em andamento"
              stream: _firestore.collection('pedidos').where('status', isEqualTo: 'em andamento').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final pedidos = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,  // Faz a ListView não ocupar mais espaço do que o necessário
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final pedidoId = pedido['pedidoId'];
                    final destinatario = pedido['destinatario']['nome'];
                    final valorEntrega = double.tryParse(pedido['valorEntrega'].toString()) ?? 0.0;
                    String status = pedido['status'];

                    // Garantir que o status seja um valor válido para o DropdownButton
                    if (!['em andamento', 'finalizado'].contains(status)) {
                      status = 'em andamento';  // Define o valor padrão caso o status seja inválido
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        title: Text('Pedido: $pedidoId'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Destinatário: $destinatario'),
                            SizedBox(height: 8.0),
                            Text('Valor: R\$ ${valorEntrega.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Dropdown para aceitar ou finalizar o pedido
                            DropdownButton<String>(
                              value: status,  // Usa o status atualizado, agora com um valor válido
                              items: <String>['em andamento', 'finalizado']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newStatus) {
                                if (newStatus != null && newStatus != status) {
                                  _aceitarPedido(pedido.id, newStatus);  // Atualiza o status do pedido
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
