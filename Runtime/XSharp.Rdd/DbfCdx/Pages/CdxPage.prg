// CdxBlock.prg
// Created by    : fabri
// Creation Date : 10/25/2018 10:43:18 PM
// Created for   : 
// WorkStation   : FABPORTABLE

USING System
USING System.Collections.Generic
USING System.Text
USING System.IO
USING System.Runtime.CompilerServices
USING System.Reflection
USING System.Reflection.Emit
USING System.Runtime.InteropServices

BEGIN NAMESPACE XSharp.RDD.CDX

	/// <summary>
	/// The CdxPageBase class.
	/// </summary>
	INTERNAL ABSTRACT CLASS CdxPage
	    PROTECTED _bag      AS CDXOrderBag
        PROTECTED _tag      AS CDXTag
        PROTECTED _nPage    AS Int32
		PROTECTED _buffer   AS BYTE[]
		PROTECTED _hot      AS LOGIC        // Hot ?  => Page has changed ?
        PROTECTED _dumped   as LOGIC
        INTERNAL PROPERTY Dumped as LOGIC GET _dumped SET _dumped := Value
        INTERNAL PROPERTY IsHot  AS LOGIC get _hot SET _hot := Value
        INTERNAL PROPERTY Tag    AS CDXTag Get _tag SET _tag := Value
        INTERNAL PROPERTY KeyLength as LONG GET IIF(_tag == NULL, 0, _tag:KeyLength)
        PROPERTY Buffer AS BYTE[] GET _buffer
        PROPERTY PageNo AS Int32 GET _nPage

	    PROTECTED INTERNAL CONSTRUCTOR( bag AS CdxOrderBag , nPage AS Int32 , buffer AS BYTE[])
			//
			SELF:_bag    := bag
            SELF:_nPage  := nPage
			SELF:_buffer := buffer
			SELF:isHot  := FALSE
		RETURN
        #region Read/Write
			
		PROTECTED INTERNAL VIRTUAL METHOD Write() AS LOGIC
			RETURN _Bag:Write(SELF)

    	PROTECTED INTERNAL VIRTUAL METHOD Read() AS LOGIC
			RETURN _Bag:Read(SELF)

        #endregion
        #region Helper Methods to read/write numbers are strings out of the buffer
        
			[MethodImpl(MethodImplOptions.AggressiveInlining)];        
			PROTECTED INTERNAL METHOD _GetByte(nOffSet AS INT) AS BYTE
				RETURN Buffer[ nOffset]

            [MethodImpl(MethodImplOptions.AggressiveInlining)];        
			PROTECTED INTERNAL METHOD _SetByte(nOffSet AS INT, bValue AS BYTE) AS VOID
				Buffer[ nOffset] := bValue
                isHot := TRUE

            [MethodImpl(MethodImplOptions.AggressiveInlining)];        
			PROTECTED INTERNAL METHOD _GetWord(nOffSet AS INT) AS WORD
				RETURN BitConverter.ToUInt16(Buffer, nOffset)
				
			[MethodImpl(MethodImplOptions.AggressiveInlining)];        
			PROTECTED INTERNAL METHOD _SetWord(nOffSet AS INT, wValue AS WORD) AS VOID
				Array.Copy(BitConverter.GetBytes(wValue),0, Buffer, nOffSet, SIZEOF(WORD))
				isHot := TRUE
				
			[MethodImpl(MethodImplOptions.AggressiveInlining)];        
			PROTECTED INTERNAL METHOD _GetDWord(nOffSet AS INT) AS DWORD
				RETURN BitConverter.ToUInt32(Buffer, nOffset)
				
			[MethodImpl(MethodImplOptions.AggressiveInlining)];        
			PROTECTED INTERNAL METHOD _SetDWord(nOffSet AS INT, dwValue AS DWORD) AS VOID
				Array.Copy(BitConverter.GetBytes(dwValue),0, Buffer, nOffSet, SIZEOF(DWORD))
				isHot := TRUE
                
			[MethodImpl(MethodImplOptions.AggressiveInlining)];        
			PROTECTED INTERNAL METHOD _GetLong(nOffSet AS INT) AS Int32
				RETURN BitConverter.ToInt32(Buffer, nOffset)
				
			[MethodImpl(MethodImplOptions.AggressiveInlining)];        
			PROTECTED INTERNAL METHOD _SetLong(nOffSet AS INT, liValue AS Int32) AS VOID
				Array.Copy(BitConverter.GetBytes(liValue),0, Buffer, nOffSet, SIZEOF(Int32))
				isHot := TRUE


			[MethodImpl(MethodImplOptions.AggressiveInlining)];        
			PROTECTED INTERNAL STATIC METHOD _GetString(buffer AS BYTE[], nOffSet AS INT, count AS INT) AS STRING
				LOCAL str := System.Text.Encoding.ASCII:GetString( buffer,nOffSet, count ) AS STRING
				IF ( str == NULL )
					str := String.Empty
				ENDIF
				RETURN str

			[MethodImpl(MethodImplOptions.AggressiveInlining)];        
            PROTECTED INTERNAL STATIC METHOD _GetBytes(buffer AS BYTE[], nOffSet AS INT, count AS INT) AS BYTE[]
                LOCAL result AS BYTE[]
                result := BYTE[]{count}
			    MemCopy(buffer, nOffSet, result, 0, count)
                RETURN result


			[MethodImpl(MethodImplOptions.AggressiveInlining)];        
			PROTECTED INTERNAL STATIC METHOD _SetString(buffer AS BYTE[], nOffSet AS INT, nSize AS INT, sValue AS STRING) AS VOID
				// Be sure to fill the Buffer with 0
				MemSet( Buffer, nOffSet, nSize , 0)
				System.Text.Encoding.ASCII:GetBytes( sValue, 0, Math.Min(nSize,sValue:Length), Buffer, nOffSet)
				
            #endregion

        #region MemSet and MemCopy
        PRIVATE INITONLY STATIC _memSetter AS  Action<IntPtr, BYTE, INT>		
        PRIVATE INITONLY STATIC _memCopier AS  Action<IntPtr, IntPtr, INT>
        
        STATIC CONSTRUCTOR()
            VAR atts := MethodAttributes.Public | MethodAttributes.Static
            VAR dm := DynamicMethod{"Memset", atts, CallingConventions.Standard, NULL,  <System.Type> { TYPEOF(IntPtr), TYPEOF(BYTE), TYPEOF(INT) }, TYPEOF(CdxPage), TRUE}
            VAR generator	  := dm:GetILGenerator()
            generator:Emit(OpCodes.Ldarg_0)
            generator:Emit(OpCodes.Ldarg_1)
            generator:Emit(OpCodes.Ldarg_2)
            generator:Emit(OpCodes.Initblk)
            generator:Emit(OpCodes.Ret)
            _memSetter := (Action<IntPtr, BYTE, INT>) dm:CreateDelegate(TYPEOF(Action<IntPtr, BYTE, INT>))
            dm := DynamicMethod{"Memcopy", atts, CallingConventions.Standard, NULL,  <System.Type> { TYPEOF(IntPtr), TYPEOF(IntPtr), TYPEOF(INT) }, TYPEOF(CdxPage), TRUE}
        
            generator := dm:GetILGenerator()
            generator:Emit(OpCodes.Ldarg_0)
            generator:Emit(OpCodes.Ldarg_1)
            generator:Emit(OpCodes.Ldarg_2)
            generator:Emit(OpCodes.Cpblk)
            generator:Emit(OpCodes.Ret)
            _memCopier := (Action<IntPtr, IntPtr, INT>) dm:CreateDelegate(TYPEOF(Action<IntPtr, IntPtr, INT>))

        STATIC METHOD MemSet(bytes AS BYTE[], start AS INT, length AS INT, VALUE AS BYTE) AS VOID
            LOCAL h AS GcHandle
            LOCAL p AS IntPtr
            p := IntPtr.Zero
            
            TRY
                h := GCHandle.Alloc(bytes, GCHandleType.Pinned)
                p := h:AddrOfPinnedObject() + start
                _memSetter(p, VALUE, length)
            FINALLY
                IF h:IsAllocated
                    h:Free()
                ENDIF
            END TRY

        STATIC METHOD MemCopy(source AS BYTE[], target AS BYTE[], length AS INT) AS VOID
            MemCopy(source, 0, target, 0, length)

        STATIC METHOD MemCopy(source AS BYTE[], sourceoffset AS INT, target AS BYTE[], targetoffset AS INT, length AS INT) AS VOID
            LOCAL hSrc AS GcHandle
            LOCAL pSrc AS IntPtr
            LOCAL hTrg AS GcHandle
            LOCAL pTrg AS IntPtr
            pSrc := pTrg := IntPtr.Zero
            TRY
                hSrc := GCHandle.Alloc(source, GCHandleType.Pinned)
                pSrc := hSrc:AddrOfPinnedObject() + sourceoffset
                hTrg := GCHandle.Alloc(target, GCHandleType.Pinned)
                pTrg := hTrg:AddrOfPinnedObject() + targetoffset
                _memCopier(pTrg, pSrc, length)
            FINALLY
                IF hSrc:IsAllocated
                    hSrc:Free()
                ENDIF
                IF hTrg:IsAllocated
                    hTrg:Free()
                ENDIF
            END TRY
        #endregion

		INTERNAL CONST CDXPAGE_SIZE        := 512 AS WORD

        METHOD Dump AS STRING
            RETURN String.Empty

       
	END CLASS
END NAMESPACE 