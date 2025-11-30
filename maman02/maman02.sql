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
	FOREIGN KEY(id) REFERENCES Shelter
);

-- Distribution (rid, id, vid, quantity, ddate, notes)

CREATE TABLE Distribution(
	rid int,
	id int,
	vid int,
	quantity int,
	ddate date,
	notes varchar(50),
	PRIMARY KEY (rid,vid),
	FOREIGN KEY (rid) REFERENCES Request,
	FOREIGN KEY (id) REFERENCES Shelter,
	FOREIGN KEY (vid) REFERENCES Volunteer
);


--2 the function:
CREATE OR REPLACE FUNCTION trigf1()
RETURNS TRIGGER AS $$

DECLARE
	req_status varchar(50);
	req_quantity int;
	total_dist int;

BEGIN
-- check if request not satisfied if not returns error and doesnt add
--                                if yes change to satisfied (status = 'done')

	SELECT status, quantity
	INTO req_status, req_quantity
	FROM request
	WHERE rid = NEW.rid
	FOR UPDATE;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'not found request with rid=%',NEW.rid;
	END IF;

	IF req_status='done' THEN
		RAISE EXCEPTION 'request % cannot be added ,already completed', NEW.rid
	END IF;

	SELECT 
		CASE WHEN SUM(quantity) IS NULL THEN 0 ELSE SUM(quantity) END 
	INTO total_dist
	FROM distribution
	WHERE rid = NEW.rid

	total_dist := total_dist + NEW.quantity

	IF total_dist >= req_quantity THEN
		UPDATE request
		SET status = 'done'
		WHERE rid = NEW.rid
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--trigger 
CREATE TRIGGER trig1
BEFORE INSERT ON distribution
FOR EACH ROW
EXECUTE FUNCTION trigf1();

--3)
INSERT INTO supplies (sid, sname, category, quantity, location, area) VALUES
(1, 'mineral water',     'food',      200, 'tel aviv central', 'center'),
(2, 'winter blanket',    'clothing',  300, 'haifa depot',      'north'),
(3, 'first aid kit',     'medicine',  150, 'jerusalem store',  'jerusalem'),
(4, 'energy bars',       'food',      500, 'beersheba hub',    'south');

INSERT INTO volunteer (vid, vname, phone, skill, area) VALUES
(1, 'ruth cohen',     1112223333, 'organizing', 'north'),
(2, 'danny levi',     2223334444, 'first aid',  'center'),
(3, 'michal peretz',  3334445555, 'transport',  'jerusalem'),
(4, 'naama sharon',   4445556666, 'organizing', 'south');

INSERT INTO shelter (id, name, address, capacity, occupancy, contact, phone) VALUES
(1, 'tel aviv shelter',    'herzl 10 tel aviv',      250, 120, 'ayelet levi',  5551112222),
(2, 'jerusalem shelter',   'yafo 20 jerusalem',      180,  90, 'david cohen',  5552223333),
(3, 'haifa shelter',       'hanassi 15 haifa',       300, 150, 'miri israel',  5553334444),
(4, 'beersheba shelter',   'ben gurion 5 beersheba', 200,  80, 'ron ohana',    5554445555);

INSERT INTO request (rid, id, sid, quantity, priority, status, rdate) VALUES
(1, 1, 1, 50,  2, 'pending', '2025-06-20'),
(2, 2, 2, 40,  1, 'done',    '2025-06-21'),
(3, 3, 3, 75,  3, 'pending', '2025-06-22'),
(4, 4, 4, 30,  2, 'pending', '2025-06-23');

INSERT INTO distribution (rid, id, vid, quantity, ddate, notes) VALUES
(1, 1, 1, 50, '2025-06-25', 'initial delivery'),
(2, 2, 3, 40, '2025-06-26', 'fully supplied'),
(3, 3, 2, 30, '2025-06-27', 'partial delivery'),
(4, 4, 4, 25, '2025-06-28', 'on time');
