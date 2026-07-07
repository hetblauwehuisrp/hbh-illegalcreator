@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo ========================================
echo HBH IllegalCreator Git Update
echo ========================================
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo [FOUT] Git is niet gevonden op deze pc.
    echo Installeer Git of controleer je PATH.
    pause
    exit /b 1
)

if not exist ".git" (
    echo [FOUT] Deze map is geen Git repository.
    echo Zet dit bestand in je hbh-illegalcreator map.
    pause
    exit /b 1
)

for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set BRANCH=%%b
if "%BRANCH%"=="HEAD" (
    echo [FOUT] Je zit niet op een branch.
    echo Run eerst: git checkout main
    pause
    exit /b 1
)

echo Branch: %BRANCH%
echo.

git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo [FOUT] Geen origin remote gevonden.
    echo Voeg eerst je GitHub repo toe:
    echo git remote add origin https://github.com/hetblauwehuisrp/hbh-illegalcreator.git
    pause
    exit /b 1
)

echo Origin controleren...
git fetch origin --prune

echo.
echo Controleren of GitHub nieuwere bestanden heeft...

set BEHIND=0
for /f %%i in ('git rev-list --count HEAD..refs/remotes/origin/%BRANCH% 2^>nul') do set BEHIND=%%i

if not "%BEHIND%"=="0" (
    echo Er staan nieuwe bestanden op GitHub.
    echo Eerst ophalen met rebase...
    git pull --rebase origin refs/heads/%BRANCH%

    if errorlevel 1 (
        echo.
        echo [FOUT] Pull/rebase mislukt.
        echo Waarschijnlijk is er een merge conflict.
        echo Los dit eerst op en run daarna update.cmd opnieuw.
        pause
        exit /b 1
    )
) else (
    echo GitHub is up-to-date.
)

echo.
echo Lokale wijzigingen controleren...

git status --porcelain > "%temp%\hbh_git_status.txt"
for %%A in ("%temp%\hbh_git_status.txt") do set SIZE=%%~zA

if "%SIZE%"=="0" (
    echo Geen lokale wijzigingen om te pushen.
    del "%temp%\hbh_git_status.txt" >nul 2>&1
    pause
    exit /b 0
)

del "%temp%\hbh_git_status.txt" >nul 2>&1

echo.
echo Wijzigingen gevonden:
git status --short
echo.

set /p COMMIT_MSG=Commit bericht invoeren, of druk Enter voor automatisch bericht: 

if "%COMMIT_MSG%"=="" (
    set COMMIT_MSG=Auto update hbh-illegalcreator %date% %time%
)

echo.
echo Bestanden toevoegen...
git add -A

echo.
echo Commit maken...
git commit -m "%COMMIT_MSG%"

if errorlevel 1 (
    echo.
    echo [FOUT] Commit mislukt.
    pause
    exit /b 1
)

echo.
echo Pushen naar GitHub...
git push origin HEAD:refs/heads/%BRANCH%

if errorlevel 1 (
    echo.
    echo [FOUT] Push mislukt.
    echo Controleer of je GitHub permissies goed staan.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Klaar. Alles is gepushed naar GitHub.
echo ========================================
pause
