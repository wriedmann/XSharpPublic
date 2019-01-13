//
// Copyright (c) XSharp B.V.  All Rights Reserved.  
// Licensed under the Apache License, Version 2.0.  
// See License.txt in the project root for license information.
//
USING System
USING System.Collections.Generic
USING System.Linq
USING System.Text
USING XUnit
USING System.Globalization

BEGIN NAMESPACE XSharp.VO.Tests

	CLASS DbfTests

		[Fact, Trait("Category", "DBFFuncs")];
		METHOD DBCreate_Tests() AS VOID
			LOCAL aFields AS ARRAY
			aFields := {{"TEST","C",10,0}}
	
			LOCAL cFileName_WithExt AS STRING
			LOCAL cFileName_NoExt AS STRING
			cFileName_NoExt := "DBCreate_Tests"
			cFileName_WithExt := cFileName_NoExt + ".dbf"
			IF System.IO.File.Exists(cFileName_WithExt)
				System.IO.File.Delete(cFileName_WithExt)
			END IF
			Assert.True(  DBCreate(cFileName_NoExt , aFields , "DBFNTX")  )
			Assert.True(  System.IO.File.Exists(cFileName_WithExt) )
			
			IF System.IO.File.Exists(cFileName_WithExt)
				System.IO.File.Delete(cFileName_WithExt)
			END IF
			Assert.True(  DBCreate(cFileName_WithExt , aFields , "DBFNTX")  )
			Assert.True(  System.IO.File.Exists(cFileName_WithExt) )
	
			cFileName_WithExt := cFileName_NoExt + ".none"
			IF System.IO.File.Exists(cFileName_WithExt)
				System.IO.File.Delete(cFileName_WithExt)
			END IF
			Assert.True(  DBCreate(cFileName_WithExt , aFields , "DBFNTX")  )
			Assert.True(  System.IO.File.Exists(cFileName_WithExt) )
		RETURN
	
		[Fact, Trait("Category", "DBFFuncs")];
		METHOD DBAppend_Exclusive() AS VOID
			LOCAL aFields AS ARRAY
			LOCAL cFileName AS STRING
			aFields := {{"TEST","C",10,0}}
			cFileName := "DBAppend_Exclusive"
	
			Assert.True(  DBCreate(cFileName , aFields , "DBFNTX")  )
			Assert.True(  DBUseArea(,"DBFNTX",cFileName,,FALSE) )
			Assert.True(  RecCount() == 0 )
			Assert.True(  DBAppend() )
			FieldPut(1 , "test")
			Assert.True(  AllTrim(FieldGet(1)) == "test" )
			Assert.True(  DBCloseArea() )
		RETURN
	
		[Fact, Trait("Category", "DBFFuncs")];
		METHOD DBAppend_Shared() AS VOID
			LOCAL aFields AS ARRAY
			LOCAL cFileName AS STRING
			aFields := {{"TEST","C",10,0}}
			cFileName := "DBAppend_Shared"
	
			Assert.True(  DBCreate(cFileName , aFields , "DBFNTX")  )
			Assert.True(  DBUseArea(,"DBFNTX",cFileName,,TRUE) )
			Assert.True(  RecCount() == 0 )
			Assert.True(  DBAppend() )
			FieldPut(1 , "test")
			Assert.True(  AllTrim(FieldGet(1)) == "test" )
			Assert.True(  DBCloseArea() )
		RETURN
	
		[Fact, Trait("Category", "DBFFuncs")];
		METHOD DBAppend_more() AS VOID
		LOCAL cDbf AS STRING
			cDbf := "testappend.DbF"
			RDDSetDefault( "DBFNTX" )
			Assert.True(  DBCreate(cDbf , { {"TEST","C",10,0} }) )
			// Appending in exclusive mode:
			Assert.True( DBUseArea(, , cDbf , "alias1" , FALSE) )
			Assert.True( DBAppend() )
			Assert.True( RecCount() == 1 )
			FieldPut(1, "test") // ok
			Assert.True( AllTrim(FieldGet(1)) == "test" )
			Assert.True( DBCloseArea() )
	
			// Appending in SHARED mode:
			Assert.True( DBUseArea(, , cDbf , "alias2" , TRUE) )
			Assert.True( RecCount() == 1 )
			Assert.True( DBAppend() )// returns true but does not append record
			Assert.True( RecCount() == 2 )
			FieldPut(1, "test2") // ok
			Assert.True( AllTrim(FieldGet(1)) == "test2" )
			Assert.True( DBCloseArea() )
		RETURN
	
		[Fact, Trait("Category", "DBFFuncs")];
		METHOD DBUseArea_same_file_twice() AS VOID
		LOCAL cDbf AS STRING
			RDDSetDefault( "DBFNTX" )
			cDbf := "testtwice.DbF"
			Assert.True(  DBCreate(cDbf , { {"TEST","C",10,0} }) )
	
			// shared mode
			Assert.True( DBUseArea(, , cDbf , , FALSE) )
			Assert.True( DBCloseArea() )
	
			Assert.True( DBUseArea(, , cDbf , , FALSE) )
			Assert.True( DBCloseArea() )
		RETURN


		// TECH-K3TL5J8M7V
		[Fact, Trait("Category", "DBF")];
		METHOD VODBInfo() AS VOID
			
			LOCAL cFileName AS STRING
			cFileName := GetTempFileName("test")
			DBCreate(cFileName , { {"CFIELD","C",10,0} })
			DBUseArea(,,cFileName)
			DBAppend()
			
			LOCAL u AS USUAL
			VODBSkip(-1)
			
			VODBInfo(DBI_FULLPATH , REF u)
			LOCAL c AS STRING
			c := u
			? c
			Assert.True(c:EndsWith("test.DBF") .and. c:Contains(":\"))
			VODBInfo(DBI_DB_VERSION , REF u)
			Assert.True(SLen(u) > 1)
			VODBInfo(DBI_ALIAS , REF u)
			Assert.Equal("test" , u)
			
			VODBInfo(DBI_BOF , REF u)
			Assert.Equal(TRUE , u)
			VODBInfo(DBI_EOF , REF u)
			Assert.Equal(FALSE , u)
			VODBInfo(DBI_ISANSI , REF u)
			Assert.Equal(SetAnsi() , u)
			VODBInfo(DBI_FCOUNT , REF u)
			Assert.Equal(1, u)
			VODBInfo(DBI_READONLY , REF u)
			Assert.Equal(FALSE, u)
			
			DBCloseArea()
		RETURN

		// TECH-E6Y9GNHB99
		[Fact, Trait("Category", "DBF")];
		METHOD AppendShared() AS VOID
			LOCAL cDbf AS STRING
			cDbf := GetTempFileName("testAppendShared")
			RDDSetDefault( "DBFNTX" )
			DBCreate(cDbf , { {"TEST","C",10,0} })
			
//			Appending in exclusive mode:
			DBUseArea(, , cDbf , "alias2" , FALSE)
			Assert.True( DBAppend() )
			Assert.Equal( 1 , RecCount() )
			FieldPut(1, "test") // ok
			DBCloseArea()
			
//			Appending in SHARED mode:
			DBUseArea(, , cDbf , "alias2" , TRUE)
			Assert.True( DBAppend() ) // returns true but does not append record
			Assert.Equal( 2 , RecCount() ) // returns 1, wrong
			DBCloseArea()
		RETURN

		// TECH-6U40UQ0JV3
		[Fact, Trait("Category", "DBF")];
		METHOD AliasNameReuse() AS VOID
			LOCAL cDbf AS STRING
			cDbf := GetTempFileName("testdbf")
			
			RDDSetDefault( "DBFNTX" )
			
			DBCreate(cDbf , { {"TEST","C",10,0} })
			
//			opening and closing once
			DBUseArea(, , cDbf , , FALSE)
			DBCloseArea()
			
//			opening and closing again
			Assert.True( DBUseArea(, , cDbf , , FALSE) )
			Assert.True( DBCloseArea() )
		RETURN

		// TECH-SAK5955895
		[Fact, Trait("Category", "DBF")];
		METHOD SavingDecimalValues() AS VOID
			LOCAL cFileName AS STRING
			cFileName := GetTempFileName()
			DBCreate(cFileName, {{"FLD1","N",10,2},{"FLD2","N",10,0}})
			DBUseArea(,,cFileName)
			DBAppend()

			SetDecimalSep(Asc(","))
			FieldPut(1 , 12.34) // not saved in the dbf
			Assert.Equal(12.34 , FieldGet(1)) // 0,00

			SetDecimalSep(Asc("."))
			FieldPut(1 , 12.34)
			Assert.Equal(12.34 , FieldGet(1))

			DBCloseArea()
		RETURN

		// TECH-C8WB52EA4A , Runtime exception when reading from a float field, after writing to it and DBCommit()
		[Fact, Trait("Category", "DBF")];
		METHOD DBCommitAfterFieldput() AS VOID
			LOCAL cFileName AS STRING
			cFileName := GetTempFileName()
			DBCreate(cFileName, {{"FLD1","N",10,4}})
			DBUseArea( , , cFileName , "tempalias")
			DBAppend()
			DBCloseArea()
			
			DBUseArea( , , cFileName)
			FieldPut(1 , 46.11) // ! a float isn/t stored !
			DBCommit()
			Assert.Equal(46.11 , FieldGet(1)) // runtime exception
			DBCloseArea()
		RETURN
	
	
		// TECH-J61EXJ870D , FieldName() and FieldSym() throw an exception with incorrect field no
		[Fact, Trait("Category", "DBF")];
		METHOD FieldNameSym() AS VOID
			LOCAL cFileName AS STRING
			cFileName := GetTempFileName()
			DBCreate(cFileName, {{"FLD1","N",10,4}})
			DBUseArea( , , cFileName , "tempalias")
			DBAppend()
			Assert.Equal("", FieldName(100)) // exception
			Assert.Equal("", FieldName(0))
			Assert.Equal(NULL_SYMBOL, FieldSym(100))
			Assert.Equal(NULL_SYMBOL, FieldSym(0))
			DBCloseArea()
		RETURN
	
	
	
		// TECH-560ANYQI2P , DBRLockList() always returns zero
		[Fact, Trait("Category", "DBF")];
		METHOD DBRLockList() AS VOID
			LOCAL cFileName AS STRING
			cFileName := GetTempFileName()
			DBCreate(cFileName, {{"FLD1","C",10,0}})
			DBUseArea( , , cFileName , "tempalias" , TRUE)
			DBAppend()
			DBAppend()
			DBGoTop()
			DBRLock()
			DBRLockList()
			Assert.Equal(1, ALen(DBRLockList()))
			Assert.Equal(1, DBRLockList()[1])
			DBUnlock()
			DBSkip()
			DBRLock()
			Assert.Equal(1, ALen(DBRLockList()))
			Assert.Equal(2, DBRLockList()[1])
			DBCloseArea()
		RETURN
	
		// TECH-34OWD3RR1Z , DBF problems with filters
		[Fact, Trait("Category", "DBF")];
		METHOD DBFilter() AS VOID
			LOCAL cDbf AS STRING
			cDbf := GetTempFileName()
			IF System.IO.File.Exists(cDbf)
				System.IO.File.Delete(cDbf)
			END IF
			DBCreate(cDbf, {{"CFIELD","C",10,0}}, "DBFNTX", TRUE)
			DBAppend()
			FieldPut(1, "ABC")
			DBAppend()
			FieldPut(1, "DEF")
			DBAppend()
			FieldPut(1, "GHI")
			DBAppend()
			FieldPut(1, "JKL")
			Assert.Equal(4 , RecCount())
			Assert.Equal(4 , LastRec())
			DBCloseArea()
						
			DBUseArea(,,cDbf)
//			"Setting filter to GHI, should be one record:"
//			"Instead, record 1 and 3 are shown"
			DBSetFilter({||AllTrim(FIELD->CFIELD) == "GHI"})
			DBGoTop()
			LOCAL nCount := 0 AS INT
			DO WHILE .not. EoF()
				Assert.Equal(3 , RecNo())
				FieldGet(1)
				DBSkip(+1)
				nCount ++
			END DO
			Assert.Equal(1 , nCount)
			
			DBGoBottom()
			Assert.False( EOF() )
			nCount := 0
			DO WHILE .not. EoF()
				Assert.Equal(3 , RecNo())
				nCount ++
				FieldGet(1)
				DBSkip(+1)
			END DO
			Assert.Equal(1 , nCount)
			
			DBCloseArea()
		RETURN

		// TECH-8C175D53DN , DBRecordInfo() always returns NULL_OBJECT
		[Fact, Trait("Category", "DBF")];
		METHOD DBRecordInfo_test() AS VOID
			LOCAL cDbf AS STRING
			LOCAL l AS LOGIC
			cDbf := GetTempFileName()
			DBCreate(cDbf, {{"CFIELD","C",10,0}}, "DBFNTX", TRUE)
			DBAppend()
			FieldPut(1, "ABC")
			
			l := DBRecordInfo( DBRI_RECNO ) // exception
			Assert.True(l)
			l := DBRecordInfo( DBRI_DELETED ) // exception
			Assert.False(l)
			l := DBRecordInfo( DBRI_LOCKED ) // exception
			Assert.True(l)
			
			DBCloseArea()
		RETURN
		
		// TECH-NVMBVB2Y44 , NullReferenceExpetion with DBFieldInfo()
		[Fact, Trait("Category", "DBF")];
		METHOD DBFieldInfo_test() AS VOID
			LOCAL cDbf AS STRING
			cDbf := GetTempFileName()
			DBCreate(cDbf, {{"NFIELD","N",10,3}}, "DBFNTX", TRUE)
			DBAppend()
			FieldPut(1, "ABC")
			
			Assert.Equal("NFIELD",	DBFieldInfo( DBS_NAME , 1 ) ) // NullReferenceException
			Assert.Equal("N",		DBFieldInfo( DBS_TYPE , 1 ) )
			Assert.Equal(10,		DBFieldInfo( DBS_LEN , 1 ) )
			Assert.Equal(3,			DBFieldInfo( DBS_DEC , 1 ) )
			Assert.Equal(5,			DBFieldInfo( DBS_PROPERTIES , 1 ) )
			
			DBCloseArea()
		RETURN

		// TECH-52M9YX557W , DBRecordInfo() changes record pointer
		[Fact, Trait("Category", "DBF")];
		METHOD DBRecordInfo_test2() AS VOID
			LOCAL cDbf AS STRING
			cDbf := GetTempFileName()
			DBCreate(cDbf, {{"CFIELD","C",10,0}}, "DBFNTX", TRUE)
			DBAppend()
			FieldPut(1, "ABC")
			DBAppend()
			FieldPut(1, "DEF")
			
			DBGoTop()
			Assert.Equal(1, RecNo())
			Assert.Equal(FALSE, EOF())
			
//			 Any of the below cause the record pointer to go EOF
			Assert.False( DBRecordInfo(DBRI_DELETED , 0) )
			DBRecordInfo(DBRI_BUFFPTR , 0)
			DBRecordInfo(DBRI_RAWDATA , 0)
			
			Assert.Equal(1, RecNo())
			Assert.Equal(FALSE, EOF())
			
			DBCloseArea()
		RETURN
	
		// TECH-C6Y1L51V1O , DBContinue() not working correctly
		[Fact, Trait("Category", "DBF")];
		METHOD DBContinue_test() AS VOID
			LOCAL cDbf AS STRING
			cDbf := GetTempFileName()
			DBCreate(cDbf, {{"NFIELD","N",10,0}}, "DBFNTX", TRUE)
			DBAppend()
			FieldPut(1, 123)
			DBAppend()
			FieldPut(1, 456)
			DBAppend()
			FieldPut(1, 789)
			
			DBGoTop()
			Assert.True( DBLocate({||_FIELD->NFIELD > 300} , , , , TRUE) ) // DBSCOPEREST
			Assert.True( Found() )
			Assert.Equal(456.0 , FieldGet(1) )
			
//			DBContinue() returns TRUE (correct) but does not move record pointer at all
			Assert.True( DBContinue() )
			Assert.True( Found() )
			Assert.Equal( 789.0 , FieldGet(1) )
			
			Assert.True( DBContinue() )
			Assert.False( Found() )
			Assert.Equal( 0.0 , FieldGet(1) )
			
			Assert.True( DBContinue() )
			Assert.False( Found() )
			Assert.Equal( 0.0 , FieldGet(1) )
			
			DBCloseArea()
		RETURN


		// TECH-Y4UUA09473 , Problem on creating error for invalid RDD command
		[Fact, Trait("Category", "DBF")];
		METHOD DBAppendWithNoWorkarea() AS VOID
			DBCloseAll()
			Assert.False( DBAppend() )
		RETURN


		// TECH-8HN2I0UUNA , Index file not correctly created when dbf is opened in SHARED mode
		[Fact, Trait("Category", "DBF")];
		METHOD Shared_Ntx() AS VOID
			LOCAL cDbf AS STRING
			LOCAL cNtx AS STRING
			cDbf := GetTempFileName()
			cNtx := cDbf + ".ntx"
			
			Assert.True( DBCreate( cDbf , {{"CFIELD" , "C" , 10 , 0 }}) )
			Assert.True( DBUseArea(,,cDbf,,FALSE) )
			Assert.True( DBAppend() )
			FieldPut ( 1 , "B")
			Assert.True( DBAppend() )
			FieldPut ( 1 , "A")
			Assert.True( DBCloseArea() )
			
			Assert.True( DBUseArea(,,cDbf,,TRUE) ) // ----- opening in SHARED mode
			Assert.True( DBCreateIndex(cNtx , "CFIELD") ) // returns TRUE
			Assert.True( DBCloseArea() )
			
			Assert.True( DBUseArea(,,cDbf,,FALSE) )
			Assert.True( DBSetIndex(cNtx) )
			DBGoTop()
			Assert.True( AllTrim(FieldGet(1)) == "A" )
			DBGoBottom()
			Assert.True( AllTrim(FieldGet(1)) == "B" )
			Assert.True( DBCloseArea() ) // XSharp.RDD.RddError here
		RETURN

		// TECH-U43F26KOT7 , Runtime error saving NULL_DATE to DATE dbf field
		[Fact, Trait("Category", "DBF")];
		METHOD Save_NULL_DATE() AS VOID
			LOCAL cDbf AS STRING
			cDbf := GetTempFileName()
			Assert.True(  DBCreate( cDbf , {{"CFIELD" , "C" , 10 , 0 },;
			{"DFIELD" , "D" , 8 , 0 }}) )
			Assert.True( DBUseArea(,,cDbf) )
			DBAppend()
			FieldPut ( 1 , "B")
			DBAppend()
			FieldPut ( 1 , "A")
			Assert.True( DBCloseArea() )
			
			Assert.True( DBUseArea(,,cDbf) )
			LOCAL u AS USUAL
			u := FieldGet(2) // it should be a NULL_DATE
			Assert.True( u == NULL_DATE )
			FieldPut(2,u) // exception
			FieldPut(2,NULL_DATE) // exception
			Assert.True( FieldGet(2) == NULL_DATE )
			Assert.True(  DBCloseArea() )
		RETURN


		// TECH-588I8LB67J , Problems with NTX indexes
		[Fact, Trait("Category", "DBF")];
		METHOD Ntx_Issues() AS VOID
			LOCAL cDbf AS STRING
			LOCAL cNtx AS STRING
			LOCAL aResult AS ARRAY
			
			cDbf := GetTempFileName()
			cNtx := cDbf + ".ntx"
			
			DBCreate( cDbf , {{"CFIELD" , "C" , 10 , 0 }})
			DBUseArea(,,cDbf)
			DBAppend()
			FieldPut ( 1 , "ABC")
			DBAppend()
			FieldPut ( 1 , "GHI")
			DBAppend()
			FieldPut ( 1 , "DEF")
			DBAppend()
			FieldPut ( 1 , "K")
			DBCloseArea()
			
			Assert.True( DBUseArea(,,cDbf) )
			Assert.True( DBCreateIndex(cNtx , "CFIELD") )
			Assert.True( DBCloseArea() )
			
			Assert.True( DBUseArea(,,cDbf,,FALSE) )
			Assert.True( DBSetIndex(cNtx) )
			aResult := GetRecords()
//			should be ABC, DEF, GHI, K
			Assert.True( aResult[1] == "ABC")
			Assert.True( aResult[2] == "DEF")
			Assert.True( aResult[3] == "GHI")
			Assert.True( aResult[4] == "K")
			
			DBGoTop()
			DBSkip()
			FieldPut(1,"HHH")
			aResult := GetRecords()
//			should be ABC, GHI, HHH, K
			Assert.True( aResult[1] == "ABC")
			Assert.True( aResult[2] == "GHI")
			Assert.True( aResult[3] == "HHH")
			Assert.True( aResult[4] == "K")

			DBGoTop()
			DBSkip(2)
			FieldPut(1,"DEF") // restore it
			
			Assert.True( DBCloseArea() )


			Assert.True( DBUseArea(,,cDbf,,TRUE) )
			Assert.True( DBSetIndex(cNtx) )
			aResult := GetRecords()
//			should be ABC, DEF, GHI, K
			Assert.True( aResult[1] == "ABC")
			Assert.True( aResult[2] == "DEF")
			Assert.True( aResult[3] == "GHI")
			Assert.True( aResult[4] == "K")
			
			DBGoTop()
			DBSkip()
			Assert.True(RLock())
			FieldPut(1,"III")
			aResult := GetRecords()
//			should be ABC, GHI, III, K
			Assert.True( aResult[1] == "ABC")
			Assert.True( aResult[2] == "GHI")
			Assert.True( aResult[3] == "III")
			Assert.True( aResult[4] == "K")
			
			Assert.True( DBCloseArea() )
		RETURN

		PRIVATE STATIC METHOD GetRecords() AS ARRAY
			LOCAL aResult AS ARRAY
			aResult := {}
			DBGoTop()
			DO WHILE .not. Eof()
				AAdd(aResult , AllTrim(FieldGet(1)))
				DBSkip()
			END DO
		RETURN aResult

		// TECH-V7A528Z0ZL , Problems with ntx indexes 2
		[Fact, Trait("Category", "DBF")];
		METHOD Ntx_Issues2() AS VOID
			LOCAL cFileName AS STRING
			cFileName := GetTempFileName()
			DBCreate(cFileName, {{"FLD1","C",10,0},{"FLD2","N",10,0}})
			DBUseArea( , , cFileName , , FALSE)
			FOR LOCAL n := 1 AS INT UPTO 10
				DBAppend()
				FieldPut(1, n:ToString())
				FieldPut(2, n)
			NEXT
			Assert.True( DBCreateIndex(cFileName + ".ntx" , "FLD2") )
			Assert.True( DBCloseArea() )

			DBUseArea( , , cFileName , , FALSE)
			Assert.True( DBSetIndex(cFileName + ".ntx") )
			DBGoTop()
			LOCAL nCount := 0 AS INT
			DO WHILE ! EOF()
				nCount ++
				Assert.True( FieldGet(2) == RecNo() )
				Assert.True( FieldGet(2) == nCount )
				Assert.True( DBSkip() )
			END DO
			Assert.True( DBCloseArea() )
		RETURN

		// TECH-965270UG7K , Workareas not being reused
		[Fact, Trait("Category", "DBF")];
		METHOD WorkareaNums() AS VOID
			LOCAL cFileName AS STRING
			cFileName := GetTempFileName()
			Assert.True( DBCreate(cFileName, {{"FLD1","C",10,0}}) )
			
			Assert.True( DBUseArea ( TRUE , , cFileName , "a1") )
			Assert.Equal( 1 , DBGetSelect() )
			Assert.True( DBCloseArea() )
			
			Assert.True( DBUseArea ( TRUE , , cFileName , "a2") )
			Assert.Equal( 1 , DBGetSelect() )
			Assert.True( DBCloseArea() )
			
			Assert.True( DBUseArea ( TRUE , , cFileName , "a3") )
			Assert.Equal( 1 , DBGetSelect() )
			Assert.True( DBCloseArea() )
		RETURN

		// FOX-ES1QLR6Y5L , dbRecordInfo ( DBRI_LOCKED ) always returns .f.
		[Fact, Trait("Category", "DBF")];
		METHOD DBRI_LOCKED_test() AS VOID
			LOCAL cFileName AS STRING
			cFileName := GetTempFileName()
			SetExclusive ( FALSE )
			DBCreate ( cFileName , { {"id", "C", 5, 0} })
		
			DBUseArea ( , , cFileName )
			DBAppend()
			DBAppend()
			DBAppend()
			DBGoTop()
			
			Assert.True( DBRLock ( RecNo() ) )
			Assert.True( DBRecordInfo ( DBRI_LOCKED ) ) // Should show TRUE
			Assert.True( AScan ( DBRLockList() , RecNo() ) > 0 )
			
			DBSkip()
//			record 2 - no lock
			Assert.False( DBRecordInfo ( DBRI_LOCKED ) )
			Assert.False( AScan ( DBRLockList() , RecNo() ) > 0 )
			
			DBSkip()
			Assert.True( DBRLock ( RecNo() ) )
			Assert.True( DBRecordInfo ( DBRI_LOCKED ) ) // Should show TRUE
			Assert.True( AScan ( DBRLockList() , RecNo() ) > 0 )
			
			LOCAL a AS ARRAY
			a:= DBRLockList()
			Assert.Equal( 2 , ALen(a) )
			Assert.Equal( 1 , a[1] )
			Assert.Equal( 3 , a[2] )

			DBCloseArea()
		RETURN

		// TECH-XQES14W9J0 , Aliasxxx() funcs throw exceptions
		[Fact, Trait("Category", "DBF")];
		METHOD Alias_test() AS VOID
			DBCloseAll()
			Assert.True( Alias() == "" )
			Assert.True( Alias0() == "" )
			Assert.True( Alias0Sym() == "" )
		RETURN

		// TECH-IXV5X91A74 , DBCreate() problem after having opened a dbf in exclusive mode
		[Fact, Trait("Category", "DBF")];
		METHOD DBCreate_test() AS VOID
			LOCAL cFileName AS STRING
			cFileName := GetTempFileName()
			
			DBCreate(cFileName, {{"FLD1","C",10,0}})
			DBUseArea(,,cFileName,,FALSE)
			DBCloseArea()

//			exception here
			Assert.True( DBCreate(cFileName, {{"FLD1","N",10,0}}) )
			
			Assert.True( DBUseArea(,,cFileName) )
			DBAppend()
			FieldPut(1 , 123)
			Assert.True( FieldGet(1) == 123 )
			Assert.True( DBCloseArea() )
		RETURN


		// TECH-ONPOSM84VS , Runtime exception on Error:ToString()
		[Fact, Trait("Category", "DBF")];
		METHOD DBError_test() AS VOID
			LOCAL cDbf AS STRING
			LOCAL cNtx AS STRING
			LOCAL aResult AS ARRAY
			
			cDbf := GetTempFileName()
			cNtx := cDbf + ".ntx"
			
			DBCreate( cDbf , {{"CFIELD" , "C" , 10 , 0 }})
			DBUseArea(,,cDbf,,TRUE)
			Assert.True( DBAppend() )
			Assert.True( DBUnlock() )
			TRY
				? FieldPut ( 1 , "ABC") // record not locked
			CATCH e AS XSharp.Error
				? e:Message
				? e:GenCodeText
				? e:SubCodeText // check if this displays correctly
				? e:OSCodeText
				? e:ToString() // exception here
			FINALLY
				Assert.True( DBCloseArea() )
			END TRY
		RETURN


	
		STATIC PRIVATE METHOD GetTempFileName() AS STRING
		RETURN GetTempFileName("testdbf")
		STATIC PRIVATE METHOD GetTempFileName(cFileName AS STRING) AS STRING
			// we may want to put them to a specific folder etc
		RETURN cFileName
			
	END CLASS
END NAMESPACE
