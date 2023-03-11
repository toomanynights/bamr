@echo off
setlocal enabledelayedexpansion

Echo --------------------------------------
Echo ---- BASIL'S AMAZING MOD REPACKER ----
Echo --------------------------------------
Echo.
Echo.


:CHECKDIR
	IF NOT EXIST pack.py (goto WRONGDIR)
	IF NOT EXIST unpack.py (goto WRONGDIR)
	
	goto SETPATHS

:WRONGDIR
	echo Wrong directory^^! Put this script in your unpacker folder.
	goto END


:SETPATHS

set pathVars[1].Name=GamePath
set pathVars[1].Desc=path to game folder
set pathVars[2].Name=PythonPath
set pathVars[2].Desc=path to where Python is installed
set pathVars[3].Name=CmdPath
set pathVars[3].Desc=path to where your SteamCMD is located

	for /l %%i in (1 1 100) do (
		if not defined pathVars[%%i].Name (
		set /a pathVarsQ=%%i-1
			echo Path array size is !pathVarsQ!
			goto CHECKCONFIG
		) 
	)
	

:CHECKCONFIG
	IF EXIST config (
		echo Validating existing config...
		goto VALIDATECONFIG
	) ELSE (echo Config doesn't exist. Proceed with creating one...)


:CREATECONFIG
	FOR /L %%i IN (1 1 !pathVarsQ!) DO  (
		call :PROCESSITEM "pathVar" "%%pathVars[%%i].Name%%" "%%pathVars[%%i].Desc%%" %%i
	)
	set ModsPath=%pathVars[1].Link%Mods\
	echo ModsPath=!ModsPath!>>config
	
	call :PROCESSITEM "donorMod"
	call :ADDMODPREP
	goto CONFIGOK


:VALIDATECONFIG
	for /l %%i in (1 1 %pathVarsQ%) do (
		call set name=%%pathVars[%%i].Name%%
		findstr /I "!name!" config
		if errorlevel 1 (
			echo !name! was not found in config. A new one has to be created.
			del config
			goto CREATECONFIG
		)
	)
	
	findstr /I "DonorID" config
		if errorlevel 1 (set noDonor=1)
	findstr /I "DonorPath" config
		if errorlevel 1 (set noDonor=1)	
		
	if !noDonor! equ 1 (
		echo Donor mod information was not found in config. A new one has to be created.
		del config
		set noDonor=
		goto CREATECONFIG
	)

	echo Config looks valid. Proceeding...
	for /f "delims=" %%x in (config) do (set "%%x")
	goto ADDMODPREP

	
:ADDMODPREP

	echo Analyzing mod list...

	for /l %%i in (1 1 100) do (
		if not defined modsQ if not defined mods[%%i].Name (
			set modNum=%%i
			set /a modsQ=!modNum!-1
			if !modsQ! gtr 0 (echo Amount of mods added: !modsQ!) else (echo You need to add at least one mod)
		))

	if !modsQ! equ 0 (goto addmod) else (goto configok)
	
	
:ADDMOD
set modToAddPath=
set modID=
set modName=
	
	set /p modID=Specify your mod's ID: 
	for /l %%a in (1,1,31) do if "!modID:~-1!"==" " set modID=!modID:~0,-1!
	if not defined modID (
		echo You have to provide input.
		goto addmod
	)
	
	set modToAddPath=%ModsPath%!modID!\
	echo Path to mod is !modToAddPath!
	if not exist !modToAddPath! (
		echo Mod's path does not exist.	
		goto addmod
	)
	
:ADDMOD2
	echo Specify path to where you store code for this mod.
	echo Make sure your scripts use correct Python Unpacker format
	echo (no extensions, unchanged names), or they won't be packed into mod archive.
	set /p modCodePath=	
	if not defined modCodePath (
		echo You have to provide input.
		goto addmod2
	)
	
	if not "!modCodePath:~-1!"=="\" set "modCodePath=!modCodePath!\"
	if not exist !modCodePath! (
		echo Path to mod code does not exist.	
		goto addmod2
	)
	
	set /p modName=Specify your mod's human readable name (empty input = ID will be used instead): 
	if not defined modName (set modName=!modID!)
	
	echo mods[!modNum!].Name=!modName!>>config
	echo mods[!modNum!].ID=!modID!>>config
	echo mods[!modNum!].Link=!modToAddPath!>>config
	echo mods[!modNum!].CodePath=!modCodePath!>>config
	
	set /a modNum=modNum+1
	set /a modsQ=modsQ+1
	
	%SystemRoot%\System32\choice.exe /C YN /N /M "Mod added. Would you like to add another one? [Y/N]"
	if not errorlevel 2 if errorlevel 1 goto addmod
	goto configok
	
	
	
	

:CONFIGOK
	for /f "delims=" %%x in (config) do (set "%%x")
	echo Variables from config applied successfully
	goto modscreen
	

:MODSCREEN
	echo.
	echo Choose number of mod to repack and hit Enter:
	echo.
	
	echo [0] Add new mod
	for /l %%x in (1,1,%modsQ%) do (
		call echo [%%x] %%mods[%%x].Name%%
	)
	echo.
	
	set /p choice=
	echo.
	
	if !choice! equ 0 goto addmod
	
	for /l %%i in (1 1 %modsQ%) do (
		if !choice! equ %%i (set choiceCorrect=1)
	)
	if not defined choiceCorrect (
		echo Invalid choice. Please choose one of the numbers from the list, no brackets.
		goto modscreen
	)
	
	call set modName=%%mods[!choice!].Name%%
	call set modID=%%mods[!choice!].ID%%
	call set modPath=%%mods[!choice!].Link%%
	call set modCodePath=%%mods[!choice!].CodePath%%
	
	call echo You chose %%mods[!choice!].Name%%
	call echo Mod ID is !modID!
	
	
:PHASE1
set dataPath=.\data\
set outPath=.\out\
	
	rmdir /s /q "!dataPath!"
	mkdir "!dataPath!"
	rmdir /s /q "!outPath!"
	mkdir "!outPath!"
	
	echo Folders "data" and "out" have been deleted and recreated
	
	copy "%ModsPath%%modID%_common.dat" "%dataPath%"
	copy "%ModsPath%%modID%_common.idx" "%dataPath%"
	
	%PythonPath%python.exe ".\unpack.py" %*
	robocopy "%modCodePath% " "!outPath!%modid%_common " "????????" /IS /XF "?.??????" "??.?????" "???.????" "????.???" "?????.??" "??????.?"
	%PythonPath%python.exe ".\pack.py" %*
		
	copy ".\out\%modid%_common.dat" "%ModsPath%"
	copy ".\out\%modid%_common.idx" "%ModsPath%"
	
	%SystemRoot%\System32\choice.exe /C YN /N /M "Repacking complete. Would you like to proceed to publication prepping? [Y/N]"
	if not errorlevel 2 if errorlevel 1 goto PHASE2
	goto :END


:PHASE2
	echo Prepping publication...
	echo.
	echo Does your mod change any vanilla localization strings^? If yes, it is advised to repack localizations via donor.
	%SystemRoot%\System32\choice.exe /C YN /N /M "Repack localizations? [Y/N]"
	if not errorlevel 2 if errorlevel 1 goto PHASE2.5
	goto :PHASE3
	

:PHASE2.5
set locdirname="%donorPath%localizations\"

	del /s /q /f "%donorPath%localizations\*.lang"
	robocopy "%modPath%\localizations\ " "%donorPath%localizations\ " *_*

	echo Renaming files in localizations folder...
	for /f "tokens=1,2 delims=_" %%G in ('dir /b !locdirname!') do (
		if exist !locdirname!%%G_%%H (
			echo %%G_%%H -^> %%G.lang
			rename !locdirname!%%G_%%H %%G.lang
		) else (
			echo Skipping file %%G
		)
	)

	echo.
	%SystemRoot%\System32\choice.exe /C YN /N /M "It's ready. Now go ahead and pack localizations donor via Storyteller so we can proceed. Ready [Y/N]?"
	if not errorlevel 2 if errorlevel 1 goto PHASE2.6
	goto PHASE2.5
	
	
:PHASE2.6
set locFilesList=_localizations.dat _localizations.idx _localizations.str
set position=1

	for %%3 in (!locFilesList!) do (
		set fileName="%ModsPath%%modID%%%3"
		set fileToRename="%ModsPath%%DonorID%%%3"
		if exist !fileName! (
			del !fileName!
		)
		if exist !fileToRename! (
			rename !fileToRename! %modID%%%3
		)
	)


:PHASE3
set modOutPath=%CmdPath%TWOM\ModsToPublish\%modID%\
set failedCount=0
set failedList=
set itemNum=0
set filesList=
set filesCleanList=
set filesCleanArray=
set pos=0
set item=
set cleanName=

	echo Copying files...
	
	if exist "!modOutPath!" rmdir /S /Q "!modOutPath!"
	mkdir "!modOutPath!"

	set filesList=%modID%_common.dat %modid%_common.dat_items.dat %modid%_common.idx %modid%_common.str %modid%_textures.dat %modid%_textures.idx %modid%_textures.str %modid%_sounds.dat %modid%_sounds.idx %modid%_sounds.str %modid%_localizations.dat %modid%_localizations.idx %modid%_localizations.str
	set filesCleanList=common.dat common.dat_items.dat common.idx common.str textures.dat textures.idx textures.str sounds.dat sounds.idx sounds.str localizations.dat localizations.idx localizations.str

	for %%l in (!filesCleanList!) do (
		set filesCleanArray[!pos!]=%%l
		set /a pos=pos+1
	)
	
	for %%0 in (%filesList%) do (
		set item=%%0
		call set cleanName=%%filesCleanArray[!itemNum!]%%		
		
		if exist "%ModsPath%!item!" (
			copy "%ModsPath%!item!" "!modOutPath!"
			echo Copied: !item! 
			rename !modOutPath!!item! !cleanName!
			echo Renamed: %%0 -^> !cleanName!
		) else (
			set failedList[!failedCount!]=!item!
			set /a failedCount=failedCount+1
		)
		set /a itemNum=itemNum+1
	)
	
	if !failedCount! gtr 0 (
		echo. & echo Attention^^! The following !failedCount! archives were ^not found^: & echo.
		set /a failedCount=failedCount-1
		for /l %%x in (0,1,!failedCount!) do (
			call echo %%failedList[%%x]%%
		)
		echo. & echo Sometimes it may be normal - for example, if your mod doesn't introduce
		echo any new sounds and therefore has no sounds archives.
		echo If that's not the case, close the program and fix the problem, otherwise you may proceed. & echo.
		pause
	)
	
:PHASE4
set vdfPath=%CmdPath%TWOM\ModsToPublish\

	if exist "%vdfPath%%modID%.vdf" (
		echo. & echo VDF file for this mod exists. It has been opened for you.
		echo Make sure it is made in accordance to the guide and you don't need to update it in any way.
		explorer.exe "%vdfPath%%modID%.vdf"
		pause
		
	) else (
		echo. >> "%vdfPath%%modID%.vdf"
		echo. & echo VDF file for this mod has been created. It has been opened for you.
		echo Make sure it is made in accordance to the guide.
		explorer.exe "%vdfPath%%modID%.vdf"
		pause
	)
	
	explorer.exe "%CmdPath%"
	echo. & echo Your upload command is: "workshop_build_item ./TWOM/ModsToPublish/%modID%.vdf". Good luck :)
	pause
	
	
	
