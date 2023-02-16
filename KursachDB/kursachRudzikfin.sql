CREATE TABLE [dbo].[RecZak]
(
	[ID_zakazchika] INT NOT NULL Primary key identity(1,1),
	[Name] nvarchar(20) not null,
	[Adres] varchar(20) not null,
	[phone] varchar(20) not null

);

select * from [RecZak]
drop table [RecZak]


CREATE TABLE [dbo].[Zakaz]
(
	[ID_zakaza] INT NOT NULL Primary key identity(1,1),
	[Naimenovanie] varchar(20) not null,
	[Budjet] nvarchar(20) not null,
	[ID_zakazchika_Zakaz] int not null
);

select * from [Zakaz]
drop table [Zakaz]

CREATE TABLE [dbo].[RecDogo]
(
	[NomerDogovor] int NOT NULL Primary key identity(1,1),
	[NazvDogo] nvarchar(20) not null,
	[Gorod] nvarchar(20) not null,
	[ID_Zakazchika_dog] int not null,
	[ID_Ispolnit_dog] int not null,
	[ID_zakaza_dog] int not null,
	[date] SMALLDATETIME, --автобинд времени

);

select * from [RecDogo]
drop table [RecDogo]


CREATE TABLE [dbo].[Smeta]
(
	[NomerChek] INT not null primary key identity(1,1),
	[VidelenoDeneg] nvarchar(30) not null,
	[NomerDogovor_smeta] int not null,
	[StoimostMat] nvarchar(20) not null,
	[Zarplata] nvarchar(20) not null,
	[Bonus] nvarchar(20) not null
)

select * from [Smeta]
drop table [Smeta]


CREATE TABLE [dbo].[RecIspoln]
(
	[ID_Ispolnit] INT NOT NULL Primary key identity(1,1),
	[Imya] varchar(20) not null,
	[AdresIsp] nvarchar(20) not null,
	[PhoneIspoln] nvarchar(20) not null
);
select * from [RecIspoln]
drop table [RecIspoln]



--------------\/\/\/\/\/\/-------------

ALTER TABLE Zakaz
	ADD CONSTRAINT FK_ID_zakazchika_Zakaz FOREIGN KEY (ID_zakazchika_Zakaz)
		REFERENCES RecZak (ID_zakazchika)
		ON DELETE CASCADE
		ON UPDATE CASCADE

ALTER TABLE RecDogo
	ADD CONSTRAINT FK_ID_zakazchika_dog FOREIGN KEY (ID_zakazchika_dog)
		REFERENCES RecZak (ID_zakazchika)
		ON DELETE NO ACTION 
		ON UPDATE NO ACTION

ALTER TABLE RecDogo
	ADD CONSTRAINT FK_ID_zakaza_dog FOREIGN KEY (ID_zakaza_dog)
		REFERENCES Zakaz (ID_zakaza)
		ON DELETE CASCADE
		ON UPDATE CASCADE

ALTER TABLE RecDogo
	ADD CONSTRAINT FK_ID_Ispolnit_dog FOREIGN KEY (ID_Ispolnit_dog)
		REFERENCES RecIspoln (ID_Ispolnit)
		ON DELETE CASCADE
		ON UPDATE CASCADE

ALTER TABLE Smeta
	ADD CONSTRAINT FK_NomerDogovor_smeta FOREIGN KEY (NomerDogovor_smeta)
		REFERENCES RecDogo (NomerDogovor)
		ON DELETE CASCADE
		ON UPDATE CASCADE

CREATE INDEX RecZak_Name_Adres_phone_idx
ON RecZak(Name, Adres, phone DESC)
drop index RecZak_Name_Adres_phone_idx on RecZak
-----------------------------------------------
CREATE UNIQUE INDEX zakaz_idx
ON Zakaz (Naimenovanie, Budjet ASC)
drop index zakaz_idx on Zakaz
-----------------------------------------------
CREATE INDEX RecDogo_klast_idx
ON RecDogo(NomerDogovor)
drop index RecDogo_klast_idx on RecDogo
-----------------------------------------------


--Поиск заказа по наименованию
	SELECT 
	Naimenovanie,
	Budjet
	FROM Zakaz
	WHERE Naimenovanie = 'Element1';
	go
EXEC get_zakaz_by_naimenovanie @e ='dom';
drop procedure get_zakaz_by_naimenovanie

