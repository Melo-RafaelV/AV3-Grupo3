-- 1. ALTER TABLE
-- EX: Adiona a coluna de email para os funcionarios
ALTER TABLE FUNCIONARIO
ADD email VARCHAR2(100);

-- 2. CREATE INDEX
-- EX: Cria um indice para a coluna cod_hospede na tabela RESERVA_HOSPEDE
CREATE INDEX idx_reserva_hospede
ON RESERVA_HOSPEDE (cod_hospede);

-- 3. INSERT INTO
-- EX: Cria o novo cargo Concierge e adicionando um novo funcionario para esse cargo.
INSERT INTO CARGOS (salario_base, nome_cargo)
VALUES (2600.00, 'Concierge');
INSERT INTO FUNCIONARIO (cpf, nome, sobrenome, cod_cargo, turno_trabalho, cod_supervisor) 
VALUES ('33333333333', 'Paulo', 'Pereira', (SELECT cod_cargo FROM CARGOS WHERE nome_cargo = 'Concierge'), 'Noite', 1);



-- 4. UPDATE
-- EX: Atuliza o valor dos quartos Standard aumentando seu valor em 10%
UPDATE QUARTO
SET valor = valor * 1.10
WHERE tipo = 'Standard';

-- 5. DELETE
-- EX: Deleta o cargo Concierge
-- OBS: Como o cod_cargo é fk em funcionario tivemos que deletar("demitir") os funcionarios desse cargo e depois deletar o cargo, poderiamos ter colocado em outro cargo usando o UPDATE SET
DELETE FROM FUNCIONARIO
WHERE cod_cargo = (SELECT cod_cargo FROM CARGOS WHERE nome_cargo = 'Concierge');
DELETE FROM CARGOS
WHERE nome_cargo = 'Concierge';

-- 6. SELECT-FROM-WHERE
-- Ex: Lista os dados do recepcionistas que trabalham no periodo da tarde
SELECT f.nome, f.sobrenome, c.nome_cargo, f.turno_trabalho
FROM FUNCIONARIO f
JOIN CARGOS c ON f.cod_cargo = c.cod_cargo
WHERE c.nome_cargo = 'Recepcionista' AND f.turno_trabalho = 'Tarde';

-- 7. BETWEEN
-- EX: Mostra as reservas feitas (checkin) entre 15/11/2025 e 30/11/2025
SELECT cod_reserva, cod_hospede, data_checkin, data_checkout
FROM RESERVA_HOSPEDE
WHERE data_checkin BETWEEN TO_DATE('2025-11-15', 'YYYY-MM-DD')
                   AND TO_DATE('2025-11-30', 'YYYY-MM-DD');

-- 8. IN
-- EX: Lista o nome e o crago dos funcionários que são recepcionista ou gerente geral
SELECT f.nome, c.nome_cargo
FROM FUNCIONARIO f
JOIN CARGOS c ON f.cod_cargo = c.cod_cargo
WHERE c.nome_cargo IN ('Recepcionista', 'Gerente Geral');

-- 9. LIKE
-- EX: Mostra todos os hospedes que o sobrenome começa com a letra S
SELECT nome, sobrenome
FROM HOSPEDE
WHERE sobrenome LIKE 'S%';

-- 10. IS NULL ou IS NOT NULL
-- EX: Mostra os funcionários que não possuem um supervisor
SELECT nome, sobrenome, cod_cargo
FROM FUNCIONARIO
WHERE cod_supervisor IS NULL;

-- 11. INNER JOIN
-- EX: mostra os dados das reservas dos hospedes.
-- Criaremos uma view para isso

SELECT h.nome, h.sobrenome, r.data_checkin, r.data_checkout, q.numero_quarto
FROM HOSPEDE h
INNER JOIN RESERVA_HOSPEDE r ON h.cod_hospede = r.cod_hospede
INNER JOIN QUARTO q ON r.numero_quarto = q.numero_quarto;

-- 12. MAX
-- EX: Mostra o salário mais alto entre os cargos
SELECT MAX(salario_base) AS salario_maximo
FROM CARGOS;

-- 13. MIN
-- EX: Mostra o valor mais barato para um quarto do tipo "Suíte Luxo"
SELECT MIN(valor) AS diaria_min_luxo
FROM QUARTO
WHERE tipo = 'Suíte Luxo';

-- 14. AVG 
-- EX: Calcula o custo médio do aluguel dos salões com base na tabela de agendamentos
SELECT AVG(custo_aluguel) AS media_custo_salao
FROM AGENDAMENTO;

-- 15. COUNT 
-- EX: conta o total de quartos que estão em manutenção
SELECT COUNT(*) AS total_em_manutencao
FROM QUARTO
WHERE status = 'Manutenção';

-- 16. LEFT ou RIGHT ou FULL OUTER JOIN 
-- EX: lista todos os hospedes e se esse hospede tiver feito uma reserva (todos fizeram) mostra os dados dessa reserva

