---------- GUIA 2 DML ----------
--*--*--*--*--*--*--*--*--*--*--

----- PREDICADOS -----

----- Comparación (>, >=, <, <=, =, <>)
select * 
from producto p 
where p.precio_unitario > 100500;


select *
from factura f 
where f.numero = 110;

-----between 
select *
from producto p 
where p.precio_unitario between 100500 and 100555;


select *
from factura f 
where f.fecha between '2023-01-01' and '2023-06-30';

-----in/not in
select *
from subcategoria s 
where id in (1, 3, 5);


select c.*, p.*, l.* 
from cliente c
join persona p on c.id_persona = p.id -- unión entre persona y cliente
join localidad l on p.id_localidad = l.id -- unión entre localidad y persona 
where l.descripcion in ('Santa Fe', 'Rosario', 'Paraná');


-----like/not like
select descripcion
from producto p 
where descripcion like 'S%';


select descripcion
from producto p 
where descripcion like '%USB%' and descripcion like '%Adaptador%';

-----null
select *
from producto p 
where id_subcategoria is null;


select c.codigo, c.fecha_alta, p.email, 
       case
           when p.tipo = 'FISICA' then pf.nombre || ' ' || pf.apellido
           when p.tipo = 'JURIDICA' then pj.denominacion
       end 
from cliente c
join persona p on c.id_persona = p.id
left join persona_fisica pf on p.id = pf.id_persona
left join persona_juridica pj on p.id = pj.id_persona
where p.email is not null;
---verificar
select 
    count(*) as total_personas,
    count(case when p.email is not null then 1 end) as personas_con_email,
    count(case when p.email is null then 1 end) as personas_sin_email
from persona p;

-----exist
select c.descripcion
from categoria c 
where exists
(
select 1 --subconsulta (join entre subcategoria y producto)
from subcategoria s 
join producto p on p.id_subcategoria=s.id
where s.id_categoria=c.id
);


select m.descripcion
from marca m
where exists(
select 1
from producto p 
where p.id_marca=m.id and p.precio_unitario>100500
);

-----FUNCIONES AGREGADAS-----

-----Funciones agregadas básicas
select 
    extract(year from f.fecha) as anio, 
    extract(month from f.fecha) as mes, 
    count(f.id) AS cant_facturas
from
    venta.factura f 
where
    f.total > 
    (
        select AVG(f1.total)
        from venta.factura f1
        where
            extract(year from f1.fecha) = extract(year from f.fecha)
            and extract(month from f1.fecha) = extract(month from f.fecha)
    )
group by 
    extract(year from f.fecha), extract(month from f.fecha)
order by anio, mes;


select count(*) as total_clientes
from cliente c;


select m.descripcion, min(p.precio_unitario) as precio_min, max(p.precio_unitario) as precio_max
from producto p 
join marca m on p.id_marca = m.id
group by m.descripcion;


select m.descripcion
from producto p 
join marca m on p.id_marca=m.id
order by m.descripcion;


select sum(f.total) as total_ventas
from factura f 

-----Alias de columnas y tablas
select m.descripcion as nombre_marca, avg(p.precio_unitario) as precio_promedio
from marca m 
join producto p on p.id_marca = m.id 
group by nombre_marca


select m.descripcion as nombre, p.precio_unitario as precio
from marca m 
join producto p on p.id_marca = m.id 
order by nombre, precio;


-----SUBCONSULTAS-----

-----subconsultas anidadas: Se ejecutan independientemente de la consulta externa. Se ejecuta primero y los resultados se evalúan
--en la consulta externa.

select *
from producto p 
where precio_unitario > (select avg(precio_unitario) from producto p2) ;

select m.descripcion as nombre_marca, count(p.id) as cant_productos
from marca m 
join producto p on p.id_marca = m.id 
group by m.descripcion 
having count(p.id) > 
	(
	select count (p2.id)
	from marca m2 
	join producto p2 on p2.id_marca = m2.id 
	where m2.descripcion = 'MSI'
	)
