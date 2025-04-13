--DECLARACIÓN DE VARIABLES - DECLARE

create or replace function persona.obtener_provincia(cod_provincia integer)
returns table(
	id bigint,
	descripcion varchar
)
language plpgsql
as $$
declare
	v_id bigint;
	v_descripcion varchar;
begin
	select id, descripcion into v_id, v_descripcion
	from persona.provincia
	where codigo = cod_provincia
	
	return query select v_id, v_descripcion;
end;
$$


--CURSORES - CURSOR/OPEN/LOOP/END LOOP/CLOSE 

create or replace function venta.procesar_facturas()
language plpgsql
as $$
declare 

	factura_cursor cursor  --declarar el cursor
	for select id, total 
	from venta.factura
	where fecha >= current_date - interval '1 year';

	v_factura_id bigint;
	v_total numeric;

begin
	
	open factura_cursor; --abrir el cursor

	loop --recorrer el cursor
		fetch factura_cursor into v_factura_id, v_total;
		exit when not found;
	
		raise notice 'Factura ID: %, Total: %', v_factura_id, v_total;
		
	end loop;

	close factura_cursor; --cerrar el cursor
	
end;
$$

--BATCHES - DO 

do
$$
begin
	update venta.factura f
	set f.total = f.total *1.1
	where f.fecha >= current_date - '1 month';

	if(
		select count(*)
		from venta.factura f 
		where f.total > 1000
	) >10 then --si hay más de 10 facturas con total mayor a 1000
	raise notice 'mas de 10 ventas superiores a $1000'
	end if ;
	
end;
$$

do
$$
begin
	insert into persona.provincia (id, version, codigo, descripcion)
	values (persona.persona_sequence.nextval, 1, 999, 'Provincia test');

	insert into persona.localidad (id, version, id_provincia, codigo, descripcion, codigo_postal)
	values (persona.persona_sequence.nextval, 1, 999, 'Localidad test', 12345);

	raise notice 'batch ejecutado exitosamente';

end
$$

--ESTRUCTURAS DE CONTROL - IF/THEN/ELSE

do -- verificar si una localidad tiene una sucursal asignada
$$
begin
	if not exist (
		select 1 from persona.sucursal s
		where id_localidad = 1
		)
		then 
		insert into persona.sucursal s (id, version, codigo, descripcion, domicilio, id_localidad)
		values (nextval('persona.persona_sequence'), 1, 101, 'Sucursal default', 'Domicilio default', 1);
		
		else raise notice 'la localidad ya tiene una sucursal asignada';
	end if;
end;

--BUCLES - FOR/WHILE

do --recorrer los productos de una subcategoria y actualizar el precio si es menor a 100
$$
declare producto record;
begin
	for producto in
		select id, precio_unitario
		from producto.producto
		where id_subcategoria = 1
		
	loop
		if p.precio_unitario < 100 then
		update producto.producto set precio_unitario = 100
		where id = producto.id;
		
		end if;
	end loop;	
end;
$$

do 
$$
declare
	precio_actual numeric(38, 2);
	incremento numeric(38, 2) := 0.05;

begin
	select precio_unitario into precio_actual
	from producto.producto p 
	where p.id=1;

	while precio_actual < 500
	
	loop
		precio_actual := precio_actual + precio_actual*incremento;
	
		update producto.producto 
		set precio_unitario = precio_actual
		where id=1;
		raise notice 'nuevo precio: %', precio_actual;
		
	end loop;
end;
$$

--SECUENCIAS - SEQUENCE

create sequence persona.persona_sequence
start with 1
increment by 1

insert into persona.provincia (id, version, codigo, descripcion)
values (nextval('persona.persona_sequence'), 1, 101, 'Provincia ejemplo')
--nextval('secuencia') -> valor siguiente (incrementado)
--currval('secuencia')-> valor actual
--setval('secuencia')-> establecer un nuevo valor


--TRANSACCIONES - BEGIN/COMMIT/ROLLBACK TRANSACTION
begin;
update persona.sucursal 
set descripcion = 'sucursal actualizada'
where codigo = 123;

update persona.cliente
set fecha_alta = current_date 
where codigo = 456;

commit; --guardar los cambios
rollback; --revertir los cambios


do
$$
begin
	begin; --iniciar la transacción
	update persona.sucursal  --actualizar la sucursal
	set descripcion = 'sucursal actualizada'
	where codigo = 123;
	
	update persona.cliente ---actualizar el cliente
	set fecha_alta = current_date 
	where codigo = 456;
	
	commit; --confirmar la transacción
	
exception
	when others then rollback;-- revertir la transacción ante un error
	raise notice 'error';

end
$$





	

	
