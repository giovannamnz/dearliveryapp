import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AvaliacaoPage extends StatefulWidget {
  final String pedidoId;

  AvaliacaoPage({required this.pedidoId});

  @override
  _AvaliacaoPageState createState() => _AvaliacaoPageState();
}

class _AvaliacaoPageState extends State<AvaliacaoPage> {
  final TextEditingController _comentarioController = TextEditingController();
  double _nota = 0;

  Future<void> _avaliarEntrega() async {
    try {
      await FirebaseFirestore.instance.collection('avaliacoes').add({
        'pedidoId': widget.pedidoId,
        'nota': _nota,
        'comentario': _comentarioController.text,
        'dataAvalicao': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Avaliação enviada com sucesso!')));
      Navigator.pop(context);
    } catch (e) {
      print("Erro: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao enviar avaliação.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Avaliar Entrega")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Slider(
              value: _nota,
              min: 0,
              max: 5,
              divisions: 5,
              label: _nota.toString(),
              onChanged: (value) {
                setState(() {
                  _nota = value;
                });
              },
            ),
            TextField(
              controller: _comentarioController,
              decoration: InputDecoration(labelText: 'Comentário'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _avaliarEntrega,
              child: Text("Enviar Avaliação"),
            ),
          ],
        ),
      ),
    );
  }
}
