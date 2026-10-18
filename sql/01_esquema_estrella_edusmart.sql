-- ============================================================================
-- UNIVERSIDAD INDOAMÉRICA (UTI)
-- FACULTAD DE INGENIERÍA Y CIENCIAS APLICADAS
-- Asignatura : Ciencia de Datos / Inteligencia de Negocios / Data Warehouse
-- Caso Base  : Sistema de Matriculación Universitaria 'EduSmart'
-- Base Datos : db_edusmart_uti
-- Motor SGBD : PostgreSQL 15+
-- Contenido  : 1. Diseño Físico DDL (Esquema en Estrella y Claves Sustitutas)
--              2. Carga de Datos DML (Poblado de Dimensiones y Hechos por SK)
--              3. Evaluación Nivel 1 (Consultas Fact JOIN Dim con SK)
--              4. Evaluación Nivel 2 (Agregaciones GROUP BY, ORDER BY y HAVING)
-- ============================================================================

-- Limpieza previa opcional (permite re-ejecutar el script de forma idempotente)
DROP TABLE IF EXISTS Fact_Matricula CASCADE;
DROP TABLE IF EXISTS Dim_Tiempo CASCADE;
DROP TABLE IF EXISTS Dim_Facultad CASCADE;
DROP TABLE IF EXISTS Dim_Curso CASCADE;
DROP TABLE IF EXISTS Dim_Estudiante CASCADE;

-- ============================================================================
-- SECCIÓN 1: DISEÑO FÍSICO Y CREACIÓN DEL ESQUEMA EN ESTRELLA (DDL)
-- ============================================================================

-- 1.1. Tabla Dimensión Estudiante
CREATE TABLE Dim_Estudiante (
    SK_Estudiante SERIAL PRIMARY KEY,      -- Surrogate Key (Clave Sustituta OLAP)
    ID_Estudiante_NK INT NOT NULL,         -- Natural Key (Clave Operacional OLTP)
    Nombre_Estudiante VARCHAR(100) NOT NULL,
    Provincia_Origen VARCHAR(50) NOT NULL
);

-- 1.2. Tabla Dimensión Curso
CREATE TABLE Dim_Curso (
    SK_Curso SERIAL PRIMARY KEY,           -- Surrogate Key (Clave Sustituta OLAP)
    ID_Curso_NK INT NOT NULL,              -- Natural Key (Clave Operacional OLTP)
    Nombre_Curso VARCHAR(100) NOT NULL,
    Creditos INT NOT NULL
);

-- 1.3. Tabla Dimensión Facultad
CREATE TABLE Dim_Facultad (
    SK_Facultad SERIAL PRIMARY KEY,        -- Surrogate Key (Clave Sustituta OLAP)
    ID_Facultad_NK INT NOT NULL,           -- Natural Key (Clave Operacional OLTP)
    Nombre_Facultad VARCHAR(100) NOT NULL
);

-- 1.4. Tabla Dimensión Tiempo
CREATE TABLE Dim_Tiempo (
    SK_Tiempo INT PRIMARY KEY,             -- Formato YYYYMMDD (Ej: 20261006)
    Fecha DATE NOT NULL,
    Anio INT NOT NULL,
    Trimestre INT NOT NULL,
    Mes INT NOT NULL,
    Nombre_Mes VARCHAR(20) NOT NULL,
    Dia INT NOT NULL
);

