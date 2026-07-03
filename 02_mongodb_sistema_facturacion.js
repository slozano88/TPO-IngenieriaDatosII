const dbName = "sistema_facturacion_nosql";
db = db.getSiblingDB(dbName);
db.dropDatabase();


// 1. CREACION DE COLECCIONES CON VALIDACION BASICA


db.createCollection("clientes", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["nro_cliente", "nombre", "apellido", "activo", "telefonos"],
      properties: {
        nro_cliente: { bsonType: "int" },
        nombre: { bsonType: "string" },
        apellido: { bsonType: "string" },
        direccion: { bsonType: ["string", "null"] },
        activo: { bsonType: "bool" },
        telefonos: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["cod_area", "nro_telefono"],
            properties: {
              cod_area: { bsonType: "int" },
              nro_telefono: { bsonType: "string" },
              tipo: { bsonType: ["string", "null"] }
            }
          }
        }
      }
    }
  }
});

db.createCollection("productos", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["codigo_producto", "marca", "nombre", "precio_sin_iva", "stock"],
      properties: {
        codigo_producto: { bsonType: "int" },
        marca: { bsonType: "string" },
        nombre: { bsonType: "string" },
        descripcion: { bsonType: ["string", "null"] },
        precio_sin_iva: { bsonType: "decimal" },
        stock: { bsonType: "int" }
      }
    }
  }
});

db.createCollection("facturas", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["nro_factura", "fecha", "cliente", "items", "total_sin_iva", "iva", "total_con_iva"],
      properties: {
        nro_factura: { bsonType: "int" },
        fecha: { bsonType: "date" },
        cliente: { bsonType: "object" },
        items: { bsonType: "array" },
        total_sin_iva: { bsonType: "decimal" },
        iva: { bsonType: "decimal" },
        total_con_iva: { bsonType: "decimal" }
      }
    }
  }
});


// 2. INSERCION DE DATOS DE PRUEBA


db.clientes.insertMany([
  {
    _id: 1,
    nro_cliente: NumberInt(1),
    nombre: "Jacob",
    apellido: "Cooper",
    direccion: "Av. Corrientes 1234",
    activo: true,
    telefonos: [
      { cod_area: NumberInt(11), nro_telefono: "5555-1001", tipo: "M" },
      { cod_area: NumberInt(11), nro_telefono: "5555-1002", tipo: "F" }
    ]
  },
  {
    _id: 2,
    nro_cliente: NumberInt(2),
    nombre: "Kai",
    apellido: "Bullock",
    direccion: "Av. Bunge 456",
    activo: true,
    telefonos: [
      { cod_area: NumberInt(2267), nro_telefono: "44-7897", tipo: "M" }
    ]
  },
  {
    _id: 3,
    nro_cliente: NumberInt(3),
    nombre: "Mia",
    apellido: "Torres",
    direccion: "Calle Libertad 789",
    activo: true,
    telefonos: [
      { cod_area: NumberInt(11), nro_telefono: "5555-3001", tipo: "M" }
    ]
  },
  {
    _id: 4,
    nro_cliente: NumberInt(4),
    nombre: "Noah",
    apellido: "Bennett",
    direccion: "Av. Shaw 222",
    activo: true,
    telefonos: [
      { cod_area: NumberInt(223), nro_telefono: "555-4001", tipo: "T" }
    ]
  },
  {
    _id: 5,
    nro_cliente: NumberInt(5),
    nombre: "Evangelina",
    apellido: "Ovelar",
    direccion: "Del Tuyu 300",
    activo: true,
    telefonos: [
      { cod_area: NumberInt(2267), nro_telefono: "555-5001", tipo: "M" }
    ]
  }
]);

