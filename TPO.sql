CREATE DATABASE IF NOT EXISTS sistema_facturacion;
USE sistema_facturacion;

CREATE TABLE E01_CLIENTE (
    nro_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(45) NOT NULL,
    apellido VARCHAR(45) NOT NULL,
    direccion VARCHAR(100),
    activo TINYINT(1) DEFAULT 1
);


CREATE TABLE E01_TELEFONO (
    nro_cliente INT NOT NULL,
    cod_area INT NOT NULL,
    nro_telefono VARCHAR(20) NOT NULL,
    tipo CHAR(1),

    PRIMARY KEY (nro_cliente, cod_area, nro_telefono),

    CONSTRAINT fk_telefono_cliente
        FOREIGN KEY (nro_cliente)
        REFERENCES E01_CLIENTE(nro_cliente)
);


CREATE TABLE E01_PRODUCTO (
    codigo_producto INT PRIMARY KEY AUTO_INCREMENT,
    marca VARCHAR(45) NOT NULL,
    nombre VARCHAR(45) NOT NULL,
    descripcion VARCHAR(100),
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL
);


CREATE TABLE E01_FACTURA (
    nro_factura INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    total_sin_iva DECIMAL(10,2),
    iva DECIMAL(10,2),
    total_con_iva DECIMAL(10,2),

    nro_cliente INT NOT NULL,

    CONSTRAINT fk_factura_cliente
        FOREIGN KEY (nro_cliente)
        REFERENCES E01_CLIENTE(nro_cliente)
);

CREATE TABLE E01_DETALLE_FACTURA (
    nro_factura INT NOT NULL,
    nro_item INT NOT NULL,
    cantidad FLOAT NOT NULL,

    codigo_producto INT NOT NULL,

    PRIMARY KEY (nro_factura, nro_item),

    CONSTRAINT fk_detalle_factura
        FOREIGN KEY (nro_factura)
        REFERENCES E01_FACTURA(nro_factura),

    CONSTRAINT fk_detalle_producto
        FOREIGN KEY (codigo_producto)
        REFERENCES E01_PRODUCTO(codigo_producto)
);

-- Se importan los datos desde los csv con table data import wizard



-- Requerimiento 1 | Obtener los datos de los clientes junto con sus teléfonos.

SELECT
    c.*,
    t.cod_area,
    t.nro_telefono,
    t.tipo
FROM E01_CLIENTE c
JOIN E01_TELEFONO t
ON c.nro_cliente = t.nro_cliente;


-- Requerimiento 2 | Obtener los teléfonos y el número de cliente del cliente con nombre.

SELECT
    c.nro_cliente,
    t.cod_area,
    t.nro_telefono
FROM E01_CLIENTE c
JOIN E01_TELEFONO t
ON c.nro_cliente = t.nro_cliente
WHERE c.nombre = 'Jacob'
AND c.apellido = 'Cooper';

-- Req 3. mostrar cada teléfono junto con los datos del cliente
 
SELECT
    t.cod_area,
    t.nro_telefono,
    t.tipo,
    c.*
FROM E01_TELEFONO t
LEFT JOIN E01_CLIENTE c
ON t.nro_cliente = c.nro_cliente;
 
 
-- Req 4. obtener todos los clientes que tengan registrada al menos una factura
 
SELECT DISTINCT c.*
FROM E01_CLIENTE c
INNER JOIN E01_FACTURA f
ON c.nro_cliente = f.nro_cliente;


-- Req 5. Identificar todos los clientes que no tengan registrada ninguna factura.

SELECT c.*
FROM E01_CLIENTE c
LEFT JOIN E01_FACTURA f
ON c.nro_cliente = f.nro_cliente
WHERE f.nro_factura IS NULL;


-- Req 6. Devolver todos los clientes con la cantidad de facturas registradas.
-- Si no tienen facturas, mostrar 0.

SELECT
    c.nro_cliente,
    c.nombre,
    c.apellido,
    c.direccion,
    c.activo,
    COUNT(f.nro_factura) AS cantidad_facturas
FROM E01_CLIENTE c
LEFT JOIN E01_FACTURA f
ON c.nro_cliente = f.nro_cliente
GROUP BY
    c.nro_cliente,
    c.nombre,
    c.apellido,
    c.direccion,
    c.activo;


-- Req 7. Listar los datos de todas las facturas compradas por Kai Bullock.

SELECT f.*
FROM E01_FACTURA f
INNER JOIN E01_CLIENTE c
ON f.nro_cliente = c.nro_cliente
WHERE c.nombre = 'Kai'
AND c.apellido = 'Bullock';


-- Req 8. Seleccionar los productos facturados al menos una vez.

SELECT DISTINCT p.*
FROM E01_PRODUCTO p
INNER JOIN E01_DETALLE_FACTURA df
ON p.codigo_producto = df.codigo_producto;


-- Req 9. Listar los datos de todas las facturas que contengan productos de la marca “Ipsum”.

SELECT DISTINCT f.*
FROM E01_FACTURA f
INNER JOIN E01_DETALLE_FACTURA df
ON f.nro_factura = df.nro_factura
INNER JOIN E01_PRODUCTO p
ON df.codigo_producto = p.codigo_producto
WHERE p.marca = 'Ipsum';
