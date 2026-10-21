class Tarefa {
  final String id;
  final String titulo;
  final String descricao;
  final String prioridade;
  final String status;
  final String criadoEm;

  const Tarefa({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.prioridade,
    required this.status,
    this.criadoEm = '',
  });

  factory Tarefa.fromJson(Map<String, dynamic> json) => Tarefa(
        id: '${json['id'] ?? ''}',
        titulo: '${json['titulo'] ?? ''}',
        descricao: '${json['descricao'] ?? ''}',
        prioridade: '${json['prioridade'] ?? 'media'}',
        status: '${json['status'] ?? 'pendente'}',
        criadoEm: '${json['criado_em'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descricao': descricao,
        'prioridade': prioridade,
        'status': status,
      };
}