--Поиск заказчика по имени
CREATE PROCEDURE get_zakazchik_by_namezakazchik @gzn nvarchar(20)
AS
	SELECT 
	Name,
	Adres,
	phone
	FROM RecZak
	WHERE Name = @gzn;
	go
EXEC get_zakazchik_by_namezakazchik @gzn ='Михаил';
drop procedure get_zakazchik_by_namezakazchik
--------------------------------------------------------------------------
CREATE PROCEDURE get_dogovor_by_nomer @gdnn int
AS
	SELECT 
	NomerDogovor,
	NazvDogo,
	Gorod
	FROM RecDogo
	WHERE NomerDogovor = '15';
	go
EXEC get_dogovor_by_nomer @gdnn ='1';
drop procedure get_dogovor_by_nomer

-- Вывод заказа по имени заказчика и выведение статуса заказа
CREATE PROCEDURE get_zakaz_by_namezakazchik @n nvarchar(20)
AS
	SELECT 
	Name,
	phone,
	Naimenovanie,
	Zakaz.Budjet,
	(CASE WHEN dbo.Zakaz.Budjet > 1000000 THEN 'Гос.заказ' ELSE 'Частный заказ' END) AS [Status]
	FROM RecZak JOIN Zakaz 
	ON RecZak.ID_zakazchika = Zakaz.ID_zakazchika_Zakaz
	WHERE Name = @n;
	go
EXEC get_zakaz_by_namezakazchik @n ='Михаил';
drop procedure get_zakaz_by_namezakazchik
-- Вывод заказов по названию договора и городу подписания
CREATE OR ALTER VIEW zakazi_po_nazv_gorod
	AS
	SELECT Naimenovanie, Budjet, RecDogo.NazvDogo, RecDogo.Gorod, RecDogo.ID_Zakazchika_dog FROM Zakaz JOIN RecDogo
	ON ID_zakaza = ID_zakaza_dog
	WHERE NazvDogo = '' and Gorod = '';
	select * from zakazi_po_nazv_gorod WHERE NazvDogo = 'avtotochka' and Gorod = 'Spetersburg';
drop view zakazi_po_nazv_gorod
-- Вывод количества договоров всего
CREATE PROCEDURE get_kolichestvo_dogovorov
AS
SELECT COUNT(*) AS kolichDogovorov, (SELECT COUNT(*) FROM Zakaz) AS kolichZakazov FROM RecDogo
EXEC get_kolichestvo_dogovorov
drop procedure get_kolichestvo_dogovorov
-- Вывод номера договора и ИД заказчика по сумме бонуса выше вводимой суммы
CREATE PROCEDURE where_bonus_more @d float(5)
AS
SELECT (SELECT NazvDogo FROM RecDogo WHERE NomerDogovor_smeta = NomerDogovor), Bonus FROM (SELECT NomerDogovor_smeta, Bonus FROM Smeta JOIN RecDogo ON NomerDogovor = Smeta.NomerDogovor_smeta WHERE Smeta.Bonus > @d)
AS Smeta WHERE Smeta.Bonus>@d
EXEC where_bonus_more 10000
drop procedure where_bonus_more
-- Вывод номера договора и наименование заказа с одинаковым авансом и стоимостью материалов выше вводимой суммы
-- avans=videlenoDeneg:
CREATE PROCEDURE dogovori_s_odinak_avansom @o float(5), @y float(5)
AS
SELECT NazvDogo, (SELECT Naimenovanie FROM Zakaz WHERE ID_zakaza_dog = ID_zakaza) FROM RecDogo cons WHERE @o IN (SELECT VidelenoDeneg FROM Smeta where NomerDogovor = NomerDogovor_smeta and StoimostMat > @y) 
EXEC dogovori_s_odinak_avansom 234000, 70000
drop procedure dogovori_s_odinak_avansom

-- Коррелированные подзапросы --
------------------------------------
--самый старый договор--работает
SELECT NazvDogo, date FROM RecDogo WHERE date = (SELECT MIN(date) FROM RecDogo)
------------------------------------
--самый новый договор--работает
SELECT NazvDogo, date FROM RecDogo WHERE date = (SELECT MAX(date) FROM RecDogo)
------------------------------------
--найти договоры без сметы--работает
SELECT * FROM RecDogo r
WHERE not EXISTS(SELECT NomerDogovor_smeta FROM Smeta WHERE  NomerDogovor_smeta = r.NomerDogovor)
----------------------------
--количество заказов в договоре HAVING
CREATE PROCEDURE kolich_zak_v_dog @s int
AS
SELECT NazvDogo, Gorod, COUNT(Zakaz.Naimenovanie) AS [Всего заказов]
FROM RecDogo JOIN Zakaz
ON RecDogo.ID_zakaza_dog = Zakaz.ID_zakaza
GROUP BY NazvDogo, Gorod
HAVING COUNT(Zakaz.Naimenovanie) >= @s
ORDER BY NazvDogo, Gorod;

