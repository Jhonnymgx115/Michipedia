-- Scripts de clase - Septiembre 5 de 2024 
-- Curso de Tópicos Avanzados de base de datos - UPB 202420
-- Juan Dario Rodas - juand.rodasm@upb.edu.co

-- Proyecto: Michipedia - Enciclopedia de Gatos
-- Motor de Base de datos: PostgreSQL 16.x

-- ***********************************
-- Abastecimiento de imagen en Docker
-- ***********************************
 
-- Descargar la imagen
docker pull postgres:latest

-- Crear el contenedor
docker run --name postgres-Michis -e POSTGRES_PASSWORD=unaClav3 -d -p 5432:5432 postgres:latest

-- ****************************************
-- Creación de base de datos y usuarios
-- ****************************************

-- Con usuario Postgres:

-- crear el esquema la base de datos
create database michis_db;

-- Conectarse a la base de datos
\c michis_db;

-- Creamos un esquema para almacenar todo el modelo de datos del dominio
create schema core;

-- crear el usuario con el que se implementará la creación del modelo
create user michi_app with encrypted password 'unaClav3';

-- asignación de privilegios para el usuario
grant connect on database michis_db to michi_app;
grant create on database michis_db to michi_app;
grant create, usage on schema core to michi_app;
alter user michi_app set search_path to core;

-- crear el usuario con el que se conectará la aplicación
create user michi_usr with encrypted password 'unaClav3';

-- asignación de privilegios para el usuario
grant connect on database michis_db to michi_usr;
grant usage on schema core to michi_usr;
alter default privileges for user michi_app in schema core grant insert, update, delete, select on tables to michi_usr;
alter default privileges for user michi_app in schema core grant execute on routines TO michi_usr;
alter user michi_usr set search_path to core;

-- Activar la extensión que permite el uso de UUID
create extension if not exists "uuid-ossp";

-- ****************************************
-- Creación de las tablas base
-- ****************************************

-- En el esquema core

-- Tabla paises
create table core.paises
(
    id      	    integer generated always as identity constraint paises_pk primary key,
    nombre  	    varchar(100) not null,
    continente      varchar(100) not null,
    pais_uuid       uuid default gen_random_uuid(),
    constraint paises_continentes_uk unique (nombre,continente)
);

comment on table core.paises is 'Paises origen de las razas de gatos';
comment on column core.paises.id is 'id del pais';
comment on column core.paises.nombre is 'Nombre del pais';
comment on column core.paises.continente is 'Continente donde está ubicado el país';
comment on column core.paises.pais_uuid is 'UUID del país para uso por API';

-- Tabla Caracteristicas
create table core.caracteristicas
(
    id                      integer generated always as identity constraint caracteristicas_pk primary key,
    nombre                  varchar(30) not null,
    descripcion             varchar(200) not null,
    caracteristica_uuid     uuid default gen_random_uuid()
);

comment on table core.caracteristicas is 'Características de las razas de gatos';
comment on column core.caracteristicas.id is 'id de la característica';
comment on column core.caracteristicas.nombre is 'Nombre de la característica';
comment on column core.caracteristicas.descripcion is 'Descripción de la característica';
comment on column core.caracteristicas.caracteristica_uuid is 'UUID de la característica para uso por API';

-- Tabla Comportamientos
create table core.comportamientos
(
    id      	            integer generated always as identity constraint comportamientos_pk primary key,
    nombre                  varchar(30) not null,
    descripcion             varchar(200) not null,
    comportamiento_uuid     uuid default gen_random_uuid()
);

comment on table core.comportamientos is 'Comportamiento de las razas de gatos';
comment on column core.comportamientos.id is 'id del comportamiento';
comment on column core.comportamientos.nombre is 'Nombre del comportamiento';
comment on column core.comportamientos.descripcion is 'Descripción del comportamiento';
comment on column core.comportamientos.comportamiento_uuid is 'UUID del comportamiento para uso por API';

-- Tabla de comportamientos_niveles
create table core.comportamientos_niveles
(
    id      	        integer generated always as identity constraint comportamientos_niveles_pk primary key,
    comportamiento_id   integer not null constraint comportamientos_niveles_comportamientos_fk references core.comportamientos,
    nombre              varchar(20) not null,
    valoracion          varchar(200) not null
);

