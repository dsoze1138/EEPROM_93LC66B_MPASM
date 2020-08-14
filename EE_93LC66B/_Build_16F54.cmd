@set PIC_TARGET=16F54
@set MPASM_PATH=C:\PIC_dev\MPLAB8\MPASM Suite
@pushd %MPASM_PATH%
@if NOT ""=="%1" MPASMWIN.exe /x- /q /p%PIC_TARGET% %~dp0%~n1.asm
@if     ""=="%1" FOR /F %%I IN ('dir /b %~dp0*.asm') DO MPASMWIN.exe /x- /q /p%PIC_TARGET% %~dp0%%~nI.asm
@if ERRORLEVEL 1 goto Errors
@goto Done
:Errors
@echo Errors
@pause
:Done
@popd
@set PIC_TARGET=
@set MPASM_PATH=