-- 1.5. Tabla de Hechos: Fact_Matricula
-- Grano: Una fila representa la inscripción individual de un estudiante
--        en un curso específico para un periodo lectivo determinado.
CREATE TABLE Fact_Matricula (
    -- Claves Foráneas referenciando estrictamente a las Claves Sustitutas (SK)
    SK_Estudiante INT NOT NULL,
    SK_Curso INT NOT NULL,
    SK_Facultad INT NOT NULL,
    SK_Tiempo INT NOT NULL,

    -- Métricas / Hechos Cuantitativos
    Monto_Pagado_USD NUMERIC(10, 2) NOT NULL,
    Porcentaje_Descuento_Beca NUMERIC(5, 2) DEFAULT 0.00,
    Cantidad_Matriculas INT DEFAULT 1,

    -- Clave Primaria Compuesta
    CONSTRAINT PK_Fact_Matricula PRIMARY KEY (SK_Estudiante, SK_Curso, SK_Facultad, SK_Tiempo),

    -- Restricciones de Integridad Referencial hacia Dimensiones
    CONSTRAINT FK_Fact_Estudiante FOREIGN KEY (SK_Estudiante) REFERENCES Dim_Estudiante(SK_Estudiante),
    CONSTRAINT FK_Fact_Curso FOREIGN KEY (SK_Curso) REFERENCES Dim_Curso(SK_Curso),
    CONSTRAINT FK_Fact_Facultad FOREIGN KEY (SK_Facultad) REFERENCES Dim_Facultad(SK_Facultad),
    CONSTRAINT FK_Fact_Tiempo FOREIGN KEY (SK_Tiempo) REFERENCES Dim_Tiempo(SK_Tiempo)
);

-- 1.6. Índices de Optimización Analítica
CREATE INDEX IX_Fact_Matricula_Tiempo ON Fact_Matricula(SK_Tiempo);
CREATE INDEX IX_Fact_Matricula_Facultad ON Fact_Matricula(SK_Facultad);


-- ============================================================================
-- SECCIÓN 2: INSERCIÓN Y CARGA DE DATOS DE PRUEBA (DML)
-- ============================================================================

-- 2.1. Poblar Dim_Tiempo
INSERT INTO Dim_Tiempo (SK_Tiempo, Fecha, Anio, Trimestre, Mes, Nombre_Mes, Dia) VALUES
(20261006, '2026-10-06', 2026, 4, 10, 'Octubre', 6),
(20261007, '2026-10-07', 2026, 4, 10, 'Octubre', 7);

-- 2.2. Poblar Dim_Facultad (Genera SK_Facultad = 1, 2, 3 mediante SERIAL)
INSERT INTO Dim_Facultad (ID_Facultad_NK, Nombre_Facultad) VALUES
(101, 'Facultad de Ingeniería y Ciencias Aplicadas'),
(102, 'Facultad de Ciencias Administrativas y Económicas'),
(103, 'Facultad de Arquitectura, Artes y Diseño');

-- 2.3. Poblar Dim_Estudiante (Genera SK_Estudiante = 1, 2, 3, 4 mediante SERIAL)
INSERT INTO Dim_Estudiante (ID_Estudiante_NK, Nombre_Estudiante, Provincia_Origen) VALUES
(9001, 'Carlos Pérez', 'Pichincha'),
(9002, 'María Fernanda Gómez', 'Tungurahua'),
(9003, 'Luis Alberto Torres', 'Pichincha'),
(9004, 'Diana Carolina Silva', 'Cotopaxi');

-- 2.4. Poblar Dim_Curso (Genera SK_Curso = 1, 2, 3 mediante SERIAL)
INSERT INTO Dim_Curso (ID_Curso_NK, Nombre_Curso, Creditos) VALUES
(505, 'Inteligencia de Negocios', 4),
(506, 'Minería de Datos', 4),
(507, 'Gestión Financiera', 3);

-- 2.5. Registrar Hechos en Fact_Matricula (Usando estrictamente las SK generadas)
INSERT INTO Fact_Matricula (
    SK_Estudiante, SK_Curso, SK_Facultad, SK_Tiempo,
    Monto_Pagado_USD, Porcentaje_Descuento_Beca, Cantidad_Matriculas
) VALUES
(1, 1, 1, 20261006, 350.00, 10.00, 1), -- Carlos Pérez | Ing. | Inteligencia de Negocios (Beca 10%)
(2, 1, 1, 20261006, 370.00,  5.00, 1), -- María Gómez  | Ing. | Inteligencia de Negocios (Beca 5%)
(3, 2, 1, 20261007, 360.00,  8.00, 1), -- Luis Torres  | Ing. | Minería de Datos (Beca 8%)
(4, 3, 2, 20261007, 390.00,  2.00, 1), -- Diana Silva  | Adm. | Gestión Financiera (Beca 2% -> < 5%)
(2, 2, 3, 20261007, 340.00,  6.00, 1); -- María Gómez  | Arq. | Minería de Datos (Beca 6%)


