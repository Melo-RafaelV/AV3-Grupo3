-- 1. Criação das sequências para os ids

CREATE SEQUENCE seq_hospede START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_end_hospede START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_funcionario START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_cargo START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_quarto START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_servico START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_reserva START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_contrato START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_salao START WITH 1 INCREMENT BY 1;

-- 2. Criação das Tabelas
CREATE TABLE ENDERECO_HOSPEDE ( 
    cod_endereco NUMBER(10) DEFAULT seq_end_hospede.NEXTVAL NOT NULL, 
    cod_hospede  NUMBER(10) NOT NULL, 
    rua          VARCHAR2(200) NOT NULL, 
    numero       VARCHAR2(20), 
    cidade       VARCHAR2(100) NOT NULL, 
     
    CONSTRAINT pk_endereco PRIMARY KEY (cod_endereco), 
     
    CONSTRAINT uk_endereco_detalhes UNIQUE (rua, numero, cidade) 

);

CREATE TABLE HOSPEDE ( 
    cod_hospede     NUMBER(10) DEFAULT seq_hospede.NEXTVAL NOT NULL, 
    cpf             VARCHAR2(11) NOT NULL, 
    nome            VARCHAR2(50) NOT NULL, 
    sobrenome       VARCHAR2(100) NOT NULL, 
    data_nascimento DATE, 
    cod_endereco    NUMBER(10), 
     
    CONSTRAINT pk_hospede PRIMARY KEY (cod_hospede), 
     
    CONSTRAINT uk_hospede_cpf UNIQUE (cpf), 
 
    CONSTRAINT fk_hospede_endereco FOREIGN KEY (cod_endereco)  
        REFERENCES ENDERECO_HOSPEDE(cod_endereco) 
);

-- Adicionando cod_hospede como fk em endereço depois de criar as tabelas para não dar erro (dependencia circular) 
-- e permitir que o enderço seja deletado cajo o hospede for deletado


ALTER TABLE ENDERECO_HOSPEDE 
ADD CONSTRAINT fk_endereco_hospede 
FOREIGN KEY (cod_hospede) 
REFERENCES HOSPEDE(cod_hospede) 
ON DELETE CASCADE;

CREATE TABLE HOSPEDE_TELEFONES (  
    cod_hospede NUMBER(10) NOT NULL,  
    telefone VARCHAR2(20) NOT NULL,  
    CONSTRAINT pk_hospede_telefones PRIMARY KEY (cod_hospede, telefone),  
    CONSTRAINT fk_telefone_hospede FOREIGN KEY (cod_hospede) REFERENCES HOSPEDE(cod_hospede) ON DELETE CASCADE  
);

CREATE TABLE DEPENDENTE (  
    cod_hospede NUMBER(10) NOT NULL,  
    nome_dependente VARCHAR2(150) NOT NULL,  
    parentesco VARCHAR2(30),  
    CONSTRAINT pk_dependente PRIMARY KEY (cod_hospede, nome_dependente),  
    CONSTRAINT fk_dependente_hospede FOREIGN KEY (cod_hospede) REFERENCES HOSPEDE(cod_hospede) ON DELETE CASCADE  
);

CREATE TABLE CARGOS (  
    cod_cargo NUMBER(10) DEFAULT seq_cargo.NEXTVAL NOT NULL,  
    salario_base NUMBER(10, 2) NOT NULL,  
    nome_cargo VARCHAR2(50) NOT NULL,  
    CONSTRAINT pk_cargos PRIMARY KEY (cod_cargo),  
    CONSTRAINT ck_salario_positivo CHECK (salario_base > 0)  
);

CREATE TABLE FUNCIONARIO (  
    cod_funcionario NUMBER(10) DEFAULT seq_funcionario.NEXTVAL NOT NULL,  
    cpf VARCHAR2(11) NOT NULL,  
    nome VARCHAR2(50) NOT NULL,  
    sobrenome VARCHAR2(100) NOT NULL,  
    cod_cargo NUMBER(10) NOT NULL,  
    turno_trabalho VARCHAR2(20),  
    cod_supervisor NUMBER(10),  
    CONSTRAINT pk_funcionario PRIMARY KEY (cod_funcionario),  
    CONSTRAINT uk_funcionario_cpf UNIQUE (cpf),  
    CONSTRAINT fk_funcionario_cargo FOREIGN KEY (cod_cargo) REFERENCES CARGOS(cod_cargo),  
    CONSTRAINT fk_funcionario_supervisor FOREIGN KEY (cod_supervisor) REFERENCES FUNCIONARIO(cod_funcionario),  
    CONSTRAINT ck_turno_trabalho CHECK (turno_trabalho IN ('Manhã', 'Tarde', 'Noite', 'Integral'))  
);

