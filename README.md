# logcomp_aps


# ParkingScript – Linguagem para Estacionamento Inteligente  

O controle de estacionamentos é um problema cotidiano em prédios residenciais, shoppings e empresas.  
Gerenciar a quantidade de vagas, organizar entradas e saídas de veículos e emitir alertas quando o estacionamento está cheio são tarefas essenciais para evitar transtornos.  

O **ParkingScript** resolve esse problema ao oferecer uma **linguagem de domínio específico (DSL)** com comandos simples e intuitivos.

## Contexto  

Gerenciar estacionamentos em prédios, shoppings ou empresas envolve:  
- Controlar o número de vagas disponíveis.  
- Evitar superlotação.  
- Emitir alertas quando vagas são liberadas.  
- Automatizar processos repetitivos de entrada e saída.  

A ideia principal do **ParkingScript** é estar **integrado à cancela do estacionamento**, servindo como “programa auxiliar” para os manobristas.  
Assim, quando o estacionamento estiver cheio, a cancela **bloqueia automaticamente a entrada de novos veículos**, evitando confusões.  
Da mesma forma, quando vagas são liberadas, o sistema pode **alertar** os funcionários.  

## Funcionalidades  

- **Definição de vagas**

        vagas X

Define a capacidade inicial do estacionamento de X vagas.

- **Entrada de veículos**

       entrada Y

Y veículos entram (vagas diminuem).

- **Saída de veículos**
 
       saida Z

Z veículo sai.

- **Alarme**

       alarme

Emite um sinal (equivalente a PRINT na VM).

- **Laços condicionais**

         enquanto vagas > 0 {
         alarme
         saida Z
            }

Executa o bloco de comandos enquanto a condição for verdadeira.

- **Parada do programa**
 
       parar

Encerra programa.


## Exemplo em ParkingScript 

```text
vagas 5

entrada 2
saida 1
alarme

enquanto vagas > 0 {
  entrada 2
  alarme
}

parar
```

## Explicação:

* Define o estacionamento com 5 vagas.
* entrada 2 → entram 2 carros → vagas passam a 3.
* saida 1 → sai 1 carro → vagas passam a 4.
* alarme → imprime 4 (estado atual das vagas).

Depois, o laço:

* enquanto vagas > 0:

       * entrada 2 → vagas diminuem de 2 em 2 (saturando em 0).
       * alarme → imprime o número de vagas restantes.

* Quando as vagas chegam a 0, a condição falha e o laço termina.

* parar encerra o programa.

## Gramática (EBNF)

            Programa      = { Declaracao | Comando } ;

            Declaracao    = "vagas" Numero ;          (* define a capacidade inicial *)
            
            Comando       = Entrada
                          | Saida
                          | Alarme
                          | Enquanto
                          | Parar ;
            
            Entrada       = "entrada" Numero ;        (* simula entrada de N carros *)
            Saida         = "saida" Numero ;          (* simula saída de N carros  *)
            Alarme        = "alarme" ;                (* emite sinal sonoro/print  *)
            Parar         = "parar" ;                 (* encerra execução          *)
            
            Enquanto      = "enquanto" Condicao "{" { Comando } "}" ;
            
            Condicao      = "vagas" Operador Numero ;
            
            Operador      = ">" | "<" | "==" ;
            
            Numero        = Digit { Digit } ;
            Digit         = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;

Observação de implementação:
embora a gramática permita operadores >, < e == com qualquer número,
a implementação final usada na APS suporta e valida especificamente o caso
enquanto vagas > 0.


### Estrutura das pastas

              parking-script/
              ├─ src/
              │  ├─ parking.l        # lexer (Flex)
              │  ├─ parking.y        # parser + geração de código Microwave 
              │  ├─ main.c           # ponto de entrada (chama yyparse)
              │  └─ parking_test.ps  # exemplo de programa em ParkingScript
              ├─ out/                # saída gerada (por ex. parking_test.mwasm)
              ├─ Makefile
              └─ README.md

