/// MODEL do Cliente (RF01 - Cadastro Simplificado).
/// Model = apenas dados e conversão para o banco. Não conhece telas.
class Cliente {
  final String nome;

  /// WhatsApp somente com números, ex: 86999998888
  final String whatsapp;

  /// CPF somente com números
  final String cpf;

  final String email;

  const Cliente({
    required this.nome,
    required this.whatsapp,
    required this.cpf,
    required this.email,
  });

  /// Converte o objeto em Map para salvar no Firebase (Firestore trabalha com Map).
  Map<String, dynamic> toMap() => {
        'nome': nome,
        'whatsapp': whatsapp,
        'cpf': cpf,
        'email': email,
      };

  /// Cria um Cliente a partir de um Map vindo do banco.
  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
        nome: map['nome'] as String,
        whatsapp: map['whatsapp'] as String,
        cpf: map['cpf'] as String,
        email: map['email'] as String,
      );
}