CREATE TABLE GERENTE (  
    cod_funcionario NUMBER(10) NOT NULL,  
    bonus_anual NUMBER(10, 2),  
    departamento_gerenciado VARCHAR2(50),  
    CONSTRAINT pk_gerente PRIMARY KEY (cod_funcionario),  
    CONSTRAINT fk_gerente_funcionario FOREIGN KEY (cod_funcionario) REFERENCES FUNCIONARIO(cod_funcionario) ON DELETE CASCADE  
);

CREATE TABLE RECEPCIONISTA (  
    cod_funcionario NUMBER(10) NOT NULL,  
    ramal_telefonico VARCHAR2(10),  
    CONSTRAINT pk_recepcionista PRIMARY KEY (cod_funcionario),  
    CONSTRAINT fk_recepcionista_funcionario FOREIGN KEY (cod_funcionario) REFERENCES FUNCIONARIO(cod_funcionario) ON DELETE CASCADE  
);

CREATE TABLE RECEPCIONISTA_IDIOMAS (  
    cod_funcionario NUMBER(10) NOT NULL,  
    idioma VARCHAR2(30) NOT NULL,  
    CONSTRAINT pk_recepcionista_idiomas PRIMARY KEY (cod_funcionario, idioma),  
    CONSTRAINT fk_idioma_recepcionista FOREIGN KEY (cod_funcionario) REFERENCES RECEPCIONISTA(cod_funcionario) ON DELETE CASCADE  
);

CREATE TABLE QUARTO (  
    numero_quarto NUMBER(4) DEFAULT seq_quarto.NEXTVAL NOT NULL,  
    andar NUMBER(3) NOT NULL,  
    tipo VARCHAR2(50),  
    status VARCHAR2(20),  
    valor NUMBER(10, 2) NOT NULL,  
    CONSTRAINT pk_quarto PRIMARY KEY (numero_quarto),  
    CONSTRAINT ck_quarto_status CHECK (status IN ('Disponível', 'Ocupado', 'Manutenção', 'Limpeza'))  
);

CREATE TABLE SERVICO (  
    cod_servico NUMBER(10) DEFAULT seq_servico.NEXTVAL NOT NULL,  
    descricao VARCHAR2(200) NOT NULL,  
    preco_padrao NUMBER(10, 2) NOT NULL,  
    CONSTRAINT pk_servico PRIMARY KEY (cod_servico)  
);

CREATE TABLE RESERVA_HOSPEDE (  
    cod_reserva NUMBER(10) DEFAULT seq_reserva.NEXTVAL NOT NULL,  
    data_checkin DATE NOT NULL,  
    data_checkout DATE NOT NULL,  
    valor_total_diarias NUMBER(12, 2),  
    cod_hospede NUMBER(10) NOT NULL,  
    numero_quarto NUMBER(4) NOT NULL,  
    CONSTRAINT pk_reserva_hospede PRIMARY KEY (cod_reserva),  
    CONSTRAINT fk_reserva_hospede FOREIGN KEY (cod_hospede) REFERENCES HOSPEDE(cod_hospede),  
    CONSTRAINT fk_reserva_quarto FOREIGN KEY (numero_quarto) REFERENCES QUARTO(numero_quarto),  
    CONSTRAINT ck_datas_reserva CHECK (data_checkout > data_checkin)  
);

CREATE TABLE CONTRATA (  
    cod_contrato NUMBER(10) DEFAULT seq_contrato.NEXTVAL NOT NULL,  
    cod_reserva NUMBER(10) NOT NULL,  
    cod_servico NUMBER(10) NOT NULL,  
    data_solicitacao DATE NOT NULL,  
    quantidade_contratada NUMBER(3),  
    preco_cobrado NUMBER(10, 2),  
    CONSTRAINT pk_contrata PRIMARY KEY (cod_contrato),  
    CONSTRAINT fk_contrata_reserva FOREIGN KEY (cod_reserva) REFERENCES RESERVA_HOSPEDE(cod_reserva) ON DELETE CASCADE,  
    CONSTRAINT fk_contrata_servico FOREIGN KEY (cod_servico) REFERENCES SERVICO(cod_servico)  
);

