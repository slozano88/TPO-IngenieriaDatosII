Trabajo Practico Obligatorio - Sistema de Facturacion
Ingenieria de Datos II - 2026

Archivos incluidos:
1) Documentacion_TPO_Facturacion_Poliglota.docx
   Documento de entrega con explicacion del diseño, justificaciones y mapeo de requerimientos.

2) 01_mysql_sistema_facturacion.sql
   Script completo de MySQL: crea la base, tablas, indices, procedimientos, datos de prueba, vistas y consultas de los 14 requerimientos.

3) 02_mongodb_sistema_facturacion.js
   Script completo de MongoDB: crea colecciones, validaciones, datos de prueba, vistas, indices, consultas y funciones CRUD de apoyo.

Ejecucion MySQL:
- Abrir MySQL Workbench.
- Abrir el archivo 01_mysql_sistema_facturacion.sql.
- Ejecutarlo completo.
- Requiere MySQL 8

Ejecucion MongoDB:
- Tener MongoDB y mongosh instalados.
- Ejecutar desde terminal:
  mongosh 02_mongodb_sistema_facturacion.js

Criterio de diseño:
- MySQL funciona como base principal transaccional, porque permite integridad referencial, claves foraneas y transacciones para controlar stock y facturacion.
- MongoDB funciona como base complementaria documental para consultas y reportes de facturas desnormalizadas.
