
create table triangulo(
  id integer not null,
  descripcion varchar(60),
  
  constraint pk_triangulo PRIMARY key (id)
);

create  table lado(
  id integer not null,
  id_triangulo integer not null,
  descripcion varchar(60),
  longitudcm integer not null,
  
  constraint pk_lado primary key (id),
  constraint pk_lado_triangulo FOREIGN key (id_triangulo) references triangulo(id)
);


--triángulo con lados válidos
insert into triangulo values(1, 'triangulo 1');
insert into lado values(1, 1, 'lado ab', 5);
insert into lado values(2, 1, 'lado ac', 5);
insert into lado values(3, 1, 'lado bc', 9);


--triángulo con lados inválidos
insert into triangulo values(2, 'triangulo 2');
insert into lado values(4, 2, 'lado ab', 3);
insert into lado values(5, 2, 'lado ac', 5);
insert into lado values(6, 2, 'lado bc', 9);


select *
from triangulo t;

select *
from lado l;


-- Validar triángulos imposibles
select distinct t.descripcion
from triangulo t
join lado l1 on l1.id_triangulo = t.id
join lado l2 on l2.id_triangulo = t.id 
join lado l3 on l3.id_triangulo = t.id 
where not (
    l1.longitudcm + l2.longitudcm > l3.longitudcm and
    l2.longitudcm + l3.longitudcm > l1.longitudcm and
    l3.longitudcm + l1.longitudcm > l2.longitudcm
);