CREATE TABLE SALAO_DE_EVENTOS (  
    cod_salao NUMBER(10) DEFAULT seq_salao.NEXTVAL NOT NULL,  
    nome_salao VARCHAR2(100) NOT NULL,  
    capacidade_salao NUMBER(4),  
    CONSTRAINT pk_salao_eventos PRIMARY KEY (cod_salao)  
);

CREATE TABLE AGENDAMENTO ( 
    cod_salao        NUMBER NOT NULL, 
    cod_funcionario  NUMBER NOT NULL, 
    cod_hospede      NUMBER NOT NULL, 
    data_evento      DATE NOT NULL, 
    horario_inicio   TIMESTAMP, 
    horario_fim      TIMESTAMP, 
    custo_aluguel    NUMBER(10, 2), 
 
    CONSTRAINT pk_agendamento  
        PRIMARY KEY (cod_salao, cod_funcionario, cod_hospede, horario_inicio), 
 
    CONSTRAINT fk_agendamento_salao  
        FOREIGN KEY (cod_salao)  
        REFERENCES SALAO_DE_EVENTOS(cod_salao), 
 
    CONSTRAINT fk_agendamento_funcionario  
        FOREIGN KEY (cod_funcionario)  
        REFERENCES FUNCIONARIO(cod_funcionario), 
 
    CONSTRAINT fk_agendamento_hospede  
        FOREIGN KEY (cod_hospede)  
        REFERENCES HOSPEDE(cod_hospede) 
);





-- 3. Povoando CARGOS
INSERT INTO CARGOS (salario_base, nome_cargo) VALUES (8000.00, 'Gerente Geral');
INSERT INTO CARGOS (salario_base, nome_cargo) VALUES (3500.00, 'Recepcionista');
INSERT INTO CARGOS (salario_base, nome_cargo) VALUES (2200.00, 'Camareira');
INSERT INTO CARGOS (salario_base, nome_cargo) VALUES (2800.00, 'Chefe de Cozinha');
INSERT INTO CARGOS (salario_base, nome_cargo) VALUES (4500.00, 'Gerente de TI');
INSERT INTO CARGOS (salario_base, nome_cargo) VALUES (2100.00, 'Manobrista');
INSERT INTO CARGOS (salario_base, nome_cargo) VALUES (3800.00, 'Analista de TI');
INSERT INTO CARGOS (salario_base, nome_cargo) VALUES (1900.00, 'Auxiliar de Limpeza');
INSERT INTO CARGOS (salario_base, nome_cargo) VALUES (2300.00, 'Garçom');
INSERT INTO CARGOS (salario_base, nome_cargo) VALUES (2500.00, 'Segurança');
INSERT INTO CARGOS (salario_base, nome_cargo) VALUES (6500.00, 'Gerente de RH');

-- 4. Povoando QUARTO

INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (101, 1, 'Standard', 'Disponível', 250.00);
INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (102, 1, 'Standard', 'Disponível', 250.00);
INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (201, 2, 'Suíte Luxo', 'Ocupado', 600.00);
INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (202, 2, 'Suíte Luxo', 'Disponível', 600.00);
INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (301, 3, 'Standard', 'Manutenção', 250.00);
INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (302, 3, 'Standard', 'Limpeza', 250.00);
INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (401, 4, 'Suíte Presidencial', 'Disponível', 1200.00);
INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (402, 4, 'Suíte Luxo', 'Disponível', 650.00);
INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (501, 5, 'Standard', 'Disponível', 270.00);
INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (502, 5, 'Standard', 'Disponível', 270.00);
INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (103, 1, 'Standard', 'Limpeza', 250.00);
INSERT INTO QUARTO (numero_quarto, andar, tipo, status, valor) VALUES (203, 2, 'Suíte Luxo', 'Manutenção', 600.00);

-- 5. Povoando Serviços

INSERT INTO SERVICO (descricao, preco_padrao) VALUES ('Café da Manhã no Quarto', 50.00);
INSERT INTO SERVICO (descricao, preco_padrao) VALUES ('Serviço de Lavanderia (por peça)', 15.00);
INSERT INTO SERVICO (descricao, preco_padrao) VALUES ('Frigobar - Bebida Alcoólica', 20.00);
INSERT INTO SERVICO (descricao, preco_padrao) VALUES ('Frigobar - Snack', 12.00);
INSERT INTO SERVICO (descricao, preco_padrao) VALUES ('Estacionamento com Manobrista (diária)', 40.00);
INSERT INTO SERVICO (descricao, preco_padrao) VALUES ('Massagem Relaxante (1h)', 180.00);
INSERT INTO SERVICO (descricao, preco_padrao) VALUES ('Aluguel de Bicicleta (diária)', 35.00);
INSERT INTO SERVICO (descricao, preco_padrao) VALUES ('Jantar Especial no Quarto', 120.00);
INSERT INTO SERVICO (descricao, preco_padrao) VALUES ('Garrafa de Vinho Seleção', 90.00);
INSERT INTO SERVICO (descricao, preco_padrao) VALUES ('Babysitting (por hora)', 60.00);

