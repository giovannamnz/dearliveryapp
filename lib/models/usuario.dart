import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String tipo;
  final String? telefone;
  final DateTime? dataCriacao;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    this.telefone,
    this.dataCriacao,
  });

  // Método para criar um usuário a partir de um map (por exemplo, do Firebase)
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      nome: map['nome'],
      email: map['email'],
      tipo: map['tipo'],
      telefone: map['telefone'],
      dataCriacao: map['dataCriacao'] != null
          ? (map['dataCriacao'] as Timestamp).toDate() // Aqui usamos Timestamp
          : null,
    );
  }

  // Método para converter o objeto Usuario para um mapa (para armazenar no Firebase)
  Map<String, dynamic> toMap() {
  return {
    'id': id,
    'nome': nome,
    'email': email,
    'tipo': tipo,
    'telefone': telefone,
    'dataCriacao': dataCriacao ?? FieldValue.serverTimestamp(), // Corrigido aqui
  };
  }   
}