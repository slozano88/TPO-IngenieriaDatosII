DROP DATABASE IF EXISTS sistema_facturacion;
CREATE DATABASE sistema_facturacion
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE sistema_facturacion;


-- 1. CREACION DE TABLAS


CREATE TABLE E01_CLIENTE (
    nro_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(45) NOT NULL,
    apellido VARCHAR(45) NOT NULL,
    direccion VARCHAR(100),
    activo TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chk_cliente_activo CHECK (activo IN (0, 1))
) ENGINE = InnoDB;

CREATE TABLE E01_TELEFONO (
    nro_cliente INT NOT NULL,
    cod_area INT NOT NULL,
    nro_telefono VARCHAR(20) NOT NULL,
    tipo CHAR(1),

    PRIMARY KEY (nro_cliente, cod_area, nro_telefono),

    CONSTRAINT fk_telefono_cliente
        FOREIGN KEY (nro_cliente)
        REFERENCES E01_CLIENTE(nro_cliente)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_telefono_tipo CHECK (tipo IS NULL OR tipo IN ('M', 'F', 'T', 'O'))
) ENGINE = InnoDB;

CREATE TABLE E01_PRODUCTO (
    codigo_producto INT PRIMARY KEY AUTO_INCREMENT,
    marca VARCHAR(45) NOT NULL,
    nombre VARCHAR(45) NOT NULL,
    descripcion VARCHAR(100),
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL,

    CONSTRAINT chk_producto_precio CHECK (precio >= 0),
    CONSTRAINT chk_producto_stock CHECK (stock >= 0)
) ENGINE = InnoDB;