-- ============================================================================
-- SECCIÓN 3: EVALUACIÓN NIVEL 1 — LECTURA EN ESTRELLA CON CLAVES SUSTITUTAS (SK)
-- Objetivo: Comprender cómo se conecta la tabla de hechos con las dimensiones
--           utilizando estrictamente las claves sustitutas (SK).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- EJERCICIO 1.1: Desglose de Matrículas por Estudiante y Facultad
-- Enunciado: Escribe una consulta que liste el nombre completo del estudiante,
--            la provincia de origen, el nombre de la facultad a la que pertenece
--            y el monto pagado, uniendo la tabla Fact_Matricula con sus
--            respectivas dimensiones (Dim_Estudiante, Dim_Facultad).
-- ----------------------------------------------------------------------------
SELECT 
    e.Nombre_Estudiante,
    e.Provincia_Origen,
    f.Nombre_Facultad,
    m.Monto_Pagado_USD
FROM Fact_Matricula m
INNER JOIN Dim_Estudiante e 
    ON m.SK_Estudiante = e.SK_Estudiante
INNER JOIN Dim_Facultad f 
    ON m.SK_Facultad = f.SK_Facultad;

-- ----------------------------------------------------------------------------
-- EJERCICIO 1.2: Análisis por Curso y Créditos
-- Enunciado: Obtén el nombre del curso, los créditos que otorga y el monto
--            pagado por cada inscripción registrada en el Data Warehouse.
-- ----------------------------------------------------------------------------
SELECT 
    c.Nombre_Curso,
    c.Creditos,
    m.Monto_Pagado_USD
FROM Fact_Matricula m
INNER JOIN Dim_Curso c 
    ON m.SK_Curso = c.SK_Curso;


-- ============================================================================
-- SECCIÓN 4: EVALUACIÓN NIVEL 2 — AGREGACIONES Y MÉTRICAS DE NEGOCIO
-- Objetivo: Explotar las métricas aditivas y no aditivas del esquema mediante
--           GROUP BY y HAVING para responder preguntas gerenciales clave.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- EJERCICIO 2.1: Recaudación Total por Facultad
-- Enunciado: Calcula la suma total recaudada (Monto_Pagado_USD) y el número
--            total de matrículas (Cantidad_Matriculas) agrupadas por el nombre
--            de cada facultad. Ordena el resultado de mayor a menor recaudación.
-- ----------------------------------------------------------------------------
SELECT 
    f.Nombre_Facultad,
    SUM(m.Monto_Pagado_USD) AS Total_Recaudado_USD,
    SUM(m.Cantidad_Matriculas) AS Total_Matriculas_Aditivas,
    COUNT(m.Cantidad_Matriculas) AS Conteo_Matriculas
FROM Fact_Matricula m
INNER JOIN Dim_Facultad f 
    ON m.SK_Facultad = f.SK_Facultad
GROUP BY 
    f.Nombre_Facultad
ORDER BY 
    Total_Recaudado_USD DESC;

-- ----------------------------------------------------------------------------
-- EJERCICIO 2.2: Filtrado con HAVING sobre Descuentos
-- Enunciado: Muestra los nombres de los cursos en los cuales el promedio del
--            porcentaje de descuento por beca aplicado a los estudiantes haya
--            sido superior o igual al 5%.
-- ----------------------------------------------------------------------------
SELECT 
    c.Nombre_Curso,
    ROUND(AVG(m.Porcentaje_Descuento_Beca), 2) AS Promedio_Descuento_Beca_Pct
FROM Fact_Matricula m
INNER JOIN Dim_Curso c 
    ON m.SK_Curso = c.SK_Curso
GROUP BY 
    c.Nombre_Curso
HAVING 
    AVG(m.Porcentaje_Descuento_Beca) >= 5.00
ORDER BY 
    Promedio_Descuento_Beca_Pct DESC;