:END
	echo My work here is done
	pause
	goto :eof
	

:PROCESSITEM
set type=%~1
set link=


	if %type% equ pathVar (
	
	set name=%~2
	set desc=%~3
	set num=%~4
	
		call set /p link=Provide !desc!: 
		if not defined link (
			echo You have to provide input.
			call :PROCESSITEM "!type!" "!name!" "!desc!" !num!
		) else (
			for /l %%a in (1,1,31) do if "!link:~-1!"==" " set link=!link:~0,-1!
			if not "!link:~-1!"=="\" set "link=!link!\"
			
			if exist !link! (
				if not defined pathVars[!num!].Link (
					set pathVars[!num!].Link=!link!
					echo !name!=!link!>>config
			)) else (
				echo Path does not exist.
				call :PROCESSITEM "!type!" "!name!" "!desc!" !num!
			)
		)

	set "name=" & set "desc=" & set "num="
	)
	
	if %type% equ donorMod (
	
		call set /p did=Provide your Localization Donor mod's ID: 
		
		if not defined did (
			echo You have to provide input.
			call :PROCESSITEM "!type!"
		) else (	
			for /l %%a in (1,1,31) do if "!did:~-1!"==" " set did=!did:~0,-1!
			set donorPath=%ModsPath%!did!\
			echo Donor mod's path is !donorPath!
			if not exist !donorPath! (
				echo Donor mod's path does not exist.
				call :PROCESSITEM "!type!"
			) else (
				findstr /I "DonorID" config
				if errorlevel 1 (
					echo DonorID=!did!>>config
					echo DonorPath=!donorPath!>>config
					echo.>>config
				)
			)
		)
	)
	
	
	
	


	
