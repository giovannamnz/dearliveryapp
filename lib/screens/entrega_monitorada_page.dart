import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

class AcompanhamentoEntregaPage extends StatefulWidget {
  final String pedidoId;

  const AcompanhamentoEntregaPage({
    super.key,
    required this.pedidoId,
  });

  @override
  State<AcompanhamentoEntregaPage> createState() =>
      _AcompanhamentoEntregaPageState();
}

class _AcompanhamentoEntregaPageState
    extends State<AcompanhamentoEntregaPage> {
  final _db = FirebaseFirestore.instance;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _rotaCarregada = false;

  // 🔑 SUA CHAVE DA API DO GOOGLE (Directions + Maps)
  final String _googleApiKey = 'AIzaSyAQlQUY1BJoS0QXlDXnuuVfu6xQeihb5T8';

  // ==================================================
  // 1) Buscar rota na Directions API e desenhar polyline
  // ==================================================
  Future<void> _carregarRota({
    required LatLng origem,
    required LatLng destino,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origem.latitude},${origem.longitude}'
        '&destination=${destino.latitude},${destino.longitude}'
        '&mode=driving'
        '&key=$_googleApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        print('Erro ao buscar rota: ${response.body}');
        return;
      }

      final data = jsonDecode(response.body);

      if (data['routes'] == null || data['routes'].isEmpty) {
        print('Nenhuma rota encontrada');
        return;
      }

      final points = data['routes'][0]['overview_polyline']['points'];

      // 👉 versão correta com método estático
      final List<PointLatLng> decodedPoints =
          PolylinePoints.decodePolyline(points);

      final List<LatLng> polylineCoords = decodedPoints
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('rota_pedido'),
            width: 5,
            color: Colors.blue,
            points: polylineCoords,
          ),
        );
      });
    } catch (e) {
      print('Erro ao decodificar rota: $e');
    }
  }

  // ==================================================
  // 2) Ajustar câmera para mostrar origem + destino
  // ==================================================
  Future<void> _ajustarCamera({
    required LatLng origem,
    required LatLng destino,
  }) async {
    if (_mapController == null) return;

    final southwest = LatLng(
      origem.latitude < destino.latitude ? origem.latitude : destino.latitude,
      origem.longitude < destino.longitude
          ? origem.longitude
          : destino.longitude,
    );

    final northeast = LatLng(
      origem.latitude > destino.latitude ? origem.latitude : destino.latitude,
      origem.longitude > destino.longitude
          ? origem.longitude
          : destino.longitude,
    );

    final bounds = LatLngBounds(southwest: southwest, northeast: northeast);

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  // ==================================================
  // 3) Atualizar marcadores (origem, destino, entregador)
  // ==================================================
  void _atualizarMarcadores({
    required LatLng origem,
    required LatLng destino,
    LatLng? entregador,
  }) {
    final markers = <Marker>{};

    markers.add(
      Marker(
        markerId: const MarkerId('origem'),
        position: origem,
        infoWindow: const InfoWindow(title: 'Origem'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      ),
    );

    markers.add(
      Marker(
        markerId: const MarkerId('destino'),
        position: destino,
        infoWindow: const InfoWindow(title: 'Destino'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      ),
    );

    if (entregador != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('entregador'),
          position: entregador,
          infoWindow: const InfoWindow(title: 'Entregador'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('pedidos').doc(widget.pedidoId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar pedido'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // -------------------------
          // Lê origem e destino
          // -------------------------
          if (data['origemLat'] == null ||
              data['origemLng'] == null ||
              data['destinoLat'] == null ||
              data['destinoLng'] == null) {
            return const Center(
              child: Text('Origem/destino ainda não foram definidos.'),
            );
          }

          final origem = LatLng(
            (data['origemLat'] as num).toDouble(),
            (data['origemLng'] as num).toDouble(),
          );

          final destino = LatLng(
            (data['destinoLat'] as num).toDouble(),
            (data['destinoLng'] as num).toDouble(),
          );

          LatLng? entregador;
          if (data['entregadorLat'] != null &&
              data['entregadorLng'] != null) {
            entregador = LatLng(
              (data['entregadorLat'] as num).toDouble(),
              (data['entregadorLng'] as num).toDouble(),
            );
          }

          // Atualiza marcadores sempre que o Firestore mudar
          _atualizarMarcadores(
            origem: origem,
            destino: destino,
            entregador: entregador,
          );

          // Carrega rota apenas uma vez
          if (!_rotaCarregada) {
            _rotaCarregada = true;
            _carregarRota(origem: origem, destino: destino);
            Future.delayed(const Duration(milliseconds: 500), () {
              _ajustarCamera(origem: origem, destino: destino);
            });
          }

          final status = (data['status'] ?? 'desconhecido').toString();
          final valorEntrega = (data['valorEntrega'] ?? '').toString();
          final entregadorNome =
              (data['entregadorNome'] ?? 'Entregador').toString();

          return Stack(
            children: [
              // =====================
              // MAPA
              // =====================
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: origem,
                  zoom: 14,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _ajustarCamera(origem: origem, destino: destino);
                },
                markers: _markers,
                polylines: _polylines,
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
              ),

              // =====================
              // CARD SUPERIOR (INFO PEDIDO)
              // =====================
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.delivery_dining, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pedido ${data['pedidoId'] ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                if (valorEntrega.isNotEmpty)
                                  Text(
                                    'Valor: R\$ $valorEntrega',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // =====================
              // CARD INFERIOR (ENTREGADOR)
              // =====================
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entregadorNome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entregador != null
                                  ? 'Entregador a caminho...'
                                  : 'Aguardando atribuição de entregador',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: () {
                          _ajustarCamera(origem: origem, destino: destino);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // =====================
              // BOTÃO VOLTAR
              // =====================
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
