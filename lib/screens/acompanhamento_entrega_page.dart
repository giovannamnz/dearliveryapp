import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AcompanhamentoEntregaPage extends StatefulWidget {
  final String pedidoId;

  AcompanhamentoEntregaPage({required this.pedidoId});

  @override
  _AcompanhamentoEntregaPageState createState() => _AcompanhamentoEntregaPageState();
}

class _AcompanhamentoEntregaPageState extends State<AcompanhamentoEntregaPage> {
  late DocumentSnapshot pedido;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance.collection('pedidos').doc(widget.pedidoId).snapshots().listen((snapshot) {
      setState(() {
        pedido = snapshot;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Acompanhamento da Entrega")),
      body: pedido.exists
          ? Column(
              children: [
                Text("Descrição: ${pedido['descricao']}"),
                Text("Endereço: ${pedido['endereco']}"),
                Text("Status: ${pedido['status']}"),
                // Aqui você pode adicionar o mapa de rastreamento.
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
