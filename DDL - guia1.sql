/* Tablas de nivel 1 */
CREATE TABLE PROVINCIA (
  codProv SMALLINT NOT NULL,
  nomProv VARCHAR(50) NOT NULL,
  CONSTRAINT pk_provincia PRIMARY KEY (codProv)
);

CREATE TABLE CARGO (
  codCargo SMALLINT NOT NULL,
  nomCargo VARCHAR(50) NOT NULL,
  CONSTRAINT pk_cargo PRIMARY KEY (codCargo)
);

CREATE TABLE SECCION (
  codSeccion SMALLINT NOT NULL,
  nomSeccion VARCHAR(50) NOT NULL,
  CONSTRAINT pk_seccion PRIMARY KEY (codSeccion)
);

CREATE TABLE ESPECIALIDAD (
  codEsp SMALLINT NOT NULL,
  nomEsp VARCHAR(50) NOT NULL,
  CONSTRAINT pk_especialidad PRIMARY KEY (codEsp)
);

/* Tablas de nivel 2 */
CREATE TABLE LOCALIDAD (
  codLoc SMALLINT NOT NULL,
  codProv SMALLINT NOT NULL,
  nomLoc VARCHAR(50) NOT NULL,
  CONSTRAINT pk_localidad PRIMARY KEY (codLoc, codProv),
  CONSTRAINT fk_localidad_provincia FOREIGN KEY (codProv) REFERENCES PROVINCIA(codProv)
);

CREATE TABLE SECTOR (
  codSector SMALLINT NOT NULL,
  codSeccion SMALLINT NOT NULL,
  nomSector VARCHAR(50) NOT NULL,
  CONSTRAINT pk_sector PRIMARY KEY (codSector, codSeccion),
  CONSTRAINT fk_sector_seccion FOREIGN KEY (codSeccion) REFERENCES SECCION(codSeccion)
);

/* Tablas de nivel 3 */
CREATE TABLE PERSONA (
  tipoDoc VARCHAR(30) NOT NULL DEFAULT 'DNI' CHECK (tipoDoc IN ('DNI', 'Pasaporte', 'LC', 'otro')),
  nroDoc INTEGER NOT NULL,
  sexo VARCHAR(1) NOT NULL,
  Apenom VARCHAR(50) NOT NULL,
  domicilio VARCHAR(50) NULL,
  Fnacimiento DATE NULL,
  codProvN SMALLINT NULL,
  codLocN SMALLINT NULL,
  codProvV SMALLINT NOT NULL,
  codLocV SMALLINT NOT NULL,
  tipoDocP VARCHAR(30) NULL,
  nroDocP INTEGER NULL,
  sexoP VARCHAR(1) NULL,
  tipoDocM VARCHAR(30) NULL,
  nroDocM INTEGER NULL,
  sexoM VARCHAR(1) NULL,
  
  CONSTRAINT pk_persona PRIMARY KEY (tipoDoc, nroDoc, sexo),
  CONSTRAINT fk1_persona_localidad_N FOREIGN KEY (codProvN, codLocN) REFERENCES LOCALIDAD (codProv, codLoc),
  CONSTRAINT fk2_persona_localidad_V FOREIGN KEY (codProvV, codLocV) REFERENCES LOCALIDAD (codProv, codLoc),
  CONSTRAINT fk3_persona_padre FOREIGN KEY (tipoDocP, nroDocP, sexoP) REFERENCES PERSONA (tipoDoc, nroDoc, sexo),
  CONSTRAINT fk4_persona_madre FOREIGN KEY (tipoDocM, nroDocM, sexoM) REFERENCES PERSONA (tipoDoc, nroDoc, sexo)
);

/* Tablas de nivel 4 */
CREATE TABLE EMPLEADO (
  codEmp INTEGER NOT NULL,
  tipoDoc VARCHAR(30) NOT NULL,
  nroDoc INTEGER NOT NULL,
  sexo VARCHAR(1) NOT NULL,
  Fingreso DATE NOT NULL,
  
  CONSTRAINT pk_empleado PRIMARY KEY (codEmp),
  CONSTRAINT fk_empleado_persona FOREIGN KEY (tipoDoc, nroDoc, sexo) REFERENCES PERSONA (tipoDoc, nroDoc, sexo)
);

