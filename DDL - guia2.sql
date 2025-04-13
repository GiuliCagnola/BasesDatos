/*GUIA 2 - ALUMNADO */

/*Tablas nivel 1*/
create table PROVINCIA(
  codProv integer not null,
  nomProv varchar(50) not NULL,
  
  CONSTRAINT pk_provincia PRIMARY key (codprov)
);
  
create table DEPARTAMENTO(
  codDepto integer not null,
  nomDepto varchar(50) not null,
    
  CONSTRAINT pk_departamento PRIMARY key(codDepto)
);

create table CARGO(
  codCargo integer not null,
  nomCargo varchar(50) not null,
  
  CONSTRAINT pk_cargo PRIMARY key(codCargo)
);

/*Tablas nivel 2*/
CREATE TABLE LOCALIDAD(
  codLoc integer not null,
  codProv integer not null,
  nomLoc varchar(50) not null,
  codPostal smallint not null,
  
  CONSTRAINT pk_localidad PRIMARY key(codLoc, codProv),
  CONSTRAINT fk_localidad_provincia FOREIGN key (codProv) REFERENCES PROVINCIA(codProv)
);

CREATE TABLE MATERIA(
  codMat INTEGER not null,
  codDepto integer not null,
  nomMat varchar(50)  not null,
  
  CONSTRAINT pk_materia PRIMARY key(codMat),
  CONSTRAINT fk_materia_departamento FOREIGN key(codDepto) references DEPARTAMENTO(codDepto)
);

/*Tablas nivel 3*/
CREATE TABLE PERSONA(
  tipoDoc VARCHAR(50) NOT NULL DEFAULT 'DNI' CHECK (tipoDoc IN ('DNI', 'Pasaporte', 'LC', 'otro')),
  nroDoc integer not null,
  codProvN integer not null,
  codLocN integer not null,
  codProvV integer not null,
  codLocV integer not null,
  apellido varchar(50) null,
  nombre varchar(50) NULL,
  Fnacimiento date not null,
  domicilio varchar(50) null,
  
  CONSTRAINT pk_persona PRIMARY key(tipoDoc, nroDoc),
  CONSTRAINT fk_persona_localidadN FOREIGN key(codProvN, codLocN) references LOCALIDAD(codProv, codLoc),
  CONSTRAINT fk_persona_localidadV FOREIGN key(codProvV, codLocV) references LOCALIDAD(codProv, codLoc) 
);

/*Tablas nivel 4*/
create table ALUMNO(
  legajoA integer not null,
  tipoDoc varchar(50) not null,
  nroDoc integer not null,
  Fingreso date not null,
  
  CONSTRAINT pk_alumno PRIMARY key(legajoA, tipoDoc, nroDoc),
  CONSTRAINT fk_alumno_persona FOREIGN key (tipoDoc, nroDoc) references PERSONA(tipoDoc, nroDoc)
);

create table DOCENTE (
  legajoD integer not null,
  tipoDoc varchar(50) not null,
  nroDoc integer not null,
  Fingreso date not null,
  
  CONSTRAINT pk_docente PRIMARY key(legajoD, tipoDoc, nroDoc),
  CONSTRAINT fk_docente_persona FOREIGN key (tipoDoc, nroDoc) references PERSONA(tipoDoc, nroDoc)
);

/*Tablas nivel 5*/
create table CURSADO(
  nroCom SMALLINT not null,
  codMat integer not null,
  Finicio date not null,
  descripcion varchar(100) null,
  
  CONSTRAINT pk_cursado PRIMARY key (nroCom, codMat),
  CONSTRAINT fk_cursado_materia FOREIGN key (codMat) REFERENCES MATERIA(codMat)
);

create table HISTORIAL_CARGO(
  Finicio date not null,
  codCargo integer not null,
  legajoD integer not null,
  tipoDoc varchar(50) not null,
  nroDoc integer not null,
  codMat integer not null,
  Ffin date null,
  
  CONSTRAINT pk_historialCargo PRIMARY key(Finicio, legajoD, tipoDoc, nroDoc, codMat),
  CONSTRAINT fk1_historialCargo_cargo FOREIGN key(codCargo) references CARGO(codCargo),
  CONSTRAINT fk2_historialCargo_docente FOREIGN key(legajoD, tipoDoc, nroDoc) REFERENCES DOCENTE(legajoD, tipoDoc, nroDoc),
  CONSTRAINT fk2_historialCargo_materia FOREIGN key(codMat) REFERENCES materia(codMat)
);

/*Tablas nivel 6*/
create table DETALLE_CURSADO(
  legajoA integer not null,
  tipoDoc varchar(50) not null,
  nroDoc integer not null,
  nroCom smallint not null,
  codMat integer not null,
  condicion varchar(1) not null,
  calificacion smallint not null,
  
  CONSTRAINT pk_detalleCursado PRIMARY key(legajoA, tipoDoc, nroDoc, nroCom, codMat),
  CONSTRAINT fk1_detalleCursado_alumno FOREIGN key (legajoA, tipoDoc, nroDoc) REFERENCES ALUMNO(legajoA, tipoDoc, nroDoc),
  CONSTRAINT fk2_detalleCursado_cursado FOREIGN key(nroCom, codMat) REFERENCES CURSADO(nroCom, codMat)
  );
  
CREATE TABLE DOCENTE_CURSADO(
  legajoD integer not null,
  tipoDoc VARCHAR(50) not null,
  nroDoc integer not null,
  nroCom smallint not null,
  codMat integer not null,
    
  CONSTRAINT pk_docenteCursado PRIMARY key(legajoD, tipoDoc, nroDoc, nroCom, codMat),
  CONSTRAINT fk1_docenteCursado_docente FOREIGN key(legajoD, tipoDoc, nroDoc) references DOCENTE(legajoD, tipoDoc, nroDoc),
  CONSTRAINT fk2_docenteCursado_cursado FOREIGN key(nroCom, codMat) REFERENCES CURSADO(nroCom, codMat)
);

/*Suponga que se decide incorporar la información necesaria para hacer el seguimiento de todas
las carreras de la Universidad. Discutir como definiría conceptos como:
* Facultad: unidad donde se cursan varias carreras y donde funcionan varios departamentos; 
* Carrera: compuesta por varias materias;
Cómo modelaría alumno si este puede inscribirse en distintas carreras, y cada vez que se
inscribe a una carrera se le asigna un nuevo legajo?. Cuál sería su clave de negocio?*/

CReate table FACULTAD(
  codFac smallint not null,
  nomFac  varchar(50) not null,
  
  CONSTRAINT pk_facultad PRIMARY key(codFac)
);

create table CARRERA(
  codCar SMALLINT not null,
  codFac smallint not null,
  nomCar varchar(50) not null,
  
  CONSTRAINT pk_carrera PRIMARY key(codCar),
  CONSTRAINT fk_carrera_facultad FOREIGN key(codFac) REFERENCES FACULTAD(codFac) 
);


/*modificar DEPARTAMENTO (asumo que depende de facultad)*/
alter table DEPARTAMENTO add column codFac smallint not null;
ALTER TABLE DEPARTAMENTO DROP CONSTRAINT pk_departamento;
ALTER TABLE DEPARTAMENTO add CONSTRAINT pk_departamento PRIMARY key(codDepto, codFac);
alter table DEPARTAMENTO add CONSTRAINT fk_departamento_facultad FOREIGN key (codFac) REFERENCES FACULTAD(codFac);









