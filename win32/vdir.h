/* vdir.h
 *
 * (c) 1999 Microsoft Corporation. All rights reserved. 
 * Portions (c) 1999 ActiveState Tool Corp, http://www.ActiveState.com/
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 */

#ifndef ___VDir_H___
#define ___VDir_H___

const int driveCount = 30;

class VDir
{
public:
    VDir(int bManageDir = 1);
    ~VDir() {};

    void Init(VDir* pDir, VMem *pMem);
    void SetDefaultA(char const *pDefault);
    void SetDefaultW(WCHAR const *pDefault);
    char* MapPathA(const char *pInName);
    WCHAR* MapPathW(const WCHAR *pInName);
    int SetCurrentDirectoryA(char *lpBuffer);
    int SetCurrentDirectoryW(WCHAR *lpBuffer);
    inline const char *GetDirA(int index)
    {
	return dirTableA[index];
    };
    inline const WCHAR *GetDirW(int index)
    {
	return dirTableW[index];
    };
    inline int GetDefault(void) { return nDefault; };

    inline char* GetCurrentDirectoryA(int dwBufSize, char *lpBuffer)
    {
	char* ptr = dirTableA[nDefault];
	while (dwBufSize--)
	{
	    if ((*lpBuffer++ = *ptr++) == '\0')
		break;
	}
	return lpBuffer;
    };
    inline WCHAR* GetCurrentDirectoryW(int dwBufSize, WCHAR *lpBuffer)
    {
	WCHAR* ptr = dirTableW[nDefault];
	while (dwBufSize--)
	{
	    if ((*lpBuffer++ = *ptr++) == '\0')
		break;
	}
	return lpBuffer;
    };


    DWORD CalculateEnvironmentSpace(void);
    LPSTR BuildEnvironmentSpace(LPSTR lpStr);

protected:
    int SetDirA(char const *pPath, int index);
    void FromEnvA(char *pEnv, int index);
    inline const char *GetDefaultDirA(void)
    {
	return dirTableA[nDefault];
    };

    inline void SetDefaultDirA(char const *pPath, int index)
    {
	SetDirA(pPath, index);
	nDefault = index;
    };
    int SetDirW(WCHAR const *pPath, int index);
    inline const WCHAR *GetDefaultDirW(void)
    {
	return dirTableW[nDefault];
    };

    inline void SetDefaultDirW(WCHAR const *pPath, int index)
    {
	SetDirW(pPath, index);
	nDefault = index;
    };

    inline int DriveIndex(char chr)
    {
	return (chr | 0x20)-'a';
    };

    VMem *pMem;
    int nDefault, bManageDirectory;
    char *dirTableA[driveCount];
    char szLocalBufferA[MAX_PATH+1];
    WCHAR *dirTableW[driveCount];
    WCHAR szLocalBufferW[MAX_PATH+1];
};


VDir::VDir(int bManageDir /* = 1 */)
{
    nDefault = 0;
    bManageDirectory = bManageDir;
    memset(dirTableA, 0, sizeof(dirTableA));
    memset(dirTableW, 0, sizeof(dirTableW));
}

void VDir::Init(VDir* pDir, VMem *p)
{
    int index;
    DWORD driveBits;
    int nSave;
    char szBuffer[MAX_PATH*driveCount];

    pMem = p;
    if (pDir) {
	for (index = 0; index < driveCount; ++index) {
	    SetDirW(pDir->GetDirW(index), index);
	}
	nDefault = pDir->GetDefault();
    }
    else {
	nSave = bManageDirectory;
	bManageDirectory = 0;
	driveBits = GetLogicalDrives();
	if (GetLogicalDriveStrings(sizeof(szBuffer), szBuffer)) {
	    char* pEnv = GetEnvironmentStrings();
	    char* ptr = szBuffer;
	    for (index = 0; index < driveCount; ++index) {
		if (driveBits & (1<<index)) {
		    ptr += SetDirA(ptr, index) + 1;
		    FromEnvA(pEnv, index);
		}
	    }
	    FreeEnvironmentStrings(pEnv);
	}
	SetDefaultA(".");
	bManageDirectory = nSave;
    }
}

