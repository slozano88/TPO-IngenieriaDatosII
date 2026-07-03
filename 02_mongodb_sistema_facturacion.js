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


