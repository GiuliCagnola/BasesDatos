---------- FINAL 02/04/24 ----------
--*--*--*--*--*--*--*--*--*--*--*--*

create schema catastro;


create table catastro.persona(
	id bigint not null,
	tipodoc varchar(3) not null,
	nrodoc integer not null,
	apellido varchar(100) not null,
	nombre varchar(100) not null,
	
	constraint pk_persona primary key(id),
	constraint uk_persona unique(tipodoc, nrodoc),
	constraint chk_tipodoc check (tipodoc in ('DNI', 'LE', 'LC'))
);

create table catastro.partida(
	id bigint not null,
	depto varchar(2) not null,
	partida varchar(6) not null,
	domicilio varchar(100) null,
	
	constraint pk_partida primary key(id),
	constraint uk_partida unique(depto, partida)
);


create table catastro.mejora(
	id bigint not null,
	id_partida bigint not null,
	categoria smallint not null,
	superficie float not null,
	anio smallint not null,
	
	constraint pk_mejora primary key(id),
	constraint fk_mejora_partida foreign key(id_partida) references catastro.partida(id)
);
create index idx_mejora_partida on catastro.mejora(id_partida);


create table catastro.partida_persona(
	id_partida bigint not null,
	id_persona bigint not null,
	porcentaje float not null,
	
	constraint pk_pp primary key(id_partida, id_persona),
	constraint fk1_pp_partida foreign key(id_partida) references catastro.partida(id),
	constraint fk2_pp_persona foreign key(id_persona) references catastro.persona(id),
	constraint chk_porcentaje check(porcentaje >=0 and porcentaje <=100)
);

insert into catastro.persona(id, tipodoc, nrodoc, apellido, nombre) values
	(1, 'DNI', 12345, 'juan', 'perez'),
	(2, 'DNI', 23456, 'maria', 'perez'),
	(3, 'LC', 11111, 'juana', 'lopez'); --persona a obtener según las condiciones establecidas

insert into catastro.partida(id, depto, partida, domicilio) values
	(1, '10', '100100', 'calle123'),
	(2, '10', '101010', 'calleabc'),
	(3, '10', '111111', 'callexyz');

insert into catastro.partida_persona(id_partida, id_persona, porcentaje) values
	(1, 1, 50), (1, 2, 50), --misma partida para las personas 1 y 2
	(2, 1, 30), (2, 3, 70); --misma partida para las personas 1 y 3
	
insert into catastro.mejora(id, id_partida, categoria, superficie, anio) values
	(1, 1, 1, 500, 2020),
	(2, 2, 2, 200, 2024),
	(3, 1, 1, 1000, 2022); -- partida de categoria 1 con el doble de superficie 
	

/*obtener apellido y nombre de de los propietarios de partidas cuando alguna de sus partidas posean mejoras de categoría 1 siempre y cuando esas
partidas también posean mejoras de categoría 1 pero con exactamente el doble de superficie */
	
select 
	pe.nombre as nombre,
	pe.apellido as apellido
from catastro.persona pe
join catastro.partida_persona pp on pp.id_persona = pe.id --unión entre persona y pp
join catastro.partida pa on pp.id_partida = pa.id --unión entre pp y partida
join catastro.mejora m1 on m1.id_partida = pa.id --unión entre partida y mejora1
join catastro.mejora m2 on m2.id_partida = pa.id --unión entre partida y mejora2
where(
	m1.categoria = 1 and m2.categoria = 1
	and m1.superficie = 2*m2.superficie 
);

-----------------------------

--sesión 1
begin;
set transaction isolation read uncommitted;

delete from catastro.mejora
where id = 1;

select pg_sleep(30); --delay de 30 segundos

rollback;


--sesión 2
select *
from catastro.mejora m 
where m.	id = 1;
