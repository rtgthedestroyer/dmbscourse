-- 1 . Creating the tables:

-- Supplies (sid, sname, category, quantity, location, area)

CREATE TABLE Supplies (
	sid int,
	sname varchar(50),
	category varchar(50),
	quantity int,
	location varchar(50),
	area varchar(50),
	PRIMARY KEY (sid)
);

-- Volunteer (vid, vname, phone, skill, area)

CREATE TABLE Volunteer(
	vid int,
	vname varchar(50),
	phone numeric(10,0),
	skill varchar(50),
	area varchar(50),
 	PRIMARY KEY(vid)
);

--Shelter

CREATE TABLE Shelter(
	id int ,
	name varchar(50),
	address varchar(50),
	capacity int,
	occupancy int,
	contact varchar(50),
	phone numeric(10,0),
	PRIMARY KEY(id)
);

--Request (rid, id, sid, quantity, priority, status, rdate)

CREATE TABLE Request(
	rid int, 
	id int,
	sid int,
	quantity int,
	priority int,
	status varchar(50),
	rdate date,
	PRIMARY KEY(rid),
	FOREIGN KEY(id) REFERENCES(Shelter)
);

-- Distribution (rid, id, vid, quantity, ddate, notes)

CREATE TABLE Distribution(
	rid int,
	id int,
	vid int,
	quantity int,
	ddate date,
	notes varchar(50),
	FOREIGN KEY (rid) REFERENCES(Request),
	FOREIGN KEY (id) REFERENCES(Shelter),
	FOREIGN KEY (vid) REFERENCES(Volunteer)
);
