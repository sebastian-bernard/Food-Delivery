use DB_TestsProcedures
go

create or alter view ViewDishes
as
	-- select dishes that are cheaper than 500 lei
	select * 
	from Dishes d
	where d.price < 500
go



create or alter view ViewSpecialDishes
as
	---select the name of the dishes that have
	---the most calory-expensive ingredient smaller than 1000
	select d.dishName
	from Dishes d 
	where d.DSHid in
		(select di.DSHid
		from Dishes_Ingredients di inner join Ingredients i  
			on di.IGRDid = i.IGRDid
		group by di.DSHid
		having max(i.calories) < 1000
		)
go

insert into Views(Name) values('ViewDishes')

