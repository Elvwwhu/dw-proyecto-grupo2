-- ============================================================================
-- UNIVERSIDAD INDOAMÉRICA (UTI)
-- FACULTAD DE INGENIERÍA Y CIENCIAS APLICADAS
-- Asignatura : Ciencia de Datos / Data Warehouse
-- Actividad  : Actividad 3 — Estrategias de Diseño de Tablas de Hechos,
--              Granularidad Fina vs. Agregada y Gestión de Claves Sustitutas
-- Base Datos : dw_edusmart_avanzado
-- Archivo    : sql/01_esquema_dimensional.sql
-- Motor SGBD : PostgreSQL 15+
-- ============================================================================

-- Paso previo en pgAdmin 4 (ejecutar fuera del script si aún no existe la BD):
-- CREATE DATABASE dw_edusmart_avanzado;

-- Limpieza idempotente para permitir re-ejecución sin errores
DROP TABLE IF EXISTS Fact_Rendimiento_Academico CASCADE;
DROP TABLE IF EXISTS Dim_Tiempo CASCADE;
DROP TABLE IF EXISTS Dim_Asignatura CASCADE;
DROP TABLE IF EXISTS Dim_Estudiante CASCADE;

-- ============================================================
-- 1. CREACIÓN DE TABLAS DE DIMENSIONES CON CLAVES SUSTITUTAS
-- ============================================================

-- Dimensión Estudiante (Surrogate Key sintética vs Natural Key operacional)
CREATE TABLE Dim_Estudiante (
    SK_Estudiante SERIAL PRIMARY KEY,      -- Surrogate Key (Clave Sustituta autoincremental)
    ID_Estudiante_NK INT NOT NULL,         -- Natural Key (Clave de negocio proveniente de OLTP)
    Nombre_Estudiante VARCHAR(100) NOT NULL,
    Programa_Academico VARCHAR(100) NOT NULL
);

-- Dimensión Asignatura
CREATE TABLE Dim_Asignatura (
    SK_Asignatura SERIAL PRIMARY KEY,      -- Surrogate Key (Clave Sustituta autoincremental)
    ID_Asignatura_NK INT NOT NULL,         -- Natural Key (Código operacional de asignatura)
    Nombre_Asignatura VARCHAR(100) NOT NULL,
    Creditos INT NOT NULL
);

-- Dimensión Tiempo (Grano diario / fecha)
CREATE TABLE Dim_Tiempo (
    SK_Tiempo INT PRIMARY KEY,             -- Clave sustituta en formato entero (Ej: 20261006)
    Fecha DATE NOT NULL,
    Anio INT NOT NULL,
    Mes INT NOT NULL,
    Nombre_Mes VARCHAR(20) NOT NULL,
    Dia INT NOT NULL
);

-- ============================================================
-- 2. CREACIÓN DE LA TABLA DE HECHOS CON GRANULARIDAD FINA
-- ============================================================
-- Grano Fino (Atómico): Una fila representa la calificación y asistencia
-- obtenida por un estudiante en una asignatura y fecha de evaluación específica.
CREATE TABLE Fact_Rendimiento_Academico (
    -- Claves Foráneas (Enlazadas estrictamente a las Claves Sustitutas SK)
    SK_Estudiante INT NOT NULL,
    SK_Asignatura INT NOT NULL,
    SK_Tiempo INT NOT NULL,
    
    -- Métricas / Hechos cuantitativos detallados
    Calificacion_Final NUMERIC(5, 2) NOT NULL,
    Asistencia_Porcentaje NUMERIC(5, 2) NOT NULL,
    Cantidad_Intentos INT DEFAULT 1,
    
    -- Clave Primaria Compuesta del Evento de Evaluación
    CONSTRAINT PK_Fact_Rendimiento PRIMARY KEY (SK_Estudiante, SK_Asignatura, SK_Tiempo),

    -- Restricciones de Integridad Referencial (Foreign Keys)
    CONSTRAINT FK_Fact_Estudiante FOREIGN KEY (SK_Estudiante) REFERENCES Dim_Estudiante(SK_Estudiante),
    CONSTRAINT FK_Fact_Asignatura FOREIGN KEY (SK_Asignatura) REFERENCES Dim_Asignatura(SK_Asignatura),
    CONSTRAINT FK_Fact_Tiempo FOREIGN KEY (SK_Tiempo) REFERENCES Dim_Tiempo(SK_Tiempo)
);

-- ============================================================
-- 3. CREACIÓN DE ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS OLAP
-- ============================================================
CREATE INDEX IX_Fact_Rendimiento_Tiempo ON Fact_Rendimiento_Academico(SK_Tiempo);
CREATE INDEX IX_Fact_Rendimiento_Estudiante ON Fact_Rendimiento_Academico(SK_Estudiante);


