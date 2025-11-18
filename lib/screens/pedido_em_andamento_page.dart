import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/entregador_location_service.dart';

class PedidoEmAndamentoPage extends StatefulWidget {
  final String pedidoId;

  const PedidoEmAndamentoPage({
    super.key,
    required this.pedidoId,
  });

  @override
  State<PedidoEmAndamentoPage> createState() => _PedidoEmAndamentoPageState();
}

class _PedidoEmAndamentoPageState extends State<PedidoEmAndamentoPage> {
  final _locationService = EntregadorLocationService();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool _iniciouRastreamento = false;
  bool _finalizando = false;

  @override
  void initState() {
    super.initState();
    _iniciarRastreamento();
  }

  Future<void> _iniciarRastreamento() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você precisa estar logado como entregador.')),
        );
        return;
      }

      await _locationService.startTracking(
        pedidoId: widget.pedidoId,
        entregadorId: user.uid,
      );

      setState(() {
        _iniciouRastreamento = true;
      });

      // Atualiza status do pedido
      await _db.collection('pedidos').doc(widget.pedidoId).update({
        'status': 'em_andamento',
      });
    } catch (e) {
      print('Erro ao iniciar rastreamento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao iniciar rastreamento: $e')),
      );
    }
  }

  Future<void> _finalizarPedido() async {
    setState(() => _finalizando = true);

    try {
      // Para de rastrear localização
      await _locationService.stopTracking();

      // Atualiza status do pedido como finalizado
      await _db.collection('pedidos').doc(widget.pedidoId).update({
        'status': 'finalizado',
        'dataFinalizacao': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // volta pra lista de pedidos do entregador
      }
    } catch (e) {
      print('Erro ao finalizar pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar pedido: $e')),
      );
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido ${widget.pedidoId}'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          if (_iniciouRastreamento)
            const Text(
              'Rastreamento de localização ATIVO',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            )
          else
            const Text(
              'Iniciando rastreamento...',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 16),

          // Aqui você pode colocar informações do pedido, origem/destino, etc.
          Expanded(
            child: Center(
              child: Text(
                'Aqui pode ficar um mapa pequeno, dados do pedido, '
                'botão de contato, etc.',
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Botão de finalizar entrega
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _finalizando ? null : _finalizarPedido,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: _finalizando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Finalizar entrega'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