db.productos.insertMany([
  { _id: 1, codigo_producto: NumberInt(1), marca: "Ipsum", nombre: "Mouse inalambrico", descripcion: "Mouse optico USB", precio_sin_iva: NumberDecimal("15000.00"), stock: NumberInt(23) },
  { _id: 2, codigo_producto: NumberInt(2), marca: "Ipsum", nombre: "Teclado mecanico", descripcion: "Teclado USB con switches mecanicos", precio_sin_iva: NumberDecimal("25000.00"), stock: NumberInt(14) },
  { _id: 3, codigo_producto: NumberInt(3), marca: "Dolor", nombre: "Auriculares", descripcion: "Auriculares bluetooth", precio_sin_iva: NumberDecimal("32000.00"), stock: NumberInt(17) },
  { _id: 4, codigo_producto: NumberInt(4), marca: "Sit", nombre: "Webcam HD", descripcion: "Camara web 1080p", precio_sin_iva: NumberDecimal("45000.00"), stock: NumberInt(5) },
  { _id: 5, codigo_producto: NumberInt(5), marca: "Lorem", nombre: "Monitor 24 pulgadas", descripcion: "Monitor LED Full HD", precio_sin_iva: NumberDecimal("120000.00"), stock: NumberInt(12) },
  { _id: 6, codigo_producto: NumberInt(6), marca: "Amet", nombre: "Notebook 15 pulgadas", descripcion: "Notebook de oficina", precio_sin_iva: NumberDecimal("550000.00"), stock: NumberInt(3) }
]);

// En MongoDB se guardan facturas desnormalizadas: cliente e items quedan embebidos
// como foto historica de la operacion, util para reportes y consultas rapidas.

db.facturas.insertMany([
  {
    _id: 1,
    nro_factura: NumberInt(1),
    fecha: ISODate("2026-04-03T00:00:00Z"),
    cliente: { nro_cliente: NumberInt(2), nombre: "Kai", apellido: "Bullock" },
    items: [
      { nro_item: NumberInt(1), codigo_producto: NumberInt(1), marca: "Ipsum", nombre: "Mouse inalambrico", cantidad: NumberDecimal("2.00"), precio_unitario_sin_iva: NumberDecimal("15000.00"), porcentaje_descuento: NumberDecimal("0.00"), subtotal_sin_iva: NumberDecimal("30000.00") },
      { nro_item: NumberInt(2), codigo_producto: NumberInt(3), marca: "Dolor", nombre: "Auriculares", cantidad: NumberDecimal("1.00"), precio_unitario_sin_iva: NumberDecimal("32000.00"), porcentaje_descuento: NumberDecimal("0.00"), subtotal_sin_iva: NumberDecimal("32000.00") }
    ],
    total_sin_iva: NumberDecimal("62000.00"),
    iva: NumberDecimal("13020.00"),
    total_con_iva: NumberDecimal("75020.00")
  },
  {
    _id: 2,
    nro_factura: NumberInt(2),
    fecha: ISODate("2026-04-05T00:00:00Z"),
    cliente: { nro_cliente: NumberInt(1), nombre: "Jacob", apellido: "Cooper" },
    items: [
      { nro_item: NumberInt(1), codigo_producto: NumberInt(2), marca: "Ipsum", nombre: "Teclado mecanico", cantidad: NumberDecimal("6.00"), precio_unitario_sin_iva: NumberDecimal("25000.00"), porcentaje_descuento: NumberDecimal("5.00"), subtotal_sin_iva: NumberDecimal("142500.00") }
    ],
    total_sin_iva: NumberDecimal("142500.00"),
    iva: NumberDecimal("29925.00"),
    total_con_iva: NumberDecimal("172425.00")
  },
  {
    _id: 3,
    nro_factura: NumberInt(3),
    fecha: ISODate("2026-04-06T00:00:00Z"),
    cliente: { nro_cliente: NumberInt(3), nombre: "Mia", apellido: "Torres" },
    items: [
      { nro_item: NumberInt(1), codigo_producto: NumberInt(4), marca: "Sit", nombre: "Webcam HD", cantidad: NumberDecimal("10.00"), precio_unitario_sin_iva: NumberDecimal("45000.00"), porcentaje_descuento: NumberDecimal("10.00"), subtotal_sin_iva: NumberDecimal("405000.00") }
    ],
    total_sin_iva: NumberDecimal("405000.00"),
    iva: NumberDecimal("85050.00"),
    total_con_iva: NumberDecimal("490050.00")
  }
]);

