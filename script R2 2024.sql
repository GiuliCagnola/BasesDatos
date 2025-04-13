---------- R2 2024 ----------
--*--*--*--*--*--*--*--*--

-----EJERCICIO 1 - Actualización de escritura y pasaje de datos

--crear la tabla factura_estado
create table venta.factura_estado(
	id bigint not null,
	id_factura bigint not null,
	item_estado integer not null,
	fechaHora_estado time with time zone not null,
	tipo_estado varchar(10) not null default 'ET',
	observacion_estado varchar(255) null,
	
	constraint pk_facturaEstado primary key (id),
	constraint fk_facturaEstado_factura foreign key (id_factura) references venta.factura(id),
	constraint uk_facturaEstado unique(id_factura, item_estado),
	constraint chk_tipoEstado check (tipo_estado in ('ET', 'OK', 'AN'))
);

--secuencia para manejar los ids de factura_estado
create sequence facturaEstado_sequence start 1;
alter table venta.factura_estado alter column id set default nextval('facturaEstado_sequence');


alter table venta.factura add column id_estado_actual bigint null;
alter table venta.factura add constraint fk3_factura_facturaEstado foreign key(id_estado_actual) references venta.factura_estado(id);

--agrego las columnas fecha_confirmacion y fecha_anulacion que no estaban en la tabla original
alter table venta.factura 
	add column fecha_anulacion date null,
	add column fecha_confirmacion date null,
	rename column fecha to fecha_registro;


--insertar los datos de factura en factura_estado
insert into venta.factura_estado (
    id,
    id_factura,
    item_estado,
    fechaHora_estado,
    tipo_estado,
    observacion_estado
)
select
    nextval('facturaEstado_sequence') AS id,
    id as id_factura,
    1 as item_estado, 
    NOW() as fechaHora_estado, 
    case 
        when fecha_anulacion is not null then 'AN' 
        when fecha_confirmacion is not null then'OK' 
        else 'ET' 
    end as tipo_estado,
    null as observacion_estado 
from venta.factura f; 

--asignar valor a venta.factura.id_estado_actual a partir del último estado registrado
update venta.factura f
set id_estado_actual = fe.id
from (
	select distinct on (id_factura)
	id_factura, id
	from venta.factura_estado fe
	order by id_factura, fechaHora_estado desc
) fe
where f.id = fe.id_factura;

--eliminar información redundante de factura (ya está pasada a factura_estado)
alter table venta.factura 
	drop column fecha_anulacion,
	drop column fecha_confirmacion;

--verificar (en ambas tablas hay 2021 registros, es decir que hay una correspondencia 1 a 1)
select * 
from venta.factura_estado fe;


select *
from venta.factura f
join venta.factura_estado fe on f.id_estado_actual = fe.id;


-----EJERCICIO 2 - Función en PostgreSQL

create or replace function venta.f_calcular_promedio(anio integer, mes integer, p_marca varchar(50))
returns numeric as $$
declare
    promedio numeric;
begin
    -- verificar que la marca no exista
    if p_marca <> '*' and not exists (
        select 1
        from producto.marca m
        where m.descripcion = p_marca
    ) then
        raise notice 'la marca % no existe', p_marca;
    end if;

    -- calcular el promedio considerando todas las marcas
    if p_marca = '*' then
        select avg(f.total) into promedio
        from venta.factura f
        join venta.factura_estado fe on fe.id_factura = f.id -- unión entre factura y factura_estado
        where (
			fe.tipo_estado = 'ok' -- solamente facturas confirmadas
            and extract(year from f.fecha_registro) = anio
            and extract(month from f.fecha_registro) = mes
        );
    else
        -- calcular el promedio de una marca específica
        select avg(f.total) into promedio
        from venta.factura f
        join venta.factura_estado fe on fe.id_factura = f.id -- unión entre factura y factura_estado
        join venta.factura_detalle fd on fd.id_factura = f.id -- unión entre factura y factura_detalle
        join producto.producto p on fd.id_producto = p.id -- unión entre factura_detalle y producto
        join producto.marca m on p.id_marca = m.id -- unión entre producto y marca
        where (
            fe.tipo_estado = 'ok' -- solamente facturas confirmadas
            and extract(year from f.fecha_registro) = anio
            and extract(month from f.fecha_registro) = mes
            and m.descripcion = p_marca -- coincidencias por marca
        );
    end if;

    return coalesce(promedio, 0);
end;
$$ language plpgsql;


select *
from venta.f_calcular_promedio(2021, 02, '*'); --da 0 porque todas las facturas tienen estado 'ET', no 'OK'

select * 
from venta.factura f 
where extract(year from f.fecha_registro) = 2021 and extract(month from f.fecha_registro) = 02


-----EJERCICIO 3 - Facturación mensual a clientes