-- 6. Povoamento de Salão

INSERT INTO SALAO_DE_EVENTOS (nome_salao, capacidade_salao) VALUES ('Salão Rubi', 100);
INSERT INTO SALAO_DE_EVENTOS (nome_salao, capacidade_salao) VALUES ('Salão Esmeralda', 50);
INSERT INTO SALAO_DE_EVENTOS (nome_salao, capacidade_salao) VALUES ('Sala de Reuniões Topázio', 20);
INSERT INTO SALAO_DE_EVENTOS (nome_salao, capacidade_salao) VALUES ('Salão Diamante', 250);
INSERT INTO SALAO_DE_EVENTOS (nome_salao, capacidade_salao) VALUES ('Sala de Reuniões Ágata', 15);
INSERT INTO SALAO_DE_EVENTOS (nome_salao, capacidade_salao) VALUES ('Auditório Safira', 300);
INSERT INTO SALAO_DE_EVENTOS (nome_salao, capacidade_salao) VALUES ('Terraço Jade', 80);
INSERT INTO SALAO_DE_EVENTOS (nome_salao, capacidade_salao) VALUES ('Espaço Gourmet Ametista', 40);

-- 7. Povoando FUNCIONARIO e especializações


INSERT INTO FUNCIONARIO (cpf, nome, sobrenome, cod_cargo, turno_trabalho, cod_supervisor) 
VALUES ('11122233344', 'Carlos', 'Maia', 1, 'Integral', NULL);
INSERT INTO GERENTE (cod_funcionario, bonus_anual, departamento_gerenciado) 
VALUES (1, 15000.00, 'Operações'); 

INSERT INTO FUNCIONARIO (cpf, nome, sobrenome, cod_cargo, turno_trabalho, cod_supervisor) 
VALUES ('22233344455', 'Ana', 'Beatriz', 2, 'Manhã', 1);
INSERT INTO RECEPCIONISTA (cod_funcionario, ramal_telefonico) 
VALUES (2, '1000'); 
INSERT INTO RECEPCIONISTA_IDIOMAS (cod_funcionario, idioma) VALUES (2, 'Inglês');
INSERT INTO RECEPCIONISTA_IDIOMAS (cod_funcionario, idioma) VALUES (2, 'Espanhol');

INSERT INTO FUNCIONARIO (cpf, nome, sobrenome, cod_cargo, turno_trabalho, cod_supervisor) 
VALUES ('33344455566', 'Joana', 'Silva', 3, 'Tarde', 1);

INSERT INTO FUNCIONARIO (cpf, nome, sobrenome, cod_cargo, turno_trabalho, cod_supervisor) 
VALUES ('44455566677', 'Ricardo', 'Tavares', 4, 'Integral', 1);

INSERT INTO FUNCIONARIO (cpf, nome, sobrenome, cod_cargo, turno_trabalho, cod_supervisor) 
VALUES ('55566677788', 'Bruno', 'Mendes', 2, 'Noite', 1);
INSERT INTO RECEPCIONISTA (cod_funcionario, ramal_telefonico) 
VALUES (5, '1001'); 
INSERT INTO RECEPCIONISTA_IDIOMAS (cod_funcionario, idioma) VALUES (5, 'Inglês');
INSERT INTO RECEPCIONISTA_IDIOMAS (cod_funcionario, idioma) VALUES (5, 'Francês');


INSERT INTO FUNCIONARIO (cpf, nome, sobrenome, cod_cargo, turno_trabalho, cod_supervisor) 
VALUES ('66677788899', 'Marcos', 'Almeida', 11, 'Integral', 1);
INSERT INTO GERENTE (cod_funcionario, bonus_anual, departamento_gerenciado) 
VALUES (6, 10000.00, 'Recursos Humanos');