// Indices de apoyo
db.clientes.createIndex({ nro_cliente: 1 }, { unique: true });
db.clientes.createIndex({ nombre: 1, apellido: 1 });
db.productos.createIndex({ codigo_producto: 1 }, { unique: true });
db.productos.createIndex({ marca: 1 });
db.facturas.createIndex({ nro_factura: 1 }, { unique: true });
db.facturas.createIndex({ "cliente.nro_cliente": 1 });
db.facturas.createIndex({ fecha: 1 });
db.facturas.createIndex({ "items.marca": 1 });


// 3. VISTAS EN MONGODB

db.createView("v_facturas_ordenadas", "facturas", [
  { $sort: { fecha: 1, nro_factura: 1 } }
]);

db.createView("v_productos_no_facturados", "productos", [
  {
    $lookup: {
      from: "facturas",
      let: { codProducto: "$codigo_producto" },
      pipeline: [
        { $unwind: "$items" },
        { $match: { $expr: { $eq: ["$items.codigo_producto", "$$codProducto"] } } }
      ],
      as: "facturas_encontradas"
    }
  },
  { $match: { facturas_encontradas: { $size: 0 } } },
  { $project: { facturas_encontradas: 0 } }
]);


// 4. CONSULTAS DE LOS REQUERIMIENTOS EN MODELO DOCUMENTAL

print("\nREQ 1 - Clientes con telefonos");
db.clientes.find(
  {},
  { _id: 0, nro_cliente: 1, nombre: 1, apellido: 1, direccion: 1, activo: 1, telefonos: 1 }
).forEach(doc => printjson(doc));

print("\nREQ 2 - Telefonos de Jacob Cooper");
db.clientes.find(
  { nombre: "Jacob", apellido: "Cooper" },
  { _id: 0, nro_cliente: 1, telefonos: 1 }
).forEach(doc => printjson(doc));

print("\nREQ 3 - Cada telefono junto con datos del cliente");
db.clientes.aggregate([
  { $unwind: "$telefonos" },
  {
    $project: {
      _id: 0,
      nro_cliente: 1,
      nombre: 1,
      apellido: 1,
      direccion: 1,
      activo: 1,
      cod_area: "$telefonos.cod_area",
      nro_telefono: "$telefonos.nro_telefono",
      tipo: "$telefonos.tipo"
    }
  }
]).forEach(doc => printjson(doc));

print("\nREQ 4 - Clientes con al menos una factura");
db.facturas.aggregate([
  {
    $group: {
      _id: "$cliente.nro_cliente",
      nombre: { $first: "$cliente.nombre" },
      apellido: { $first: "$cliente.apellido" }
    }
  },
  { $project: { _id: 0, nro_cliente: "$_id", nombre: 1, apellido: 1 } }
]).forEach(doc => printjson(doc));

print("\nREQ 5 - Clientes sin facturas");
db.clientes.aggregate([
  {
    $lookup: {
      from: "facturas",
      localField: "nro_cliente",
      foreignField: "cliente.nro_cliente",
      as: "facturas"
    }
  },
  { $match: { facturas: { $size: 0 } } },
  { $project: { _id: 0, facturas: 0 } }
]).forEach(doc => printjson(doc));

print("\nREQ 6 - Clientes con cantidad de facturas");
db.clientes.aggregate([
  {
    $lookup: {
      from: "facturas",
      localField: "nro_cliente",
      foreignField: "cliente.nro_cliente",
      as: "facturas"
    }
  },
  { $addFields: { cantidad_facturas: { $size: "$facturas" } } },
  { $project: { _id: 0, facturas: 0 } }
]).forEach(doc => printjson(doc));