exec kolich_zak_v_dog 1

-- ALL где кол-во заказов у заказчика больше @p
CREATE PROCEDURE zakazov_bolsche_odnogo @p int(5)
AS
SELECT Name, Adres, phone FROM RecZak WHERE @p < ALL( SELECT COUNT(*) FROM Zakaz WHERE RecZak.ID_Zakazchika = ID_zakazchika_Zakaz)
exec zakazov_bolsche_odnogo 1
drop procedure zakazov_bolsche_odnogo
`------ТРИГГЕР - добавление даты(автобинд времени) при добавлении договора
CREATE TRIGGER update_dogovorn_time ON RecDogo FOR INSERT 
AS  
SET NOCOUNT ON 
UPDATE RecDogo SET date = CURRENT_TIMESTAMP 
FROM RecDogo r join inserted i ON r.NomerDogovor = i.NomerDogovor
EXEC update_dogovorn_time
drop trigger update_dogovorn_time


CREATE TRIGGER update_dogovorn_time_1 ON RecDogo FOR UPDATE 
AS  
SET NOCOUNT ON 
UPDATE RecDogo SET date = CURRENT_TIMESTAMP 
FROM RecDogo r join inserted i ON r.NomerDogovor = i.NomerDogovor
drop trigger update_dogovorn_time_1


--ЗАДАНИЕ 7-- 
CREATE PROCEDURE add_zarplata @rdnd nvarchar(20), @rdg nvarchar(20), @sum float(5), @bonus nvarchar(20), @vd nvarchar(20), @smsm nvarchar(20)
AS
BEGIN
BEGIN TRANSACTION
INSERT INTO Smeta(NomerDogovor_smeta, zarplata, Bonus, VidelenoDeneg, StoimostMat) VALUES((SELECT NomerDogovor FROM RecDogo WHERE NazvDogo = @rdnd and Gorod = @rdg), @sum, @bonus, @vd, @smsm)
IF @sum > 0 and @sum < 100000
	BEGIN
		COMMIT TRANSACTION
	END
ELSE
	BEGIN
		ROLLBACK TRANSACTION
	END
END;
exec add_zarplata avtotochka, Spetersburg, 73456, 50000, 567890, 70000
drop procedure add_zarplata


--6 задание 
CREATE PROCEDURE add_zakaz @dnz varchar(20), @dbz nvarchar(20), @zz nvarchar(20)
AS
	INSERT INTO Zakaz(Naimenovanie, Budjet, ID_zakazchika_Zakaz)  VALUES(@dnz, @dbz, (SELECT ID_zakazchika FROM RecZak WHERE Name = @zz))
drop procedure add_zakaz
exec add_zakaz 'oloxa', '4567', 'alex'
exec add_zakaz 'domfrt', '678', 'dim'

-------------------------------
CREATE PROCEDURE add_ispolnit @im varchar(20), @ai nvarchar(20), @ti nvarchar(20)
AS
	INSERT INTO RecIspoln(Imya, AdresIsp, PhoneIspoln)  VALUES(@im, @ai, @ti)
drop procedure add_ispolnit
-------------------------------
CREATE PROCEDURE add_zakazchik @zz nvarchar(20), @az varchar(20), @tz varchar(20)
AS
	INSERT INTO RecZak(Name, Adres, phone)  VALUES(@zz, @az, @tz)
exec add_zakazchik 'alex','moscow', '67898765'
exec add_zakazchik 'dim','moscow', '67898765'

drop procedure add_zakazchik
-------------------------------
CREATE PROCEDURE add_dogovor @rdnd nvarchar(20), @rdg nvarchar(20), @zz nvarchar(20), @im varchar(20), @dnz varchar(20)
AS
	INSERT INTO RecDogo(NazvDogo, Gorod, ID_Zakazchika_dog, ID_Ispolnit_dog, ID_zakaza_dog)  VALUES(@rdnd, @rdg, (SELECT ID_zakazchika FROM RecZak WHERE Name = @zz), (SELECT ID_Ispolnit FROM RecIspoln WHERE Imya = @im), (SELECT ID_zakaza FROM Zakaz WHERE Naimenovanie = @dnz))
drop procedure add_dogovor
-------------------------------
CREATE PROCEDURE add_smeta @svd nvarchar(30), @rdnd nvarchar(20), @ssm nvarchar(20), @sz nvarchar(20), @sb nvarchar(20)
AS
	INSERT INTO Smeta(VidelenoDeneg, NomerDogovor_smeta, StoimostMat, Zarplata, Bonus)  VALUES(@svd, (SELECT NomerDogovor FROM RecDogo WHERE NazvDogo = @rdnd), @ssm, @sz, @sb)
drop procedure add_smeta
-------------------------------
CREATE PROCEDURE izm_smeta @nomchek int, @vidden nvarchar(20), @nomdog_smeta nvarchar(20), @stmat nvarchar(20), @zarp nvarchar(20), @bon nvarchar(20)
AS
UPDATE Smeta
SET VidelenoDeneg= @vidden, NomerDogovor_smeta = (SELECT NomerDogovor FROM RecDogo WHERE NazvDogo = @nomdog_smeta), StoimostMat = @stmat, Zarplata= @zarp, Bonus= @bon
WHERE NomerChek = @nomchek
EXEC izm_smeta 5, 20000, 14, 3000, 15000, 30000
drop procedure izm_smeta
-------------------------------
CREATE PROCEDURE izm_zakazchik @id_zakazchika int, @nam_zakazchik nvarchar(20), @adr_zakazchik varchar(20), @phone_zakazchik varchar(20)
AS
UPDATE RecZak
SET Name= @nam_zakazchik, Adres = @adr_zakazchik, phone = @phone_zakazchik
WHERE ID_zakazchika = @id_zakazchika
EXEC izm_zakazchik 21, 'alexo', 'lobnya', 89789999
drop procedure izm_zakazchik
-------------------------------
CREATE PROCEDURE izm_zakaz @idzakaza int, @naimen varchar(20), @dudj nvarchar(20), @idzakazchikazakaz nvarchar(20)
AS
UPDATE Zakaz
SET Naimenovanie= @naimen, Budjet = @dudj, ID_zakazchika_Zakaz = (SELECT ID_zakazchika FROM RecZak WHERE Name = @idzakazchikazakaz)
WHERE ID_zakaza = @idzakaza
EXEC izm_zakaz 17, 'system', 354000, 21
drop procedure izm_zakaz
-------------------------------
CREATE PROCEDURE izm_dogovor @nomerDogovor int, @nazvdogo nvarchar(20), @gorod nvarchar(20), @idzakazchikadogo nvarchar(20), @idispolnitdogo varchar(20), @idzakazadogo varchar(20)
AS
UPDATE RecDogo
SET NazvDogo= @nazvdogo, Gorod = @gorod, ID_Zakazchika_dog = (SELECT ID_zakazchika FROM RecZak WHERE Name = @idzakazchikadogo), ID_Ispolnit_dog= (SELECT ID_Ispolnit FROM RecIspoln WHERE Imya = @idispolnitdogo), ID_zakaza_dog= (SELECT ID_zakaza FROM Zakaz WHERE Naimenovanie = @idzakazadogo)
WHERE NomerDogovor = @nomerDogovor
EXEC izm_dogovor 14, 'avtotochka', 'Spetersburg', 21, 15, 17
drop procedure izm_dogovor
-------------------------------
CREATE PROCEDURE izm_ispolnitel @id_ispolnitel int, @imya varchar(20), @adr_isp nvarchar(20), @phone_ispolnit nvarchar(20)
AS
UPDATE RecIspoln
SET Imya= @imya, AdresIsp = @adr_isp, PhoneIspoln = @phone_ispolnit
WHERE ID_Ispolnit = @id_ispolnitel
EXEC izm_ispolnitel 15, 'motolavina', 'lobnya', 89789999
drop procedure izm_ispolnitel
--------------------------------
CREATE PROCEDURE delete_smeta @deleteNomerCheck int
AS
DELETE FROM Smeta
WHERE NomerChek = @deleteNomerCheck
--------------------------------
CREATE PROCEDURE delete_zakazchik @deleteidzakazchik int
AS
DELETE FROM RecZak
WHERE ID_zakazchika = @deleteidzakazchik
--------------------------------
CREATE PROCEDURE delete_zakaz @deleteidzakaza int
AS
DELETE FROM Zakaz
WHERE ID_zakaza = @deleteidzakaza
--------------------------------
CREATE PROCEDURE delete_dogovor @deleteNomerDogovor int
AS
DELETE FROM RecDogo
WHERE NomerDogovor = @deleteNomerDogovor
--------------------------------
CREATE PROCEDURE delete_ispolnitel @deleteisp int
AS
DELETE FROM RecIspoln
WHERE ID_Ispolnit = @deleteisp

--10 задание--

CREATE LOGIN user1 WITH PASSWORD = 'user1';
CREATE USER user1 for login user1
GO
CREATE ROLE selecter;
ALTER ROLE selecter ADD MEMBER user1;

GRANT SELECT ON RecZak
    TO selecter;
GRANT SELECT ON Zakaz
    TO selecter;
GRANT SELECT ON RecDogo
    TO selecter;
GRANT SELECT ON RecIspoln
    TO selecter;
GRANT SELECT ON Smeta 
    TO selecter;

----------------
CREATE LOGIN sanches WITH PASSWORD = '1';
CREATE USER sanches for login sanches
GO
CREATE ROLE creater;
ALTER ROLE creater ADD MEMBER sanches;

GRANT SELECT ON RecZak
   TO creater;
GRANT SELECT ON Zakaz
   TO creater;
GRANT SELECT ON RecDogo
   TO creater;
GRANT SELECT ON RecIspoln
   TO creater;
GRANT SELECT ON Smeta 
   TO creater;
GRANT CREATE TABLE, CREATE PROCEDURE
   TO creater

GRANT UPDATE ON RecZak (ID_zakazchika , Name, Adres, phone)
   TO creater;
	
-----------------9 задание--------------------
-- СКАЛЯРНАЯ ФУНКЦИЯ -- работает
--поск кол-ва заказчиков учитываемых базой данных
CREATE FUNCTION check_cont_zakazchikov (@count int)
RETURNS INT 
AS
BEGIN
SET @count = (SELECT COUNT(*) FROM RecZak )
RETURN(@count)
END;
select dbo.check_cont_zakazchikov(1)
------------------------
--Возвращает введенный id-- работает
CREATE FUNCTION SK_zakazchik(@id INT) 
RETURNS int
BEGIN
    declare @id_zak int
    SELECT @id_zak = ID_zakazchika FROM RecZak WHERE ID_zakazchika = @id
    RETURN @id_zak
END;
drop function SK_zakazchik
select * from RecZak
SELECT dbo.SK_zakazchik(1)
SELECT dbo.SK_zakazchik(24)
----------------------------------------------------
--ВЕКТОРНАЯ -- работает
--Выводит данные заказчика по id
CREATE FUNCTION TB_zakazchik(@id int)
RETURNS @zak1 TABLE (ID_zakazchika INT, Name nvarchar(20), Adres varchar(20), phone varchar(20))
BEGIN 
    INSERT @zak1 
        SELECT ID_zakazchika, Name, Adres, phone FROM RecZak WHERE ID_zakazchika = @id
    RETURN
END;
select * from RecZak
SELECT * FROM dbo.TB_zakazchik(22)
DROP FUNCTION TB_zakazchik
---------------------------------------------------------------------------
--8 задание курсор--
CREATE PROCEDURE curzor
		@id int,
		@n varchar(20)
AS
DECLARE @id2 varchar(20)

DECLARE curz CURSOR FOR
SELECT ID_zakaza FROM Zakaz
OPEN curz
FETCH NEXT FROM curz INTO @id2
WHILE @@fetch_status = 0
	BEGIN
	IF @id = @id2
		
		UPDATE Zakaz
		SET Naimenovanie = @n
		WHERE ID_zakaza = @id;

		fetch next from curz into @id2
	END
CLOSE curz
DEALLOCATE curz

EXEC curzor 17, system1
DROP PROCEDURE curzor
select * from [Zakaz]


SELECT Name from RecZak JOIN Zakaz ON ID_zakazchika_Zakaz = ID_zakazchika WHERE Naimenovanie != 'oloxa'


(SELECT Naimenovanie = 'oloxa' FROM Zakaz WHERE ID_zakazchika_Zakaz = ID_zakazchika);