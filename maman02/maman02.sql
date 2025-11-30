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



-- 2) the function:
CREATE OR REPLACE FUNCTION trigf1()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    req_status   varchar(50);
    req_quantity int;
    total_dist   int;
BEGIN
    SELECT status, quantity
    INTO req_status, req_quantity
    FROM request
    WHERE rid = NEW.rid
    FOR UPDATE;


    IF req_status = 'done' THEN
        RAISE EXCEPTION 'request % cannot be added, already completed', NEW.rid;
    END IF;

    SELECT
        CASE WHEN SUM(quantity) IS NULL THEN 0 ELSE SUM(quantity) END
    INTO total_dist
    FROM distribution
    WHERE rid = NEW.rid;

    total_dist := total_dist + NEW.quantity;

    IF total_dist >= req_quantity THEN
        UPDATE request
        SET status = 'done'
        WHERE rid = NEW.rid;
    END IF;

    RETURN NEW;
END;
$$;

-- trigger 
CREATE TRIGGER trig1
BEFORE INSERT ON distribution
FOR EACH ROW
EXECUTE FUNCTION trigf1();


--3)
INSERT INTO supplies (sid, sname, category, quantity, location, area) VALUES
(1, 'מים מינרלים',     'food',      200, 'tel aviv central', 'center'),
(2, 'שמיכות חורף',    'clothing',  300, 'haifa depot',      'north'),
(3, 'first aid kit',     'medicine',  150, 'jerusalem store',  'jerusalem'),
(4, 'energy bars',       'food',      500, 'beersheba hub',    'south');

INSERT INTO volunteer (vid, vname, phone, skill, area) VALUES
(1, 'ruth cohen',     1112223333, 'ארגון', 'north'),
(2, 'danny levi',     2223334444, 'first aid',  'center'),
(3, 'michal peretz',  3334445555, 'transport',  'jerusalem'),
(4, 'naama sharon',   4445556666, 'ארגון', 'south');

INSERT INTO shelter (id, name, address, capacity, occupancy, contact, phone) VALUES
(1, 'tel aviv shelter',    'herzl 10 tel aviv',      250, 120, 'ayelet levi',  5551112222),
(2, 'jerusalem shelter',   'yafo 20 jerusalem',      180,  90, 'david cohen',  5552223333),
(3, 'haifa shelter',       'hanassi 15 haifa',       300, 150, 'miri israel',  5553334444),
(4, 'beersheba shelter',   'ben gurion 5 beersheba', 200,  80, 'ron ohana',    5554445555);

INSERT INTO request (rid, id, sid, quantity, priority, status, rdate) VALUES
(1, 1, 1, 50,  2, 'pending', '2025-06-20'),
(2, 2, 2, 40,  1, 'pending',    '2025-06-21'),
(3, 3, 3, 75,  3, 'pending', '2025-06-22'),
(4, 4, 4, 30,  2, 'pending', '2025-06-23');

INSERT INTO distribution (rid, id, vid, quantity, ddate, notes) VALUES
(1, 1, 1, 50, '2025-06-25', 'initial delivery'),
(2, 2, 3, 40, '2025-06-26', 'on the way'),
(3, 3, 2, 30, '2025-06-27', 'partial delivery'),
(4, 4, 4, 25, '2025-06-28', 'on time');


--4
SELECT name
from shelter,
where capacity>200;

-- 5
SELECT  v.vname
FROM volunteer v, distribution d, request r, supplies s
WHERE d.vid = v.vid
  AND d.rid = r.rid
  AND r.sid = s.sid
  AND s.category = 'clothing';


-- 6
SELECT  v.name, v.vid, count(DISTINCT d.id) as num_of_shelters
FROM volunteer v, distribution d 
WHERE v.vid=d.vid
GROUP BY v.vid, v.vname
HAVING COUNT(DISTINCT	 d.id) > 50;

--7
SELECT s.id , s.name, s.contact 
FROM shelter s 
WHERE s.occupancy > (
	(SELECT SUM(capacity)/COUNT(capacity) FROM shelter )/2
);

--8
SELECT v.vid, v.vname
FROM volunteer v
WHERE NOT EXISTS (
	SELECT d.vid 
	FROM distribution d, request r, supplies s
	WHERE d.vid = v.vid
	AND d.rid = r.rid
	AND r.sid = s.sid
	AND r.quantity > (
		SELECT SUM(r2.quantity)/COUNT(r2.quantity)
		FROM request r2
		WHERE r2.sid=r.sid
	)
);

--9
SELECT v.vid, v.name
FROM volunteer v , distribution d 
WHERE v.vid = d.vid AND v.skill= 'ארגון'
GROUP BY v.vid, v.vname
HAVING SUM(d.quantity) >= ALL (
	SELECT SUM(d2.quantity) 
	FROM vulunteer v2, distribution d2
	WHERE v2.vid = d2.vid
	AND v2.skill = 'ארגון'
	GROUP BY v2.vid
);

--10
SELECT sh.id, sh.name, sh.address
FROM shelter sh
WHERE
  NOT EXISTS (
    SELECT 1
    FROM request r2, supplies s2
    WHERE r2.id = sh.id
      AND r2.sid = s2.sid
      AND s2.sname = 'שמיכות חורף'
      AND r2.quantity < 50
  )
  AND
  (
    SELECT SUM(r.quantity)
    FROM request r, supplies s
    WHERE r.id = sh.id
      AND r.sid = s.sid
      AND s.sname = 'מים מינרלים'
  ) >= ALL (
    SELECT SUM(r3.quantity)
    FROM shelter sh3, request r3, supplies s3
    WHERE sh3.id = r3.id
      AND r3.sid = s3.sid
      AND s3.sname = 'מים מינרלים'
      AND NOT EXISTS (
          SELECT 1
          FROM request r4, supplies s4
          WHERE r4.id = sh3.id
            AND r4.sid = s4.sid
            AND s4.sname = 'שמיכות חורף'
            AND r4.quantity < 50
      )
    GROUP BY sh3.id
  );