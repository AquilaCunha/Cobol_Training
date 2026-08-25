>>SOURCE FORMAT FREE
IDENTIFICATION DIVISION.
PROGRAM-ID. LANCAMENTO-FINANCEIRO.

DATA DIVISION.
WORKING-STORAGE SECTION.
01 WS-TIPO              PIC X.
01 WS-VALOR             PIC 9(7)V99 VALUE ZERO.
01 WS-SALDO             PIC S9(7)V99 VALUE 1000.

PROCEDURE DIVISION.
    DISPLAY "Saldo atual: " WS-SALDO
    DISPLAY "Tipo do lancamento (C=credito, D=debito): " WITH NO ADVANCING
    ACCEPT WS-TIPO
    DISPLAY "Valor: " WITH NO ADVANCING
    ACCEPT WS-VALOR

    EVALUATE WS-TIPO
        WHEN "C"
            ADD WS-VALOR TO WS-SALDO
            DISPLAY "Credito registrado."
        WHEN "D"
            SUBTRACT WS-VALOR FROM WS-SALDO
            DISPLAY "Debito registrado."
        WHEN OTHER
            DISPLAY "Tipo invalido; nenhum lancamento foi registrado."
    END-EVALUATE
    DISPLAY "Saldo atualizado: " WS-SALDO
    GOBACK.
