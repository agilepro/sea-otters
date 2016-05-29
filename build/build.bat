set tempFolder=e:\temp\sobuild\temp
set outputFolder=e:\temp\sobuild\out
set srcFolder=d:\GitHub\sea-otters\trunk\

del /q %outputFolder%\*.* 
xcopy /s /y %srcFolder%\site\*.* %outputFolder%

d:\Perl\bin\perl.exe %srcFolder%\_GatherSwimInfo.pl >out.txt
pause