int VDir::SetDirA(char const *pPath, int index)
{
    char chr, *ptr;
    int length = 0;
    WCHAR wBuffer[MAX_PATH+1];
    if (index < driveCount && pPath != NULL) {
	length = strlen(pPath);
	pMem->Free(dirTableA[index]);
	ptr = dirTableA[index] = (char*)pMem->Malloc(length+2);
	if (ptr != NULL) {
	    strcpy(ptr, pPath);
	    ptr += length-1;
	    chr = *ptr++;
	    if (chr != '\\' && chr != '/') {
		*ptr++ = '\\';
		*ptr = '\0';
	    }
	    MultiByteToWideChar(CP_ACP, 0, dirTableA[index], -1,
		    wBuffer, (sizeof(wBuffer)/sizeof(WCHAR)));
	    length = wcslen(wBuffer);
	    pMem->Free(dirTableW[index]);
	    dirTableW[index] = (WCHAR*)pMem->Malloc((length+1)*2);
	    if (dirTableW[index] != NULL) {
		wcscpy(dirTableW[index], wBuffer);
	    }
	}
    }

    if(bManageDirectory)
	::SetCurrentDirectoryA(pPath);

    return length;
}

void VDir::FromEnvA(char *pEnv, int index)
{   /* gets the directory for index from the environment variable. */
    while (*pEnv != '\0') {
	if ((pEnv[0] == '=') && (DriveIndex(pEnv[1]) == index)) {
	    SetDirA(&pEnv[4], index);
	    break;
	}
	else
	    pEnv += strlen(pEnv)+1;
    }
}

void VDir::SetDefaultA(char const *pDefault)
{
    char szBuffer[MAX_PATH+1];
    char *pPtr;

    if (GetFullPathNameA(pDefault, sizeof(szBuffer), szBuffer, &pPtr)) {
        if (*pDefault != '.' && pPtr != NULL)
	    *pPtr = '\0';

	SetDefaultDirA(szBuffer, DriveIndex(szBuffer[0]));
    }
}

int VDir::SetDirW(WCHAR const *pPath, int index)
{
    WCHAR chr, *ptr;
    char szBuffer[MAX_PATH+1];
    int length = 0;
    if (index < driveCount && pPath != NULL) {
	length = wcslen(pPath);
	pMem->Free(dirTableW[index]);
	ptr = dirTableW[index] = (WCHAR*)pMem->Malloc((length+2)*2);
	if (ptr != NULL) {
	    wcscpy(ptr, pPath);
	    ptr += length-1;
	    chr = *ptr++;
	    if (chr != '\\' && chr != '/') {
		*ptr++ = '\\';
		*ptr = '\0';
	    }
	    WideCharToMultiByte(CP_ACP, 0, dirTableW[index], -1, szBuffer, sizeof(szBuffer), NULL, NULL);
	    length = strlen(szBuffer);
	    pMem->Free(dirTableA[index]);
	    dirTableA[index] = (char*)pMem->Malloc(length+1);
	    if (dirTableA[index] != NULL) {
		strcpy(dirTableA[index], szBuffer);
	    }
	}
    }

    if(bManageDirectory)
	::SetCurrentDirectoryW(pPath);

    return length;
}

void VDir::SetDefaultW(WCHAR const *pDefault)
{
    WCHAR szBuffer[MAX_PATH+1];
    WCHAR *pPtr;

    if (GetFullPathNameW(pDefault, (sizeof(szBuffer)/sizeof(WCHAR)), szBuffer, &pPtr)) {
        if (*pDefault != '.' && pPtr != NULL)
	    *pPtr = '\0';

	SetDefaultDirW(szBuffer, DriveIndex((char)szBuffer[0]));
    }
}

inline BOOL IsPathSep(char ch)
{
    return (ch == '\\' || ch == '/');
}

inline void DoGetFullPathNameA(char* lpBuffer, DWORD dwSize, char* Dest)
{
    char *pPtr;

    /*
     * On WinNT GetFullPathName does not fail, (or at least always
     * succeeds when the drive is valid) WinNT does set *Dest to Nullch
     * On Win98 GetFullPathName will set last error if it fails, but
     * does not touch *Dest
     */
    *Dest = '\0';
    GetFullPathNameA(lpBuffer, dwSize, Dest, &pPtr);
}

