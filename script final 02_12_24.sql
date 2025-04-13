---------- FINAL 02/12/24 ----------
--*--*--*--*--*--*--*--*--*--*--*--*

-----EJERCICIO 1 

create or replace function public.f_calcular_performance_empleados(anio integer)
returns table (
	posicion integer,
	nombre varchar(50),
	apellido varchar(50),
	sucursal varchar(100),
	localidad varchar(100),
	monto_facturado numeric,
	cant_facturas_confirmadas integer,
	promedio_factura numeric
) as $$
begin 
	return query
	select 
		rank() over (order by monto_facturado desc) as posicion,
		pf.nombre as nombre_empleado,
		pf.apellido as apellido_empleado,
		s.descripcion as sucursal,
		l.descripcion as localidad,
		sum(f.total) as monto_facturado,
		sum(f.id) as cant_facturas_confirmadas,
		monto_facturado/cant_facturas_confirmadas as promedio_factura
		
	from persona.persona_fisica pf
	
	join persona.empleado e on e.id_persona_fisica = pf.id --unión entre persona_fisca y empleado
	join persona.sucursal s on e.id_sucursal = s.id --unión entre empleado y sucursal
	join persona.localidad l on s.id_localidad = l.id --unión entre sucursal y localidad
	join venta.factura f on f.id_empleado = e.id --unión entre empleado y factura
	join venta.factura_estado fe on f.id_estado_actual = fe.id --unión entre factura y factura_estado
	
	where (
		fe.tipo_estado = 'OK' --solamente facturas confirmadas
		and extract(year from f.fecha_registro) = anio
	)
	group by nombre_empleado, apellido_empleado, sucursal, localidad
	order by monto_facturado desc;
	
end;
 $$ language plpgsql;

select * from public.f_calcular_performance_empleados(extract (year from current_date-1)); --cálculo para el año anterior

select * 
from public.f_calcular_performance_empleados(2023)
where apellido_empleado = 'García';

--creo la tabla top3_empleados_anual
create table persona.top3_empleados_anual(

	id bigint not null,
	anio integer not null,
	posicion integer not null,
	id_empleado bigint not null,
	monto_facturado numeric not null,
	
	constraint pk_top3_empleados_anual primary key(id),
	constraint fk_top3_empleados_anual_empleado foreign key(id_empleado) references persona.empleado(id),
	constraint uk_top3_empleados_anual unique(anio, posicion),
	constraint chk_top3_empleados_anual check (posicion in (1,2,3))	
);

--batch para almacenar los empleados en la tabla 
do $$
begin
	--1) Eliminar el contenido de la tabla top3_empleados_anual
	truncate table persona.top3_empleados_anual;
	
	--2) Indentificar los años en los que se han registrado ventas
	for anio in(
		select distinct extract (year from f.fecha_registro):: integer as anio
		from venta.factura f
		join venta.factura_estado fe on fe.id_factura = f.id --unión entre factura y factura_estado	
		where fe.tipo_estado = 'OK' -- solo facturas confirmadas
	) loop
	--3) Insertar los 3 primeros empleados con mayor facturacion
		insert into top3_empleados_anual
		select *
		from public.f_calcular_performance_empleados(anio)
		where posicion <= 3;
	end loop;
	--4) Devolver los datos mediante una consulta, ordenados por año y posición
	return query
	select *
	from persona.top3_empleados_anual
	order by anio, posicion;

end;
$$ language plpgsql;

select *
from persona.top3_empleados_anual
where posicion = 1
order by anio;


-----EJERCICIO 2

/* Al establecer las pk automáticamente se crean los índices asociados 
Esto no sucede con las fk, sin embargo, es una buena páctica hacerlo para optimizar los joins y mantener la integridad referencial
Adicionalmente se pueden crear índices en columnas que son frecuentemente consultadas para optimizar el rendimiento, por ejemplo 
el total de la factura.
En columnas que admiten pocos valores (por ejemplo tipo_estado en factura_estado) no es necesario.
Los índices deben ser creados en las columnas de las tablas que contienen las claves foráneas, no en las tablas referenciadas */

----- crear los índices para las fk (solo para las tablas de gestión)

--tabla cliente
create index idx_cliente_persona on persona.cliente(id_persona); --fk

--tabla factura
create index idx_factura_cliente on venta.factura(id_cliente); --fk1
create index idx_factura_empleado on venta.factura(id_empleado); --fk2
create index idx_factura_estadoActual on venta.factura(id_estado_actual); --fk3
create index idx_factura_promocion on venta.factura(id_promocion); --fk4

--tabla factura_estado
create index idx_facturaEstado_factura on venta.factura_estado(id_factura); --fk

