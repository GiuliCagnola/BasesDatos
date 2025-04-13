create schema taller;

--Esquema correspondiente al examen final del 18/12/2023
create table taller.taller(
id bigint not null,
	codTaller integer not null,
	nombre varchar(100) not null,
	
	constraint pk_taller primary key(id),
	constraint uk_taller unique(codTaller)
);

create table taller.proyecto(
	id bigint not null,
	codProyecto integer not null,
	nombre varchar(100) not null,
	monto numeric not null,
	
	constraint pk_proyecto primary key(id),
	
	constraint uk_proyecto unique(codProyecto)
);

create table taller.sensor(
	id bigint not null,
	nroSerie integer not null,
	fecha_fabricacion date not null,
	id_taller integer not null,
	id_proyecto integer not null,
	
	constraint pk_sensor primary key(id),
	
	constraint fk1_sensor_taller foreign key(id_taller) references taller.taller(id),
	constraint fk2_sensor_proyecto foreign key(id_proyecto) references taller.proyecto(id),
	
	constraint uk_sensor unique(nroSerie)
);

create table taller.visita(
	id bigint not null,
	fecha_visita date not null,
	observaciones varchar(255) null,
	id_sensor bigint not null,
	nroSerie integer not null,
	
		
	constraint pk_visita primary key(id),
	
	constraint fk_visita_sensor foreign key(id_sensor) references taller.sensor(id),
	
	constraint uk_visita unique(nroSerie, fecha_visita)
);


create table taller.lectura_sensor(
	id bigint not null,
	momento timestamp not null,
	estado_emocional varchar(1) not null,
	id_visita integer null, --null para hacer ejemplos sin tener que crear todas las tablas de niveles inferiores
	nroSerie integer not null,
	fecha_visita date not null,
	
		
	constraint pk_lectura primary key(id),
	
	constraint fk_lectura_visita foreign key(id_visita) references taller.visita(id),
	
	constraint uk_lectura unique(nroSerie, fecha_visita, momento),
	
	constraint chk_lectura check (estado_emocional in ('P', 'A', 'S'))
);

create sequence taller.taller_sequence start with 1 increment by 1;
create sequence taller.proyecto_sequence start with 1 increment by 1;
create sequence taller.sensor_sequence start with 1 increment by 1;
create sequence taller.visita_sequence start with 1 increment by 1;
create sequence taller.lectura_sequence start with 1 increment by 1;

-----EJERCICIO 1 - Función de importación de datos

create or replace function importar_archivos_so(archivo_lecturas varchar(100), observaciones varchar(255))
return varchar as $$
declare 
	v_id_visita bigint;
	v_fecha_visita date := current_time;
	filas_insertadas integer;

begin
	--1) insertar una fila en VISITA
	insert into taller.visita(fecha_visita, observaciones, id_sensor, nroSerie)
	values (v_fecha_visita, null, null, null) -- null porque aún no se tiene el sensor asociado
	returning id into v_id_visita
	
	--2) importar los datos a LECTURA_SENSOR
	
	--3) Retornar la cantidad de filas insertadas
	
end; 
$$;

-----EJERCICIO 2 - Trigger de control de inserción de datos útiles

create or replace function taller.validar_insercion()
returns trigger as $$
declare v_estado_emocional varchar(1);
begin
	
	--obtener el último estado emocional registrado por el sensor
	select estado_emocional into v_estado_emocional
	from taller.lectura_sensor 
	where id = new.id
	order by momento desc 
	limit 1;

	--validar que el registro sea distinto al último e insertar
	if v_estado_emocional is null or new.estado_emocional <> v_estado_emocional then 
		raise notice 'inserción % exitosa', new.estado_emocional;
		return new ; --permitir la inserción
	
	else 
		raise notice 'inserción % no validada', new.estado_emocional;
		return null; -- no hacer nada	
	end if;
end;
$$ language plpgsql;

create or replace trigger trigger_validar_insercion
before insert on taller.lectura_sensor 
for each row 
execute function taller.validar_insercion();

--registro 1
insert into taller.lectura_sensor(id, momento, estado_emocional, id_visita, nroserie, fecha_visita)
values (1, now(), 'P', null, 10, '11-12-24');

--registro 2
insert into taller.lectura_sensor(id, momento, estado_emocional, id_visita, nroserie, fecha_visita)
values (2, now(), 'A', null, 20, '11-12-24');

--registro 3
insert into taller.lectura_sensor(id, momento, estado_emocional, id_visita, nroserie, fecha_visita)
values (3, now(), 'S', null, 30, '11-12-24');

--registro 4 - no válido
insert into taller.lectura_sensor(id, momento, estado_emocional, id_visita, nroserie, fecha_visita)
values (4, now(), 'S', null, 40, '11-12-24');

select * from taller.lectura_sensor ls ;

-----EJERCICIO 3
select 
	p.nombre as nombre_proyecto,
	p.monto as monto_aportado, 
	count(s.id) as cant_sensores_fabricados,
	p.monto/coalesce(count(s.id), 0) as costo_por_sensor

from taller.proyecto p 
join taller.sensor s on s.id_proyecto = p.id --unión entre proyecto y sensor
group by p.nombre, p.monto 
order by monto desc;

-----EJERCICIO 4

--cargar datos de prueba
insert into taller.taller(id, codtaller, nombre) values(1, 10, 'taller1');
insert into taller.taller(id, codtaller, nombre) values(2, 20, 'taller2');

insert into taller.proyecto(id, codproyecto, nombre, monto) values (1, 10, 'proyecto1', 1000);
insert into taller.proyecto(id, codproyecto, nombre, monto) values (2, 20, 'proyecto2', 2000);

insert into taller.sensor (id, nroserie, fecha_fabricacion, id_taller, id_proyecto) values(1, 10, '01-01-2024', 1, 1);
insert into taller.sensor (id, nroserie, fecha_fabricacion, id_taller, id_proyecto) values(2, 20, '01-01-2024', 1, 1);

/* Antes la relación entre sensor y taller era (1, m) (un sensor es fabricado en un único taller y en cada taller se fabrican muchos
sensores) pero al modificarlo y que un sensor pueda ser fabricado en más de un taller, la relación pasa a ser (m, n), por lo que se debe
crear una tabla intermedia que modele la relación entre estas tablas */

create table taller.sensor_taller(
	id_sensor bigint not null,
	id_taller bigint not null,
	porcentaje_realizado numeric not null,
	
	constraint pk_sensor_taller primary key(id_sensor, id_taller),
	constraint fk1_sensor_taller foreign key(id_sensor) references taller.sensor(id),
	constraint fk2_sensor_taller foreign key(id_taller) references taller.taller(id)
);

--trasladar los datos a la nueva estructura
insert into taller.sensor_taller(id_sensor, id_taller, porcentaje_realizado)
select 
	id as id_sensor, id_taller,
	100 as porcentaje_realizado
from taller.sensor;

--elimino el id_taller de sensor, ya que ahora pertenece a la tabla intermedia
alter table taller.sensor drop column id_taller;

select * from taller.sensor_taller st;



