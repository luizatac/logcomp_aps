# logcomp_aps


# ParkingScript – Linguagem para Estacionamento Inteligente  

O **ParkingScript** é uma **linguagem de domínio específico (DSL)** criada para simular e controlar estacionamentos de forma simples.  
A ideia é que pessoas leigas (como um síndico ou gerente de estacionamento) possam escrever regras de entrada, saída e alarmes usando comandos próximos da linguagem natural.  


## Contexto  

Gerenciar estacionamentos em prédios, shoppings ou empresas envolve:  
- Controlar o número de vagas disponíveis.  
- Evitar superlotação.  
- Emitir alertas quando vagas são liberadas.  
- Automatizar processos repetitivos de entrada e saída.  

O **ParkingScript** foi criado para atender esse cenário. Ele mostra como problemas práticos podem ser descritos em uma linguagem simples e depois traduzidos em instruções de baixo nível executadas por uma VM minimalista.  

## Exemplo em ParkingScript  

```parking
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

Dispara um alarme.

Remove mais um carro.

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
