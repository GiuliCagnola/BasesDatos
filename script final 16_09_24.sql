---------- FINAL 16/09/24 ----------
--*--*--*--*--*--*--*--*--*--*--*--*


create schema inicial;

create table inicial.funcion(
	id bigint not null,
	codigo integer not null,
	nombre varchar(100) not null,
	
	constraint pk_funcion primary key(id),
	constraint uk_funcion unique(codigo)
);

create table inicial.localidad(
	id bigint not null,
	codigo integer not null,
	nombre varchar(100) not null,
	
	constraint pk_localidad primary key(id),
	constraint uk_localidad unique(codigo)
);

create table inicial.persona(
	id bigint not null,
	tipo_persona varchar(2) not null,
	fnacimiento date not null,
	codigo_org integer null,
	nombre_org varchar(100) null,
	cuit integer null,
	razon_social varchar(100) null,
	tipodoc varchar(3) null,
	nrodoc integer null,
	apellido varchar(100) null,
	nombre varchar(100) null,
	legajo_emp integer null,
	fingreso_emp date null,
	direccion varchar(100) null,
	id_localidad bigint not null,
	cod_org_ref integer null,
	cuit_ref integer null,
	id_funcion bigint null,
	
	constraint pk_persona primary key(id),
	
	constraint fk1_persona_localidad foreign key(id_localidad) references inicial.localidad(id),
	constraint fk2_persona_organizacion foreign key(cod_org_ref) references inicial.persona(codigo_org), --referencia a otra persona de tipo organismo
	constraint fk3_persona_pjuridica foreign key(cuit_ref) references inicial.persona(cuit), --referencia a otra persona de tipo persona_juridica
	constraint fk4_persona_funcion foreign key(id_funcion) references inicial.funcion(id),
	
	constraint uk1_organismo unique(codigo_org),
	constraint uk2_pj unique(cuit),
	constraint uk3_pf unique(tipodoc, nrodoc),
	
	constraint chk_tipopoersona check(tipo_persona in('PF', 'PJ', 'O')),
	constraint chk_tipodoc check(tipodoc in ('DNI', 'LE', 'LC', 'P'))
);

insert into inicial.funcion(id, codigo, nombre) values
	(1, 1, 'tesorero'), (2, 2, 'informático');

insert into inicial.localidad(id, codigo, nombre) values
	(1, 1, 'santa fe'), (2, 2, 'buenos aires'), (3, 3, 'paraná');

insert into inicial.persona(id, tipo_persona, fnacimiento, codigo_org, nombre_org, cuit, razon_social, tipodoc, nrodoc, apellido, nombre, legajo_emp,
fingreso_emp, direccion, id_localidad, cod_org_ref, cuit_ref, id_funcion) values 
	(1, 'PF', '13-11-2000', null, null, null, null, 'DNI', 12345678, 'perez', 'juan', null, null, 'calle123', 1, null, null, 1),
	(2, 'PJ', '31/12/1990', 123, 'org123', null, null, 'DNI', 87654321, 'perez', 'juana', null, null, 'calleabc', 2, null, null, 2);

select * from inicial.funcion f ;
select * from inicial.localidad l ;
select * from inicial.persona p ;
-------------------
create schema final;

--tablas nivel 1

create table final.localidad(
	codigo integer not null,
	nombre varchar(100) not null,
	
	constraint pk_localidad primary key(codigo)
);

create table final.funcion(
	codigo integer not null,
	nombre varchar(100) not null,
	
	constraint pk_funcion primary key(codigo)
);

--tablas nivel 2
create table final.persona(
	id bigint not null,
	direccion varchar(100) not null,
	cod_localidad integer not null,
	
	constraint pk_persona primary key(id),
	constraint fk_persona_localidad foreign key(cod_localidad) references final.localidad(codigo)
);

--tablas nivel 3
create table final.organismo(
	codigo bigint not null,
	nombre varchar(100) not null,
	id_persona bigint not null,
	
	constraint pk_organismo primary key(codigo),
	constraint fk_organismo_persona foreign key(id_persona) references final.persona(id)
);

create table final.persona_fisica(
	tipodoc varchar(3) not null,
	nrodoc integer not null,
	apellido varchar(100) not null,
	nombre varchar(100) not null,
	id_persona bigint not null,
	
	constraint pk_pf primary key(tipodoc, nrodoc),
	constraint fk_pf_persona foreign key(id_persona) references final.persona(id)
);

create table final.persona_juridica(
	cuit integer not null,
	razon_social varchar(100) not null,
	id_persona bigint not null,
	
	constraint pk_pj primary key(cuit),
	constraint fk_pj_persona foreign key(id_persona) references final.persona(id)
);

--tablas nivel 4
create table final.pf_integra_org(
	f_desde date not null,
	f_hasta date null,
	codigo_org integer not null,
	tipodoc varchar(3) not null,
	nrodoc integer not null,
	codigo_funcion integer not null,
	
	constraint pk_pforg primary key(f_desde),
	constraint fk1_pforg_org foreign key(codigo_org) references final.organismo(codigo),
	constraint fk2_pforg_pf foreign key(tipodoc, nrodoc) references final.persona_fisica(tipodoc, nrodoc),
	constraint fk3_pforg_funcion foreign key(codigo_funcion) references final.funcion(codigo)
);

create table final.pf_integra_pj(
	f_desde date not null,
	f_hasta date null,
	tipodoc varchar(3) not null,
	nrodoc integer not null,
	cuit integer not null,
	codigo_funcion integer not null,
	
	constraint pk_pfpj primary key(f_desde),
	constraint fk1_pfpj_pf foreign key(tipodoc, nrodoc) references final.persona_fisica(tipodoc, nrodoc),
	constraint fk2_pfpj_pj foreign key(cuit) references final.persona_juridica(cuit),
	constraint fk3_pfpj_funcion foreign key(codigo_funcion) references final.funcion(codigo)
);