INSERT INTO FUNCIONARIO (cpf, nome, sobrenome, cod_cargo, turno_trabalho, cod_supervisor) 
VALUES ('77788899900', 'Leticia', 'Carvalho', 2, 'Tarde', 1);
INSERT INTO RECEPCIONISTA (cod_funcionario, ramal_telefonico) 
VALUES (7, '1002'); 
INSERT INTO RECEPCIONISTA_IDIOMAS (cod_funcionario, idioma) VALUES (7, 'Inglês');
INSERT INTO RECEPCIONISTA_IDIOMAS (cod_funcionario, idioma) VALUES (7, 'Alemão');


INSERT INTO FUNCIONARIO (cpf, nome, sobrenome, cod_cargo, turno_trabalho, cod_supervisor) 
VALUES ('88899900011', 'Fernando', 'Pereira', 9, 'Noite', 1);


INSERT INTO FUNCIONARIO (cpf, nome, sobrenome, cod_cargo, turno_trabalho, cod_supervisor) 
VALUES ('99900011122', 'Sandra', 'Oliveira', 10, 'Integral', 1);


INSERT INTO FUNCIONARIO (cpf, nome, sobrenome, cod_cargo, turno_trabalho, cod_supervisor) 
VALUES ('00011122233', 'Tiago', 'Ribeiro', 5, 'Integral', 1);
INSERT INTO GERENTE (cod_funcionario, bonus_anual, departamento_gerenciado) 
VALUES (10, 9000.00, 'TI');


-- 8. Povoando HOSPEDE, ENDERECO_HOSPEDE, TELEFONES e DEPENDENTES


INSERT INTO HOSPEDE (cpf, nome, sobrenome, data_nascimento, cod_endereco) 
VALUES ('77788899911', 'Lucas', 'Gomes', TO_DATE('1990-05-15', 'YYYY-MM-DD'), NULL);
INSERT INTO ENDERECO_HOSPEDE (cod_hospede, rua, numero, cidade) 
VALUES (1, 'Rua das Flores', '123', 'São Paulo');
UPDATE HOSPEDE SET cod_endereco = 1 WHERE cod_hospede = 1;

INSERT INTO HOSPEDE_TELEFONES (cod_hospede, telefone) VALUES (1, '11987654321');
INSERT INTO HOSPEDE_TELEFONES (cod_hospede, telefone) VALUES (1, '1122334455');
INSERT INTO DEPENDENTE (cod_hospede, nome_dependente, parentesco) VALUES (1, 'Julia Gomes', 'Filha');

INSERT INTO HOSPEDE (cpf, nome, sobrenome, data_nascimento, cod_endereco) 
VALUES ('88899911122', 'Mariana', 'Alves', TO_DATE('1985-10-20', 'YYYY-MM-DD'), NULL);
INSERT INTO ENDERECO_HOSPEDE (cod_hospede, rua, numero, cidade) 
VALUES (2, 'Avenida Principal', '456B', 'Rio de Janeiro');
UPDATE HOSPEDE SET cod_endereco = 2 WHERE cod_hospede = 2;

INSERT INTO HOSPEDE_TELEFONES (cod_hospede, telefone) VALUES (2, '21912345678');

INSERT INTO HOSPEDE (cpf, nome, sobrenome, data_nascimento, cod_endereco) 
VALUES ('99911122233', 'Rafael', 'Costa', TO_DATE('1995-02-28', 'YYYY-MM-DD'), NULL);
INSERT INTO ENDERECO_HOSPEDE (cod_hospede, rua, numero, cidade) 
VALUES (3, 'Rua da Moeda', '789', 'Recife');
UPDATE HOSPEDE SET cod_endereco = 3 WHERE cod_hospede = 3;

INSERT INTO HOSPEDE_TELEFONES (cod_hospede, telefone) VALUES (3, '81999998888');
INSERT INTO DEPENDENTE (cod_hospede, nome_dependente, parentesco) VALUES (3, 'Pedro Costa', 'Filho');
INSERT INTO DEPENDENTE (cod_hospede, nome_dependente, parentesco) VALUES (3, 'Ana Costa', 'Esposa');

INSERT INTO HOSPEDE (cpf, nome, sobrenome, data_nascimento, cod_endereco) 
VALUES ('11133355577', 'Beatriz', 'Lima', TO_DATE('2001-07-10', 'YYYY-MM-DD'), NULL);
INSERT INTO ENDERECO_HOSPEDE (cod_hospede, rua, numero, cidade) 
VALUES (4, 'Praça da Sé', 'S/N', 'Salvador');
UPDATE HOSPEDE SET cod_endereco = 4 WHERE cod_hospede = 4;

INSERT INTO HOSPEDE_TELEFONES (cod_hospede, telefone) VALUES (4, '71988887777');


