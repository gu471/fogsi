setLocal EnableDelayedExpansion

set variable1=%ComputerName%
set variable3=FogImage

if not "x!variable1:%variable3%=!"=="x%variable1%" (goto end)

endlocal

if exist "C:\cmds\opsiinstalled" (goto remove)

if not exist "C:\opsi-client-agent\silent_setup.cmd" (goto end)

mkdir "C:\cmds\opsiinstalled"
cd "C:\opsi-client-agent"
silent_setup.cmd

:remove
rmdir /Q /S "C:\opsi-client-agent"
rmdir /Q /S "C:\cmds\opsiinstalled"
goto end

:end
pause
