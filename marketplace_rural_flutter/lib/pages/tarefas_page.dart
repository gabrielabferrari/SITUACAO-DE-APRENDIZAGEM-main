import 'package:flutter/material.dart';
import '../models/tarefa.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TarefasPage extends StatefulWidget {
  const TarefasPage({super.key});

  @override
  State<TarefasPage> createState() => _TarefasPageState();
}

class _TarefasPageState extends State<TarefasPage> {
  final ApiService api = ApiService();
  List<Tarefa> tarefas = [];
  bool carregando = true;
  String? erro;

  @override
  void initState() {
    super.initState();
    carregarTarefas();
  }

  Future<void> carregarTarefas() async {
    setState(() { carregando = true; erro = null; });
    try {
      final resposta = await api.get('');
      final dados = resposta['dados'];
      if (dados is! List) throw const ApiException('A lista de tarefas retornada pela API é inválida.');
      final lista = dados.map((item) => Tarefa.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      if (!mounted) return;
      setState(() { tarefas = lista; carregando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { carregando = false; erro = _mensagemErro(e); });
    }
  }

  String _mensagemErro(Object e) {
    if (e is ApiException) return e.message;
    if (e is Exception) return 'Não foi possível conectar à API. Confira a rede e se o servidor PHP está ativo.';
    return 'Ocorreu um erro inesperado.';
  }

  Future<void> abrirFormulario({Tarefa? tarefa}) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _TarefaDialog(tarefa: tarefa),
    );
    if (resultado == null) return;
    try {
      if (tarefa == null) {
        await api.post('', resultado);
        _aviso('Tarefa cadastrada com sucesso.');
      } else {
        await api.put('?id=${Uri.encodeQueryComponent(tarefa.id)}', resultado);
        _aviso('Tarefa atualizada com sucesso.');
      }
      await carregarTarefas();
    } catch (e) {
      _aviso(_mensagemErro(e), erro: true);
    }
  }

  Future<void> excluir(Tarefa tarefa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: Text('Deseja excluir “${tarefa.titulo}”?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await api.delete('?id=${Uri.encodeQueryComponent(tarefa.id)}');
      _aviso('Tarefa excluída com sucesso.');
      await carregarTarefas();
    } catch (e) {
      _aviso(_mensagemErro(e), erro: true);
    }
  }

  void _aviso(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: erro ? Colors.red.shade700 : AppColors.darkGreen,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirFormulario(),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: carregarTarefas,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.task_alt, color: Colors.white, size: 30),
                SizedBox(height: 10),
                Text('Organize suas tarefas', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('Gerencie atividades conectadas à API do projeto.', style: TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              const Expanded(child: Text('Tarefas cadastradas', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.text))),
              IconButton(onPressed: carregarTarefas, tooltip: 'Atualizar lista', icon: const Icon(Icons.refresh, color: AppColors.green)),
            ]),
            if (carregando)
              const Padding(padding: EdgeInsets.all(35), child: Center(child: CircularProgressIndicator()))
            else if (erro != null)
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                const Icon(Icons.cloud_off_outlined, size: 42, color: AppColors.muted),
                const SizedBox(height: 10), Text(erro!, textAlign: TextAlign.center),
                const SizedBox(height: 12), OutlinedButton.icon(onPressed: carregarTarefas, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
              ])))
            else if (tarefas.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(24), child: Column(children: [Icon(Icons.checklist, size: 42, color: AppColors.muted), SizedBox(height: 8), Text('Nenhuma tarefa encontrada.'), Text('Toque em “Nova tarefa” para cadastrar.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted))])))
            else
              ...tarefas.map(_cartaoTarefa),
          ],
        ),
      ),
    );
  }

  Widget _cartaoTarefa(Tarefa tarefa) {
    final concluida = tarefa.status == 'concluida';
    final prioridade = tarefa.prioridade;
    final prioridadeCor = prioridade == 'alta' ? Colors.red.shade700 : prioridade == 'baixa' ? AppColors.green : Colors.orange.shade800;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(concluida ? Icons.check_circle : Icons.radio_button_unchecked, color: concluida ? AppColors.green : AppColors.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(tarefa.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text))),
          PopupMenuButton<String>(tooltip: 'Ações', onSelected: (v) { if (v == 'editar') abrirFormulario(tarefa: tarefa); if (v == 'excluir') excluir(tarefa); }, itemBuilder: (_) => const [PopupMenuItem(value: 'editar', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'))), PopupMenuItem(value: 'excluir', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Excluir')))]),
        ]),
        if (tarefa.descricao.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 34, top: 3), child: Text(tarefa.descricao, style: const TextStyle(color: AppColors.muted))),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.only(left: 34), child: Wrap(spacing: 8, runSpacing: 8, children: [
          _etiqueta(prioridade.toUpperCase(), prioridadeCor),
          _etiqueta(concluida ? 'Concluída' : 'Pendente', concluida ? AppColors.green : AppColors.muted),
        ])),
        if (tarefa.criadoEm.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 34, top: 10), child: Text('Criada em ${tarefa.criadoEm}', style: const TextStyle(fontSize: 11, color: AppColors.muted))),
      ]))),
    );
  }

  Widget _etiqueta(String texto, Color cor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: cor.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
    child: Text(texto, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

class _TarefaDialog extends StatefulWidget {
  final Tarefa? tarefa;
  const _TarefaDialog({this.tarefa});
  @override
  State<_TarefaDialog> createState() => _TarefaDialogState();
}

class _TarefaDialogState extends State<_TarefaDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titulo;
  late final TextEditingController descricao;
  late String prioridade;
  late String status;

  @override
  void initState() {
    super.initState();
    titulo = TextEditingController(text: widget.tarefa?.titulo ?? '');
    descricao = TextEditingController(text: widget.tarefa?.descricao ?? '');
    prioridade = widget.tarefa?.prioridade ?? 'media';
    status = widget.tarefa?.status ?? 'pendente';
  }

  @override
  void dispose() { titulo.dispose(); descricao.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.tarefa == null ? 'Nova tarefa' : 'Editar tarefa'),
    content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: titulo, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Título', prefixIcon: Icon(Icons.title)), validator: (v) => v == null || v.trim().isEmpty ? 'Informe o título.' : null),
      const SizedBox(height: 12),
      TextFormField(controller: descricao, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição', prefixIcon: Icon(Icons.notes))),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: prioridade, decoration: const InputDecoration(labelText: 'Prioridade'), items: const [DropdownMenuItem(value: 'baixa', child: Text('Baixa')), DropdownMenuItem(value: 'media', child: Text('Média')), DropdownMenuItem(value: 'alta', child: Text('Alta'))], onChanged: (v) { if (v != null) setState(() => prioridade = v); }),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Status'), items: const [DropdownMenuItem(value: 'pendente', child: Text('Pendente')), DropdownMenuItem(value: 'concluida', child: Text('Concluída'))], onChanged: (v) { if (v != null) setState(() => status = v); }),
    ]))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () { if (!formKey.currentState!.validate()) return; Navigator.pop(context, {'titulo': titulo.text.trim(), 'descricao': descricao.text.trim(), 'prioridade': prioridade, 'status': status}); }, child: const Text('Salvar'))],
  );
}