INSERT INTO HOSPEDE (cpf, nome, sobrenome, data_nascimento, cod_endereco) 
VALUES ('22244466688', 'Fernanda', 'Souza', TO_DATE('1998-11-03', 'YYYY-MM-DD'), NULL);
INSERT INTO ENDERECO_HOSPEDE (cod_hospede, rua, numero, cidade) 
VALUES (5, 'Rua Nova', '10A', 'Belo Horizonte');
UPDATE HOSPEDE SET cod_endereco = 5 WHERE cod_hospede = 5;
INSERT INTO HOSPEDE_TELEFONES (cod_hospede, telefone) VALUES (5, '31988776655');
INSERT INTO DEPENDENTE (cod_hospede, nome_dependente, parentesco) VALUES (5, 'Bruno Souza', 'Irmão');


INSERT INTO HOSPEDE (cpf, nome, sobrenome, data_nascimento, cod_endereco) 
VALUES ('33355577799', 'Guilherme', 'Martins', TO_DATE('1975-01-20', 'YYYY-MM-DD'), NULL);
INSERT INTO ENDERECO_HOSPEDE (cod_hospede, rua, numero, cidade) 
VALUES (6, 'Avenida Atlântica', '1200', 'Rio de Janeiro');
UPDATE HOSPEDE SET cod_endereco = 6 WHERE cod_hospede = 6;
INSERT INTO HOSPEDE_TELEFONES (cod_hospede, telefone) VALUES (6, '21988889999');
INSERT INTO HOSPEDE_TELEFONES (cod_hospede, telefone) VALUES (6, '2122334455');


INSERT INTO HOSPEDE (cpf, nome, sobrenome, data_nascimento, cod_endereco) 
VALUES ('44466688800', 'Clara', 'Nunes', TO_DATE('1992-09-12', 'YYYY-MM-DD'), NULL);
INSERT INTO ENDERECO_HOSPEDE (cod_hospede, rua, numero, cidade) 
VALUES (7, 'Rua da Aurora', '505', 'Recife');
UPDATE HOSPEDE SET cod_endereco = 7 WHERE cod_hospede = 7;
INSERT INTO HOSPEDE_TELEFONES (cod_hospede, telefone) VALUES (7, '81977776666');
INSERT INTO DEPENDENTE (cod_hospede, nome_dependente, parentesco) VALUES (7, 'Davi Nunes', 'Filho');
INSERT INTO DEPENDENTE (cod_hospede, nome_dependente, parentesco) VALUES (7, 'Marcos Andrade', 'Marido');


INSERT INTO HOSPEDE (cpf, nome, sobrenome, data_nascimento, cod_endereco) 
VALUES ('55577799911', 'Vitor', 'Barros', TO_DATE('2000-03-05', 'YYYY-MM-DD'), NULL);
INSERT INTO ENDERECO_HOSPEDE (cod_hospede, rua, numero, cidade) 
VALUES (8, 'Rua Augusta', '800', 'São Paulo');
UPDATE HOSPEDE SET cod_endereco = 8 WHERE cod_hospede = 8;
INSERT INTO HOSPEDE_TELEFONES (cod_hospede, telefone) VALUES (8, '11966554433');


INSERT INTO HOSPEDE (cpf, nome, sobrenome, data_nascimento, cod_endereco) 
VALUES ('66688800022', 'Larissa', 'Melo', TO_DATE('1988-08-18', 'YYYY-MM-DD'), NULL);
INSERT INTO ENDERECO_HOSPEDE (cod_hospede, rua, numero, cidade) 
VALUES (9, 'Quadra 301', 'Lote 5', 'Brasília');
UPDATE HOSPEDE SET cod_endereco = 9 WHERE cod_hospede = 9;
INSERT INTO HOSPEDE_TELEFONES (cod_hospede, telefone) VALUES (9, '61955443322');


-- 9. Povoando RESERVA_HOSPEDE
INSERT INTO RESERVA_HOSPEDE (data_checkin, data_checkout, valor_total_diarias, cod_hospede, numero_quarto) 
VALUES (TO_DATE('2025-11-10', 'YYYY-MM-DD'), TO_DATE('2025-11-15', 'YYYY-MM-DD'), 1250.00, 1, 101);

INSERT INTO RESERVA_HOSPEDE (data_checkin, data_checkout, valor_total_diarias, cod_hospede, numero_quarto) 
VALUES (TO_DATE('2025-10-30', 'YYYY-MM-DD'), TO_DATE('2025-11-02', 'YYYY-MM-DD'), 1800.00, 2, 201);

