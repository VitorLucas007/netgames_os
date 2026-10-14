/// Lê o código de acesso a partir de uma URL de acompanhamento.
///
/// Aceita os dois formatos:
///   https://dominio/acompanhar/CODIGO
///   https://dominio/#/acompanhar/CODIGO   (hash, usado pelo Flutter Web por padrão)
///
/// Devolve null se a URL não for um link de acompanhamento.
String? codigoAcessoDaUrl(Uri url) {
  const marcador = 'acompanhar/';
  for (final trecho in [url.path, url.fragment]) {
    final i = trecho.indexOf(marcador);
    if (i < 0) continue;
    // Pega só o código, ignorando barras, parâmetros e âncoras depois dele
    final codigo = trecho.substring(i + marcador.length).split(RegExp(r'[/?#]')).first;
    if (codigo.isNotEmpty) return codigo;
  }
  return null;
}