-- INSERINDO UM NOVO HOSPEDE QUE NÂO TENHA FEITO NENHUMA RESERVA APENAS PARA MOSTRAR QUE ESTA FUNCIONANDO O LEFT JOIN
INSERT INTO HOSPEDE (cpf, nome, sobrenome, data_nascimento, cod_endereco) 
VALUES ('22222222222', 'Carlos', 'Costa', TO_DATE('1990-05-15', 'YYYY-MM-DD'), NULL);
UPDATE HOSPEDE SET cod_endereco = 1 WHERE cod_hospede = 10;

SELECT h.nome, h.sobrenome, r.cod_reserva
FROM HOSPEDE h
LEFT JOIN RESERVA_HOSPEDE r ON h.cod_hospede = r.cod_hospede;


-- 17. SUBCONSULTA COM OPERADOR RELACIONAL
-- EX: Mostrando os funcionarios que ganham mais que a media salarial
SELECT f.nome, c.nome_cargo, c.salario_base
FROM FUNCIONARIO f
JOIN CARGOS c ON f.cod_cargo = c.cod_cargo
WHERE c.salario_base > (SELECT AVG(salario_base) FROM CARGOS);

-- 18. SUBCONSULTA COM IN 
-- EX: NOME E SOBRENOME DE TODOS OS HOSPEDES QUE CONTRATARAM UM SERVIÇO NAS SUAS RESERVAS
SELECT nome, sobrenome
FROM HOSPEDE
WHERE cod_hospede IN (
    SELECT r.cod_hospede
    FROM RESERVA_HOSPEDE r
    WHERE r.cod_reserva IN (SELECT c.cod_reserva FROM CONTRATA c)
);

-- 19. SUBCONSULTA COM ANY 
-- EX: Pegando o nome, cargo e o salário de todas os funcionários que ganhma mais que qualquer gerente (todos que ganham mais que o gerente com o menor salário)

SELECT f.nome, c.nome_cargo, c.salario_base
FROM FUNCIONARIO f
JOIN CARGOS c ON f.cod_cargo = c.cod_cargo
WHERE c.salario_base > ANY (
    SELECT c2.salario_base
    FROM CARGOS c2
    WHERE c2.nome_cargo LIKE 'Gerente%');

-- 20. SUBCONSULTA COM ALL 
-- EX: Pega os dados da suíte de luxo mais cara entre todas as suítes de luxo.

SELECT numero_quarto, tipo, valor
FROM QUARTO
WHERE tipo = 'Suíte Luxo'
  AND valor >= ALL (
    SELECT valor
    FROM QUARTO
    WHERE tipo = 'Suíte Luxo'
  );

-- 21. ORDER BY 
-- EX: Listando todos os serviços do mais caro ao mais barato

SELECT descricao, preco_padrao
FROM SERVICO
ORDER BY preco_padrao DESC;


-- 22. GROUP BY 
-- EX: Listando a quantidade de reservas que cada hospede fez
SELECT 
    h.nome || ' ' || h.sobrenome AS nome_hospede,
    h.cod_hospede,
    COUNT(rh.cod_reserva) AS total_de_reservas
FROM RESERVA_HOSPEDE rh
JOIN HOSPEDE h ON rh.cod_hospede = h.cod_hospede
GROUP BY h.cod_hospede, h.nome, h.sobrenome;

-- 23. HAVING
-- Lista os hospedes que fizeram +1 reserva

SELECT h.nome, h.sobrenome, COUNT(r.cod_reserva) AS total_de_reservas
FROM RESERVA_HOSPEDE r
JOIN HOSPEDE h ON r.cod_hospede = h.cod_hospede
GROUP BY h.nome, h.sobrenome
HAVING COUNT(r.cod_reserva) > 1;

-- 24. UNION ou INTERSECT ou MINUS (UNION)
-- EX: Criando uma lista com todas as pessoas presentes nos bancos de dados e identificando se são funcionarias ou hospedes.

SELECT nome, sobrenome, cpf, 'Hospede' AS tipo
FROM HOSPEDE
UNION
SELECT nome, sobrenome, cpf, 'Funcionario' AS tipo
FROM FUNCIONARIO;

-- 25. CREATE VIEW
-- EX: Criando uma view para detalhar dados das reservas, juntando os dados: nome_hospede, cpf, cod_reserva, data_checkin, data_checkout, numero_quarto, tipo_quarto e valor em um unico lugar

CREATE VIEW v_detalhes_reserva AS
SELECT
    h.nome || ' ' || h.sobrenome AS nome_hospede,
    h.cpf,
    r.cod_reserva,
    r.data_checkin,
    r.data_checkout,
    q.numero_quarto,
    q.tipo AS tipo_quarto,
    r.valor_total_diarias
FROM HOSPEDE h
JOIN RESERVA_HOSPEDE r ON h.cod_hospede = r.cod_hospede
JOIN QUARTO q ON r.numero_quarto = q.numero_quarto;

  -- consultando a view
SELECT * FROM v_detalhes_reserva WHERE nome_hospede = 'Lucas Gomes';

-- 26. GRANT
-- EX: Dando permissão para usuarios do tipo "recepcao" fazer SELECT na view criada no item 25.
GRANT SELECT ON v_detalhes_reserva TO recepcao;

-- REVOKE:
-- EX: retirando a permissão dada os usuarios do tipo "recepcao" no item 26.

REVOKE SELECT ON v_detalhes_reserva FROM recepcao;
