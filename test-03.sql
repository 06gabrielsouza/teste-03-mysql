-- 1. Configuração inicial para permitir importação de arquivos locais
SET GLOBAL local_infile = 1;

-- 2. Criação do banco de dados
CREATE DATABASE IF NOT EXISTS desafio_ans 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE desafio_ans;

-- Tabela de operadoras ativas corrigida
CREATE TABLE IF NOT EXISTS operadoras_ativas (
    registro_ans VARCHAR(20) PRIMARY KEY,
    cnpj VARCHAR(18),
    razao_social VARCHAR(255),
    nome_fantasia VARCHAR(255),
    modalidade VARCHAR(100),
    logradouro VARCHAR(255),
    numero VARCHAR(20),
    complemento VARCHAR(100),
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    uf VARCHAR(2),
    cep VARCHAR(10),
    ddd VARCHAR(4),
    telefone VARCHAR(20),
    fax VARCHAR(20),
    email VARCHAR(100),
    representante VARCHAR(100),
    cargo_representante VARCHAR(100),
    data_registro_ans DATE,
    INDEX idx_razao_social (razao_social(100)),
    INDEX idx_nome_fantasia (nome_fantasia(100))
) ENGINE=InnoDB;  

-- 4. Criação da tabela de demonstrações contábeis
CREATE TABLE IF NOT EXISTS demonstracoes_contabeis (
    id INT AUTO_INCREMENT PRIMARY KEY,
    registro_ans VARCHAR(20),
    competencia VARCHAR(7),
    conta_contabil VARCHAR(50),
    descricao VARCHAR(255),
    valor DECIMAL(15, 2),
    FOREIGN KEY (registro_ans) REFERENCES operadoras_ativas(registro_ans)
) ENGINE=InnoDB;

-- 5. Verificação do diretório seguro
SHOW VARIABLES LIKE 'secure_file_priv';

-- 6. Importação dos dados das operadoras
LOAD DATA LOCAL INFILE 'C:/dados_ans/operadoras/Relatorio_cadop.csv'
INTO TABLE operadoras_ativas
CHARACTER SET latin1
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(registro_ans, cnpj, razao_social, nome_fantasia, modalidade, 
 logradouro, numero, complemento, bairro, cidade, uf, @cep,
 ddd, telefone, fax, email, representante, cargo_representante, 
 @data_registro_ans)
SET 
    data_registro_ans = STR_TO_DATE(@data_registro_ans, '%d/%m/%Y'),
    cep = REPLACE(REPLACE(@cep, '.', ''), '-', '');

-- 7. Importação das demonstrações contábeis (exemplo para 1T2023)
LOAD DATA LOCAL INFILE 'C:/dados_ans/demonstracoes/1T2023.csv'
INTO TABLE demonstracoes_contabeis
CHARACTER SET latin1
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(registro_ans, competencia, conta_contabil, descricao, @valor)
SET 
    valor = REPLACE(REPLACE(@valor, '.', ''), ',', '.');

-- 8. Consultas analíticas

-- Top 10 operadoras com maiores despesas no último trimestre
SELECT 
    o.razao_social,
    o.nome_fantasia,
    FORMAT(SUM(d.valor), 2) AS total_despesas
FROM 
    demonstracoes_contabeis d
JOIN 
    operadoras_ativas o ON d.registro_ans = o.registro_ans
WHERE 
    d.descricao LIKE '%EVENTOS/%SINISTROS CONHECIDOS OU AVISADOS DE ASSISTÊNCIA A SAÚDE MEDICO HOSPITALAR%'
    AND RIGHT(d.competencia, 4) = YEAR(CURDATE())
    AND LEFT(d.competencia, 1) IN (
        SELECT LEFT(competencia, 1) 
        FROM demonstracoes_contabeis 
        WHERE RIGHT(competencia, 4) = YEAR(CURDATE())
        ORDER BY competencia DESC 
        LIMIT 1
    )
GROUP BY 
    o.razao_social, o.nome_fantasia
ORDER BY 
    SUM(d.valor) DESC
LIMIT 10;

-- Top 10 operadoras com maiores despesas no último ano
SELECT 
    o.razao_social,
    o.nome_fantasia,
    FORMAT(SUM(d.valor), 2) AS total_despesas_anual
FROM 
    demonstracoes_contabeis d
JOIN 
    operadoras_ativas o ON d.registro_ans = o.registro_ans
WHERE 
    d.descricao LIKE '%EVENTOS/%SINISTROS CONHECIDOS OU AVISADOS DE ASSISTÊNCIA A SAÚDE MEDICO HOSPITALAR%'
    AND RIGHT(d.competencia, 4) = YEAR(CURDATE())
GROUP BY 
    o.razao_social, o.nome_fantasia
ORDER BY 
    SUM(d.valor) DESC
LIMIT 10;

