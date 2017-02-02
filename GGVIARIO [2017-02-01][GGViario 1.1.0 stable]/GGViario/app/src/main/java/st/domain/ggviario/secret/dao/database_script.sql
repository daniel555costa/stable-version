-- user table creation
DROP TABLE IF EXISTS T_USER;
create TABLE T_USER(

   user_id integer PRIMARY KEY autoincrement not NULL,
   user_name character varying(32) not null,
   user_surname character varying (48) not null,
   user_accessname character varying(32) not null,
   user_pwd character varying(32) not null,
   user_state smallint not null default 2

);


--  sector table

DROP TABLE IF EXISTS T_SECTOR;
CREATE TABLE T_SECTOR (

  sector_id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
  sector_name character varying not null

);

-- despesa table creation
DROP TABLE IF EXISTS T_DESPESA;
CREATE TABLE T_OUTGO(

   out_id integer PRIMARY KEY AUTOINCREMENT not NULL,
   out_user_id integer not null,
   out_data DATE NOT NULL,
   out_dtreg DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   out_state smallint not null default 1,
   CONSTRAINT fk_OUTGO_to_user FOREIGN KEY (out_user_id) REFERENCES T_USER(out_id)

);


-- provider table

DROP TABLE IF EXISTS T_PROVIDER;
create table T_PROVIDER (

   provider_id integer PRIMARY KEY  AUTOINCREMENT NOT NULL,
   provider_name character varying (48) not null,
   provider_location character varying (56) not null,
   provider_telephone character varying(15) not null,
   provider_mail character varying(15) not null,
   provider_site character varying not null,
   provider_state smallint not null default 1,
   provider_dtreg datetime not null DEFAULT current_timestamp

);


DROP TABLE IF EXISTS T_OUTGOPERATION;
CREATE TABLE T_OUTGOPERATION(

   oprout_id integer PRIMARY KEY AUTOINCREMENT not NULL,
   oprout_out_id integer not null,
   oprout_provider_id integer not null,
   oprout_state smallint not null DEFAULT 1,
   oprout_dtreg datetime not null default current_time,

   CONSTRAINT fk_OUTGOoperation_to_provider FOREIGN KEY (oprout_provider_id)  REFERENCES T_PROVIDER (provider_id),
   CONSTRAINT fk_OUTGOoperation_to_OUTGO FOREIGN KEY (oprout_out_id)  REFERENCES T_OUTGO (out_id)

);


-- item OUTGO creation
DROP TABLE IF EXISTS T_ITEMOUTGO;
create table T_ITEMOUTGO(

  iout_id integer PRIMARY KEY AUTOINCREMENT not null,
  iout_oprout_id integer not null REFERENCES T_OUTGOPERATION(oprout_id),
  iout_prod_id integer not null references T_PRODUCT(prod_id),
  iout_quantity float not null,
  iout_price float,
  iout_finalprice float not null,
  iout_state smallint not null default 1,
  iout_dtreg datetime not null default current_timestamp

);


-- colheita table
DROP TABLE IF EXISTS T_CROP;
CREATE TABLE T_CROP (

  crop_id integer PRIMARY KEY AUTOINCREMENT NOT NULL ,
  crop_sector_id integer NOT NULL REFERENCES T_SECTOR(sector_id),
  crop_user_id integer not null REFERENCES T_USER(user_id),
  crop_totalovos integer not null,
  crop_percasovos integer not null default 0,
  crop_percasgalinhas integer not null default 0,
  crop_state smallint NOT NULL DEFAULT 1,
  crop_dtreg datetime not null DEFAULT  current_timestamp

);



