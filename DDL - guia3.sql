/*Tablas nivel 1*/
create table PERSONA(
  tipoDoc varchar(50) not null,
  nroDoc integer not null,
  sexo varchar(1) not null,
  apellido varchar(50) not null,
  nombre varchar(50) not null,
  Fnacimiento date not null,
  domicilio varchar(50) null,
  
  CONSTRAINT pk_persona primary key (tipoDoc, nroDoc, sexo)
);

create table FAMILIAR(
  codVinculoF integer not null,
  nomVinculoF varchar(50) not null,
  
  CONSTRAINT pk_familiar PRIMARY key(codVinculoF)
);

create table FUNCION(
  codFuncion integer not null,
  nomFuncion varchar(50) not null,
  categoriaF varchar(50) not null,
  
  CONSTRAINT pk_funcion primary key(codFuncion)
);

create table ESTADO_CIVIL(
  codEC INTEGER NOT NULL,
  nomEC VARCHAR(50) NOT NULL,
  
  CONSTRAINT pk_estadoCivil PRIMARY key(codEC)
);

create table NIVEL(
  codNivel integer not null,
  nomNivel varchar(50) not null,
  
  CONSTRAINT pk_nivel PRIMARY key( codNivel),
  CONSTRAINT fk_nivel_nivel FOREIGN key (codNivel) REFERENCES NIVEL(codNivel)
);

/*Tablas nivel 2*/
CREATE TABLE EMPLEADO(
  legajo integer not null,
  tipoDoc varchar(50) not null,
  nroDoc integer not null,
  sexo varchar(1) not null,
  Fingreso date not null,
  telefono integer null,
  
  constraint pk_empleado primary key(legajo),
  CONSTRAINT fk_empleado_persona FOREIGN key(tipoDoc, nroDoc, sexo) REFERENCES PERSONA(tipoDoc, nroDoc, sexo)
);

create table OFICINA(
  codOfi integer not NULL,
  nomOfi varchar(50) not null,
  codNivel integer not null,
  
  CONSTRAINT pk_oficina PRIMARY key(codOfi, codNivel),
  CONSTRAINT fk_oficina_oficina FOREIGN key(codOfi, codNivel) REFERENCES OFICINA(codOfi, codNivel) 
);

create table CATEGORIA(
  FinicioCat date not null,
  categoria integer not null,
  FfinCat date null,
  observaciones varchar(100) null,
  legajo integer not null,
  
  CONSTRAINT pk_categoria PRIMARY key(FinicioCat, legajo),
  CONSTRAINT fk_categoria_empleado FOREIGN key(legajo) REFERENCES EMPLEADO(legajo)
);

CREATE TABLE CASADO (
  itemCasam INTEGER NOT NULL,
  Fcasam DATE NOT NULL,
  FfinCasam DATE NULL,
  tipoDoc VARCHAR(50) NOT NULL,
  nroDoc INTEGER NOT NULL,
  sexo VARCHAR(1) NOT NULL,
  legajo INTEGER NOT NULL,
  
  CONSTRAINT pk_casado PRIMARY KEY (itemCasam, legajo),
  CONSTRAINT fk1_casado_persona FOREIGN KEY (tipoDoc, nroDoc, sexo) REFERENCES PERSONA (tipoDoc, nroDoc, sexo),
  CONSTRAINT fk2_casado_empleado FOREIGN KEY (legajo) REFERENCES EMPLEADO (legajo)
);

CREATE TABLE HISTORIAL_EC (
  FinicioEC DATE NOT NULL,
  FfinEC DATE NULL,
  observaciones VARCHAR(100) NULL,
  codEC INTEGER NOT NULL,
  legajo INTEGER NOT NULL,
  
  CONSTRAINT pk_historialEC PRIMARY KEY (FinicioEC, legajo),
  CONSTRAINT fk1_historialEC_EC FOREIGN KEY (codEC) REFERENCES ESTADO_CIVIL (codEC),
  CONSTRAINT fk2_historialEC_empleado FOREIGN KEY (legajo) REFERENCES EMPLEADO (legajo)
);

CREATE TABLE A_CARGO (
  FinicioCargo DATE NOT NULL,
  FfinCargo DATE NULL,
  observaciones VARCHAR(100) NULL,
  tipoDoc VARCHAR(50) NOT NULL,
  nroDoc INTEGER NOT NULL,
  sexo VARCHAR(1) NOT NULL,
  legajo INTEGER NOT NULL,
  codVinculoF INTEGER NOT NULL,
  
  CONSTRAINT pk_aCargo PRIMARY KEY (FinicioCargo, tipoDoc, nroDoc, sexo, legajo),
  CONSTRAINT fk1_aCargo_persona FOREIGN KEY (tipoDoc, nroDoc, sexo) REFERENCES PERSONA (tipoDoc, nroDoc, sexo),
  CONSTRAINT fk2_aCargo_empleado FOREIGN KEY (legajo) REFERENCES EMPLEADO (legajo),
  CONSTRAINT fk3_aCargo_familiar FOREIGN KEY (codVinculoF) REFERENCES FAMILIAR (codVinculoF)
);

create table HIJO(
  tipoDoc varchar(50) not null,
  nroDoc integer not null,
  sexo varchar(1) not null,
  legajo integer not null,
  
  CONSTRAINT pk_hijo PRIMARY key(tipoDoc, nroDoc, sexo, legajo),
  CONSTRAINT fk1_hijo_persona FOREIGN key(tipoDoc, nroDoc, sexo) REFERENCES PERSONA(tipoDoc, nroDoc, sexo),
  CONSTRAINT fk2_hijo_empleado FOREIGN key(legajo) REFERENCES EMPLEADO(legajo)
);

create table ASIGNACION(
  FinicioA date not null,
  FfinA date null,
  legajo integer not null,
  codOfi integer not null,
  codNivel integer not null,
  codFuncion integer not null,
  
  CONSTRAINT pk_asignacion PRIMARY KEY (FinicioA, legajo),
  CONSTRAINT fk1_asignacion_empleado FOREIGN key(legajo) REFERENCES EMPLEADO(legajo),
  CONSTRAINT fk2_asignacion_oficina FOREIGN key(codOfi, codNivel) REFERENCES OFICINA(codOfi, codNivel),
  CONSTRAINT fk3_asignacion_funcion FOREIGN key(codFuncion) REFERENCES FUNCION(codFuncion)
);


  
  