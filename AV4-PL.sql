-- 1) Criação de função reutilizável para calcular o valor total das diárias de uma reserva com base no preço do quarto e nas datas.
-- Utilização de 5 (CREATE FUNCTION), 6 (%TYPE), 13 (SELECT... INTO), 15 (EXCEPTINO WHEN), 16 (USO DE IN).

CREATE OR REPLACE FUNCTION calcular_valor_estadia ( -- Parâmetros
    p_numero_quarto IN QUARTO.numero_quarto%TYPE,
    p_data_checkin IN RESERVA_HOSPEDE.data_checkin%TYPE,
    p_data_checkout IN RESERVA_HOSPEDE.data_checkout%TYPE
)
RETURN NUMBER IS
    -- Declaração de variáveis locais
    v_valor_diaria QUARTO.valor%TYPE;
    v_total_dias NUMBER;
    v_valor_total NUMBER;
BEGIN
    -- Busca o valor da diária do quarto e armazena na variável
    SELECT valor INTO v_valor_diaria
    FROM QUARTO
    WHERE numero_quarto = p_numero_quarto;

    -- Calcula o número de dias.
    v_total_dias := TRUNC(p_data_checkout) - TRUNC(p_data_checkin);
    
    -- Se o check-in e check-out forem no mesmo dia, cobra 1 diária
    IF v_total_dias = 0 THEN
        v_total_dias := 1;
    END IF;

    v_valor_total := v_valor_diaria * v_total_dias;

    RETURN v_valor_total;

EXCEPTION
    -- Trata o erro se o quarto não for encontrado
    WHEN NO_DATA_FOUND THEN
        -- Retorna -1 para indicar um erro (quarto não existe)
        RETURN -1;
    WHEN OTHERS THEN
        RETURN -1;
END calcular_valor_estadia;
/

-- 2) Criação de função para calcular taxa de Late Check-out - taxa por hora que o hóspede atrasa o check-out
-- Utilização de 5 (CREATE FUNCTION), 11 (WHILE LOOP)
CREATE OR REPLACE FUNCTION calcular_late_checkout (
    p_hora_saida_real IN TIMESTAMP,
    p_taxa_por_hora IN NUMBER
)
RETURN NUMBER IS
    v_hora_checkout_padrao TIMESTAMP := TRUNC(p_hora_saida_real) + INTERVAL '12' HOUR;
    v_hora_atraso_calculada TIMESTAMP := v_hora_checkout_padrao;
    v_taxa_total NUMBER := 0;
BEGIN
    -- Se a hora de saída for antes ou igual ao padrão (12:00), não há taxa.
    IF p_hora_saida_real <= v_hora_checkout_padrao THEN
        RETURN 0;
    END IF;

    WHILE v_hora_atraso_calculada < p_hora_saida_real LOOP
        -- Adiciona a taxa pela hora de atraso
        v_taxa_total := v_taxa_total + p_taxa_por_hora; 
        
        -- Incrementa a hora de dívida em 1 hora
        v_hora_atraso_calculada := v_hora_atraso_calculada + INTERVAL '1' HOUR;
        
    END LOOP;

    RETURN v_taxa_total;

END calcular_late_checkout;
/

-- 3) Criação de Package que terá um procedimento para buscar os dependentes de um hóspede.

-- Package Specification
-- Utilização de 1 (RECORD), 2 (ESTRUTURA TABLE), 4 (PROCEDURE), 16 (USO DE IN & OUT), 17 (CREATE OR REPLACE PACKAGE)
CREATE OR REPLACE PACKAGE pkg_gerencia_hospede AS

    -- Definição de um tipo de registro customizado para armazenar um dependente
    TYPE rec_dependente IS RECORD (
        nome_dependente DEPENDENTE.nome_dependente%TYPE,
        parentesco DEPENDENTE.parentesco%TYPE
    );

    -- Definição de um tipo "tabela" (array) que pode armazenar uma lista dos registros
    TYPE tab_dependentes IS TABLE OF rec_dependente INDEX BY BINARY_INTEGER;

    -- Declaração de procedimento que o pacote oferecerá
    PROCEDURE sp_listar_dependentes (
        p_cod_hospede IN  HOSPEDE.cod_hospede%TYPE,
        p_lista_deps OUT tab_dependentes,
        p_total_deps OUT NUMBER
    );