comment on table core.comportamientos_niveles is 'Niveles de comportamiento de las razas de gatos';
comment on column core.comportamientos_niveles.id is 'id del nivel de comportamiento';
comment on column core.comportamientos_niveles.comportamiento_id is 'id del comportamiento';
comment on column core.comportamientos_niveles.nombre is 'Nombre del nivel de comportamiento';
comment on column core.comportamientos_niveles.valoracion is 'Valoración del nivel de comportamiento';

-- Tabla Razas
create table core.razas
(
    id              integer generated always as identity constraint razas_pk primary key,
    nombre          varchar(100) not null,
    pais_id         integer not null constraint razas_paises_fk references core.paises,
    descripcion     text,
    raza_uuid       uuid default gen_random_uuid()
);

comment on table core.razas is 'Las razas de gatos';
comment on column core.razas.id is 'id de la raza';
comment on column core.razas.nombre is 'Nombre de la raza';
comment on column core.razas.pais_id is 'Id del país origen de la raza';
comment on column core.razas.descripcion is 'Descripción de la raza';
comment on column core.razas.raza_uuid is 'UUID de la raza para uso por API';

-- Tabla de caracteristicas_raza
create table core.caracteristicas_razas
(
    raza_id             integer not null constraint raza_caracteristica_raza_fk references core.razas,
    caracteristica_id   integer not null constraint caracteristica_caracteristica_raza_fk references core.caracteristicas,
    descripcion         varchar(200) not null,
    constraint caracteristicas_razas_pk primary key (raza_id, caracteristica_id)
);

comment on table core.caracteristicas_razas is 'Relación de las características con las razas de gatos';
comment on column core.caracteristicas_razas.raza_id is 'id de la raza';
comment on column core.caracteristicas_razas.caracteristica_id is 'id de la característica';
comment on column core.caracteristicas_razas.descripcion is 'Descripción de la característica de la raza';

-- Tabla de comportamientos_niveles_razas
create table core.comportamientos_niveles_razas
(
    raza_id                     integer not null constraint raza_caracteristica_raza_fk references core.razas,
    comportamiento_nivel_id     integer not null constraint raza_nivel_comportamiento_fk references core.comportamientos_niveles,
    constraint comportamientos_razas_pk primary key (raza_id, comportamiento_nivel_id)
);

comment on table core.comportamientos_niveles_razas is 'Relación de los comportamientos de las razas de gatos';
comment on column core.comportamientos_niveles_razas.raza_id is 'id de la raza';
comment on column core.comportamientos_niveles_razas.comportamiento_nivel_id is 'id del nivel del comportamiento';

-- ****************************************
-- Creación de las vistas
-- ****************************************

-- Vista v_info_comportamientos
create or replace view core.v_info_comportamientos as
(
    select
        nc.comportamiento_id,
        c.comportamiento_uuid,
        c.nombre comportamiento_nombre,
        c.descripcion comportamiento_descripcion,
        nc.id nivel_id,
        nc.nombre nivel_nombre,
        nc.valoracion nivel_valoracion
    from comportamientos c
        inner join comportamientos_niveles nc on c.id = nc.comportamiento_id
);

-- Vista v_info_caracteristicas_razas
create or replace view core.v_info_caracteristicas_razas as
(
    select distinct
        cr.raza_id,
        r.nombre,
        r.descripcion,
        r.raza_uuid,
        c.nombre caracteristica_nombre,
        c.descripcion caracteristica_descripcion
    from razas r
        inner join caracteristicas_razas cr on r.id = cr.raza_id
        inner join caracteristicas c on cr.caracteristica_id = c.id
);

-- Vista v_info_razas_paises
create or replace view core.v_info_razas_paises as
(
select distinct
    r.id raza_id,
    r.nombre raza_nombre,
    r.pais_id,
    p.nombre pais_nombre,
    p.continente pais_continente
    from core.razas r
        inner join core.paises p on p.id = r.pais_id
);