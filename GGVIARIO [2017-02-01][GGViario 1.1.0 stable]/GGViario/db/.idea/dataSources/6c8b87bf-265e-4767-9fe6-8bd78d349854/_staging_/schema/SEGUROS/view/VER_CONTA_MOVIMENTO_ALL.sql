create or REPLACE view VER_CONTA_MOVIMENTO_ALL as
SELECT "ID","DOCUMENTO","VALOR","MOVIMENTACAO","CONTA","OBSERVACAO","DATA","REGISTRO","OPERACAO","OP","TP MOV","ID CONTA","DATA_SF","REGISTRO_SF","MOEDA","ID MOEDA","VALOR STD"
   FROM (SELECT ID,
                DOCUMENTO,
                VALOR,
                MOVIMENTACAO,
                CONTA,
                OBSERVACAO,
                DATA,
                REGISTRO,
                COLABORADOR
                OPERACAO,
                OP,
                "TP MOV",
                "ID CONTA",
                DATA_SF,
                REGISTRO_SF,
                "MOEDA",
                "ID MOEDA",
                "VALOR STD"
                
            FROM VER_CONTA_MOVIMENTO_LANCAMENTO LANCA
               UNION (SELECT ID,
                              DOCUMENTO,
                              VALOR,
                              MOVIMENTO,
                              CONTA,
                              OBSERVACAO,
                              DATA,
                              REGISTRO,
                              COLABORADOR
                              OPERACAO,
                              OP,
                              "TP MOV",
                              "ID CONTA",
                              DATA_SF,
                              REGISTRO_SF,
                              "MOEDA",
                              "ID MOEDA",
                              "VALOR STD"
                         FROM VER_CONTA_MOVIMENTO_PAGAMENTO PAY)
               UNION (SELECT ID,
                            DOCUMENTO,
                            VALOR,
                            MOVIMENTO,
                            CONTA,
                            OBSERVACAO,
                            DATA,
                            REGISTRO,
                            COLABORADOR
                            OPERACAO,
                            OP,
                            "TP MOV",
                            "ID CONTA",
                            DATA_SF,
                            REGISTRO_SF,
                            "MOEDA",
                            "ID MOEDA",
                            "VALOR STD"
                         FROM VER_CONTA_MOVIMENTO_RECEBIMENT REC)
        ) CONTAMOV
   ORDER BY CONTAMOV.REGISTRO_SF DESC