create table final.empleado(
	legajo integer not null,
	f_ingreso date not null,
	tipodoc varchar(3) not null,
	nrodoc integer not null,
	
	constraint pk_empleado primary key(legajo),
	constraint fk_empleado_persona foreign key(tipodoc, nrodoc) references final.persona_fisica(tipodoc, nrodoc)
);

--migración de datos del esquema inicial al esquema final

insert into final.localidad (codigo, nombre)
select l.codigo, l.nombre
from inicial.localidad l;

insert into final.funcion (codigo, nombre)
select f.codigo, f.nombre
from inicial.funcion f;

insert into final.persona(id, direccion, cod_localidad)
select p.id, p.direccion, l.codigo
from inicial.persona p
join inicial.localidad l on p.id_funcion = l.id;

insert into final.organismo(codigo, nombre, id_persona)
select p.codigo_org, p.nombre_org, p.id
from inicial.persona p
where p.tipo_persona = 'O';

insert into final.persona_fisica(tipodoc, nrodoc, apellido, nombre, id_persona)
select p.tipodoc, p.nrodoc, p.apellido, p.nombre, p.id
from inicial.persona p
where p.tipo_persona = 'PF';

insert into final.persona_juridica(cuit, razon_social, id_persona)
select p.cuit, p.razon_social, p.id
from inicial.persona p
where p.tipo_persona = 'PJ'; --------null

insert into final.empleado(legajo, f_ingreso, tipodoc, nrodoc)
select p.legajo_emp, p.fingreso_emp, p.tipodoc, p.nrodoc 
from inicial.persona p
join final.persona_fisica pf on pf.tipodoc = p.tipodoc and pf.nrodoc = p.nrodoc
where p.legajo_emp is not null;

insert into final.pf_integra_org(f_desde, f_hasta, codigo_org, tipodoc, nrodoc, codigo_funcion)
select '01-01-2024' as f_desde, null as f_hasta, p.cod_org_ref, p.tipodoc, p.nrodoc, f.codigo
from inicial.persona p
join inicial.funcion f on p.id_funcion = f.id 
join final.persona_fisica pf on pf.tipodoc = p.tipodoc and pf.nrodoc = p.nrodoc 
where p.tipo_persona = 'PF' and p.cod_org_ref is not null;

insert into final.pf_integra_pj(f_desde, f_hasta, tipodoc, nrodoc, cuit, codigo_funcion)
select '01-01-2024' as f_desde, null as f_hasta, p.tipodoc, p.nrodoc, p.cuit, f.codigo
from inicial.persona p
join inicial.funcion f on p.id_funcion =f.id 
join final.persona_fisica pf on pf.tipodoc = p.tipodoc and pf.nrodoc = p.nrodoc 
where p.tipo_persona = 'PF' and p.cuit_ref is not null;

drop schema inicial cascade;



--visualizar todas las personas físicas que son empleados y además cumplen alguna función en pj u org
select 
	pf.tipodoc as tipo_documento,
	pf.nrodoc as nro_documento,
	pf.apellido as apellido,
	pf.nombre as nombre,
	case 
		when o.codigo is not null then o.nombre
		when pj.cuit is not null then pj.razon_social
	end as donde_trabaja

from final.persona p

left join final.organismo o on o.id_persona = p.id -- persona -> organismo
left join final.persona_juridica pj on pj.id_persona = p.id -- persona -> persona_juridica
left join final.persona_fisica pf on pf.id_persona = p.id -- persona -> persona_fisica
left join final.empleado e on e.tipodoc = pf.tipodoc and e.nrodoc = pf.nrodoc -- persona _fisica-> empleado
left join final.pf_integra_org pio on pio.tipodoc = pf.tipodoc and pio.nrodoc = pf.nrodoc -- persona_fisica -> pf_integra_org
left join final.pf_integra_pj pip on pip.tipodoc = pf.tipodoc and pip.nrodoc = pf.nrodoc -- persona_fisica -> pf_integra_pj
left join final.funcion f on pio.codigo_funcion = f.codigo -- pf_integra_org -> funcion
left join final.funcion f2 on pip.codigo_funcion = f2.codigo --> pf_integra_pj -> funcion
--validar que el empleado tenga registros en pf_integra_org o pf_integra_pj
where (e.legajo is not null and (pio.f_desde is not null or pip.f_desde is not null))
order by apellido, nombre;

--trigger que impida insertar datos en empleado si este está desempeñando funciones en persona_juridica con vigencia al día actual 
--(fecha de inicio menor o igual a la actual y fecha de finalización nula)

create or replace function f_validar_empleado()
returns trigger as $$
begin 
    -- Verificar si el empleado está desempeñando funciones en persona_juridica
    if exists (
        select 1 
        from final.pf_integra_pj pip
        where pip.tipodoc = new.tipodoc 
          and pip.nrodoc = new.nrodoc 
          and pip.f_desde <= current_date 
          and pip.f_hasta is null
    ) then 
        -- El empleado ya tiene una función activa en persona jurídica
        raise exception 'El empleado se encuentra desempeñando funciones en persona_juridica. Inserción no permitida.';
        return null; -- No permitir la inserción
    end if;

    -- Permitir la inserción
    raise notice 'Empleado validado. Inserción permitida.';
    return new;
end;
$$ language plpgsql;


create or replace trigger trigger_validar_empleado
before insert on final.empleado 
for each row 
execute function f_validar_empleado();
	
	
