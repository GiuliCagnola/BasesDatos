---------- GUIA 1 DML ----------
--*--*--*--*--*--*--*--*--*--*--

-----TABLA PRODUCTO-----
------------------------

----- EJERCICIO 1 (select simple) -----

-- SELECT limita las columnas
-- FROM limita las filas
-- WHERE establece la condición
-- ORDER BY ordena los resultados según la columna

select * from categoria c ;

select * from producto p ;

select * from marca m ;

select codigo, descripcion from producto p where descripcion like 'E%' order by descripcion ;


----- EJERCICIO 2 (enlace de dos tablas) -----
	
-- JOIN une las tablas (producto y marca en este caso)
-- ON establece la condición de unión: unir las filas donde el código de la marca coincida con la fk id_marca de producto

select m.codigo as cod_marca, p.codigo as codigo_producto
from marca m 
join producto p on m.codigo = p.id_marca
where m.descripcion in ('Acer', 'AMD')
order by m.codigo, p.descripcion;


-----EJERCICIO 3 (salidas agrupadas) -----

-- COUNT cuenta la cantidad total de filas
-- GROUP BY agrupa los resultados (por id_marca en este caso)
-- HAVING filtra los resultados despues de agrupar
-- DESC indica orden descendiente en el ordenamiento (mayor a menor cantidad de prductos por marca)

select id_marca, count (*) as cant_productos 
from producto p
group by id_marca
order by id_marca;

select m.descripcion, count(p.codigo) as cant_productos -- nombre de la marca y cantidad de productos asociados
from marca m 
join producto p on m.codigo = p.id_marca -- codigo de la marca a la que pertenece cada producto
group by m.descripcion 
having count(p.codigo) >=3 --restrinjo a al menos 3 productos por marca
order by cant_productos desc;


-----TABLA PERSONA-----
-----------------------

----- EJERCICIO 4 (otras consultas) -----

select min(fecha_nacimiento) as fecha_nacimiento_antigua from persona_fisica pf ;

select max(fecha_nacimiento) as fecha_nacimiento_reciente from persona_fisica pf ;

select *
from persona_fisica pf 
where fecha_nacimiento = (select min(fecha_nacimiento) from persona_fisica)
or fecha_nacimiento = (select max(fecha_nacimiento) from persona_fisica)
order by apellido, nombre;




