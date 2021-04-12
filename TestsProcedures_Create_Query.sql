use DB_TestsProcedures
go


CREATE TABLE Dishes(
  DSHid int PRIMARY key not null,
  dishName VARCHAR(50),
  --FSid int FOREIGN key REFERENCES FoodSections(FSid) on DELETE CASCADE,
  price INT
)

CREATE TABLE Ingredients(
  IGRDid int primary KEY,
  ingredientName VARCHAR(50),
  weight_or_number VARCHAR(50),
  calories int
)

CREATE TABLE Dishes_Ingredients(
  DSHid int FOREIGN key REFERENCES Dishes(DSHid) on DELETE CASCADE,
  IGRDid int FOREIGN key REFERENCES Ingredients(IGRDid) on DELETE CASCADE
  constraint PK_Dishes_Ingredients primary key (DSHid, IGRDid)
)


CREATE TABLE Towns(
  Tid int primary key not null,
  TownName varchar(50),

)

create TABLE Deliverer(
  Did int primary key not null,
  Tid INT foreign key REFERENCES Towns(Tid) on delete cascade,
  DelivererName varchar(50),
  DeliversTotal int
)

insert into Tables(Name) values('Ingredients');
insert into Tables(Name) values('Dishes');
insert into Tables(Name) values('Dishes_Ingredients');
insert into Tables(Name) values('Towns');
insert into Tables(Name) values('Deliverer');

insert into Tests(Name) values('test1');
insert into Tests(Name) values('test2');

select * from Tests
select * from Tables

insert into TestTables(TestID, TableID, NoOfRows, Position) values (1,1,5000,1);
insert into TestTables(TestID, TableID, NoOfRows, Position) values (1,2,5000,2);
insert into TestTables(TestID, TableID, NoOfRows, Position) values (1,3,5000,3);

create or alter procedure insertIntoIngredients(@rows INT)
as
begin
	while @rows > 0 begin
		insert into Ingredients(IGRDid, ingredientName, weight_or_number, calories) values (@rows, 'ingredients '+CAST(@rows as varchar) , @rows*5 , @rows*50);		
		set @rows = @rows - 1
	end
end
go

create or alter procedure insertIntoDishes(@rows INT)
as
begin
	while @rows > 0 begin
		insert into Dishes(DSHid, dishName, price) values (@rows, 'dish '+CAST(@rows as varchar) , @rows*100);		
		set @rows = @rows - 1
	end
end
go


create or alter procedure insertIntoDishes_Ingredients(@rows INT)
as
begin
	declare @dishId int;
	declare @ingredientsId int;

	while @rows > 0 begin
		set @dishId = (select top 1 d.DSHid
						from Dishes d
						order by NEWID()
					  )

		set @ingredientsId = (select top 1 i.IGRDid 
								from Ingredients i
								order by NEWID()
							 )

		while exists (select *
						from Dishes_Ingredients	di
						where di.DSHid = @dishId and di.IGRDid = @ingredientsId
						)
		begin
			set @dishId = (select top 1 d.DSHid
						from Dishes d
						order by NEWID()
					  )

		set @ingredientsId = (select top 1 i.IGRDid 
								from Ingredients i
								order by NEWID()
							 )
		end

		insert into Dishes_Ingredients(IGRDid, DSHid) values (@ingredientsId, @dishId);
		
		set @rows = @rows - 1
	end
end
go

create or alter procedure runTest(@idTest int)
as
	declare @testRunID int	
	declare @testStartTime datetime2
	declare @startTime datetime2
	declare @endTime datetime2
	declare @table varchar(50)
	declare @rows int
	declare @pos int
	declare @command varchar(100)

	set @testRunID = (select max(TestRunID)+ 1 from TestRuns)
    if @testRunID is null
        set @testRunID = 1
	
	declare @testName varchar(max);

	select @testName = t.Name
	from Tests t
	where t.TestID = @idTest; 

	SET IDENTITY_INSERT TestRuns ON
	insert into TestRuns(TestRunID, Description, StartAt) values (@testRunID, @testName, SYSDATETIME());
	SET IDENTITY_INSERT TestRuns OFF

	declare tableCursor cursor scroll for
    select T1.Name, T2.NoOfRows, T2.Position
    from Tables T1 join TestTables T2 on T1.TableID = T2.TableID
    where T2.TestID = @idTest
    order by T2.Position

	set @testStartTime = sysdatetime()
	open tableCursor
	fetch last from tableCursor into @table, @rows, @pos
	while @@FETCH_STATUS = 0 begin
		exec ('delete from '+ @table)
		fetch prior from tableCursor into @table, @rows, @pos
	end
	close tableCursor

	open tableCursor	
	fetch tableCursor into @table, @rows, @pos
	while @@FETCH_STATUS = 0 begin
		set @command = 'insertInto' + @table
		set @startTime = sysdatetime()
		exec @command @rows
		set @endTime = sysdatetime()
		insert into TestRunTables (TestRunID, TableId, StartAt, EndAt) values (@testRunID, (select TableID from Tables where Name=@table), @startTime, @endTime)
		fetch tableCursor into @table, @rows, @pos
	end
	close tableCursor
	deallocate tableCursor

	update TestRuns
    set EndAt=sysdatetime()
    where TestRunID = @testRunID

go

exec runTest 1

select * from TestRuns

select * from TestRunTables