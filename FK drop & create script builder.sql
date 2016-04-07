--shows FK's coming to the table
set nocount on

declare	
				@ref_schema_id				int,
				@parent_object_id			int,
				@par_schema_id				int,
				@referenced_object_id		int,
				@referenced_column_id		int,
				@constraint_object_id		int,
				@old_constraint_object_id		int,
				@constraint_column_id    int,
				@RecCnt				int,
				@TableNm				varchar(40),
				@fkcol			varchar(100),
				@SqlStrCr		nvarchar(MAX),
				@FKStr			nvarchar(MAX),
				@SqlStrDr			nvarchar(MAX),
				@parTblStr		nvarchar(300),
				@refTblStr 		nvarchar(300),
				@fkName			nvarchar(400),
				@DestFKStr		nvarchar(MAX)

declare @tbl table(createStr		nvarchar(MAX), dropStr	nvarchar(MAX) )

-------------------------------------------
-- put table name here of current database
------------------------------------------
set @TableNm = 'Users'


set @old_constraint_object_id =  0
set @RecCnt	 = 0

select 
		'referenced_object_id' = b.referenced_object_id,
		'ref_schema_id' = c.schema_id,
		'parent_object_id' = a.parent_object_id,
		'par_schema_id' = a.schema_id,
		'constraint_object_id' = a.object_id,
		'constraint_column_id' = b.parent_column_id,
		'referenced_column_id '= b.referenced_column_id

/*
		-- 'fkname' = object_name(a.object_id), 
		--'partable' = schema_name(a.schema_id) + '.' + object_name(a.parent_object_id), 

--			'reftable' = schema_name(c.schema_id) + '.' + object_name(b.referenced_object_id),

			'fkcol' = col_name( b.referenced_object_id , b.constraint_column_id),
			b.constraint_object_id -- same as a.object_id
*/

into #t1

from sys.foreign_keys a
		join sys.foreign_key_columns b on a.object_id = b.constraint_object_id
		JOin  sys.objects c on b.referenced_object_id = c.object_id

where object_name(a.parent_object_id) = @TableNm 
order by object_name(a.parent_object_id),
				b.referenced_object_id,
				a.object_id,
				b.constraint_column_id

DECLARE fk_cursor CURSOR FOR 

select		referenced_object_id,
				ref_schema_id,
				parent_object_id,
				par_schema_id,
				constraint_object_id,
				constraint_column_id,
				referenced_column_id

from #t1

open fk_cursor 				

FETCH NEXT FROM  fk_cursor  
INTO	@referenced_object_id,
			@ref_schema_id	,
			@parent_object_id,
			@par_schema_id,
			@constraint_object_id,
			@constraint_column_id,
			@referenced_column_id

WHILE @@FETCH_STATUS = 0
BEGIN
		if ( @old_constraint_object_id != @constraint_object_id ) 
			begin

				if ( @RecCnt	 >0  ) 
					begin

						select @SqlStrCr  = 'Alter table ' +@parTblStr  + ' Add Constraint ' + 
													@fkname  + ' Foreign Key(' +   @FKStr  + ') References ' + @refTblStr  + '(' + @DestFKStr  + ')'
	
						select @SqlStrDr = 'ALTER TABLE ' + @parTblStr + ' DROP CONSTRAINT ' + @fkname

						--print @SqlStrCr
						--print @SqlStrDr

						insert into @tbl values(@sqlStrCr, @SqlStrDr)

						select @FKStr = ''
						select @parTblStr = ''
						select @refTblStr = ''
						select @fkname  = ''
						select @DestFKStr = ''
					end

					--select @FKStr = col_name( @referenced_object_id , @constraint_column_id)	
					
					select @FKStr = col_name( @parent_object_id , @constraint_column_id)
					select @DestFKStr = col_name(@referenced_object_id,@referenced_column_id)	
					
					select @parTblStr = schema_name(@par_schema_id) + '.' + object_name(@parent_object_id) 
					select @refTblStr = schema_name(@ref_schema_id) + '.' + object_name(@referenced_object_id) 
					select @fkname = object_name(@constraint_object_id) 
			end
			else
				begin
					--select @FKStr   = @FKStr + ',' + col_name( @referenced_object_id , @constraint_column_id)	
				 
				 select @FKStr   = @FKStr + ',' + col_name( @parent_object_id , @constraint_column_id)	
				 select @DestFKStr = @DestFKStr + ',' + col_name(@referenced_object_id,@referenced_column_id)
				 
				 end 

		select  @RecCnt	 =  @RecCnt	 + 1

		select @old_constraint_object_id = @constraint_object_id

		FETCH NEXT FROM  fk_cursor  
		INTO		@referenced_object_id,
						@ref_schema_id	,
						@parent_object_id,
						@par_schema_id,
						@constraint_object_id,
						@constraint_column_id,
						@referenced_column_id

	-- get the last record
	if ( @@FETCH_STATUS <>  0)
		begin

			select @SqlStrCr  = 'Alter table ' +@parTblStr  + ' Add Constraint ' + 
										@fkname  + ' Foreign Key(' +   @FKStr  + ') References ' + @refTblStr + '(' + @DestFKStr  + ')'
	
			select @SqlStrDr = 'ALTER TABLE ' + @parTblStr  + ' DROP CONSTRAINT ' + @fkname
			--print @SqlStrCr
			--print @SqlStrDr

			insert into @tbl values(@sqlStrCr, @SqlStrDr)

		--select dropStr	from @tbl
		--select createStr	from @tbl
		end