print("\nREQ 7 - Facturas de Kai Bullock");
db.facturas.find(
  { "cliente.nombre": "Kai", "cliente.apellido": "Bullock" },
  { _id: 0 }
).forEach(doc => printjson(doc));

print("\nREQ 8 - Productos facturados al menos una vez");
db.facturas.aggregate([
  { $unwind: "$items" },
  {
    $group: {
      _id: "$items.codigo_producto",
      marca: { $first: "$items.marca" },
      nombre: { $first: "$items.nombre" }
    }
  },
  { $project: { _id: 0, codigo_producto: "$_id", marca: 1, nombre: 1 } }
]).forEach(doc => printjson(doc));

print("\nREQ 9 - Facturas con productos de marca Ipsum");
db.facturas.find(
  { "items.marca": "Ipsum" },
  { _id: 0 }
).forEach(doc => printjson(doc));

print("\nREQ 10 - Gasto total con IVA por cliente");
db.facturas.aggregate([
  {
    $group: {
      _id: {
        nro_cliente: "$cliente.nro_cliente",
        nombre: "$cliente.nombre",
        apellido: "$cliente.apellido"
      },
      total_gastado_con_iva: { $sum: "$total_con_iva" }
    }
  },
  {
    $project: {
      _id: 0,
      nro_cliente: "$_id.nro_cliente",
      nombre: "$_id.nombre",
      apellido: "$_id.apellido",
      total_gastado_con_iva: 1
    }
  }
]).forEach(doc => printjson(doc));

print("\nREQ 11 - Vista facturas ordenadas por fecha");
db.v_facturas_ordenadas.find({}, { _id: 0 }).forEach(doc => printjson(doc));

print("\nREQ 12 - Vista productos no facturados");
db.v_productos_no_facturados.find({}, { _id: 0 }).forEach(doc => printjson(doc));


// 5. FUNCIONALIDADES CRUD DE APOYO EN MONGODB

function crearCliente(cliente) {
  return db.clientes.insertOne(cliente);
}

function modificarCliente(nroCliente, cambios) {
  return db.clientes.updateOne(
    { nro_cliente: NumberInt(nroCliente) },
    { $set: cambios }
  );
}

function bajaLogicaCliente(nroCliente) {
  return db.clientes.updateOne(
    { nro_cliente: NumberInt(nroCliente) },
    { $set: { activo: false } }
  );
}

function eliminarClienteFisico(nroCliente) {
  return db.clientes.deleteOne({ nro_cliente: NumberInt(nroCliente) });
}

function crearProducto(producto) {
  return db.productos.insertOne(producto);
}

function modificarProducto(codigoProducto, cambios) {
  return db.productos.updateOne(
    { codigo_producto: NumberInt(codigoProducto) },
    { $set: cambios }
  );
}

print("\nFunciones CRUD disponibles: crearCliente, modificarCliente, bajaLogicaCliente, eliminarClienteFisico, crearProducto, modificarProducto");

/*
Ejemplos de uso sin ejecutarlos automaticamente:

crearCliente({
  _id: 6,
  nro_cliente: NumberInt(6),
  nombre: "Sofia",
  apellido: "Martinez",
  direccion: "Calle Ejemplo 123",
  activo: true,
  telefonos: []
});

modificarCliente(1, { direccion: "Av. Shaw 456" });
bajaLogicaCliente(1);
eliminarClienteFisico(5);

crearProducto({
  _id: 7,
  codigo_producto: NumberInt(7),
  marca: "Ipsum",
  nombre: "Mouse inalambrico PRO",
  descripcion: "Mouse optico USB",
  precio_sin_iva: NumberDecimal("18000.00"),
  stock: NumberInt(25)
});

modificarProducto(1, { precio_sin_iva: NumberDecimal("18000.00"), stock: NumberInt(30) });
*/

