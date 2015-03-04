:start
echo off
echo Choose the appropriate sysprep stage:
echo.
echo 1) For Deployment (Limit three, final step before upload, take a backup first)
echo 2) Create Build Process Restore Point (Can be done an infinite number of times)
echo 2) change to auditmode (does not work on some machines)
echo.
set /p type=
if %type% == 1 goto 1
if %type% == 2 goto 2
if %type% == 3 goto 3
goto 4
:1
c:\windows\system32\sysprep\sysprep.exe /quiet /generalize /oobe /shutdown /unattend:c:\cmds\sysprep\unatt.xml
goto 5
:2
c:\windows\system32\sysprep\sysprep.exe /quiet /generalize /oobe /shutdown /unattend:c:\cmds\sysprep\unatt_skip.xml
goto 5
:3
c:\windows\system32\sysprep\sysprep.exe /audit /reboot /unattend:c:\windows\system32\sysprep\unattskip.xml
goto 5
:4
echo   That didn't look like a 1 or a 2, please try again and make a VALID choice.
pause
echo.
echo.
goto start
:5
echo All done
exit