END pkg_gerencia_hospede;
/

-- Package Body
-- Utilização de 7 (%ROWTYPE), 10 (LOOP EXIT WHEN), 14 (CURSOR), 16 (USO DE IN & OUT), 18 (CREATE OR REPLACE PACKAGE BODY).
CREATE OR REPLACE PACKAGE BODY pkg_gerencia_hospede AS

    -- Implementação do procedimento declarado na Specification
    PROCEDURE sp_listar_dependentes (
        p_cod_hospede IN HOSPEDE.cod_hospede%TYPE,
        p_lista_deps OUT tab_dependentes,
        p_total_deps OUT NUMBER
    ) IS
    
        -- Declara uma variável que pode armazenar uma linha inteira da tabela DEPENDENTE
        v_dep_linha DEPENDENTE%ROWTYPE;
        
        -- Um cursor é necessário para processar múltiplas linhas de um SELECT
        CURSOR c_dependentes IS
            SELECT * FROM DEPENDENTE
            WHERE cod_hospede = p_cod_hospede;
            
        v_contador NUMBER := 0;
        
    BEGIN
        -- Abre o cursor, executando a consulta
        OPEN c_dependentes;
        
        -- Loop para ler o cursor
        LOOP
            -- Busca uma linha do cursor e armazena na nossa variável %ROWTYPE
            FETCH c_dependentes INTO v_dep_linha;
            
            -- Sai do loop quando não houver mais linhas para buscar
            EXIT WHEN c_dependentes%NOTFOUND;
            
            -- Incrementa o contador e preenche a tabela de saída
            v_contador := v_contador + 1;
            p_lista_deps(v_contador).nome_dependente := v_dep_linha.nome_dependente;
            p_lista_deps(v_contador).parentesco := v_dep_linha.parentesco;
            
        END LOOP;
        
        -- Define o total de dependentes encontrados
        p_total_deps := v_contador;
        
        -- Fecha o cursor para liberar os recursos
        CLOSE c_dependentes;
        
    EXCEPTION
        WHEN OTHERS THEN
            p_total_deps := 0;
            IF c_dependentes%ISOPEN THEN
                CLOSE c_dependentes;
            END IF;
    END sp_listar_dependentes;

END pkg_gerencia_hospede;
/


-- 4) Criação de Triggers para automatizar algumas tarefas.
-- Utilização de 8 (IF ELSIF), 9 (CASE WHEN), 19 (CREATE OR REPLACE TRIGGER - COMANDO), 20 (CREATE OR REPLACE TRIGGER - LINHA).

-- Dispara no console se o valor do quarto foi alterado na tabela QUARTO
CREATE OR REPLACE TRIGGER trg_audita_valor_quarto
    AFTER UPDATE OF valor ON QUARTO
    FOR EACH ROW -- Trigger de linha
BEGIN
    IF :OLD.valor != :NEW.valor THEN
        DBMS_OUTPUT.PUT_LINE('AUDITORIA: Valor do Quarto ' || :NEW.numero_quarto || ' alterado de ' || :OLD.valor || ' para ' || :NEW.valor);
    END IF;
END;
/

-- Dispara por comando e impede alguém de alterar a tabela CARGOS fora do horário comercial
CREATE OR REPLACE TRIGGER trg_bloqueio_edicao_cargos
    BEFORE INSERT OR UPDATE OR DELETE ON CARGOS
DECLARE
    v_dia_semana VARCHAR2(10);
