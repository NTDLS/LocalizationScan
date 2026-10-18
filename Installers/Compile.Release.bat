@echo off
@set path=C:\Program Files (x86)\Inno Setup 6\;%path%

cd /d "%~dp0"
md publish
dotnet publish ..\LocalizationScan.csproj -c Release -o publish\LocalizationScan --runtime win-x64 --self-contained false
del publish\LocalizationScan\*.pdb /q

iscc Installer.iss
rd publish\LocalizationScan /s /q
pause