INSERT INTO RESERVA_HOSPEDE (data_checkin, data_checkout, valor_total_diarias, cod_hospede, numero_quarto) 
VALUES (TO_DATE('2025-11-20', 'YYYY-MM-DD'), TO_DATE('2025-11-22', 'YYYY-MM-DD'), 500.00, 3, 102);

INSERT INTO RESERVA_HOSPEDE (data_checkin, data_checkout, valor_total_diarias, cod_hospede, numero_quarto) 
VALUES (TO_DATE('2025-12-01', 'YYYY-MM-DD'), TO_DATE('2025-12-05', 'YYYY-MM-DD'), 4800.00, 4, 401);
INSERT INTO RESERVA_HOSPEDE (data_checkin, data_checkout, valor_total_diarias, cod_hospede, numero_quarto) 
VALUES (TO_DATE('2025-12-20', 'YYYY-MM-DD'), TO_DATE('2025-12-26', 'YYYY-MM-DD'), 3600.00, 1, 202);

INSERT INTO RESERVA_HOSPEDE (data_checkin, data_checkout, valor_total_diarias, cod_hospede, numero_quarto) 
VALUES (TO_DATE('2025-11-05', 'YYYY-MM-DD'), TO_DATE('2025-11-08', 'YYYY-MM-DD'), 810.00, 5, 501);

INSERT INTO RESERVA_HOSPEDE (data_checkin, data_checkout, valor_total_diarias, cod_hospede, numero_quarto) 
VALUES (TO_DATE('2025-11-12', 'YYYY-MM-DD'), TO_DATE('2025-11-18', 'YYYY-MM-DD'), 3900.00, 6, 402);

INSERT INTO RESERVA_HOSPEDE (data_checkin, data_checkout, valor_total_diarias, cod_hospede, numero_quarto) 
VALUES (TO_DATE('2025-11-16', 'YYYY-MM-DD'), TO_DATE('2025-11-18', 'YYYY-MM-DD'), 500.00, 7, 101);

INSERT INTO RESERVA_HOSPEDE (data_checkin, data_checkout, valor_total_diarias, cod_hospede, numero_quarto) 
VALUES (TO_DATE('2025-11-25', 'YYYY-MM-DD'), TO_DATE('2025-11-30', 'YYYY-MM-DD'), 1250.00, 8, 102);

INSERT INTO RESERVA_HOSPEDE (data_checkin, data_checkout, valor_total_diarias, cod_hospede, numero_quarto) 
VALUES (TO_DATE('2025-12-10', 'YYYY-MM-DD'), TO_DATE('2025-12-15', 'YYYY-MM-DD'), 3000.00, 9, 202);



-- 10. Povoando CONTRATA
INSERT INTO CONTRATA (cod_reserva, cod_servico, data_solicitacao, quantidade_contratada, preco_cobrado) 
VALUES (1, 1, TO_DATE('2025-11-10', 'YYYY-MM-DD'), 2, 100.00);
INSERT INTO CONTRATA (cod_reserva, cod_servico, data_solicitacao, quantidade_contratada, preco_cobrado) 
VALUES (1, 2, TO_DATE('2025-11-11', 'YYYY-MM-DD'), 5, 75.00);
INSERT INTO CONTRATA (cod_reserva, cod_servico, data_solicitacao, quantidade_contratada, preco_cobrado) 
VALUES (2, 3, TO_DATE('2025-10-30', 'YYYY-MM-DD'), 4, 80.00);
INSERT INTO CONTRATA (cod_reserva, cod_servico, data_solicitacao, quantidade_contratada, preco_cobrado) 
VALUES (2, 5, TO_DATE('2025-10-30', 'YYYY-MM-DD'), 3, 120.00);
INSERT INTO CONTRATA (cod_reserva, cod_servico, data_solicitacao, quantidade_contratada, preco_cobrado) 
VALUES (3, 1, TO_DATE('2025-11-20', 'YYYY-MM-DD'), 1, 50.00);
INSERT INTO CONTRATA (cod_reserva, cod_servico, data_solicitacao, quantidade_contratada, preco_cobrado) 
VALUES (3, 4, TO_DATE('2025-11-20', 'YYYY-MM-DD'), 3, 36.00);
INSERT INTO CONTRATA (cod_reserva, cod_servico, data_solicitacao, quantidade_contratada, preco_cobrado) 
VALUES (6, 8, TO_DATE('2025-11-05', 'YYYY-MM-DD'), 1, 120.00);

