import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'Repositories/ordem_servico_repository.dart';
import 'Repositories/ordem_servico_repository_firebase.dart';
import 'core/rota_acompanhamento.dart';
import 'Views/acompanhamento_page.dart';
import 'Views/lista_ordens_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Para voltar ao repositório em memória (sem internet), use OrdemServicoRepositoryMemoria().
  final OrdemServicoRepository repositorio = OrdemServicoRepositoryFirebase();
  runApp(AssistenciaApp(repositorio: repositorio));
}

class AssistenciaApp extends StatelessWidget {
  final OrdemServicoRepository repositorio;

  const AssistenciaApp({super.key, required this.repositorio});

  /// Se a URL for um link de acompanhamento, abre a tela do cliente.
  /// Caso contrário, abre a lista de OS do técnico.
  Widget _paginaInicial() {
    final codigo = codigoAcessoDaUrl(Uri.base);
    if (codigo != null) {
      return AcompanhamentoPage(codigoAcesso: codigo, repositorio: repositorio);
    }
    return ListaOrdensPage(repositorio: repositorio);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assistência Técnica',
      debugShowCheckedModeBanner: false,
      // Tema claro e escuro, seguindo a configuração do celular
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: _paginaInicial(),
    );
  }
}