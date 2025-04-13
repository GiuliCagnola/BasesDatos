---------- P1 2024 ----------
--*--*--*--*--*--*--*--*--*--*--

-----creación de tablas

create table provincia (
    codProv smallint not null,
    nomProv varchar(50) not null,
    constraint pk_provincia primary key (codProv)
);

create table localidad (
    codProv smallint not null, 
    codLoc integer not null,
    nomLoc varchar(50) not null,
    codPostal smallint null,
    constraint pk_localidad primary key (codProv, codLoc),
    constraint fk_localidad_provincia foreign key (codProv) references provincia(codProv)
);

create table persona (
    tipoDoc smallint not null,
    nroDoc integer not null,
    codProv smallint not null,
    codLoc integer not null,
    apellido varchar(120) not null,
    nombre varchar(120) not null,
    genero smallint null,
    domicilio varchar(120) null,
    constraint pk_persona primary key (tipoDoc, nroDoc),
    constraint fk_persona_localidad foreign key (codProv, codLoc) references localidad(codProv, codLoc),
    constraint chk_tipoDoc_persona check (tipoDoc in (1, 2, 3, 4, 5)),
    constraint chk_genero_persona check (genero is null or (genero in (1, 2, 3)))
);

create table tipo_parentesco (
    codTipoP integer not null,
    nomTipoP varchar(50) not null,
    constraint pk_tipoP primary key (codTipoP)
);

create table parentesco (
    tipoDocP1 smallint not null,
    nroDocP1 integer not null,
    tipoDocP2 smallint not null,
    nroDocP2 integer not null,
    codTipoP integer not null,
    constraint pk_parentesco primary key (tipoDocP1, nroDocP1, tipoDocP2, nroDocP2),
    constraint fk1_parentesco_tipoP foreign key (codTipoP) references tipo_parentesco(codTipoP),
    constraint fk2_parentesco_persona1 foreign key (tipoDocP1, nroDocP1) references persona(tipoDoc, nroDoc),
    constraint fk3_parentesco_persona2 foreign key (tipoDocP2, nroDocP2) references persona(tipoDoc, nroDoc)
);


-----implementación con claves subrogadas

-- dropeo las fk
alter table parentesco
    drop constraint fk1_parentesco_tipoP,
    drop constraint fk2_parentesco_persona1,
    drop constraint fk3_parentesco_persona2;

alter table persona drop constraint fk_persona_localidad;

alter table localidad drop constraint fk_localidad_provincia;

-- dropeo la pk, creo el id y lo establezco como pk, paso el atributo que estaba como pk como uk

alter table provincia drop constraint pk_provincia;
alter table provincia 
    add column id_provincia integer not null,
    add constraint pk_provincia primary key (id_provincia),
    add constraint uk_provincia unique (codprov);

alter table localidad drop constraint pk_localidad;
alter table localidad
    add column id_localidad integer not null,
    add column id_provincia integer not null,
    add constraint pk_localidad primary key(id_provincia, id_localidad), --va id_provincia?
    add constraint fk_localidad_provincia foreign key(id_provincia) references provincia(id_provincia),
    add constraint uk_localidad unique(codProv, codLoc);

alter table persona drop constraint pk_persona;
alter table persona
    add column id_persona integer not null,
    add column id_localidad integer not null,
    add column id_provincia integer not null,
    add constraint pk_persona primary key (id_persona),
    add constraint fk_persona_localidad foreign key(id_provincia, id_localidad) references localidad(id_provincia, id_localidad),
    add constraint uk_persona unique(tipoDoc, nroDoc);

alter table tipo_parentesco drop constraint pk_tipoP;
alter table tipo_parentesco 
    add column id_tipoP integer not null,
    add constraint pk_tipoP primary key (id_tipoP),
    add constraint uk_tipoP unique (codTipoP);

alter table parentesco drop constraint pk_parentesco;
alter table parentesco
    add column id_parentesco integer not null,
    add column id_persona1 integer not null,
    add column id_persona2 integer not null,
    add column id_tipoP integer not null,
    add constraint pk_parentesco primary key(id_parentesco, id_persona1, id_persona2), --van los ids de persona1 y persona2?
    add constraint fk1_parentesco_persona1 foreign key(id_persona1) references persona(id_persona),
    add constraint fk2_parentesco_persona2 foreign key(id_persona2) references persona(id_persona),
    add constraint fk_parentesco_tipoP foreign key(id_tipoP) references tipo_parentesco(id_tipoP),
    add constraint uk1_parentesco unique(tipoDocP1, nroDocP1),
    add constraint uk2_parentesco unique(tipoDocP2, nroDocP2);

-- elimino las columnas no utilizadas de parentesco
alter table parentesco
    drop column tipoDocP1, drop column nroDocP1,
    drop column tipoDocP2, drop column nroDocP2,
    drop column codTipoP;

	
/*PASOS
 * Dropeo las fk (del nivel más alto al más bajo para no afectar las dependencias)
 * Dropeo la pk
 * Agrego un atributo id
 * Al id lo establezco como pk
 * Los atributos que eran pk en el modelo con claves de negocios pasan a ser uk en el modelo con claves suborgadas
 */