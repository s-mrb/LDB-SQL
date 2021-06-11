/*SCHEMA*/

create database test2;

create table fee(

cloth_type_id int NOT NULL auto_increment,
cloth_type_description varchar(20),
f_iron int,
f_dry_clean int,
f_washing int,

PRIMARY KEY (cloth_type_id)
);

CREATE TABLE Hostel
(
  hostel_id INT NOT NULL auto_increment,
  hostel_name varchar (20),
  hostel_block varchar (20),
  PRIMARY KEY (hostel_id),
   CONSTRAINT U_hostel UNIQUE (hostel_name,hostel_block)
);

create table finished_cloth_d
(
slip_id INT NOT NULL,
  cloth_id INT NOT NULL,
  task_type_id int,
  order_type_id int,
  cms INT NOT NULL,
  PRIMARY KEY (slip_id,cloth_id),
  Foreign key (cloth_id) references cloth(cloth_id),
  FOREIGN KEY (cms) REFERENCES Student(cms)
);

CREATE TABLE Cloth
(
  cloth_id INT NOT NULL auto_increment,
  cloth_color varchar (20),
  image blob,
 cms int,
 cloth_type_id int,
 FOREIGN KEY cloth(cms) REFERENCES student(cms),
 Foreign key cloth(cloth_type_id) references fee (cloth_type_id),
  PRIMARY KEY (cloth_id)
);

CREATE TABLE Student
(
  cms INT NOT NULL,
  first_name varchar (20),
  middle_name varchar (20),
  last_name varchar(20),
  hostel_id INT NOT NULL,
  
  PRIMARY KEY (cms),
  FOREIGN KEY Student(hostel_id) REFERENCES Hostel(hostel_id)
);

CREATE TABLE finished_orders
(
  slip_id INT NOT NULL,
  cms INT NOT NULL,
  total_cloth int,
  _date date,
  PRIMARY KEY (slip_id),
  FOREIGN KEY (cms) REFERENCES Student(cms)
 );
 
 CREATE TABLE cloth_taken
(
slip_id int Primary Key,
total_cloth_taken int
);

CREATE TABLE to_do
(

  slip_id INT NOT NULL,
  cloth_id INT NOT NULL,
  
  # why chaged from simple string to int and as foreign key,
  # so that their is more dynamic way to add new task_types without changing schema
  task_type_id int,
  order_type_id int,
  cms INT NOT NULL,
  PRIMARY KEY (slip_id,cloth_id),
  Foreign key (cloth_id) references cloth(cloth_id),
  Foreign key (task_type_id) references t_type( task_type_id ),
  Foreign key (order_type_id) references o_type (order_type_id),
  FOREIGN KEY (cms) REFERENCES Student(cms)
 
);


CREATE TABLE _order
(
  slip_id INT NOT NULL AUTO_INCREMENT,
  total_cloth INT NOT NULL,
  cms INT NOT NULL,
  _date date,
  PRIMARY KEY (slip_id),
  FOREIGN KEY (cms) REFERENCES Student(cms)
);


CREATE TABLE t_type
(
  task_type_id int NOT NULL AUTO_INCREMENT,
  task_type varchar(10),
	PRIMARY KEY (task_type_id)
);


CREATE table o_type
(
order_type_id int NOT NULL AUTO_INCREMENT ,
order_type varchar(10),
PRIMARY KEY (order_type_id)
);


create TABLE env_variable
(
# auto increment so that in set reg cloth limmit we need not to add PK for first time
access_flag int NOT NULL AUTO_INCREMENT,
regular_cloth_limmit int,
total_reg_cloth int,
primary key (access_flag)
);