char *VDir::MapPathA(const char *pInName)
{   /*
     * possiblities -- relative path or absolute path with or without drive letter
     * OR UNC name
     */
    char szBuffer[(MAX_PATH+1)*2];
    char szlBuf[MAX_PATH+1];

    if (strlen(pInName) > MAX_PATH) {
	strncpy(szlBuf, pInName, MAX_PATH);
	if (IsPathSep(pInName[0]) && !IsPathSep(pInName[1])) {   
	    /* absolute path - reduce length by 2 for drive specifier */
	    szlBuf[MAX_PATH-2] = '\0';
	}
	else
	    szlBuf[MAX_PATH] = '\0';
	pInName = szlBuf;
    }
    /* strlen(pInName) is now <= MAX_PATH */

    if (pInName[1] == ':') {
	/* has drive letter */
	if (IsPathSep(pInName[2])) {
	    /* absolute with drive letter */
	    strcpy(szLocalBufferA, pInName);
	}
	else {
	    /* relative path with drive letter */
	    strcpy(szBuffer, GetDirA(DriveIndex(*pInName)));
	    strcat(szBuffer, &pInName[2]);
	    if(strlen(szBuffer) > MAX_PATH)
		szBuffer[MAX_PATH] = '\0';

	    DoGetFullPathNameA(szBuffer, sizeof(szLocalBufferA), szLocalBufferA);
	}
    }
    else {
	/* no drive letter */
	if (IsPathSep(pInName[1]) && IsPathSep(pInName[0])) {
	    /* UNC name */
	    strcpy(szLocalBufferA, pInName);
	}
	else {
	    strcpy(szBuffer, GetDefaultDirA());
	    if (IsPathSep(pInName[0])) {
		/* absolute path */
		szLocalBufferA[0] = szBuffer[0];
		szLocalBufferA[1] = szBuffer[1];
		strcpy(&szLocalBufferA[2], pInName);
	    }
	    else {
		/* relative path */
		strcat(szBuffer, pInName);
		if (strlen(szBuffer) > MAX_PATH)
		    szBuffer[MAX_PATH] = '\0';

		DoGetFullPathNameA(szBuffer, sizeof(szLocalBufferA), szLocalBufferA);
	    }
	}
    }

    return szLocalBufferA;
}

int VDir::SetCurrentDirectoryA(char *lpBuffer)
{
    HANDLE hHandle;
    WIN32_FIND_DATA win32FD;
    char szBuffer[MAX_PATH+1], *pPtr;
    int length, nRet = -1;

    GetFullPathNameA(MapPathA(lpBuffer), sizeof(szBuffer), szBuffer, &pPtr);
    /* if the last char is a '\\' or a '/' then add
     * an '*' before calling FindFirstFile
     */
    length = strlen(szBuffer);
    if(length > 0 && IsPathSep(szBuffer[length-1])) {
	szBuffer[length] = '*';
	szBuffer[length+1] = '\0';
    }

    hHandle = FindFirstFileA(szBuffer, &win32FD);
    if (hHandle != INVALID_HANDLE_VALUE) {
        FindClose(hHandle);

	/* if an '*' was added remove it */
	if(szBuffer[length] == '*')
	    szBuffer[length] = '\0';

	SetDefaultDirA(szBuffer, DriveIndex(szBuffer[0]));
	nRet = 0;
    }
    return nRet;
}

DWORD VDir::CalculateEnvironmentSpace(void)
{   /* the current directory environment strings are stored as '=d=d:\path' */
    int index;
    DWORD dwSize = 0;
    for (index = 0; index < driveCount; ++index) {
	if (dirTableA[index] != NULL) {
	    dwSize += strlen(dirTableA[index]) + 4;  /* add 1 for trailing NULL and 3 for '=d=' */
	}
    }
    return dwSize;
}

LPSTR VDir::BuildEnvironmentSpace(LPSTR lpStr)
{   /* store the current directory environment strings as '=d=d:\path' */
    int index;
    LPSTR lpDirStr;
    for (index = 0; index < driveCount; ++index) {
	lpDirStr = dirTableA[index];
	if (lpDirStr != NULL) {
	    lpStr[0] = '=';
	    lpStr[1] = lpDirStr[0];
	    lpStr[2] = '=';
	    strcpy(&lpStr[3], lpDirStr);
	    lpStr += strlen(lpDirStr) + 4; /* add 1 for trailing NULL and 3 for '=d=' */
	}
    }
    return lpStr;
}

