import 'package:flutter/material.dart';

class CadastroPedidoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cadastro de Pedido"),
      ),
      body: Center(
        child: Text(
          "Formulário para cadastrar um novo pedido de entrega.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
