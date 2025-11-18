import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';

class CriacaoPedidoPage extends StatefulWidget {
  @override
  _CriacaoPedidoPageState createState() => _CriacaoPedidoPageState();
}

class _CriacaoPedidoPageState extends State<CriacaoPedidoPage> {
  // ID do pedido
  final _pedidoIdController = TextEditingController();

  // ORIGEM (Lojista)
  final _origemCepController = TextEditingController();
  final _origemEstadoController = TextEditingController();
  final _origemCidadeController = TextEditingController();
  final _origemEnderecoController = TextEditingController();
  final _origemNumeroController = TextEditingController();
  final _origemBairroController = TextEditingController();
  final _origemComplementoController = TextEditingController();

  // DESTINO (Destinatário)
  final _destinatarioNameController = TextEditingController();
  final _destinatarioCepController = TextEditingController();
  final _destinatarioEstadoController = TextEditingController();
  final _destinatarioCidadeController = TextEditingController();
  final _destinatarioEnderecoController = TextEditingController();
  final _destinatarioNumeroController = TextEditingController();
  final _destinatarioComplementoController = TextEditingController();
  final _destinatarioBairroController = TextEditingController();

  // Outros campos
  final _horarioSaidaController = TextEditingController();
  final _valorEntregaController = TextEditingController();

  String _pedidoId = "";
  bool _loading = false;
  bool _loadingCepOrigem = false;
  bool _loadingCepDestino = false;

  double? _origemLat;
  double? _origemLng;
  double? _destinoLat;
  double? _destinoLng;

  TimeOfDay? _horarioSaidaSelecionado;

  // =====================
  // Gera um ID de 6 caracteres
  // =====================
  String generatePedidoId() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    String pedidoId = '';