END

CLOSE fk_cursor
DEALLOCATE fk_cursor



--shows the PK as an FK to other tables

set @old_constraint_object_id =  0
set @RecCnt	 = 0
	
--
-- put into a temp table
--
select		a.referenced_object_id,
				b.schema_id,
				a.parent_object_id,
				'par_schema_id' = c.schema_id,
				a.constraint_object_id,
				a.parent_column_id,
				a.referenced_column_id
into #t2

from sys.foreign_key_columns a
			JOin  sys.objects b on a.referenced_object_id = b.object_id
			JOin  sys.objects c on a.parent_object_id =  c.object_id

where object_name(a.referenced_object_id) =@TableNm
order by a.referenced_object_id,
				a.parent_object_id,
				a.constraint_object_id,
				a.parent_column_id


DECLARE fk_cursor CURSOR FOR 
select		referenced_object_id,
				schema_id,
				parent_object_id,
				par_schema_id,
				constraint_object_id,
				parent_column_id,
				referenced_column_id

from #t2

open fk_cursor 

FETCH NEXT FROM  fk_cursor  
INTO		@referenced_object_id,
				@ref_schema_id	,
				@parent_object_id,
				@par_schema_id,
				@constraint_object_id,
				@constraint_column_id,
				@referenced_column_id

WHILE @@FETCH_STATUS = 0
BEGIN
		if ( @old_constraint_object_id != @constraint_object_id ) 
			begin

--select @RecCnt, @old_constraint_object_id, @constraint_object_id, object_name(@parent_object_id)

				if ( @RecCnt	 >0  ) 
					begin

						select @SqlStrCr  = 'ALTER TABLE ' +@parTblStr  + ' Add Constraint ' + 
													@fkname  + ' Foreign Key(' +   @FKStr  + ') References ' + @refTblStr + '(' + @DestFKStr  + ')'
	
						select @SqlStrDr = 'ALTER TABLE ' + @parTblStr  + ' DROP CONSTRAINT ' + @fkname

						--print @SqlStrCr
						--print @SqlStrDr

						insert into @tbl values(@sqlStrCr, @SqlStrDr)

						select @FKStr = ''
						select @parTblStr = ''
						select @refTblStr = ''
						select @fkname  = ''
						select @DestFKStr = ''
					end

					--select @FKStr = col_name( @referenced_object_id , @constraint_column_id)	

					select @FKStr = col_name( @parent_object_id , @constraint_column_id)
					select @DestFKStr = col_name(@referenced_object_id, @referenced_column_id)	

					select @parTblStr = schema_name(@par_schema_id) + '.' + object_name(@parent_object_id) 
					select @refTblStr = schema_name(@ref_schema_id) + '.' + object_name(@referenced_object_id) 
					select @fkname = object_name(@constraint_object_id) 
				end
			else
				begin
					--select @FKStr   = @FKStr + ',' + col_name( @referenced_object_id , @constraint_column_id)	
					
					select @FKStr   = @FKStr + ',' + col_name( @parent_object_id , @constraint_column_id)
  					select @DestFKStr = @DestFKStr + ',' + col_name(@referenced_object_id,@referenced_column_id)
				 end 

		select  @RecCnt	 =  @RecCnt	 + 1

		select @old_constraint_object_id = @constraint_object_id

		FETCH NEXT FROM  fk_cursor  
		INTO		@referenced_object_id,
						@ref_schema_id	,
						@parent_object_id,
						@par_schema_id,
						@constraint_object_id,
						@constraint_column_id,
						@referenced_column_id

	-- get the last record
	if ( @@FETCH_STATUS <>  0)
		begin

			select @SqlStrCr  = 'ALTER TABLE ' +@parTblStr  + ' Add Constraint ' + 
										@fkname  + ' Foreign Key(' +   @FKStr  + ') References ' + @refTblStr + '(' + @DestFKStr  + ')'
	
			select @SqlStrDr = 'ALTER TABLE ' + @parTblStr  + ' DROP CONSTRAINT ' + @fkname
			--print @SqlStrCr
			--print @SqlStrDr

			insert into @tbl values(@sqlStrCr, @SqlStrDr)

		--			select dropStr	from @tbl
		--			select createStr	from @tbl
		
		end

END

CLOSE fk_cursor
DEALLOCATE fk_cursor


select @RecCnt = (select count(*) from @tbl)
print 'Total Objects: ' + ltrim(rtrim(str(@RecCnt)))
print ''

select dropStr	from @tbl
select createStr from @tbl

drop table #t1
drop table #t2

