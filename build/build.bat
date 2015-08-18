set tempFolder=e:\temp\sobuild\temp
set outputFolder=e:\temp\sobuild\out
set srcFolder=d:\svn\mendo\SeaOtters\

del /q %outputFolder%\*.* 
copy %srcFolder%\site\*.* %outputFolder%

d:\Perl\bin\perl.exe %srcFolder%\_GatherSwimInfo.pl
pause
