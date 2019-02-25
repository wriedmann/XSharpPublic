/*
BRANCH Page
- Branch pages are used to link the tree. Their contents is
BYTE     attr    [ 2 ];    node type 
BYTE     nKeys   [ 2 ];    number of keys 
BYTE     leftPtr [ 4 ];    offset of left node or -1 
BYTE     rightPtr[ 4 ];    offset of right node or -1
// array of key entries
// each key entry is keyLen + 8 bytes long
// BYTE Key data [keyLen]
// BYTE record number[ 4]
// BYTE child page [4]

*/
USING System
USING System.Collections.Generic
USING System.Text
USING System.IO
USING System.Runtime.CompilerServices
USING System.Diagnostics
BEGIN NAMESPACE XSharp.RDD.CDX

    /// <summary>
    /// CdxBranchePage. this class maps the Branch page from the file in memory
    /// Manipulating the page is implemented in the CdxTag class
    /// </summary>
    /*
    - Branch pages are used to link the tree. Their contents is
    BYTE     attr    [ 2 ];    node type 
    BYTE     nKeys   [ 2 ];    number of keys 
    BYTE     leftPtr [ 4 ];    offset of left node or -1 
    BYTE     rightPtr[ 4 ];    offset of right node or -1
    BYTE     freeSpc [ 2 ];    free space available in a page 
    // array of key entries
    // each key entry is keyLen + 8 bytes long
    // BYTE Key data [keyLen]
    // BYTE record number[ 4]
    // BYTE child page [4]
    */
    INTERNAL CLASS CdxBranchePage INHERIT CdxTreePage 
        PROTECTED _keyLen    AS Int32
        PROTECTED _maxKeys   AS Int32
        PROTECTED _right    := NULL AS CdxBranchePage
        PROTECTED _left     := NULL AS CdxBranchePage
        
        INTERNAL CONSTRUCTOR( bag AS CdxOrderBag , nPage AS Int32 , buffer AS BYTE[], nKeyLen AS Int32)
            SUPER(bag, nPage, buffer)
            SELF:_keyLen  := nKeyLen
            SELF:_maxKeys := MaxKeysPerPage(nKeyLen)
            
            //? "Branch Page", SELF:PageNo:ToString("X"), SELF:NumKeys, "Startswith ", GetRecno(0), _bag:_oRDD:_Encoding:GetString(GetKey(0),0,_keyLen)
            
            #region ICdxKeyValue
        PUBLIC METHOD GetKey(nPos AS Int32) AS BYTE[]
            LOCAL nStart AS INT
            Debug.Assert(nPos >= 0 .AND. nPos < SELF:NumKeys)
            nStart := CDXBRANCH_HEADERLEN + nPos * (_keyLen + 8)
            RETURN _GetBytes(SELF:Buffer, nStart, _keyLen)
            
        PUBLIC METHOD GetRecno(nPos AS Int32) AS Int32
            LOCAL nStart AS INT
            Debug.Assert(nPos >= 0 .AND. nPos < SELF:NumKeys)
            nStart := CDXBRANCH_HEADERLEN + nPos * (_keyLen + 8)
            RETURN _GetLongLE(nStart+_keyLen)
            
            #endregion
            
        PUBLIC METHOD SetKey(nPos AS Int32, key AS BYTE[]) AS VOID
            LOCAL nStart AS INT
            Debug.Assert(nPos >= 0 .AND. nPos < SELF:NumKeys)
            nStart := CDXBRANCH_HEADERLEN + nPos * (_keyLen + 8)
            Array.Copy(key, 0, SELF:Buffer, nStart, _keyLen)
            
            
        PUBLIC METHOD SetRecno(nPos AS Int32, nRecord AS Int32) AS VOID
            LOCAL nStart AS INT
            Debug.Assert(nPos >= 0 .AND. nPos < SELF:NumKeys)
            nStart := CDXBRANCH_HEADERLEN + nPos * (_keyLen + 8)
            _SetLongLE(nStart+_keyLen, nRecord)
            
            
        METHOD GetChildPage(nPos AS Int32) AS Int32
            LOCAL nStart AS INT
            Debug.Assert(nPos >= 0 .AND. nPos < SELF:NumKeys)
            nStart := CDXBRANCH_HEADERLEN + nPos * (_keyLen + 8)
            RETURN _GetLongLE(nStart+_keyLen+4)
            
        METHOD SetChildPage(nPos AS Int32, nPage AS Int32) AS VOID
            LOCAL nStart AS INT
            Debug.Assert(nPos >= 0 .AND. nPos < SELF:NumKeys)
            nStart := CDXBRANCH_HEADERLEN + nPos * (_keyLen + 8)
            _SetLongLE(nStart+_keyLen+4, nPage)
            RETURN
            
        INTERNAL STATIC METHOD MaxKeysPerPage(nKeyLen AS INT) AS WORD
            RETURN  (WORD) (CDXBRANCH_BYTESFREE / (nKeyLen + 8))
            
            
            #region Properties
            INTERNAL PROPERTY BuffLen        AS WORD  GET CDXBRANCH_BYTESFREE
            
            PUBLIC PROPERTY NumKeys AS WORD ;
            GET _GetWord(CDXBRANCH_OFFSET_NUMKEYS) ;
            SET _SetWord(CDXBRANCH_OFFSET_NUMKEYS, VALUE), isHot := TRUE
            
            INTERNAL PROPERTY LeftPtr AS Int32 ;
            GET _GetLong(CDXBRANCH_OFFSET_LEFTPTR) ;
            SET _SetLong(CDXBRANCH_OFFSET_LEFTPTR, VALUE), isHot := TRUE
            
            INTERNAL PROPERTY RightPtr AS Int32 ;
            GET _GetLong(CDXBRANCH_OFFSET_RIGHTPTR) ; 
            SET _SetLong(CDXBRANCH_OFFSET_RIGHTPTR, VALUE), isHot := TRUE
            #endregion                
        #region Constants
        PRIVATE CONST CDXBRANCH_OFFSET_NUMKEYS		:= 2	AS WORD 
        PRIVATE CONST CDXBRANCH_OFFSET_LEFTPTR		:= 4	AS WORD 
        PRIVATE CONST CDXBRANCH_OFFSET_RIGHTPTR		:= 8	AS WORD 
        PRIVATE CONST CDXBRANCH_HEADERLEN           := 12	AS WORD
        PRIVATE CONST CDXBRANCH_BYTESFREE           := 500  AS WORD
        #endregion
        INTERNAL PROPERTY Right  AS CdxBranchePage GET _right SET _right := VALUE
        INTERNAL PROPERTY Left   AS CdxBranchePage GET _left  SET _left := VALUE
        INTERNAL PROPERTY LastNode AS CdxPageNode GET SELF[SELF:NumKeys-1]
        
        INTERNAL PROPERTY MaxKeys AS LONG GET _maxKeys
        
        
        INTERNAL METHOD Add(node AS CdxPageNode) AS LOGIC
            LOCAL nPos := SELF:NumKeys AS WORD
            IF nPos >= SELF:MaxKeys
                RETURN FALSE
            ENDIF
            // node contains recno & keydata
            // node:Page has value for ChildPageNo
            SELF:_setNode(nPos, node)
            SELF:NumKeys += 1
            RETURN TRUE
            
        INTERNAL METHOD Insert(nPos AS LONG, node AS CdxPageNode) AS LOGIC
            LOCAL nMax := SELF:NumKeys AS WORD
            IF nPos >= SELF:MaxKeys -1
                RETURN FALSE
            ENDIF
            // node contains recno & keydata
            // node:Page has value for ChildPageNo
            FOR VAR nI := nMax-1 DOWNTO nPos
                SELF:_copyNode(nI, nI+1)
            NEXT
            _setNode(nPos, node)
            SELF:NumKeys += 1
            RETURN TRUE
            
        INTERNAL METHOD Delete(nPos AS LONG) AS LOGIC
            LOCAL nMax := SELF:NumKeys AS WORD
            IF nMax == 0 .OR. nPos < 0 .OR. nPos > nMax-1
                RETURN FALSE
            ENDIF
            // node contains recno & keydata
            // node:Page has value for ChildPageNo
            FOR VAR nI := nPos DOWNTO nMax-1
                SELF:_copyNode(nI+1, nI)
            NEXT
            SELF:NumKeys -= 1
            RETURN TRUE
            
        INTERNAL METHOD Replace(nPos AS LONG, node AS CdxPageNode) AS LOGIC
            IF nPos < 0 .OR. nPos >= SELF:NumKeys
                RETURN FALSE
            ENDIF
            _setNode(nPos, node)
            RETURN TRUE
            
            // Helper methods
        PRIVATE METHOD _copyNode(nSrc AS LONG, nTrg AS LONG) AS VOID
            SELF:SetRecno(nTrg, SELF:GetRecno(nSrc))
            SELF:SetChildPage(nTrg, SELF:GetChildPage(nSrc))
            SELF:SetKey(nTrg, SELF:GetKey(nSrc))
            RETURN 
            
        PRIVATE METHOD _setNode(nPos AS LONG, node AS CdxPageNode) AS VOID
            SELF:SetRecno(nPos, node:Recno)
            SELF:SetChildPage(nPos, node:Page:PageNo)
            SELF:SetKey(nPos, node:KeyBytes)
            RETURN 
            
        INTERNAL METHOD Dump AS STRING
            LOCAL Sb AS stringBuilder
            sb := stringBuilder{}
            VAR item := SELF[0]
            sb:AppendLine("--------------------------")
            sb:AppendLine(String.Format("{0} Page {1:X6}, # of keys: {2}", SELF:PageType, SELF:PageNo, SELF:NumKeys))
            sb:AppendLine(String.Format("Left page reference {0:X6}", SELF:LeftPtr))
            FOR VAR i := 0 TO SELF:NumKeys-1
                item:Pos := i
                sb:AppendLine(String.Format("Item {0,2}, Page {1:X6}, Record {2,5} : {3} ", i, item:ChildPageNo, item:Recno, item:KeyText))
            NEXT
            sb:AppendLine(String.Format("Right page reference {0:X6}", SELF:RightPtr))
            RETURN sb:ToString()
            
            
    END CLASS
END NAMESPACE 