-- ============================================================
-- 4. CARGA DE DATOS DE PRUEBA (DML) PARA VERIFICACIÓN EN PGADMIN 4
-- ============================================================

-- 4.1. Poblar Dim_Tiempo
INSERT INTO Dim_Tiempo (SK_Tiempo, Fecha, Anio, Mes, Nombre_Mes, Dia) VALUES
(20261006, '2026-10-06', 2026, 10, 'Octubre', 6),
(20261015, '2026-10-15', 2026, 10, 'Octubre', 15);

-- 4.2. Poblar Dim_Estudiante (Genera SK_Estudiante = 1, 2, 3, 4)
INSERT INTO Dim_Estudiante (ID_Estudiante_NK, Nombre_Estudiante, Programa_Academico) VALUES
(9001, 'Carlos Pérez', 'Ingeniería en Ciencia de Datos'),
(9002, 'María Fernanda Gómez', 'Ingeniería en Sistemas de Información'),
(9003, 'Luis Alberto Torres', 'Ingeniería en Ciencia de Datos'),
(9004, 'Diana Carolina Silva', 'Administración de Empresas');

-- 4.3. Poblar Dim_Asignatura (Genera SK_Asignatura = 1, 2, 3)
INSERT INTO Dim_Asignatura (ID_Asignatura_NK, Nombre_Asignatura, Creditos) VALUES
(505, 'Inteligencia de Negocios y Data Warehouse', 4),
(506, 'Minería de Datos Avanzada', 4),
(507, 'Estadística Inferencial', 3);

-- 4.4. Poblar Fact_Rendimiento_Academico (Usando estrictamente SKs)
INSERT INTO Fact_Rendimiento_Academico (
    SK_Estudiante, SK_Asignatura, SK_Tiempo,
    Calificacion_Final, Asistencia_Porcentaje, Cantidad_Intentos
) VALUES
(1, 1, 20261006, 9.50, 96.00, 1),
(2, 1, 20261006, 8.80, 92.00, 1),
(3, 2, 20261015, 9.10, 95.00, 1),
(4, 3, 20261015, 7.60, 84.00, 2),
(1, 2, 20261015, 8.90, 90.00, 1);


-- ============================================================
-- 5. CONSULTAS ANALÍTICAS DE VERIFICACIÓN (NIVEL FINO Y AGREGADO)
-- ============================================================

-- 5.1. Consulta de Granularidad Fina (Lectura en Estrella Fact JOIN Dim por SK)
SELECT 
    e.Nombre_Estudiante,
    e.Programa_Academico,
    a.Nombre_Asignatura,
    a.Creditos,
    t.Fecha,
    r.Calificacion_Final,
    r.Asistencia_Porcentaje,
    r.Cantidad_Intentos
FROM Fact_Rendimiento_Academico r
INNER JOIN Dim_Estudiante e ON r.SK_Estudiante = e.SK_Estudiante
INNER JOIN Dim_Asignatura a ON r.SK_Asignatura = a.SK_Asignatura
INNER JOIN Dim_Tiempo t ON r.SK_Tiempo = t.SK_Tiempo
ORDER BY r.Calificacion_Final DESC;

-- 5.2. Consulta de Granularidad Agregada por Programa Académico (GROUP BY)
SELECT 
    e.Programa_Academico,
    ROUND(AVG(r.Calificacion_Final), 2) AS Promedio_Calificacion,
    ROUND(AVG(r.Asistencia_Porcentaje), 2) AS Promedio_Asistencia_Pct,
    SUM(r.Cantidad_Intentos) AS Total_Intentos_Evaluados,
    COUNT(*) AS Total_Registros_Evaluacion
FROM Fact_Rendimiento_Academico r
INNER JOIN Dim_Estudiante e ON r.SK_Estudiante = e.SK_Estudiante
GROUP BY e.Programa_Academico
ORDER BY Promedio_Calificacion DESC;

-- 5.3. Filtrado Post-Agregación con HAVING por Asignatura (Promedio >= 8.50)
SELECT 
    a.Nombre_Asignatura,
    a.Creditos,
    ROUND(AVG(r.Calificacion_Final), 2) AS Promedio_Curso,
    ROUND(AVG(r.Asistencia_Porcentaje), 2) AS Asistencia_Media_Pct
FROM Fact_Rendimiento_Academico r
INNER JOIN Dim_Asignatura a ON r.SK_Asignatura = a.SK_Asignatura
GROUP BY a.Nombre_Asignatura, a.Creditos
HAVING AVG(r.Calificacion_Final) >= 8.50
ORDER BY Promedio_Curso DESC;