CREATE TABLE MEDICO (
  matricula SMALLINT NOT NULL,
  codEsp SMALLINT NOT NULL,
  tipoDoc VARCHAR(30) NOT NULL,
  nroDoc INTEGER NOT NULL,
  sexo VARCHAR(1),
  
  CONSTRAINT pk_medico PRIMARY KEY (matricula),
  CONSTRAINT fk1_medico_especialidad FOREIGN KEY (codEsp) REFERENCES ESPECIALIDAD (codEsp),
  CONSTRAINT fk2_medico_persona FOREIGN KEY (tipoDoc, nroDoc, sexo) REFERENCES PERSONA (tipoDoc, nroDoc, sexo)
);

/* Tablas de nivel 5 */
CREATE TABLE SALA (
  nroSala SMALLINT NOT NULL,
  nomSala VARCHAR(50) NOT NULL,
  capacidad SMALLINT NOT NULL,
  codSector SMALLINT NOT NULL,
  codSeccion SMALLINT NOT NULL,
  codEsp SMALLINT NOT NULL,
  codEmp INTEGER NOT NULL,
  
  CONSTRAINT pk_sala PRIMARY KEY (nroSala, codSector, codSeccion),
  CONSTRAINT fk1_sala_sector_seccion FOREIGN KEY (codSector, codSeccion) REFERENCES SECTOR (codSector, codSeccion),
  CONSTRAINT fk2_sala_especialidad FOREIGN KEY (codEsp) REFERENCES ESPECIALIDAD (codEsp),
  CONSTRAINT fk3_sala_empleado FOREIGN KEY (codEmp) REFERENCES EMPLEADO (codEmp)
);

/* Tablas de nivel 6 */
CREATE TABLE ASIGNACION (
  nroAsig INTEGER NOT NULL,
  Fasigna DATE NOT NULL,
  Fsalida DATE NULL,
  matricula SMALLINT NOT NULL,
  tipoDoc VARCHAR(30) NOT NULL,
  nroDoc INTEGER NOT NULL,
  sexo VARCHAR(1) NOT NULL,
  codEmp INTEGER NOT NULL,
  nroSala SMALLINT NOT NULL,
  codSector SMALLINT NOT NULL,
  codSeccion SMALLINT NOT NULL,
  
  CONSTRAINT pk_asignacion PRIMARY KEY (nroAsig),
  CONSTRAINT fk1_asignacion_medico FOREIGN KEY (matricula) REFERENCES MEDICO (matricula),
  CONSTRAINT fk2_asignacion_persona FOREIGN KEY (tipoDoc, nroDoc, sexo) REFERENCES PERSONA (tipoDoc, nroDoc, sexo),
  CONSTRAINT fk3_asignacion_empleado FOREIGN KEY (codEmp) REFERENCES EMPLEADO (codEmp),
  CONSTRAINT fk4_asignacion_sala FOREIGN KEY (nroSala, codSector, codSeccion) REFERENCES SALA (nroSala, codSector, codSeccion)
);

CREATE TABLE HISTORIAL (
  Finicio DATE NOT NULL,
  Ffin DATE NULL,
  codEmp INTEGER NOT NULL,
  codCargo SMALLINT NOT NULL,
  
  CONSTRAINT pk_historial PRIMARY KEY (Finicio, codEmp),
  CONSTRAINT fk1_historial_empleado FOREIGN KEY (codEmp) REFERENCES EMPLEADO (codEmp),
  CONSTRAINT fk2_historial_cargo FOREIGN KEY (codCargo) REFERENCES CARGO (codCargo)
);

CREATE TABLE TRABAJA_EN (
  codEmp INTEGER NOT NULL,
  nroSala SMALLINT NOT NULL,
  codSector SMALLINT NOT NULL,
  codSeccion SMALLINT NOT NULL,
  
  CONSTRAINT pk_trabajaEn PRIMARY KEY (codEmp, nroSala, codSector, codSeccion),
  CONSTRAINT fk1_trabajaEn_sala FOREIGN KEY (nroSala, codSector, codSeccion) REFERENCES SALA (nroSala, codSector, codSeccion)
);

/*¿Qué pasa si la Localidad no fuera dependiente de Provincia?
a. Cuales serían los cambios en el modelo.
b. Cuales serían los cambios en las tablas, atributos y referencias? Qué instrucciones
hay que codificar y en que orden?

si localidad no fuese dependiente de provincia, provincia no sería parte de la pk ni de la fk de localidad
*/

/*eliminar la dependencia de localidad a provincia*/
alter table LOCALIDAD DROP CONSTRAINT fk_localidad_provincia;
/*eliminar la columna de provincia*/
alter table LOCALIDAD drop COLUMN codProv;
/*modificar la pk de localidad (primero eliminar)*/
alter table LOCALIDAD drop CONSTRAINT pk_localidad;
alter table LOCALIDAD add CONSTRAINT pk_localidad PRIMARY key (codLoc);