    for (int i = 0; i < 6; i++) {
      pedidoId += characters[random.nextInt(characters.length)];
    }
    return pedidoId;
  }

  // =====================
  // Seletor de horário bonito
  // =====================
  Future<void> _selecionarHorarioSaida() async {
    final agora = TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: _horarioSaidaSelecionado ?? agora,
      helpText: 'Selecione o horário de saída',
    );

    if (picked != null) {
      setState(() {
        _horarioSaidaSelecionado = picked;
        final hora = picked.hour.toString().padLeft(2, '0');
        final minuto = picked.minute.toString().padLeft(2, '0');
        _horarioSaidaController.text = "$hora:$minuto";
      });
    }
  }

  // =====================
  // Buscar CEP (genérico)
  // =====================
  Future<Map<String, dynamic>> _buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'\D'), '');
    if (cepLimpo.length != 8) {
      throw Exception('CEP inválido. Use 8 dígitos (ex: 70000000).');
    }

    final url = Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Erro ao consultar CEP.');
    }

    final data = jsonDecode(response.body);
    if (data['erro'] == true) {
      throw Exception('CEP não encontrado.');
    }

    return {
      'logradouro': (data['logradouro'] ?? '').toString(),
      'bairro': (data['bairro'] ?? '').toString(),
      'cidade': (data['localidade'] ?? '').toString(),
      'uf': (data['uf'] ?? '').toString(),
    };
  }

  Future<Location> _geocodificarEndereco(
    String logradouro,
    String numero,
    String bairro,
    String cidade,
    String uf,
  ) async {
    final enderecoCompleto = [
      if (logradouro.isNotEmpty)
        '$logradouro${numero.isNotEmpty ? ', $numero' : ''}',
      if (bairro.isNotEmpty) bairro,
      if (cidade.isNotEmpty) cidade,
      if (uf.isNotEmpty) uf,
      'Brasil',
    ].join(', ');

    print('Endereço para geocoding: $enderecoCompleto');

    final locations = await locationFromAddress(enderecoCompleto);
    if (locations.isEmpty) {
      throw Exception('Não foi possível obter coordenadas para este endereço.');
    }
    return locations.first;
  }

  // =========================
  // CEP ORIGEM → endereço + lat/lng
  // =========================
  Future<void> _buscarCepOrigem() async {
    final cep = _origemCepController.text;
    setState(() => _loadingCepOrigem = true);

    try {
      final dados = await _buscarCep(cep);

      _origemEnderecoController.text = dados['logradouro'];
      _origemBairroController.text = dados['bairro'];
      _origemCidadeController.text = dados['cidade'];
      _origemEstadoController.text = dados['uf'];

      final numero = _origemNumeroController.text.trim();
      final loc = await _geocodificarEndereco(
        dados['logradouro'],
        numero,
        dados['bairro'],
        dados['cidade'],
        dados['uf'],
      );

      _origemLat = loc.latitude;
      _origemLng = loc.longitude;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Origem localizada: (${_origemLat!.toStringAsFixed(5)}, ${_origemLng!.toStringAsFixed(5)})',
          ),
        ),
      );
    } catch (e) {
      print('Erro ao buscar CEP origem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar CEP de origem: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingCepOrigem = false);
    }
  }

  // =========================
  // CEP DESTINO → endereço + lat/lng
  // =========================
  Future<void> _buscarCepDestino() async {
    final cep = _destinatarioCepController.text;
    setState(() => _loadingCepDestino = true);

    try {
      final dados = await _buscarCep(cep);

      _destinatarioEnderecoController.text = dados['logradouro'];
      _destinatarioBairroController.text = dados['bairro'];
      _destinatarioCidadeController.text = dados['cidade'];
      _destinatarioEstadoController.text = dados['uf'];

      final numero = _destinatarioNumeroController.text.trim();
      final loc = await _geocodificarEndereco(
        dados['logradouro'],
        numero,
        dados['bairro'],
        dados['cidade'],
        dados['uf'],
      );

      _destinoLat = loc.latitude;
      _destinoLng = loc.longitude;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Destino localizado: (${_destinoLat!.toStringAsFixed(5)}, ${_destinoLng!.toStringAsFixed(5)})',
          ),
        ),
      );
    } catch (e) {
      print('Erro ao buscar CEP destino: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar CEP de destino: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingCepDestino = false);
    }
  }

  // =========================
  // Criar pedido no Firestore
  // =========================
  Future<void> _criarPedido() async {
    print("Chamando a função para criar o pedido...");

    // validações básicas
    if (_origemCepController.text.trim().isEmpty ||
        _origemEnderecoController.text.trim().isEmpty ||
        _origemCidadeController.text.trim().isEmpty ||
        _origemEstadoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os dados de origem.')),
      );
      return;
    }

    if (_destinatarioCepController.text.trim().isEmpty ||
        _destinatarioEnderecoController.text.trim().isEmpty ||
        _destinatarioCidadeController.text.trim().isEmpty ||
        _destinatarioEstadoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os dados de destino.')),
      );
      return;
    }

    if (_horarioSaidaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o horário de saída.')),
      );
      return;
    }

    // Garante que temos coordenadas de origem/destino
    if (_origemLat == null || _origemLng == null) {
      await _buscarCepOrigem();
      if (_origemLat == null || _origemLng == null) return;
    }

    if (_destinoLat == null || _destinoLng == null) {
      await _buscarCepDestino();
      if (_destinoLat == null || _destinoLng == null) return;
    }

    setState(() => _loading = true);

    _pedidoId = _pedidoIdController.text.isEmpty
        ? generatePedidoId()
        : _pedidoIdController.text;

    try {
      final origemEnderecoFormatado =
          "${_origemEnderecoController.text.trim()}, "
          "${_origemNumeroController.text.trim()} - "
          "${_origemBairroController.text.trim()}, "
          "${_origemCidadeController.text.trim()} - "
          "${_origemEstadoController.text.trim()}, "
          "CEP ${_origemCepController.text.trim()}";

      final destinoEnderecoFormatado =
          "${_destinatarioEnderecoController.text.trim()}, "
          "${_destinatarioNumeroController.text.trim()} - "
          "${_destinatarioBairroController.text.trim()}, "
          "${_destinatarioCidadeController.text.trim()} - "
          "${_destinatarioEstadoController.text.trim()}, "
          "CEP ${_destinatarioCepController.text.trim()}";

      await FirebaseFirestore.instance.collection('pedidos').add({
        'pedidoId': _pedidoId,
        'status': 'disponível',
        'dataCriacao': Timestamp.now(),

        // ORIGEM
        'origem': {
          'cep': _origemCepController.text,
          'estado': _origemEstadoController.text,
          'cidade': _origemCidadeController.text,
          'endereco': _origemEnderecoController.text,
          'numero': _origemNumeroController.text,
          'complemento': _origemComplementoController.text,
          'bairro': _origemBairroController.text,
        },
        'origemEndereco': origemEnderecoFormatado,
        'origemLat': _origemLat,
        'origemLng': _origemLng,

        // DESTINO
        'destinatario': {
          'nome': _destinatarioNameController.text,
          'cep': _destinatarioCepController.text,
          'estado': _destinatarioEstadoController.text,
          'cidade': _destinatarioCidadeController.text,
          'endereco': _destinatarioEnderecoController.text,
          'numero': _destinatarioNumeroController.text,
          'complemento': _destinatarioComplementoController.text,
          'bairro': _destinatarioBairroController.text,
        },
        'destinoEndereco': destinoEnderecoFormatado,
        'destinoLat': _destinoLat,
        'destinoLng': _destinoLng,

        'horarioSaida': _horarioSaidaController.text,
        'valorEntrega': _valorEntregaController.text, // string formatada "12,34"
      });

      print("Pedido criado com sucesso!");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido criado com sucesso!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Erro ao criar pedido: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao criar pedido. Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pedidoIdController.dispose();

    _origemCepController.dispose();
    _origemEstadoController.dispose();
    _origemCidadeController.dispose();
    _origemEnderecoController.dispose();
    _origemNumeroController.dispose();
    _origemBairroController.dispose();
    _origemComplementoController.dispose();

    _destinatarioNameController.dispose();
    _destinatarioCepController.dispose();
    _destinatarioEstadoController.dispose();
    _destinatarioCidadeController.dispose();
    _destinatarioEnderecoController.dispose();
    _destinatarioNumeroController.dispose();
    _destinatarioComplementoController.dispose();
    _destinatarioBairroController.dispose();

    _horarioSaidaController.dispose();
    _valorEntregaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Criar Pedido"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Informações",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _pedidoIdController,
                decoration: const InputDecoration(labelText: "ID do Pedido"),
                maxLength: 6,
              ),
              const SizedBox(height: 16),

              // ================= ORIGEM =================
              const Text(
                "Origem (Lojista)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _origemCepController,
                decoration: InputDecoration(
                  labelText: "CEP de origem",
                  suffixIcon: IconButton(
                    icon: _loadingCepOrigem
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    onPressed: _loadingCepOrigem ? null : _buscarCepOrigem,
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 9,
              ),
              TextField(
                controller: _origemEstadoController,
                decoration: const InputDecoration(labelText: "Estado (UF)"),
                maxLength: 2,
              ),
              TextField(
                controller: _origemCidadeController,
                decoration: const InputDecoration(labelText: "Cidade"),
              ),
              TextField(
                controller: _origemEnderecoController,
                decoration: const InputDecoration(labelText: "Endereço"),
              ),
              TextField(
                controller: _origemNumeroController,
                decoration: const InputDecoration(labelText: "Número"),
                keyboardType: TextInputType.number,
                maxLength: 5,
              ),
              TextField(
                controller: _origemBairroController,
                decoration: const InputDecoration(labelText: "Bairro"),
              ),
              TextField(
                controller: _origemComplementoController,
                decoration: const InputDecoration(labelText: "Complemento"),
              ),
              const SizedBox(height: 24),

              // ================= DESTINO =================
              const Text(
                "Destinatário",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _destinatarioNameController,
                decoration:
                    const InputDecoration(labelText: "Nome do Destinatário"),
              ),
              TextField(
                controller: _destinatarioCepController,
                decoration: InputDecoration(
                  labelText: "CEP de destino",
                  suffixIcon: IconButton(
                    icon: _loadingCepDestino
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    onPressed: _loadingCepDestino ? null : _buscarCepDestino,
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 9,
              ),
              TextField(
                controller: _destinatarioEstadoController,
                decoration: const InputDecoration(labelText: "Estado (UF)"),
                maxLength: 2,
              ),
              TextField(
                controller: _destinatarioCidadeController,
                decoration: const InputDecoration(labelText: "Cidade"),
              ),
              TextField(
                controller: _destinatarioEnderecoController,
                decoration: const InputDecoration(labelText: "Endereço"),
              ),
              TextField(
                controller: _destinatarioNumeroController,
                decoration: const InputDecoration(labelText: "Número"),
                keyboardType: TextInputType.number,
                maxLength: 5,
              ),
              TextField(
                controller: _destinatarioBairroController,
                decoration: const InputDecoration(labelText: "Bairro"),
              ),
              TextField(
                controller: _destinatarioComplementoController,
                decoration: const InputDecoration(labelText: "Complemento"),
              ),
              const SizedBox(height: 24),

              // Horário de saída (bonito)
              TextField(
                controller: _horarioSaidaController,
                readOnly: true,
                onTap: _selecionarHorarioSaida,
                decoration: InputDecoration(
                  labelText: "Horário de saída",
                  hintText: "Selecione o horário",
                  prefixIcon: const Icon(Icons.access_time),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Valor da entrega (R$ formatado)
              TextField(
                controller: _valorEntregaController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: "Valor da entrega",
                  hintText: "0,00",
                  prefixText: "R\$ ",
                  prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _criarPedido,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Criar Pedido"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================
// Formatter de moeda R$
// ==========================
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) digits = '0';

    if (digits.length == 1) {
      digits = '0,0$digits';
    } else if (digits.length == 2) {
      digits = '0,$digits';
    } else {
      final parteInteira = digits.substring(0, digits.length - 2);
      final parteCentavos = digits.substring(digits.length - 2);
      digits = '$parteInteira,$parteCentavos';
    }

    final textoFormatado = digits;

    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
    );
  }
}
