# Exemplos com dados reais

Execute `dart run example/real_world.dart` ou abra a aba **Real data** no laboratório
Flutter. Os dois clientes usam as mesmas classes, dados locais e API assíncrona.
[Fontes, atribuição e hashes](../example/data/README.md) acompanham os snapshots.
Nenhum download é necessário durante a execução.

## Iris: classificação supervisionada

Quatro medidas em centímetros entram em uma MLP de 8 neurônios tanh e saída
softmax de 3 classes. A receita é fixa: seed 42, Adam 0,01, batch 16, clipping 1
e 120 épocas.

Antes de dividir, o exemplo remove linhas exatamente repetidas de atributos/rótulo:
as 150 observações da fonte viram 147 únicas. Cada classe é embaralhada com seed
`42 + índice da classe`; 60% arredondados para baixo vão para treino, 20% para
validação e o restante para teste. Resultado: **87/28/32**. Identidades não se
sobrepõem e nenhum vetor idêntico cruza partições.

O StandardScaler aprende apenas com o treino. A perda de validação é diagnóstica;
o teste reservado é avaliado no relatório final. São exibidas acurácia, macro-F1
e matriz de confusão: linhas reais, colunas previstas. O baseline escolhe a classe
mais frequente no treino, usando o menor índice em caso de empate.

Na execução registrada: **87,5% de acurácia**, macro-F1 **0,8727**, baseline **31,25%**.
Isso descreve uma divisão e uma receita, sem validação cruzada nem seleção do
melhor resultado. Não use o teste publicado para ajustar hiperparâmetros. As
particularidades nas medidas da fonte UCI são preservadas e documentadas.

## AirPassengers: previsão temporal

A série contém 144 observações mensais, de 1949 a 1960, em **milhares de passageiros**.
Uma GRU com 8 unidades recebe os 12 meses anteriores para prever o mês seguinte.

| Partição dos alvos | Período | Quantidade |
| --- | --- | --- |
| Treino | Jan/1950 a dez/1956 | 84 |
| Validação | Jan/1957 a dez/1958 | 24 |
| Teste | Jan/1959 a dez/1960 | 24 |

Os 12 primeiros meses servem de contexto. O log reduz a escala da série; o scaler
é ajustado só com observações até dezembro de 1956. A divisão é cronológica.
Nenhuma janela contém seu próprio alvo ou um mês futuro. Adam 0,01, batch 12,
clipping 1, seed 42, 100 épocas e `shuffle: false` estão definidos previamente.
A validação é reportada; o teste não seleciona a família, pesos ou hiperparâmetros.

O protocolo é de **um passo com histórico observado**. Ao prever fevereiro de
1959, janeiro de 1959 já está disponível. Não é uma previsão recursiva de 24 meses
feita em dezembro de 1958. Janelas podem compartilhar meses anteriores sem que
isso revele o alvo futuro. A transformação inversa e exp devolvem milhares de
passageiros, usados para calcular MAE e RMSE.

Os baselines usam o mês anterior e o mesmo mês do ano anterior, sob o mesmo
protocolo. Na execução registrada:

| Método | MAE em milhares |
| --- | --- |
| GRU | 68,64 |
| Mês anterior | 44,21 |
| Mesmo mês do ano anterior | 47,58 |

A GRU foi pior que os dois baselines. Esse resultado é mantido: ensinar a avaliar
um modelo inclui reconhecer quando uma alternativa simples funciona melhor.
Veja os [resultados registrados](benchmarks/real-world-results.json).

## Onde está cada responsabilidade?

Os parsers e divisões estão em `example/flutter_lab/lib/real_world/*_dataset.dart`. As receitas e
métricas estão em `*_experiment.dart`, implementando `RealWorldExperiment`. O
Flutter separa o runner da renderização em `pages/real_world_page.dart`.

Os testes verificam dados CSV espelhados, identidades sem sobreposição, scaler
ajustado só com treino, janelas causais e baselines conhecidos. Um cancelamento
não gera relatório do teste. O CI não exige que a rede supere o baseline. Para
novos experimentos, defina o protocolo e a receita antes de consultar seu teste.