CREATE TABLE E01_FACTURA (
    nro_factura INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    total_sin_iva DECIMAL(12,2) NOT NULL DEFAULT 0,
    iva DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_con_iva DECIMAL(12,2) NOT NULL DEFAULT 0,

    nro_cliente INT NOT NULL,

    CONSTRAINT fk_factura_cliente
        FOREIGN KEY (nro_cliente)
        REFERENCES E01_CLIENTE(nro_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE E01_DETALLE_FACTURA (
    nro_factura INT NOT NULL,
    nro_item INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,

    codigo_producto INT NOT NULL,

    -- Campos agregados para conservar el valor historico de la venta.
    -- Si el precio del producto cambia luego, la factura mantiene el importe real facturado.

    precio_unitario_sin_iva DECIMAL(10,2) NOT NULL,
    porcentaje_descuento DECIMAL(5,2) NOT NULL DEFAULT 0,
    subtotal_sin_iva DECIMAL(12,2) NOT NULL,

    PRIMARY KEY (nro_factura, nro_item),

    CONSTRAINT fk_detalle_factura
        FOREIGN KEY (nro_factura)
        REFERENCES E01_FACTURA(nro_factura)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_detalle_producto
        FOREIGN KEY (codigo_producto)
        REFERENCES E01_PRODUCTO(codigo_producto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_detalle_descuento CHECK (porcentaje_descuento >= 0 AND porcentaje_descuento <= 100),
    CONSTRAINT chk_detalle_subtotal CHECK (subtotal_sin_iva >= 0)
) ENGINE = InnoDB;

-- Indices de apoyo para consultas frecuentes.
CREATE INDEX idx_factura_cliente ON E01_FACTURA(nro_cliente);
CREATE INDEX idx_factura_fecha ON E01_FACTURA(fecha);
CREATE INDEX idx_producto_marca ON E01_PRODUCTO(marca);
CREATE INDEX idx_detalle_producto ON E01_DETALLE_FACTURA(codigo_producto);


-- 2. PROCEDIMIENTOS DE NEGOCIO


DELIMITER //

CREATE PROCEDURE sp_crear_factura(
    IN p_nro_cliente INT,
    IN p_items JSON
)
BEGIN
    DECLARE v_nro_factura INT DEFAULT 0;
    DECLARE v_total_sin_iva DECIMAL(12,2) DEFAULT 0;
    DECLARE v_iva DECIMAL(12,2) DEFAULT 0;
    DECLARE v_total_con_iva DECIMAL(12,2) DEFAULT 0;
    DECLARE v_count_items INT DEFAULT 0;
    DECLARE v_rows_updated INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        DROP TEMPORARY TABLE IF EXISTS tmp_items_factura;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_items IS NULL OR JSON_LENGTH(p_items) = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La factura debe tener al menos un producto.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM E01_CLIENTE
        WHERE nro_cliente = p_nro_cliente
          AND activo = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cliente inexistente o inactivo.';
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_items_factura;

    CREATE TEMPORARY TABLE tmp_items_factura (
        codigo_producto INT NOT NULL PRIMARY KEY,
        cantidad DECIMAL(10,2) NOT NULL
    ) ENGINE = MEMORY;

    INSERT INTO tmp_items_factura (codigo_producto, cantidad)
    SELECT
        jt.codigo_producto,
        SUM(jt.cantidad) AS cantidad
    FROM JSON_TABLE(
        p_items,
        '$[*]' COLUMNS (
            codigo_producto INT PATH '$.codigo_producto' ERROR ON EMPTY,
            cantidad DECIMAL(10,2) PATH '$.cantidad' ERROR ON EMPTY
        )
    ) AS jt
    GROUP BY jt.codigo_producto;

    SELECT COUNT(*) INTO v_count_items
    FROM tmp_items_factura;

    IF v_count_items = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se encontraron items validos para facturar.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM tmp_items_factura
        WHERE cantidad <= 0
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cantidad de cada producto debe ser mayor a cero.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM tmp_items_factura ti
        LEFT JOIN E01_PRODUCTO p
            ON p.codigo_producto = ti.codigo_producto
        WHERE p.codigo_producto IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Uno o mas productos no existen.';
    END IF;

    -- Actualizacion atomica del stock. Si algun producto no alcanza, se revierte toda la factura.
    UPDATE E01_PRODUCTO p
    INNER JOIN tmp_items_factura ti
        ON ti.codigo_producto = p.codigo_producto
    SET p.stock = p.stock - ti.cantidad
    WHERE p.stock >= ti.cantidad;

    SET v_rows_updated = ROW_COUNT();

    IF v_rows_updated <> v_count_items THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente para uno o mas productos.';
    END IF;

    INSERT INTO E01_FACTURA (fecha, total_sin_iva, iva, total_con_iva, nro_cliente)
    VALUES (CURRENT_DATE(), 0, 0, 0, p_nro_cliente);

    SET v_nro_factura = LAST_INSERT_ID();

    INSERT INTO E01_DETALLE_FACTURA (
        nro_factura,
        nro_item,
        cantidad,
        codigo_producto,
        precio_unitario_sin_iva,
        porcentaje_descuento,
        subtotal_sin_iva
    )
    SELECT
        v_nro_factura AS nro_factura,
        ROW_NUMBER() OVER (ORDER BY ti.codigo_producto) AS nro_item,
        ti.cantidad,
        ti.codigo_producto,
        p.precio AS precio_unitario_sin_iva,
        CASE
            WHEN ti.cantidad >= 10 THEN 10.00
            WHEN ti.cantidad >= 5 THEN 5.00
            ELSE 0.00
        END AS porcentaje_descuento,
        ROUND(
            ti.cantidad * p.precio *
            (1 - CASE
                WHEN ti.cantidad >= 10 THEN 0.10
                WHEN ti.cantidad >= 5 THEN 0.05
                ELSE 0.00
            END),
            2
        ) AS subtotal_sin_iva
    FROM tmp_items_factura ti
    INNER JOIN E01_PRODUCTO p
        ON p.codigo_producto = ti.codigo_producto;

    SELECT ROUND(COALESCE(SUM(subtotal_sin_iva), 0), 2)
    INTO v_total_sin_iva
    FROM E01_DETALLE_FACTURA
    WHERE nro_factura = v_nro_factura;

    SET v_iva = ROUND(v_total_sin_iva * 0.21, 2);
    SET v_total_con_iva = ROUND(v_total_sin_iva + v_iva, 2);

    UPDATE E01_FACTURA
    SET total_sin_iva = v_total_sin_iva,
        iva = v_iva,
        total_con_iva = v_total_con_iva
    WHERE nro_factura = v_nro_factura;

    COMMIT;

    DROP TEMPORARY TABLE IF EXISTS tmp_items_factura;

    SELECT *
    FROM E01_FACTURA
    WHERE nro_factura = v_nro_factura;
END//


DELIMITER //

CREATE PROCEDURE sp_crear_cliente(
    IN p_nombre VARCHAR(45),
    IN p_apellido VARCHAR(45),
    IN p_direccion VARCHAR(100),
    IN p_activo TINYINT
)
BEGIN
    INSERT INTO E01_CLIENTE (nombre, apellido, direccion, activo)
    VALUES (p_nombre, p_apellido, p_direccion, COALESCE(p_activo, 1));

    SELECT *
    FROM E01_CLIENTE
    WHERE nro_cliente = LAST_INSERT_ID();
END//

CREATE PROCEDURE sp_modificar_cliente(
    IN p_nro_cliente INT,
    IN p_nombre VARCHAR(45),
    IN p_apellido VARCHAR(45),
    IN p_direccion VARCHAR(100),
    IN p_activo TINYINT
)
BEGIN
    IF EXISTS (SELECT 1 FROM E01_CLIENTE WHERE nro_cliente = p_nro_cliente) THEN

        UPDATE E01_CLIENTE
        SET nombre = COALESCE(p_nombre, nombre),
            apellido = COALESCE(p_apellido, apellido),
            direccion = COALESCE(p_direccion, direccion),
            activo = COALESCE(p_activo, activo)
        WHERE nro_cliente = p_nro_cliente;

        SELECT *
        FROM E01_CLIENTE
        WHERE nro_cliente = p_nro_cliente;

    ELSE
        SELECT 'El cliente indicado no existe' AS mensaje;
    END IF;
END//

CREATE PROCEDURE sp_baja_logica_cliente(
    IN p_nro_cliente INT
)
BEGIN
    IF EXISTS (SELECT 1 FROM E01_CLIENTE WHERE nro_cliente = p_nro_cliente) THEN

        UPDATE E01_CLIENTE
        SET activo = 0
        WHERE nro_cliente = p_nro_cliente;

        SELECT *
        FROM E01_CLIENTE
        WHERE nro_cliente = p_nro_cliente;

    ELSE
        SELECT 'El cliente indicado no existe' AS mensaje;
    END IF;
END//

CREATE PROCEDURE sp_eliminar_cliente_fisico(
    IN p_nro_cliente INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM E01_CLIENTE WHERE nro_cliente = p_nro_cliente) THEN

        SELECT 'El cliente indicado no existe' AS mensaje;

    ELSEIF EXISTS (SELECT 1 FROM E01_FACTURA WHERE nro_cliente = p_nro_cliente) THEN

        SELECT 'No se puede eliminar fisicamente el cliente porque tiene facturas relacionadas' AS mensaje;

    ELSE

        DELETE FROM E01_CLIENTE
        WHERE nro_cliente = p_nro_cliente;

        SELECT 'Cliente eliminado correctamente' AS mensaje;

    END IF;
END//

CREATE PROCEDURE sp_crear_producto(
    IN p_marca VARCHAR(45),
    IN p_nombre VARCHAR(45),
    IN p_descripcion VARCHAR(100),
    IN p_precio DECIMAL(10,2),
    IN p_stock INT
)
BEGIN
    INSERT INTO E01_PRODUCTO (marca, nombre, descripcion, precio, stock)
    VALUES (p_marca, p_nombre, p_descripcion, p_precio, p_stock);

    SELECT *
    FROM E01_PRODUCTO
    WHERE codigo_producto = LAST_INSERT_ID();
END//

CREATE PROCEDURE sp_modificar_producto(
    IN p_codigo_producto INT,
    IN p_marca VARCHAR(45),
    IN p_nombre VARCHAR(45),
    IN p_descripcion VARCHAR(100),
    IN p_precio DECIMAL(10,2),
    IN p_stock INT
)
BEGIN
    IF EXISTS (SELECT 1 FROM E01_PRODUCTO WHERE codigo_producto = p_codigo_producto) THEN

        UPDATE E01_PRODUCTO
        SET marca = COALESCE(p_marca, marca),
            nombre = COALESCE(p_nombre, nombre),
            descripcion = COALESCE(p_descripcion, descripcion),
            precio = COALESCE(p_precio, precio),
            stock = COALESCE(p_stock, stock)
        WHERE codigo_producto = p_codigo_producto;

        SELECT *
        FROM E01_PRODUCTO
        WHERE codigo_producto = p_codigo_producto;

    ELSE
        SELECT 'El producto indicado no existe' AS mensaje;
    END IF;
END//

DELIMITER ;


-- Facturas generadas con control de stock, descuentos e IVA.
-- Descuento aplicado por volumen: 0% hasta 4 unidades, 5% desde 5, 10% desde 10.

CALL sp_crear_factura(2, JSON_ARRAY(
    JSON_OBJECT('codigo_producto', 1, 'cantidad', 2),
    JSON_OBJECT('codigo_producto', 3, 'cantidad', 1)
));

CALL sp_crear_factura(1, JSON_ARRAY(
    JSON_OBJECT('codigo_producto', 2, 'cantidad', 6)
));

CALL sp_crear_factura(3, JSON_ARRAY(
    JSON_OBJECT('codigo_producto', 4, 'cantidad', 10)
));


-- 4. VISTAS

CREATE OR REPLACE VIEW V_FACTURAS_ORDENADAS AS
SELECT *
FROM E01_FACTURA
ORDER BY fecha ASC, nro_factura ASC;

CREATE OR REPLACE VIEW V_PRODUCTOS_NO_FACTURADOS AS
SELECT p.*
FROM E01_PRODUCTO p
LEFT JOIN E01_DETALLE_FACTURA df
    ON p.codigo_producto = df.codigo_producto
WHERE df.codigo_producto IS NULL;


-- 5. CONSULTAS 

-- Requerimiento 1: Obtener los datos de los clientes junto con sus telefonos.
SELECT
    c.nro_cliente,
    c.nombre,
    c.apellido,
    c.direccion,
    c.activo,
    t.cod_area,
    t.nro_telefono,
    t.tipo
FROM E01_CLIENTE c
INNER JOIN E01_TELEFONO t
    ON c.nro_cliente = t.nro_cliente;

-- Requerimiento 2: Obtener telefonos y numero de cliente de Jacob Cooper.
SELECT
    c.nro_cliente,
    t.cod_area,
    t.nro_telefono,
    t.tipo
FROM E01_CLIENTE c
INNER JOIN E01_TELEFONO t
    ON c.nro_cliente = t.nro_cliente
WHERE c.nombre = 'Jacob'
  AND c.apellido = 'Cooper';

-- Requerimiento 3: Mostrar cada telefono junto con los datos del cliente.
SELECT
    t.cod_area,
    t.nro_telefono,
    t.tipo,
    c.nro_cliente,
    c.nombre,
    c.apellido,
    c.direccion,
    c.activo
FROM E01_TELEFONO t
LEFT JOIN E01_CLIENTE c
    ON t.nro_cliente = c.nro_cliente;

-- Requerimiento 4: Clientes que tengan registrada al menos una factura.
SELECT DISTINCT c.*
FROM E01_CLIENTE c
INNER JOIN E01_FACTURA f
    ON c.nro_cliente = f.nro_cliente;

-- Requerimiento 5: Clientes que no tengan registrada ninguna factura.
SELECT c.*
FROM E01_CLIENTE c
LEFT JOIN E01_FACTURA f
    ON c.nro_cliente = f.nro_cliente
WHERE f.nro_factura IS NULL;

-- Requerimiento 6: Todos los clientes con la cantidad de facturas registradas.
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

-- Requerimiento 7: Facturas compradas por Kai Bullock.
SELECT f.*
FROM E01_FACTURA f
INNER JOIN E01_CLIENTE c
    ON f.nro_cliente = c.nro_cliente
WHERE c.nombre = 'Kai'
  AND c.apellido = 'Bullock';

-- Requerimiento 8: Productos facturados al menos una vez.
SELECT DISTINCT p.*
FROM E01_PRODUCTO p
INNER JOIN E01_DETALLE_FACTURA df
    ON p.codigo_producto = df.codigo_producto;

-- Requerimiento 9: Facturas que contengan productos de la marca Ipsum.
SELECT DISTINCT f.*
FROM E01_FACTURA f
INNER JOIN E01_DETALLE_FACTURA df
    ON f.nro_factura = df.nro_factura
INNER JOIN E01_PRODUCTO p
    ON df.codigo_producto = p.codigo_producto
WHERE p.marca = 'Ipsum';

-- Requerimiento 10: Nombre y apellido de cada cliente junto con su gasto total con IVA incluido.
SELECT
    c.nro_cliente,
    c.nombre,
    c.apellido,
    COALESCE(SUM(f.total_con_iva), 0) AS total_gastado_con_iva
FROM E01_CLIENTE c
LEFT JOIN E01_FACTURA f
    ON c.nro_cliente = f.nro_cliente
GROUP BY
    c.nro_cliente,
    c.nombre,
    c.apellido;

-- Requerimiento 11: Vista de facturas ordenadas por fecha.
SELECT *
FROM V_FACTURAS_ORDENADAS;

-- Requerimiento 12: Vista de productos aun no facturados.
SELECT *
FROM V_PRODUCTOS_NO_FACTURADOS;

-- Requerimiento 13: Funcionalidad para crear, eliminar y modificar clientes.
-- Ejemplos de uso:
-- CALL sp_crear_cliente('Sofia', 'Martinez', 'Calle Ejemplo 123', 1);
-- CALL sp_modificar_cliente(1, NULL, NULL, 'Av. Shaw 456', 1);
-- CALL sp_baja_logica_cliente(1);
-- CALL sp_eliminar_cliente_fisico(5);

-- Requerimiento 14: Funcionalidad para crear nuevos productos y modificar existentes.
-- El precio se registra sin IVA.
-- Ejemplos de uso:
-- CALL sp_crear_producto('Ipsum', 'Mouse inalambrico PRO', 'Mouse optico USB', 18000.00, 25);
-- CALL sp_modificar_producto(1, NULL, NULL, NULL, 18000.00, 30);