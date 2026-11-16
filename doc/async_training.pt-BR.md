# Treinamento assíncrono — 0.3.0

A API está no código da próxima 0.3.0; não faz parte da versão publicada 0.2.1.
Use o checkout do repositório até a publicação. O núcleo continua em Dart puro.

## Qual execução escolher?

| Caminho | Dart/Flutter nativo | Web | Modelos e extensões |
| --- | --- | --- | --- |
| `AsyncTrainingTask.start(request)` | Isolate dedicado | Mini-batches cooperativos | MLP, CNN, RNN, LSTM, GRU, Adam/SGD e MSE/BCE/CCE |
| `TrainingExecution.cooperative` | Mesmo isolate, com pausas entre lotes | Event loop do navegador | Mesmos codecs do worker |
| `TrainingExecution.isolate` | Isolate dedicado | Retorna UnsupportedError | Mesmos codecs do worker |
| `TrainingSession<I>.fitAsync(...)` | Execução cooperativa | Execução cooperativa | Também aceita modelo, perda e otimizador personalizados |

O autoencoder usa o modelo denso. O SOM mantém seu treinamento competitivo e sua
própria curva de decaimento; não é tratado como uma sessão supervisionada.

O modo `automatic` escolhe o caminho da plataforma. Consulte `task.execution` para
saber qual foi escolhido. O worker recebe cópias dos dados, pesos e estado do
Adam/SGD. O modelo original não é alterado: restaure o checkpoint retornado para
fazer previsões. A cópia/serialização inicial ocorre na thread chamadora.

## Exemplo completo

Execute `dart run example/async_training.dart`. Ele:

1. Cria uma MLP para XOR, Adam e seed 42.
2. Treina uma referência síncrona por 80 épocas.
3. Inicia uma tarefa assíncrona e observa o progresso por época.
4. Solicita cancelamento e recebe o checkpoint da última época completa.
5. Faz uma ida e volta pelo JSON, retoma até 80 e compara o checkpoint inteiro.

Trecho central, usando a função `request` do exemplo:

```dart
final task = AsyncTrainingTask.start(request(session.checkpoint(), 100));
final subscription = task.progress.listen((progress) {
  print('Época ${progress.epochsCompleted}: ${progress.loss}');
  if (progress.epochsThisRun >= 20) task.cancel();
});
final result = await task.result;
await subscription.cancel();
final json = jsonEncode(result.checkpoint.toJson());
```

A requisição recebe o checkpoint, entradas, alvos, `TrainingLoss`, número de épocas
e tamanho do lote. A assinatura e o exemplo integral estão no
[guia em inglês](async_training.md#start-observe-cancel-and-resume) e no
[arquivo executável](../example/async_training.dart). Para CNN, as entradas são
`ImageTensor`; para recorrentes, listas de vetores por sequência; para MLP, vetores.

## Cancelar não significa perder o treino

O cancelamento é cooperativo: termina a época em andamento, preserva os momentos
do otimizador e devolve um checkpoint coerente. Um isolate pode começar outra época
antes de receber a mensagem. Use a contagem retornada, sem presumir a época exata.
Cancelamento antes de iniciar devolve o checkpoint intacto com histórico vazio.
Cancelamento depois de concluir não muda o resultado.

Para continuar, calcule `meta - result.checkpoint.epochsCompleted` e faça outra
requisição a partir desse checkpoint. O JSON mantém pesos, momentos, contagem de
épocas e seed do embaralhamento. Dados e configuração da perda permanecem com a
aplicação. Preserve também lote, clipping, ordem, SDK e plataforma. Não há promessa
de igualdade bit a bit entre nativo e JavaScript.

`TrainingProgress` informa época absoluta, épocas desta execução, total solicitado,
perda, perda de validação opcional e tempo decorrido. A fração refere-se à execução
atual. O histórico retornado contém só esta execução. Validação reporta a perda;
essa API usa épocas fixas e não restaura automaticamente os melhores pesos.

Inscreva-se no stream imediatamente: ele não reenvia eventos antigos. Aguarde
`task.result` para capturar erros; o stream fecha tanto em sucesso quanto em falha.
Cancelar a inscrição não cancela o treino. `cancel()` é idempotente. Ao descartar
uma tela, cancele a tarefa e a inscrição. As portas nativas são fechadas ao final.
Falhas no isolate produzem `TrainingWorkerException`, com mensagem e stack remota.
O caminho cooperativo preserva o tipo original do erro. Não há checkpoint novo
em caso de falha: mantenha o último snapshot válido.

## Por que a web precisa de outra estratégia?

Isolates não estão disponíveis nesse caminho de compilação web. O mesmo executor
numérico da API síncrona passa a ceder tempo ao navegador após cada mini-batch,
usando um timer de duração zero. Uma microtask sozinha não permitiria renderizar
ou receber entrada. `batchesPerYield` controla a frequência das pausas.

Isso não é paralelismo nem Web Worker. Um lote grande, o gradiente de uma sequência
longa, a avaliação do conjunto completo e a serialização ainda são operações
síncronas. Reduza lotes/modelos/dados quando essas unidades demorarem. A API não
promete um limite rígido de duração de frame ou latência de cancelamento.

## Extensibilidade

`customSession.fitAsync` aceita os mesmos contratos externos de modelo, perda e
CheckpointOptimizer, mais `TrainingCancellation` e `onProgress`. O modelo precisa
de JsonModel para gerar o checkpoint. O consumidor independente em
`example/extensions` demonstra a retomada assíncrona de um modelo linear com Huber
e Momentum próprios. O worker portátil aceita somente codecs internos; extensões
em isolate precisam de uma entrada de worker definida pela aplicação.

Não altere modelo ou dados enquanto uma sessão cooperativa estiver ativa. A API
rejeita fit, fitAsync e checkpoint concorrentes. Sessões que falharam precisam
ser restauradas. Uma exceção no callback de progresso também falha a sessão.

## Laboratório Flutter

Na aba **Async training**, escolha a família, defina a meta e inicie. O contador
continua clicável durante o treino. Você pode trocar de aba, acompanhar métricas,
cancelar, copiar o JSON e fechar a tela. Ao voltar, cole/carregue e retome. A
comparação com treino contínuo também roda de forma assíncrona. O gráfico mostra
só a execução atual; copiar o JSON é necessário para persistir fora do aplicativo.
As abas anteriores continuam como exemplos independentes de visualização.

No XOR, a validação reutiliza a tabela verdade. Os outros exemplos mudam ruído ou
fase de dados sintéticos. Isso não demonstra generalização em problemas reais.

A [estrutura](architecture/structure.md), os
[diagramas de classes](architecture/class_diagrams.md) e o
[ciclo de treinamento](architecture/training.md) descrevem as responsabilidades.
Os testes comparam os cinco modelos com Adam e SGD nos dois modos, cancelamento,
retomada, erros, dados isolados, contratos externos e interação Flutter. O exemplo
Dart também é compilado para JavaScript e exige um marcador de conclusão no Node.