INSERT INTO CONTRATA (cod_reserva, cod_servico, data_solicitacao, quantidade_contratada, preco_cobrado) 
VALUES (6, 7, TO_DATE('2025-11-06', 'YYYY-MM-DD'), 2, 70.00);

INSERT INTO CONTRATA (cod_reserva, cod_servico, data_solicitacao, quantidade_contratada, preco_cobrado) 
VALUES (7, 9, TO_DATE('2025-11-12', 'YYYY-MM-DD'), 2, 180.00);

INSERT INTO CONTRATA (cod_reserva, cod_servico, data_solicitacao, quantidade_contratada, preco_cobrado) 
VALUES (7, 5, TO_DATE('2025-11-12', 'YYYY-MM-DD'), 6, 240.00);

INSERT INTO CONTRATA (cod_reserva, cod_servico, data_solicitacao, quantidade_contratada, preco_cobrado) 
VALUES (10, 6, TO_DATE('2025-12-11', 'YYYY-MM-DD'), 2, 360.00);

-- 11. Povoando AGENDAMENTO
INSERT INTO AGENDAMENTO (cod_salao, cod_funcionario, cod_hospede, data_evento, horario_inicio, horario_fim, custo_aluguel) 
VALUES (
    1, 2, 1, 
    TO_DATE('2025-11-13', 'YYYY-MM-DD'), 
    TO_TIMESTAMP('2025-11-13 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    TO_TIMESTAMP('2025-11-13 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    1500.00
);

INSERT INTO AGENDAMENTO (cod_salao, cod_funcionario, cod_hospede, data_evento, horario_inicio, horario_fim, custo_aluguel) 
VALUES (
    2,  5, 2, 
    TO_DATE('2025-11-01', 'YYYY-MM-DD'), 
    TO_TIMESTAMP('2025-11-01 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    TO_TIMESTAMP('2025-11-01 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    700.00
);

INSERT INTO AGENDAMENTO (cod_salao, cod_funcionario, cod_hospede, data_evento, horario_inicio, horario_fim, custo_aluguel) 
VALUES (
    3,2, 3, 
    TO_DATE('2025-11-21', 'YYYY-MM-DD'), 
    TO_TIMESTAMP('2025-11-21 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    TO_TIMESTAMP('2025-11-21 17:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    1000.00
);

INSERT INTO AGENDAMENTO (cod_salao, cod_funcionario, cod_hospede, data_evento, horario_inicio, horario_fim, custo_aluguel) 
VALUES (
    4,  7, 5, 
    TO_DATE('2025-11-07', 'YYYY-MM-DD'), 
    TO_TIMESTAMP('2025-11-07 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    TO_TIMESTAMP('2025-11-07 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    2500.00
);

INSERT INTO AGENDAMENTO (cod_salao, cod_funcionario, cod_hospede, data_evento, horario_inicio, horario_fim, custo_aluguel) 
VALUES (
    5, 9, 6, 
    TO_DATE('2025-11-15', 'YYYY-MM-DD'), 
    TO_TIMESTAMP('2025-11-15 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    TO_TIMESTAMP('2025-11-15 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    600.00
);

INSERT INTO AGENDAMENTO (cod_salao, cod_funcionario, cod_hospede, data_evento, horario_inicio, horario_fim, custo_aluguel) 
VALUES (
    6,2, 8, 
    TO_DATE('2025-11-28', 'YYYY-MM-DD'), 
    TO_TIMESTAMP('2025-11-28 08:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    TO_TIMESTAMP('2025-11-28 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 3000.00
);

INSERT INTO AGENDAMENTO (cod_salao, cod_funcionario, cod_hospede, data_evento, horario_inicio, horario_fim, custo_aluguel) 
VALUES (
    7,5, 9, 
    TO_DATE('2025-12-12', 'YYYY-MM-DD'), 
    TO_TIMESTAMP('2025-12-12 19:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    TO_TIMESTAMP('2025-12-12 23:00:00', 'YYYY-MM-DD HH24:MI:SS'), 1200.00
);

INSERT INTO AGENDAMENTO (cod_salao, cod_funcionario, cod_hospede, data_evento, horario_inicio, horario_fim, custo_aluguel) 
VALUES (
    8,7, 7, 
    TO_DATE('2025-11-17', 'YYYY-MM-DD'), 
    TO_TIMESTAMP('2025-11-17 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    TO_TIMESTAMP('2025-11-17 15:00:00', 'YYYY-MM-DD HH24:MI:SS'), 800.00
);

COMMIT;