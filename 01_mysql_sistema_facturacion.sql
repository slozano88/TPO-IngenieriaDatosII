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