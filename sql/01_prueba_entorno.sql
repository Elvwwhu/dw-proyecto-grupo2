-- Script de prueba de integración de entorno en Windows 11

CREATE TABLE IF NOT EXISTS tbl_verificacion_windows (

    id_prueba SERIAL PRIMARY KEY,

    estudiante VARCHAR(100) NOT NULL,

    sistema_operativo VARCHAR(50) DEFAULT 'Windows 11',

    sgbd VARCHAR(50) DEFAULT 'PostgreSQL 15+',

    fecha_verificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP

);

INSERT INTO tbl_verificacion_windows (estudiante) 

VALUES ('Estudiante UTI Windows 11');

SELECT * FROM tbl_verificacion_windows;