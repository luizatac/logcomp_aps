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
```
   vagas 10

Define a capacidade inicial do estacionamento.

- **Entrada de veículos**
```
   entrada 2

Dois veículos entram.

- **Saída de veículos**
 ```
   saida 1

Um veículo sai.

- **Alarme**
 ```
   alarme

Emite um sinal (equivalente a PRINT).

- **Laços condicionais**
 ```
   enquanto vagas > 0 {
   alarme
   saida 1
      }

Executa o bloco de comandos enquanto a condição for verdadeira.

- **Parada do programa**
 ```
   parar

Encerra programa.


## Exemplo em ParkingScript  

      vagas 3
      entrada 2
      saida 1
      
      enquanto vagas > 0 {
         alarme
         saida 1
      }
      
      parar

## Explicação:

Define o estacionamento com 3 vagas.

2 carros entram, reduzindo as vagas.

1 carro sai, liberando uma vaga.

Enquanto ainda houver vagas:

     * Dispara um alarme.

     * Remove mais um carro.

O programa encerra com parar.

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