inline BOOL IsPathSep(WCHAR ch)
{
    return (ch == '\\' || ch == '/');
}

inline void DoGetFullPathNameW(WCHAR* lpBuffer, DWORD dwSize, WCHAR* Dest)
{
    WCHAR *pPtr;

    /*
     * On WinNT GetFullPathName does not fail, (or at least always
     * succeeds when the drive is valid) WinNT does set *Dest to Nullch
     * On Win98 GetFullPathName will set last error if it fails, but
     * does not touch *Dest
     */
    *Dest = '\0';
    GetFullPathNameW(lpBuffer, dwSize, Dest, &pPtr);
}

WCHAR* VDir::MapPathW(const WCHAR *pInName)
{   /*
     * possiblities -- relative path or absolute path with or without drive letter
     * OR UNC name
     */
    WCHAR szBuffer[(MAX_PATH+1)*2];
    WCHAR szlBuf[MAX_PATH+1];

    if (wcslen(pInName) > MAX_PATH) {
	wcsncpy(szlBuf, pInName, MAX_PATH);
	if (IsPathSep(pInName[0]) && !IsPathSep(pInName[1])) {   
	    /* absolute path - reduce length by 2 for drive specifier */
	    szlBuf[MAX_PATH-2] = '\0';
	}
	else
	    szlBuf[MAX_PATH] = '\0';
	pInName = szlBuf;
    }
    /* strlen(pInName) is now <= MAX_PATH */

    if (pInName[1] == ':') {
	/* has drive letter */
	if (IsPathSep(pInName[2])) {
	    /* absolute with drive letter */
	    wcscpy(szLocalBufferW, pInName);
	}
	else {
	    /* relative path with drive letter */
	    wcscpy(szBuffer, GetDirW(DriveIndex((char)*pInName)));
	    wcscat(szBuffer, &pInName[2]);
	    if(wcslen(szBuffer) > MAX_PATH)
		szBuffer[MAX_PATH] = '\0';

	    DoGetFullPathNameW(szBuffer, (sizeof(szLocalBufferW)/sizeof(WCHAR)), szLocalBufferW);
	}
    }
    else {
	/* no drive letter */
	if (IsPathSep(pInName[1]) && IsPathSep(pInName[0])) {
	    /* UNC name */
	    wcscpy(szLocalBufferW, pInName);
	}
	else {
	    wcscpy(szBuffer, GetDefaultDirW());
	    if (IsPathSep(pInName[0])) {
		/* absolute path */
		szLocalBufferW[0] = szBuffer[0];
		szLocalBufferW[1] = szBuffer[1];
		wcscpy(&szLocalBufferW[2], pInName);
	    }
	    else {
		/* relative path */
		wcscat(szBuffer, pInName);
		if (wcslen(szBuffer) > MAX_PATH)
		    szBuffer[MAX_PATH] = '\0';

		DoGetFullPathNameW(szBuffer, (sizeof(szLocalBufferW)/sizeof(WCHAR)), szLocalBufferW);
	    }
	}
    }
    return szLocalBufferW;
}

int VDir::SetCurrentDirectoryW(WCHAR *lpBuffer)
{
    HANDLE hHandle;
    WIN32_FIND_DATAW win32FD;
    WCHAR szBuffer[MAX_PATH+1], *pPtr;
    int length, nRet = -1;

    GetFullPathNameW(MapPathW(lpBuffer), (sizeof(szBuffer)/sizeof(WCHAR)), szBuffer, &pPtr);
    /* if the last char is a '\\' or a '/' then add
     * an '*' before calling FindFirstFile
     */
    length = wcslen(szBuffer);
    if(length > 0 && IsPathSep(szBuffer[length-1])) {
	szBuffer[length] = '*';
	szBuffer[length+1] = '\0';
    }

    hHandle = FindFirstFileW(szBuffer, &win32FD);
    if (hHandle != INVALID_HANDLE_VALUE) {
        FindClose(hHandle);

	/* if an '*' was added remove it */
	if(szBuffer[length] == '*')
	    szBuffer[length] = '\0';

	SetDefaultDirW(szBuffer, DriveIndex((char)szBuffer[0]));
	nRet = 0;
    }
    return nRet;
}

#endif	/* ___VDir_H___ */