order by cant_productos desc;

-----subconsultas correlacionadas: Dependen de la consulta externa. Se ejecuta para cada fila de la consulta externa (comparación 1 a 1) 

select 
	extract (year from f.fecha) as anio,
	extract (month from f.fecha) as mes,
	count(*) as cant_facturas
from factura f
where f.total >
	(
	select avg(f1.total) 
	from factura f1
	where extract (year from f1.fecha) = extract(year from f.fecha) and extract (month from f1.fecha) = extract(month from f.fecha)
	)
group by extract (year from f.fecha), extract (month from f.fecha)
order by anio, mes;


select m.descripcion as nombre_marca, count(p.id) as cant_productos
from marca m 
join producto p on p.id_marca = m.id 
group by m.descripcion 
having count(p.id)>15
order by cant_productos;

-----JOINS-----
/*Los joins permiten combinar filas de dos o más tablas en función de una dada condición de relación. 
 * Join equidistante: La combinación se da mediante una condición de igualdad (=)
 * Join condicional: La combinación se da mediante una o varias condiciones
 * Join no equidistante: Se utilizan operadores relacionales de comparación (>, <, !=, etc)
 * Join multitabla: Se concatenan varios joins entre varias tablas
 * Join externo (left, rigth, full): Permiten combinar filas incluso si no hay coincidencias entre ambas tablas.
 A las columnas que faltan se le asigna el valor null 
 */

select m.descripcion as nombre_marca, p.descripcion as nombre_producto
from marca m
join producto p on p.id_marca = m.id
order by nombre_marca, nombre_producto;


select p.descripcion as nombre_producto, c.descripcion as nombre_categoria
from producto p 
join subcategoria s on p.id_subcategoria = s.id 
join categoria c on s.id_categoria = c.id 
where p.precio_unitario > 100500
order by nombre_producto, nombre_categoria;


select p.descripcion as nombre_producto, c.descripcion as nombre_categoria
from producto p 
left join subcategoria s on p.id_subcategoria = s.id 
left join categoria c on s.id_categoria = c.id 
where p.precio_unitario between 100000 and 100500
order by nombre_producto, nombre_categoria;


select p.descripcion as nombre_producto, p.precio_unitario as precio_producto
from producto p 
join producto p2 on p.precio_unitario > p2.precio_unitario and p.id_marca <> p2.id_marca 
join marca m on p.id_marca = m.id 
order by nombre_producto;


select p.descripcion as nombre_producto, m.descripcion as nombre_marca, c.descripcion as nombre_categoria
from producto p 
join marca m on p.id_marca = m.id 
left join subcategoria s on p.id_subcategoria = s.id
left join categoria c on s.id_categoria = c.id 
order by nombre_marca, nombre_categoria, nombre_producto;


select m.descripcion as nombre_marca, p.descripcion as nombre_producto
from marca m 
left join producto p on p.id_marca = m.id
order by nombre_marca, nombre_producto;


-----DISTINCT-----
--distinct elimina filas duplicadas en los resultados de una consulta. Sirve para obtener resultados únicos (no repetidos)

select  distinct l.descripcion as nombre_localidad
from persona p 
join localidad l on p.id_localidad = l.id;


select  distinct pf.apellido 
from persona_fisica pf ;


select count(distinct c.id) as cant_categorias
from categoria c;


select *
from producto p 
order by p.id 
limit 10;


--limitando la salida a los primeros 5 productos
select m.descripcion as nombre_marca, p.descripcion as nombre_producto
from marca m 
join producto p on p.id_marca = m.id 
order by nombre_marca, nombre_producto
limit 5;

--limitando la salida a las primeras 5 marcas (una marca tiene muchos productos, hago una subconsulta)
select m.descripcion as nombre_marca, p.descripcion as nombre_producto
from (
	select *
	from marca m 
	order by m.descripcion
	limit 5
	) as m
join producto p on p.id_marca = m.id
order by nombre_marca, nombre_producto;


select *
from cliente c 
limit 15;