Arquivos gerados automaticamente pelo make (podem ser recriados):

* lex.yy.c
* parking.tab.c
* parking.tab.h
* parking_parser (binário do compilador)      

### VM de destino: MicrowaveVM

Para tornar a linguagem executável, o ParkingScript é compilado para o assembly
da MicrowaveVM, uma máquina virtual minimalista (estilo Minsky) com dois registradores principais:

* TIME – registrador de propósito geral (32 bits).
* POWER – registrador auxiliar de propósito geral.

Instruções da MicrowaveVM usadas pelo compilador:

* SET R n – define o registrador R com o valor n.
* INC R – incrementa R em 1.
* DECJZ R label – se R == 0, salta para label; senão, decrementa R.
* GOTO label – salto incondicional.
* PRINT – imprime o valor atual de TIME.
* HALT – encerra o programa.

#### Mapeamento ParkingScript → MicrowaveVM

Na implementação:

* O registrador TIME representa o número de vagas livres.
* O registrador POWER é usado como contador auxiliar em laços internos.

#### Traduções principais:

| Comando ParkingScript | Descrição | Código MicrowaveVM (Assembly) |
| :--- | :--- | :--- |
| `vagas N` | Inicializa o número de vagas. | `SET TIME N` |
| `entrada N` | Tenta diminuir `TIME` em N (decrementa até 0). | `SET POWER N`<br>`Lentrada:`<br>`DECJZ POWER Lentrada_end`<br>`DECJZ TIME Lentrada`<br>`GOTO Lentrada`<br>`Lentrada_end:` |
| `saida N` | Aumenta `TIME` em N. | `SET POWER N`<br>`Lsaida:`<br>`DECJZ POWER Lsaida_end`<br>`INC TIME`<br>`GOTO Lsaida`<br>`Lsaida_end:` |
| `alarme` | Imprime o valor atual de `TIME`. | `PRINT` |
| `enquanto vagas > 0` | Laço enquanto `TIME` > 0. | `Lloop:`<br>`DECJZ TIME Lend`<br>`INC TIME`<br>`... corpo do while ...`<br>`GOTO Lloop`<br>`Lend:` |
| `parar` | Encerra o programa. | `HALT` |
         

### Como compilar o compilador da linguagem

#### Passos:

1. Entrar na pasta do compilador:
```bash
cd parking-script
```

2. Compilar com:
```bash
make
```
      
* Isso gera o executável parking_parser na pasta parking-script      

### Como gerar o código para a MicrowaveVM

Ainda na pasta parking-script:

```bash
./parking_parser src/parking_test.ps out/parking_test.mwasm
```

O arquivo out/parking_test.mwasm é o programa da MicrowaveVM correspondente ao
exemplo em ParkingScript.

### Como rodar o programa na MicrowaveVM

1. Clonar o repositório da MicrowaveVM em uma pasta paralela a que contem tudo do Parking Script

2. Executar o programa gerado:

```bash
# na pasta da VM
cd MicrowaveVM

# rodar o arquivo gerado pelo compilador da linguagem (nesse caso os nomes dos arquivos são os do meu repositório)
python3 main.py ../logcomp_aps/parking-script/out/parking_test.mwasm
```

* Saída esperada (exemplo)

```text
Loaded program from: ../logcomp_aps/parking-script/out/parking_test.mwasm
TIME: 4
TIME: 2
TIME: 0
BEEEEEPP!
Final state: {'TIME': 0, 'POWER': 0}
Final readonly state: {'TEMP': 0, 'WEIGHT': 100}
Final stack: []
```

* TIME: 4 → estado após vagas 5, entrada 2, saida 1.
* TIME: 2, TIME: 0 → estados impressos dentro do enquanto vagas > 0.
* BEEEEEPP! → programa finalizado com HALT.

```