select 
	c.codigo as cod_cliente,
	case 
		when p.tipo = 'FISICA' then pf.apellido || ' ' || pf.nombre
		when p.tipo = 'JURIDICA' then pj.denominacion
	end as identificacion,
	extract(month from f.fecha_registro) as mes,
	sum(f.total) as total_facturado

from persona.persona p

left join persona.persona_fisica pf on pf.id_persona = p.id --unión entre persona y persona_fisica
left join persona.persona_juridica pj on pj.id_persona = p.id --unión entre persona y persona_juridica
join persona.cliente c on c.id_persona = p.id --unión entre persona y cliente
join venta.factura f on f.id_cliente = c.id --unión entre cliente y factura
join venta.factura_estado fe on fe.id_factura = f.id --unión entre factura y factura_estado

where (
	fe.tipo_estado = 'OK' --solo facturas confirmadas
	and extract (year from f.fecha_registro) = 2023 --facturas del año 2023
)
group by c.codigo, p.tipo, pf.apellido, pf.nombre, pj.denominacion, f.fecha_registro

having sum(f.total) > (
	--subconsulta para calcular el promedio de facturación mensual
	select avg(f2.total)
	from venta.factura f2
	join venta.factura_estado fe2 on fe2.id_factura = f2.id
	where(
		fe2.tipo_estado = 'OK'
		and extract(year from f2.fecha_registro) = 2023
		and extract(mont from f2.fecha_registro) = extract(month from f.fecha_registro)--promedio para el mismo mes
	)
)
order by total_facturado desc;

-----EJERCICIO 4 - Actualización de precios

create table producto.historial_precios(
	id_producto bigint not null,
	fecha_hora_modificacion date not null default now(),
	precio_anterior numeric(38,2) not null,
	
	constraint pk_historialPrecios primary key(id_producto),
	
	constraint fk_historialPrecios_producto foreign key(id_producto) references producto.producto(id)
)

create or replace function registrar_cambio_precio()
returns trigger as $$
begin
	--insertar un registro en el historial de precios
	insert into producto.historial_precios(id_producto, fecha_hora_modificacion, precio_anterior)
	values(new.id(), now(), old.precio_unitario);
	
	return new;
end;
$$ language plpgsql;

create trigger trigger_registrar_cambio_precio
after update of precio_unitario on producto.producto 
for each row
execute function registrar_cambio_precio();

--modificación para probar
update producto.producto
set precio_unitario = 100800 -- precio_anterior = 100675
where id = 77;

select * from producto.historial_precios hp ;

----- EJERCICIO 5 - Concurrencia

create table producto.inventario (
    id bigint not null,
    id_producto bigint not null,
    cantidad integer not null,
    fecha_actualizacion timestamp not null default now(),
    constraint inventario_pk primary key (id),
    constraint inventario_producto_fk foreign key (id_producto) references producto.producto (id)
 );


--cargar un par de datos de prueba en inventario
insert into producto.inventario(id, id_producto, cantidad, fecha_actualizacion) values
	(1, 77, 5, now()),
	(2, 78, 10, now()),
	(3, 79, 0, now()),
	(4, 80, 1, now()),
	(5, 81, 8, now());



--El nivel de aislamiento SERIALIZABLE ejecuta las transacciones secuencialmente, evitando totalmente las concurrencias

begin transaction isolation level serializable;

--Ejemplo: Dos usuarios queriendo vender el mismo producto (y actualizar el inventario) al mismo tiempo

--1) Verificar si hay stock
select cantidad
from producto.inventario i 
where (
	id_producto = 77 --selecciono un producto
	and cantidad > 1
);
--2) Actualizar el inventario después de verificar
update producto.inventario 
set cantidad = cantidad -1, fecha_actualizacion = now() --se vendió 1 unidad del producto
where id_producto = 77;

select * from producto.inventario i ;

--3) Confirmar la venta 
commit ;

--El bloqueo pesimista bloquea todas las modificaciones mientras se está realizando la transacción, para evitar concurrencias
begin;
--1) Bloquear el producto del inventario
select cantidad
from producto.inventario i 
where id_producto = 78
for update; -- for update bloquea la fila del producto hasta que finalice la transacción

--2) Actualizar el inventario después de verificar
update producto.inventario 
set cantidad = cantidad -2, fecha_actualizacion = now() --se vendieron 2 unidades del producto
where id_producto = 78;

--3) Confirmar la venta
commit;

/* En el nivel de aislamiento SERIALIZABLE PostgreSQL genera bloqueos de rango (range locks) para evitar conflictos de
 lectura/escritura entre transacciones concurrentes. 
 Con el bloqueo pesimista definido mediante FOR UPDATE se bloquea la fila seleccionada en el where para modificaciones,
 pero no para realizar operaciones de lectura (FOR SHARE)
 
 Los bloqueos definidos en en nivel serializable y en el bloqueo pesimista se desbloquean al finalizar la transacción 
 (ya sea con COMMIT para confirmarla o ROLLBACK para descartarla)
 */

--EJERCICIO 6 - SQL dinámico








