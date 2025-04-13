---------- TP1 ----------
--*--*--*--*--*--*--*--*--

-----ESQUEMA PERSONA-----
-------------------------

----- Sucursales con información de empleados
select
	s.descripcion as nombre_sucursal,
	l.descripcion as nombre_localidad,
	p.descripcion as nombre_provincia,
	pf.apellido as apellido_empleado,
	pf.nombre as nombre_empleado
from sucursal s 
join localidad l on l.id = s.id_localidad --unión entre sucursal y localidad
join provincia p on p.id = l.id_provincia --unión entre localidad y provincia
join empleado e on s.id = e.id_sucursal --unión entre empleado y sucursal
join persona_fisica pf on pf.id = e.id_persona_fisica --unión entre empleado y persona física
order by nombre_provincia, nombre_localidad, nombre_sucursal, apellido_empleado, nombre_empleado;


----- Clientes con información de datos personales

select p.tipo,
case
	when p.tipo = 'FISICA' then pf.apellido || ' ' || pf.nombre
	when p.tipo = 'JURIDICA' then pj.denominacion
end as denominacion,
case
	when p.tipo = 'FISICA' then pf.cuil
	when p.tipo = 'JURIDICA' then pj.cuit
end as identificacion,
l.descripcion as nombre_localidad,
p2.descripcion as nombre_provincia
from persona.cliente c 
join 
	persona.persona p on p.id = c.id_persona -- unión entre cliente y persona
left join 
	persona.persona_fisica pf on p.id = pf.id_persona and p.tipo = 'FISICA' -- unión entre persona y persona física (si existe)
left join 
	persona.persona_juridica pj on p.id = pj.id_persona and p.tipo = 'JURIDICA' -- unión entre persona y persona jurídica (si existe)
left join 
	persona.localidad l on l.id = p.id_localidad -- unión entre persona y localidad
left join
	persona.provincia p2 on p2.id = l.id_provincia -- unión entre localidad y provincia 
order by denominacion;
---------------



----- Proveedores con información de datos personales


----- Personas con múltiples roles


-----ESQUEMA PRODUCTO-----
-------------------------

----- Productos con información de marca, categoría y proveedor
select * 
from producto p 
join marca m on m.id = p.id_marca --unión entre producto y marca
join subcategoria s on s.id = p.id_subcategoria --unión entre producto y subcategoría
join categoria c on c.id = s.id_categoria -- unión entre subcategoría y categoría
--falta proveedor
order by m.descripcion, p.descripcion, c.descripcion ;



-----ESQUEMA VENTA-----
-------------------------

----- Consulta de facturas con sus detalles
create function reporte_facturas(f1, f2);


----- Volumen de ventas por año-mes
create function total_ventas(anio, mes);

----- Ranking de productos, clientes y empleados