--tabla empleado
create index idx_empleado_personaFisica on persona.empleado(id_persona_fisica); --fk1
create index idx_empleado_sucursal on persona.empleado(id_sucursal); --fk2

--tabla persona_fisica
create index idx_personaFisica_persona on persona.persona_fisica(id_persona); --fk

--tabla sucursal
create index idx_sucursal_localidad on persona.sucursal(id_localidad) --fk

--tabla localidad
create index idx_localidad_provincia on persona.localidad(id_provincia); --fk

-----
--consulta para buscar facturas
select f.*
from venta.factura f
join venta.factura_estado fe on f.id_estado_actual = fe.id
where (
	fe.tipo_estado = 'OK' --solo facturas confirmadas
	and f.fecha_registro > '2023-01-01' --facturas de 2023 en adelante
);

/* La tabla factura tiene un índice correspodiente a la clave foránea que referencia a factura_estado, lo cual optimiza el join.
Sin embargo, la tabla tipo_estado no tiene un índice asociado, por lo que en la consulta se realiza una lectura secuencial,
lo cual ralentiza el tiempo de respuesta de la consulta en la condición del where. Para optimizar esta consulta, se puede crear un índice
asociado a fe.tipo_estado y f.fecha_registro */

create index idx_facturaEstado on venta.factura_estado(tipo_estado);
create index idx_factura on venta.factura(fecha_registro);

-----EJERCICIO 3

create or replace function validar_descuento_factura()
returns trigger as $$
declare
    v_descuento numeric;
begin
    if new.id_promocion is not null then
        select p.porcentaje_descuento into v_descuento
        from venta.promocion p
        where p.id = new.id_promocion;

        v_descuento := v_descuento * new.total / 100;

        if v_descuento > new.total then
            raise exception 'El descuento aplicado excede el máximo permitido';
        end if;
    else
        if new.porcentaje_descuento > 0 then
            raise exception 'No se permiten descuentos si no hay promoción asociada';
        end if;
    end if;

    return new;
end;
$$ language plpgsql;

create or replace trigger trigger_validar_descuento_factura
before insert on venta.factura 
for each row
execute function validar_descuento_factura();

--cargo un par de datos en promoción
insert into venta.promocion (id, version, codigo, descripcion, porcentaje_descuento) values
	(1, 1, 10, 'Descuento efectivo', 20),
	(2, 1, 20, 'Descuento transferencia', 15),
	(3, 1, 30, 'Promo navidad', 25);

select * from venta.promocion p ;

--borro la columna descuento de factura que pertenece a promoción
alter table venta.factura drop column descuento;

--agrego las promociones en las facturas
update venta.factura set id_promocion = 1 where id = 30;
update venta.factura set id_promocion = 2 where id = 31;
update venta.factura set id_promocion = 3 where id = 32;


--agregar una factura con descuento válido
insert into venta.factura (id, version, numero, id_cliente, id_empleado, id_promocion, id_forma_pago, fecha_registro, total , id_estado_actual)
values (19091, 0, 2046, 2086, 29, 1, 24, now(), 100000, null);

--agregar una factura con descuento inválido
insert into venta.factura (id, version, numero, id_cliente, id_empleado, id_promocion, id_forma_pago, fecha_registro, total , id_estado_actual)
values (19092, 0, 2047, 2086, 29, 2, 24, now(), 200000, null);
--cómo se verifica que se esté insertando una factura con un descuento válido?

-----EJERCICIO 4

create or replace procedure administrar_permisos(v_usuario varchar(100), v_accion varchar(100), v_tipo_app varchar(100))
language plpgsql
as $$
declare 
    v_esquema varchar(100);
    v_tabla varchar(100);
    permiso text;
    accion text;
    permisos_array text[]; -- Array para manejar múltiples permisos
