﻿//
// Copyright (c) XSharp B.V.  All Rights Reserved.  
// Licensed under the Apache License, Version 2.0.  
// See License.txt in the project root for license information.
//
USING System
USING System.Collections.Generic
USING System.Linq
USING System.Text
using XUnit
using System.Globalization


BEGIN NAMESPACE XSharp.VO.Tests

	CLASS DateTests

		[Fact, Trait("Category", "Date")];
		method CTODTest() as void 
			SetEpoch(1900)
			SetDateFormat("dd/mm/yyyy")
			Assert.Equal(2016.01.01 ,ctod("01/01/2016"))
			Assert.Equal(2016.02.13 ,ctod("13/02/2016"))
			Assert.Equal(0001.01.01 ,ctod("01/01/0001"))
			Assert.Equal(1901.01.01 ,ctod("01/01/01"))
			SetDateFormat("mm/dd/yyyy")	
			Assert.Equal(2016.01.01 ,ctod("01/01/2016"))
			Assert.Equal(2016.02.13 ,ctod("02/13/2016"))
			Assert.Equal(2016.03.13 ,ctod("03/13/2016"))
		RETURN

 		

		[Fact, Trait("Category", "Date")];
		METHOD STODTest() as void
			Assert.Equal(DATE{2016,05,06},STOD("20160506"))
			Assert.Equal(NULL_DATE, STOD("20181313"))
			Assert.Equal(NULL_DATE, STOD("AAAAAAAA"))
		RETURN

		[Fact, Trait("Category", "Date")];
		method CDOWTest() as void
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"en-US"}
			Assert.Equal("Tuesday",CDOW(Condate(2016,5,24)))
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"de-DE"}
			Assert.Equal("Dienstag",CDOW(Condate(2016,5,24)))
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"nl-NL"}
			Assert.Equal("dinsdag",CDOW(Condate(2016,5,24)))
			Assert.Equal("", CDOW(NULL_DATE))
		RETURN

		[Fact, Trait("Category", "Date")];
		METHOD CMonthTest() as void
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"en-US"}
			Assert.Equal("May",CMonth(Condate(2016,5,24)))
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"de-DE"}
			Assert.Equal("Mai",CMonth(Condate(2016,5,24)))
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"nl-NL"}
			Assert.Equal("mei",CMonth(Condate(2016,5,24)))
			Assert.Equal("", CMonth(NULL_DATE))
		RETURN

		[Fact, Trait("Category", "Date")];
		METHOD DayTest() as void
			Assert.Equal((DWORD)24,Day(Condate(2016,5,24)))
			Assert.Equal((dword)0,Day(NULL_DATE))
		RETURN

		[Fact, Trait("Category", "Date")];
		METHOD DOWTest() AS VOID
			// DOW should return 0  for empty dates
			// 1 = Sunday, 2 = Monday, .... 7 = Saturday

			Assert.Equal((DWORD)3,DOW(Condate(2016,5,24)))
			Assert.Equal((DWORD)4,DOW(Condate(2018,6,13)))
			Assert.Equal((DWORD)0,DOW(Condate(0,0,0)))
		RETURN

		[Fact, Trait("Category", "Date")];
		method DTOCTest() as void
			SetDateFormat("DD/MM/YYYY")
			Assert.Equal("24/05/2016",DTOC(CTOD("24/05/2016")))
			SetDateFormat("DD/MM/YY")
			Assert.Equal("24/05/16",DTOC(CTOD("24/05/2016")))
			SetDateFormat("MM/DD/YY")
			Assert.Equal("  /  /  ",DTOC(CTOD("24/05/2016")))
			SetDateFormat("mm-dd-YYYY")
			Assert.Equal("  -  -    ",DTOC(CTOD("24/05/2016")))
			SetDateFormat("dd-mm-YYYY")
			Assert.Equal("24-05-2016",DTOC(CTOD("24/05/2016")))
		RETURN

		[Fact, Trait("Category", "Date")];
		METHOD DTOSTest() as void
			Assert.Equal("20160524",DTOS(Condate(2016,5,24)))
			Assert.Equal("        ", DTOS(NULL_DATE))
		RETURN

		[Fact, Trait("Category", "Date")];
		METHOD MonthTest() as void
			Assert.Equal((DWORD)5,MONTH(Condate(2016,5,24)))
			Assert.Equal((dword)0,MONTH(NULL_DATE))
		RETURN

		[Fact, Trait("Category", "Date")];
		METHOD YearTest() as void
			Assert.Equal((DWORD)2016,YEAR(Condate(2016,5,24)))
			Assert.Equal((dword)0,YEAR(NULL_DATE))
		RETURN

		[Fact, Trait("Category", "Date")];
		METHOD CastTest() as void
			LOCAL i as LONG
			LOCAL dw as DWORD
			VAR d := 2017.1.1
			i := (LONG) d
			dw := (DWORD) d
			Assert.Equal(d, (Date) i)
			Assert.Equal(d, (Date) dw)

		RETURN
		[Fact, Trait("Category", "Date")];
		METHOD CompareTest() as VOID
		VAR d1 := Date{2017,09,25}
		VAR d2 := Date{2017,09,26}	// different day
		Assert.True(d1 < d2)
		Assert.True(d1 <= d2)
		Assert.True(d1+1 == d2)
		Assert.False(d1 > d2)
		Assert.False(d1 >= d2)

		d2 := Date{2017,10,25}	// different month
		Assert.True(d1 < d2)
		Assert.True(d1 <= d2)
		Assert.False(d1 > d2)
		Assert.False(d1 >= d2)

		d2 := Date{2018,09,24}	// different year
		Assert.True(d1 < d2)
		Assert.True(d1 <= d2)
		Assert.False(d1 > d2)
		Assert.False(d1 >= d2)

		Assert.True(d2 > d1)
		Assert.True(d2 >= d1)
		Assert.False(d2 < d1)
		Assert.False(d2 <= d1)
		
		Var d3 := d1
		Assert.False(d3 > d1)
		Assert.True(d3 >= d1)
		Assert.False(d3 < d1)
		Assert.True(d3 <= d1)

		[Fact, Trait("Category", "Numeric")];
		method NToCDoWTest() as void
			SetDateFormat("DD/MM/YYYY")
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"en-US"}
			Assert.Equal("Friday",NToCDoW(DOW(CTOD("27/05/2016"))))
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"de-DE"}
			Assert.Equal("Freitag",NToCDoW(DOW(CTOD("27/05/2016"))))
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"nl-NL"}
			Assert.Equal("vrijdag",NToCDoW(DOW(CTOD("27/05/2016"))))
		
		RETURN

		[Fact, Trait("Category", "Numeric")];
		METHOD NToCMonthTest() as void
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"en-US"}
			Assert.Equal("June",NToCMonth((dword)6))
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"de-DE"}
			Assert.Equal("Juni",NToCMonth((dword)6))
			System.Threading.Thread.CurrentThread:CurrentCulture := CultureInfo{"nl-NL"}
			Assert.Equal("juni",NToCMonth((dword)6))
		
		return		
		
		[Fact, Trait("Category", "Date")];
		METHOD CoNDateTest() as void
			local d1918 as Date
			local d2018 as date
			local dtest as date
			local nEpoch := SetEpoch()
			SetEpoch(1900)
			d2018 := ConDate(2018,03,15)
			d1918 := ConDate(1918,03,15)
			dtest := ConDate(18,3,15)
			Assert.Equal(d1918, dtest)
			SetEpoch(2000)
			dtest := ConDate(18,3,15)
			Assert.Equal(d2018, dtest)
			SetEpoch(1917)
			dtest := ConDate(18,3,15)	// should be 1918
			Assert.Equal(d1918, dtest)
			SetEpoch(1917)
			dtest := ConDate(18,3,15) // should be 1918
			SetEpoch(1918)
			Assert.Equal(d1918, dtest)
			dtest := ConDate(18,3,15) // should be 1918
			SetEpoch(1919)
			Assert.Equal(d2018, dtest)
			SetEpoch(nEpoch)
		return		
		[Fact, Trait("Category", "Date")];
		method Date2BinTest() as void
			local dwDate as STRING
			local dDate1 as date
			local dDate2 as date

			dDate1 := Today()
			dwDate := Date2Bin(dDate1)
			dDate2 := Bin2Date(dwDate)
			Assert.Equal(dDate1, dDate2)


		[Fact, Trait("Category", "Date")];
		METHOD TStringTest() as void
		//local r8 as real8
		//r8 := 12.0 * 60.0*60.0 
		//Assert.Equal("12:00:00", Tstring( r8))
		RETURN

		[Fact, Trait("Category", "Date")];
		method SToDTests() as void
			SetEpoch(1910)
			Assert.Equal(2005.01.31 , SToD("00050131"))
			Assert.Equal(1915.01.31 , SToD("00150131"))

		[Fact, Trait("Category", "Date")];
		method InvalidLiteralDateTests() as void
			Assert.Equal(NULL_DATE , 50.50.50)
			Assert.Equal(NULL_DATE , 0000.00.00)
			Assert.Equal(NULL_DATE , 00.00.00)
			Assert.Equal(NULL_DATE , 0.0.0)

		[Fact, Trait("Category", "Date")];
		method SetDateCountryTests() as void
			local dDate as date

			dDate := 2000.01.31
			
			SetCentury(TRUE)

			SetDateCountry(0)
			Assert.Equal("01/31/2000", DToC(dDate))
			SetDateCountry(1) // American
			Assert.Equal("01/31/2000", DToC(dDate))
			SetDateCountry(2) // Ansi
			Assert.Equal("2000.01.31", DToC(dDate))
			SetDateCountry(3) // British & French
			Assert.Equal("31/01/2000", DToC(dDate))
			SetDateCountry(4) // 
			Assert.Equal("31/01/2000", DToC(dDate))
			SetDateCountry(5) // German
			Assert.Equal("31.01.2000", DToC(dDate))
			SetDateCountry(6) // Italian
			Assert.Equal("31-01-2000", DToC(dDate))
			SetDateCountry(7) // Japanese
			Assert.Equal("2000/01/31", DToC(dDate))
			SetDateCountry(8) // USA
			Assert.Equal("01-31-2000", DToC(dDate))
				 
			SetCentury(FALSE)

			SetDateCountry(0)
			Assert.Equal("01/31/00", DToC(dDate))
			SetDateCountry(1) // American
			Assert.Equal("01/31/00", DToC(dDate))
			SetDateCountry(2) // Ansi
			Assert.Equal("00.01.31", DToC(dDate))
			SetDateCountry(3) // British & French
			Assert.Equal("31/01/00", DToC(dDate))
			SetDateCountry(4) // 
			Assert.Equal("31/01/00", DToC(dDate))
			SetDateCountry(5) // German
			Assert.Equal("31.01.00", DToC(dDate))
			SetDateCountry(6) // Italian
			Assert.Equal("31-01-00", DToC(dDate))
			SetDateCountry(7) // Japanese
			Assert.Equal("00/01/31", DToC(dDate))
			SetDateCountry(8) // USA
			Assert.Equal("01-31-00", DToC(dDate))
				 


	END CLASS
END NAMESPACE // XSharp.Runtime.Tests