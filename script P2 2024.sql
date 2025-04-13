---------- P2 2024 ----------
--*--*--*--*--*--*--*--*--

-----EJERCICIO 1

do $$
declare
	v_cod_proveedor integer := 1735;
begin
	
	--actualización de precio
	update producto.producto as pd
	set precio_unitario = pd.precio_unitario * 1.15
	from persona.proveedor as pv
	where pd.id_proveedor = pv.id and pv.codigo = v_cod_proveedor;

	raise notice 'precios actualizados para el proveedor con código %', v_cod_proveedor;

	--manejo de errores
	exception
	when others then
	raise warning 'error de actualización de precios';
	
end $$;



-----EJERCICIO 2

select 
	s.codigo as cod_sucursal,
	s.descripcion as nombre_sucursal,
	coalesce(p.descripcion, 'provincia desconocida') as nombre_provincia,
	coalesce(l.descripcion, 'localidad desconocida') as nombre_localidad,
	sum(f.total) as total_ventas

from persona.sucursal s 

left join persona.localidad l on s.id_localidad = l.id --unión entre sucursal y localidad
left join persona.provincia p on l.id_provincia = p.id --unión entre localidad y provincia
join persona.empleado e on e.id_sucursal = s.id --unión entre sucursal y empleado
join venta.factura f on f.id_empleado = e.id --unión entre empleado y factura

where f.fecha is not null

group by cod_sucursal, nombre_sucursal. nombre_provincia, nombre_localidad

order by total_ventas desc;



-----EJERCICIO 3

create or replace view vista_facturacion_dw 
select 
	c.codigo as cod_cliente,
	f.numero as nro_factura,
	extract(year from f.fecha) as anio,
	extract(month from f.fecha) as mes,
	extract(day from f.fecha) as dia,
	sum(f.total) as total_facturado,
	p.codigo as cod_producto,
	sum(fd.cantidad) as cantidad,
	p.precio_unitario as precio,
	p.costo_unitario as costo,

from persona.cliente c

join venta.factura f on f.id_cliente = c.id --unión entre cliente y factura
join venta.factura_detalle fd on fd.id_factura = f.id --unión entre factura y factura_detalle
join producto.producto p on fd.id_producto = p.id --unión entre factura_detalle y producto

where (extract(year from f.fecha) > 2021 and f.fecha is not null);


-----------------------------
/*Incrementar el precio unitario de los productos en un 10% para aquellos
 asociados a un proveedor cuyo código es pasado como parámetro.
Implementar el ajuste en un procedimiento almacenado que reciba el código del proveedor como parámetro.*/

  


		
 	





	