begin
    -- Determinar la acción (grant o revoke)
    if v_accion = 'Conceder' then
        accion := 'grant';
    elsif v_accion = 'Revocar' then
        accion := 'revoke';
    else
        raise exception 'Acción inválida. Use "Conceder" o "Revocar".';
    end if;

    -- Aplicar permisos según el tipo de aplicación
    if v_tipo_app = 'RRHH' then
        permisos_array := array['insert', 'update', 'delete'];

        -- Aplicar permisos al esquema persona
        for v_tabla in
            select table_name
            from information_schema.tables
            where table_schema = 'persona'
        loop
            foreach permiso in array permisos_array loop
                execute format('%s %s on persona.%I to %I', accion, permiso, v_tabla, v_usuario);
            end loop;
        end loop;

    elsif v_tipo_app = 'Compras' then
        -- Permisos para el esquema persona
        permisos_array := array['select'];
        for v_tabla in
            select table_name
            from information_schema.tables
            where table_schema = 'persona'
        loop
            foreach permiso in array permisos_array loop
                execute format('%s %s on persona.%I to %I', accion, permiso, v_tabla, v_usuario);
            end loop;
        end loop;

        -- Permisos para los esquemas producto y compra
        permisos_array := array['insert', 'update', 'delete'];
        for v_esquema in
            select unnest(array['producto', 'compra'])
        loop
            for v_tabla in
                select table_name
                from information_schema.tables
                where table_schema = v_esquema
            loop
                foreach permiso in array permisos_array loop
                    execute format('%s %s on %I.%I to %I', accion, permiso, v_esquema, v_tabla, v_usuario);
                end loop;
            end loop;
        end loop;

    elsif v_tipo_app = 'Ventas' then
        -- Permisos para el esquema persona
        permisos_array := array['select'];
        for v_tabla in
            select table_name
            from information_schema.tables
            where table_schema = 'persona'
        loop
            foreach permiso in array permisos_array loop
                execute format('%s %s on persona.%I to %I', accion, permiso, v_tabla, v_usuario);
            end loop;
        end loop;

        -- Permisos para los esquemas producto y venta
        permisos_array := array['insert', 'update', 'delete'];
        for v_esquema in
            select unnest(array['producto', 'venta'])
        loop
            for v_tabla in
                select table_name
                from information_schema.tables
                where table_schema = v_esquema
            loop
                foreach permiso in array permisos_array loop
                    execute format('%s %s on %I.%I to %I', accion, permiso, v_esquema, v_tabla, v_usuario);
                end loop;
            end loop;
        end loop;

    else
        raise exception 'Aplicación inválida. Use "RRHH", "Compras" o "Ventas".';
    end if;
end;
$$;

call administrar_permisos('usuario_rrhh', 'Conceder', 'RRHH');
call administrar_permisos('usuario_compras', 'Revocar', 'Compras');
call administrar_permisos('usuario_ventas', 'Revocar', 'Ventas');

-----TEORÍA
/*
1) El principio de las bases de datos relacionales que asegura que se pueda modificar la estructura física sin afectar a la estructura
de los datos es la INDEPENDENCIA DE LOS DATOS, en particular la INDEPENDENCIA FÍSICA, ya que asegura que la estructura lógica se mantendrá
ante modificaciones que se realicen en el nivel físico.

2) Las relaciones de muchos a muchos (m, n) del MCD se transforman en tablas en el MFD, independientemente si tienen o no atributos.
Esto se debe a que hay atributos del MCD (que luego serán columnas del MFD) que no pertenecen completamente a ninguna de las dos entidades
(que luego serán tablas), por lo que se establece una tabla para diagramar esta relación. Los atributos identificativos en el MCD pasarán
a ser claves primarias (primary key) en el MDF, al igual que en los casos de dependencia de una entidad respecto de otra; y las entidades
a las cuales se referencia pasan a ser columnas de claves foráneas (foreign key).

Ejemplo: Entidades MATERIA y ALUMNO. Esta relación es de muchos a muchos, ya que un alumno puede cursar varias materias, y una materia
es cursada por muchos alumnos. Por lo tanto, a partir de la ocurrencia de una no se puede determinar la ocurrencia de la otra, y en su
lugar se crea la tabla CURSADO que establece relaciones 1-m con MATERIA y con ALUMNO

MATERIA          CURSADO             ALUMNO
código PK        codigo PK, FK1      legajo PK
nombre           legajo PK, FK2      nombre_apellido
anio                                 f_ingreso

3) Un "non repeatable read" (lectura no repetible) es un problema de concurrencia que ocurre cuando una transacción lee 
inicialmente los datos, otra transacción los modifica y luego la primera al volver a leer los datos encuentra que estos han sido 
modificados. Ejemplo: Transacción A lee el precio de un producto p.precio_unitario = 100, transacción B lo modifica a
p.precio_unitario = 200, y si A vuelve a leer el precio este tiene un valor distinto al que obtuvo en la primera lectura, 
lo cual afecta la integridad y consistencia de los datos.
Este fenómeno ocurre en los niveles de aislamiento "read uncommited" (lectura no confirmada), "read commited" (lectura confirmada)
y "repeatable read" (lectura repetible), ya que se admiten concurrencias entre transacciones, pero no puede ocurrir en el nivel
"serializable" (secuencial), ya que hasta no confirmar (commit) los cambios en una transacción, las demás transacciones quedan bloqueadas.
Para evitar este problema se puede utilizar un mayor nivel de aislamiento (set transaction isolation level serializable) o bloquear 
para modificaciones los registros que se están leyendo (select * from esquema.tabla where id = 1 for update)


 */