BEGIN
    -- Pega o dia da semana
    v_dia_semana := TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH');

    -- Verifica o dia da semana
    CASE v_dia_semana
        WHEN 'SAT' THEN
            RAISE_APPLICATION_ERROR(-20001, 'Alterações na tabela CARGOS são proibidas aos Sábados.');
        WHEN 'SUN' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Alterações na tabela CARGOS são proibidas aos Domingos.');
        ELSE
            NULL; -- Permite a operação em dias de semana
    END CASE;

    IF INSERTING THEN
        DBMS_OUTPUT.PUT_LINE('Tentativa de INSERÇÃO em CARGOS permitida.');
    ELSIF UPDATING THEN
        DBMS_OUTPUT.PUT_LINE('Tentativa de UPDATE em CARGOS permitida.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- Se qualquer erro acontecer, ele será relançado
        RAISE;
END;
/


-- 5) Criação de Bloco Anônimo para executar e testar os subprogramas criados
-- Utilização de 3 (BLOCO ANÔNIMO), 11 (WHILE LOOP), 12 (FOR IN LOOP).
SET SERVEROUTPUT ON;

DECLARE -- Bloco Anônimo
    -- Variáveis para usar na função 1
    v_valor_calculado NUMBER;
    v_quarto_teste QUARTO.numero_quarto%TYPE := 101; -- Quarto 101, que custa 250
    
    -- Variáveis para usar na função 2
    v_taxa_late_checkout NUMBER;
    v_hora_saida_teste TIMESTAMP := TO_TIMESTAMP('2025-11-05 14:30:00', 'YYYY-MM-DD HH24:MI:SS'); -- Saída às 14:30
    
    -- Variáveis para usar no pacote
    v_hospede_teste HOSPEDE.cod_hospede%TYPE := 3; -- Hóspede 3 (Rafael Costa)
    v_lista pkg_gerencia_hospede.tab_dependentes;
    v_total NUMBER;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('-- TESTE DAS IMPLEMENTAÇÕES --');

    -- Testando a Função do valor de estadia
    v_valor_calculado := calcular_valor_estadia(
        p_numero_quarto => v_quarto_teste,
        p_data_checkin  => TO_DATE('2025-12-01', 'YYYY-MM-DD'),
        p_data_checkout => TO_DATE('2025-12-06', 'YYYY-MM-DD')
    );
    DBMS_OUTPUT.PUT_LINE('Função: Valor calculado para 5 dias no quarto ' || v_quarto_teste || ': R$' || v_valor_calculado);

    -- Testando a função de late check-out
    v_taxa_late_checkout := calcular_late_checkout(
        p_hora_saida_real => v_hora_saida_teste,
        p_taxa_por_hora   => 50.00 -- R$50,00 por hora de atraso
    );
    DBMS_OUTPUT.PUT_LINE('Função Late Checkout: Saída às 14:30. Taxa de atraso: R$' || v_taxa_late_checkout); -- (Deve dar R$ 150,00)

    -- Testando o Pacote
    pkg_gerencia_hospede.sp_listar_dependentes(
        p_cod_hospede  => v_hospede_teste,
        p_lista_deps   => v_lista,
        p_total_deps   => v_total
    );
    
    DBMS_OUTPUT.PUT_LINE('Pacote: Hóspede ' || v_hospede_teste || ' tem ' || v_total || ' dependente(s):');
    
    -- FOR IN LOOP para varrer a tabela (array) que o pacote retornou
    IF v_total > 0 THEN
        FOR i IN 1..v_total LOOP
            DBMS_OUTPUT.PUT_LINE('  -> Dependente: ' || v_lista(i).nome_dependente || ' (' || v_lista(i).parentesco || ')');
        END LOOP;
    END IF;

    -- Testando o TRIGGER de Linha
    DBMS_OUTPUT.PUT_LINE('Trigger: Atualizando valor do quarto 101...');
    UPDATE QUARTO SET valor = 260.00 WHERE numero_quarto = 101;
    ROLLBACK; -- Desfazendo a alteração

EXCEPTION
    -- Tratamento de erro genérico para o bloco anônimo
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERRO GERAL NO BLOCO ANÔNIMO: ' || SQLERRM);
END;
/
