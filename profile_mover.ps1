# 
# Profile-Mover
# Skript zum aufräumen von temporären Dateien und Migration in die Domäne
# Robo-Copy-Teil ursprünglicher von: NIKLAS JUMLIN
# 02.08.2018
# Robert Weißenberg
# v0.65
# 
# TODO:
# - translate output into German
# - translate comments into English
# - optimize script and runtime

# Bildschirm leeren
cls

# Prüfung ob das Skript als Administrator gestartet wurde
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
# Ausgabe Fehlermeldung, wenn das Skript nicht als Administrator läuft
{
    Write-Warning "Du hast keine Administratorrechte um dieses Skript auszuführen`nBitte führe das Skript als Administrator nochmals aus!"
    Break
}

# Abfrage nach Pfad des Profils
#$global:Dir = "[STANDARD-USER]"

# Abfrage nach eigenem Pfad - "[STANDARD-USER]"
cls
Write-Host "Soll der Profilordner '[STANDARD-USER]' verwendet werden?" -ForegroundColor Green
$Readhost = Read-Host " (J/n) "
Switch ($ReadHost) 
{ 
    J {$global:Dir = "[STANDARD-USER]"}
    N {Write-Host "Na gut..."; $CustomProfilePath=$true}
    Default {$global:Dir = "[STANDARD-USER]"} 
} 
# Eingabe eines eigenen Pfades
If ($CustomProfilePath -eq $true)
{
    $global:Dir = Read-Host -Prompt "Bitte geben Sie den Ordnernamen des Profils ein!"
    Write-host "Ist der Pfad C:\Users\$Dir korrekt? (Standard ist Nein)" -ForegroundColor Yellow
    $Readhost = Read-Host " (j/n) "
    Switch ($ReadHost) 
    { 
        J {Write-Host "Vielen Dank..."} 
        N {Write-Host "Skript wird abgebrochen."; Exit 0} 
        Default {Write-Host "Sie haben keine Antwort eingegeben - Skript wird abgebrochen"; Exit 1} 
    }
    $ProfilOrdnerVorhanden = Test-Path C:\Users\$global:Dir\
    If ($ProfilOrdnerVorhanden -eq $True)
    {
        Write-Host "Skript wird gestartet..."
    }
    else
    {
        Write-Host "Der angegebene Pfad C:\Users\$global:Dir\ wurde nicht gefunden. Abbruch!"
        Break
    }
}
else
{
    $ProfilOrdnerVorhanden = Test-Path C:\Users\$global:Dir\
    If ($ProfilOrdnerVorhanden -eq $True)
    {
        Write-Host "Skript wird gestartet..."
    }
    else
    {
        Write-Host "Der angegebene Pfad C:\Users\$global:Dir\ wurde nicht gefunden. Abbruch!"
        Break
    }
}


##############################
#                            #
# Benutzer-Profil bereinigen #
#                            #
##############################

# Temporäre Dateien im Benutzer-Profil entfernen
Write-Host "Temporäre Windows-Dateien werden entfernt"
# Get-ChildItem -Path C:\Users\$global:Dir\AppData\LocalLow\Temp\ -Include *.* -File -Recurse | foreach { $_.Delete()}
# Get-ChildItem -Path C:\Users\$global:Dir\AppData\LocalLow\Temp\ -Include * -File -Recurse | foreach { $_.Delete()}
cls
Write-Host "Temporäre Windows-Dateien werden entfernt -   0%"
Set-Location "C:\Windows\Temp"
Remove-Item * -recurse -force
cls
Write-Host "Temporäre Windows-Dateien werden entfernt -  25%"
Set-Location "C:\Windows\Prefetch"
Remove-Item * -recurse -force
cls
Write-Host "Temporäre Windows-Dateien werden entfernt -  50%"
Set-Location "C:\Users"
Remove-Item ".\*\Local Settings\temp\*" -recurse -force
cls
Write-Host "Temporäre Windows-Dateien werden entfernt -  75%"
Set-Location "C:\Users"
Remove-Item ".\*\Appdata\Local\Temp\*" -recurse -force
cls
Write-Host "Temporäre Windows-Dateien werden entfernt - 100%"

# Thunderbird Suchdatenbank entfernen
cls
Write-Host "Thunderbird Suchdatenbank wird entfernt -   0%"
Set-Location "C:\Users"
Remove-Item ".\*\Appdata\Roaming\Thunderbird\Profiles\*.default\global-messages-db.sqlite" -recurse -force
cls
Write-Host "Thunderbird Mail-Cache wird entfernt -   50%"
Set-Location "C:\Users"
Remove-Item ".\*\Appdata\Roaming\Thunderbird\Profiles\*.default\ImapMail\*" -recurse -force
cls
Write-Host "Thunderbird Suchdatenbank wird entfernt - 100%"

# Aktuell angemeldete User auslesen und in der Variable "CurrentUser" speichern
$global:CurrentUser = (Get-WmiObject -Class Win32_ComputerSystem | select username).username.Split('\')[1]
#Write-Host ---------------VARIABLEN---------------
#Write-Host $global:Dir
#Write-Host $global:CurrentUser

############################
#                          #
# Benutzer-Profil kopieren #
#                          #
############################

cls
Write-Host "Benutzerprofil wird kopiert -   0% - Spark"

############################
#                          #
# Spark-Profil kopieren    #
#                          #
############################

# Name des Jobs.
$JOB = "migration-$($global:CurrentUser)"
#Write-Host $JOB
# Quelle. Dateien werden von hier zum Ziel gespiegelt.
$SOURCE = "C:\Users\$global:Dir\AppData\Roaming\Spark\"
#Write-Host $SOURCE
# Zielverzeichnis. Dateien werden hierher gespiegelt oder entsprechend von hier entfernt.
$DESTINATION = "C:\Users\$global:CurrentUser\AppData\Roaming\Spark\"
#Write-Host $DESTINATION
# Email-Einstellungen
$SMTPServer = "YOUR SMTP"
$Mailto = "YOUR MAIL"

# Pfad zur Logdatei
$LOGFILE = "C:\$JOB.log"

# Maximal 5 Sekunden versuchen (/W:5), maximal einen weiteren Versuch (/R:1), FAT-Zeitstempel verwenden (/FFT) --> Verbessert Kompatibilität Win<->Linux
$WHAT = @("/E", "/B", "/W:3","/R:1","/FFT")

# Fortsetzen des Kopiervorgangs ermöglichen
$OPTIONS = @("/Z")

# Datum erstellen (YYYY-MM-DD)
$TIMESTAMP = get-date -uformat "%Y-%m%-%d"

# Uhrzeit erstellen (HH:MM:SS)
$TIME = get-date -uformat "%T"

# Ausgaben ans Log anhängen, alternativ ohne '+' zum Neu-Erstellen der Log-Datei
$ROBOCOPYLOG = "/LOG+:$LOGFILE"

# Sammlung aller oben angeführter Parameter für Robocopy
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$ROBOCOPYLOG,$OPTIONS)
#Write-Host $cmdArgs

# Robocopy mit den oben angegebenen Parametern starten
& C:\Windows\System32\Robocopy.exe @cmdArgs
Write-Host "Profil wird von $($global:Dir) nach $($global:CurrentUser) kopiert."

# System-Variable "LastExitCode" in Variable schreiben
$ExitCode = $LastExitCode

$MSGType=@{
"16"="Fehler"
"9"="Fehler"
"8"="Information"
"4"="Information"
"3"="Information"
"2"="Information"
"1"="Information"
"0"="Information"
}

# Beschreibungen verschiedener ExitCodes
$MSG=@{
"16"="Schwerwiegender Fehler. Robocopy hat keine Dateien kopiert."
"9"="Neue Dateien ins Zielverzeichnis kopiert. Einige Dateien oder Ordner konnten nicht kopiert werden, da Fehler auftraten und das Versuche-Limit überschritten wurde."
"8"="Einige Dateien oder Ordner konnten nicht kopiert werden, es traten Fehler auf und das Versuche-Limit wurde berschritten."
"4"="Einige nicht synchrone Dateien oder Ordner gefunden. Manuelles Eingreifen ist hier nötig."
"3"="Neue Dateien kopiert. Einige Dateien oder Ordner wurden im Ziel entfernt."
"2"="Einige Dateien oder Ordner wurden im Ziel entfernt."
"1"="Neue Dateien ins Zielverzeichnis kopiert."
"0"="Quelle und Ziel sind synchron. Kopiervorgang nicht notwendig."
}

# Email-Funktion
#function SendEmail($Subject, $Body) {
#	$From = "xxx"
#	$To = $Mailto
#	$SMTPClient = New-Object System.Net.Mail.SmtpClient($SMTPServer)
#	$SMTPClient.Send($From, $To, $Subject, $Body)
#}

# Bekannte ExitCodes ins Log schreiben, Email versenden bei ExitCode != 0
if ("$ExitCode" -ge 0) {
    Add-content $LOGFILE ($TIMESTAMP + ' ' + $TIME + ' ' + $MSG."$ExitCode") -PassThru
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode" -PassThru
    if ("$ExitCode" -ne 0) {
        SendEmail "$JOB -",$MSGType."$ExitCode" ($MSGType."$ExitCode","`n`n","Quelle `t$SOURCE `n Ziel `t`t$DESTINATION `n","`n ExitCode $ExitCode `n",$MSG."$ExitCode","`n`n Details siehe $LOGFILE")
    }
}

# Unbekannte ExitCodes ins Log schreiben, Email versenden
else {
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode (UNKNOWN)" -PassThru
    SendEmail "$JOB - Information" ("Achtung!","`n","Es ist ein unbekannter Fehler aufgetreten!","`n","ExitCode $ExitCode","`n","Möglicherweise hilft das Addieren der bekannten Exit-Codes.")
}

cls
Write-Host "Benutzerprofil wird kopiert -  11% - Thunderbird"

#######################################
#                                     #
# Thunderbird-Profil roaming kopieren #
#                                     #
#######################################

# Name des Jobs.
$JOB = "migration-$($global:CurrentUser)"
#Write-Host $JOB
# Quelle. Dateien werden von hier zum Ziel gespiegelt.
$SOURCE = "C:\Users\$global:Dir\AppData\Roaming\Thunderbird\"
#Write-Host $SOURCE
# Zielverzeichnis. Dateien werden hierher gespiegelt oder entsprechend von hier entfernt.
$DESTINATION = "C:\Users\$global:CurrentUser\AppData\Roaming\Thunderbird\"
#Write-Host $DESTINATION
# Email-Einstellungen
$SMTPServer = "YOUR SMTP"
$Mailto = "YOUR MAIL"

# Pfad zur Logdatei
$LOGFILE = "C:\$JOB.log"

# Maximal 5 Sekunden versuchen (/W:5), maximal einen weiteren Versuch (/R:1), FAT-Zeitstempel verwenden (/FFT) --> Verbessert Kompatibilität Win<->Linux
$WHAT = @("/E", "/B", "/W:3","/R:1","/FFT")

# Fortsetzen des Kopiervorgangs ermöglichen
$OPTIONS = @("/Z")

# Datum erstellen (YYYY-MM-DD)
$TIMESTAMP = get-date -uformat "%Y-%m%-%d"

# Uhrzeit erstellen (HH:MM:SS)
$TIME = get-date -uformat "%T"

# Ausgaben ans Log anhängen, alternativ ohne '+' zum Neu-Erstellen der Log-Datei
$ROBOCOPYLOG = "/LOG+:$LOGFILE"

# Sammlung aller oben angeführter Parameter für Robocopy
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$ROBOCOPYLOG,$OPTIONS)
#Write-Host $cmdArgs

# Robocopy mit den oben angegebenen Parametern starten
& C:\Windows\System32\Robocopy.exe @cmdArgs
Write-Host "Profil wird von $($global:Dir) nach $($global:CurrentUser) kopiert."

# System-Variable "LastExitCode" in Variable schreiben
$ExitCode = $LastExitCode

$MSGType=@{
"16"="Fehler"
"9"="Fehler"
"8"="Information"
"4"="Information"
"3"="Information"
"2"="Information"
"1"="Information"
"0"="Information"
}

# Beschreibungen verschiedener ExitCodes
$MSG=@{
"16"="Schwerwiegender Fehler. Robocopy hat keine Dateien kopiert."
"9"="Neue Dateien ins Zielverzeichnis kopiert. Einige Dateien oder Ordner konnten nicht kopiert werden, da Fehler auftraten und das Versuche-Limit überschritten wurde."
"8"="Einige Dateien oder Ordner konnten nicht kopiert werden, es traten Fehler auf und das Versuche-Limit wurde berschritten."
"4"="Einige nicht synchrone Dateien oder Ordner gefunden. Manuelles Eingreifen ist hier nötig."
"3"="Neue Dateien kopiert. Einige Dateien oder Ordner wurden im Ziel entfernt."
"2"="Einige Dateien oder Ordner wurden im Ziel entfernt."
"1"="Neue Dateien ins Zielverzeichnis kopiert."
"0"="Quelle und Ziel sind synchron. Kopiervorgang nicht notwendig."
}

# Email-Funktion
#function SendEmail($Subject, $Body) {
#	$From = "xxx"
#	$To = $Mailto
#	$SMTPClient = New-Object System.Net.Mail.SmtpClient($SMTPServer)
#	$SMTPClient.Send($From, $To, $Subject, $Body)
#}

# Bekannte ExitCodes ins Log schreiben, Email versenden bei ExitCode != 0
if ("$ExitCode" -ge 0) {
    Add-content $LOGFILE ($TIMESTAMP + ' ' + $TIME + ' ' + $MSG."$ExitCode") -PassThru
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode" -PassThru
    if ("$ExitCode" -ne 0) {
        SendEmail "$JOB -",$MSGType."$ExitCode" ($MSGType."$ExitCode","`n`n","Quelle `t$SOURCE `n Ziel `t`t$DESTINATION `n","`n ExitCode $ExitCode `n",$MSG."$ExitCode","`n`n Details siehe $LOGFILE")
    }
}

# Unbekannte ExitCodes ins Log schreiben, Email versenden
else {
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode (UNKNOWN)" -PassThru
    SendEmail "$JOB - Information" ("Achtung!","`n","Es ist ein unbekannter Fehler aufgetreten!","`n","ExitCode $ExitCode","`n","Möglicherweise hilft das Addieren der bekannten Exit-Codes.")
}

cls
Write-Host "Benutzerprofil wird kopiert -  22% - Thunderbird"

#####################################
#                                   #
# Thunderbird-Profil local kopieren #
#                                   #
#####################################

# Name des Jobs.
$JOB = "migration-$($global:CurrentUser)"
#Write-Host $JOB
# Quelle. Dateien werden von hier zum Ziel gespiegelt.
$SOURCE = "C:\Users\$global:Dir\AppData\Local\Thunderbird\"
#Write-Host $SOURCE
# Zielverzeichnis. Dateien werden hierher gespiegelt oder entsprechend von hier entfernt.
$DESTINATION = "C:\Users\$global:CurrentUser\AppData\Local\Thunderbird\"
#Write-Host $DESTINATION
# Email-Einstellungen
$SMTPServer = "YOUR SMTP"
$Mailto = "YOUR MAIL"

# Pfad zur Logdatei
$LOGFILE = "C:\$JOB.log"

# Maximal 5 Sekunden versuchen (/W:5), maximal einen weiteren Versuch (/R:1), FAT-Zeitstempel verwenden (/FFT) --> Verbessert Kompatibilität Win<->Linux
$WHAT = @("/E", "/B", "/W:3","/R:1","/FFT")

# Fortsetzen des Kopiervorgangs ermöglichen
$OPTIONS = @("/Z")

# Datum erstellen (YYYY-MM-DD)
$TIMESTAMP = get-date -uformat "%Y-%m%-%d"

# Uhrzeit erstellen (HH:MM:SS)
$TIME = get-date -uformat "%T"

# Ausgaben ans Log anhängen, alternativ ohne '+' zum Neu-Erstellen der Log-Datei
$ROBOCOPYLOG = "/LOG+:$LOGFILE"

# Sammlung aller oben angeführter Parameter für Robocopy
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$ROBOCOPYLOG,$OPTIONS)
#Write-Host $cmdArgs

# Robocopy mit den oben angegebenen Parametern starten
& C:\Windows\System32\Robocopy.exe @cmdArgs
Write-Host "Profil wird von $($global:Dir) nach $($global:CurrentUser) kopiert."

# System-Variable "LastExitCode" in Variable schreiben
$ExitCode = $LastExitCode

$MSGType=@{
"16"="Fehler"
"9"="Fehler"
"8"="Information"
"4"="Information"
"3"="Information"
"2"="Information"
"1"="Information"
"0"="Information"
}

# Beschreibungen verschiedener ExitCodes
$MSG=@{
"16"="Schwerwiegender Fehler. Robocopy hat keine Dateien kopiert."
"9"="Neue Dateien ins Zielverzeichnis kopiert. Einige Dateien oder Ordner konnten nicht kopiert werden, da Fehler auftraten und das Versuche-Limit überschritten wurde."
"8"="Einige Dateien oder Ordner konnten nicht kopiert werden, es traten Fehler auf und das Versuche-Limit wurde berschritten."
"4"="Einige nicht synchrone Dateien oder Ordner gefunden. Manuelles Eingreifen ist hier nötig."
"3"="Neue Dateien kopiert. Einige Dateien oder Ordner wurden im Ziel entfernt."
"2"="Einige Dateien oder Ordner wurden im Ziel entfernt."
"1"="Neue Dateien ins Zielverzeichnis kopiert."
"0"="Quelle und Ziel sind synchron. Kopiervorgang nicht notwendig."
}

# Email-Funktion
#function SendEmail($Subject, $Body) {
#	$From = "xxx"
#	$To = $Mailto
#	$SMTPClient = New-Object System.Net.Mail.SmtpClient($SMTPServer)
#	$SMTPClient.Send($From, $To, $Subject, $Body)
#}

# Bekannte ExitCodes ins Log schreiben, Email versenden bei ExitCode != 0
if ("$ExitCode" -ge 0) {
    Add-content $LOGFILE ($TIMESTAMP + ' ' + $TIME + ' ' + $MSG."$ExitCode") -PassThru
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode" -PassThru
    if ("$ExitCode" -ne 0) {
        SendEmail "$JOB -",$MSGType."$ExitCode" ($MSGType."$ExitCode","`n`n","Quelle `t$SOURCE `n Ziel `t`t$DESTINATION `n","`n ExitCode $ExitCode `n",$MSG."$ExitCode","`n`n Details siehe $LOGFILE")
    }
}

# Unbekannte ExitCodes ins Log schreiben, Email versenden
else {
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode (UNKNOWN)" -PassThru
    SendEmail "$JOB - Information" ("Achtung!","`n","Es ist ein unbekannter Fehler aufgetreten!","`n","ExitCode $ExitCode","`n","Möglicherweise hilft das Addieren der bekannten Exit-Codes.")
}

cls
Write-Host "Benutzerprofil wird kopiert -  33% - Firefox"

###################################
#                                 #
# Firefox-Profil roaming kopieren #
#                                 #
###################################

# Name des Jobs.
$JOB = "migration-$($global:CurrentUser)"
#Write-Host $JOB
# Quelle. Dateien werden von hier zum Ziel gespiegelt.
$SOURCE = "C:\Users\$global:Dir\AppData\Roaming\Mozilla\"
#Write-Host $SOURCE
# Zielverzeichnis. Dateien werden hierher gespiegelt oder entsprechend von hier entfernt.
$DESTINATION = "C:\Users\$global:CurrentUser\AppData\Roaming\Mozilla\"
#Write-Host $DESTINATION
# Email-Einstellungen
$SMTPServer = "YOUR SMTP"
$Mailto = "YOUR MAIL"

# Pfad zur Logdatei
$LOGFILE = "C:\$JOB.log"

# Maximal 5 Sekunden versuchen (/W:5), maximal einen weiteren Versuch (/R:1), FAT-Zeitstempel verwenden (/FFT) --> Verbessert Kompatibilität Win<->Linux
$WHAT = @("/E", "/B", "/W:3","/R:1","/FFT")

# Fortsetzen des Kopiervorgangs ermöglichen
$OPTIONS = @("/Z")

# Datum erstellen (YYYY-MM-DD)
$TIMESTAMP = get-date -uformat "%Y-%m%-%d"

# Uhrzeit erstellen (HH:MM:SS)
$TIME = get-date -uformat "%T"

# Ausgaben ans Log anhängen, alternativ ohne '+' zum Neu-Erstellen der Log-Datei
$ROBOCOPYLOG = "/LOG+:$LOGFILE"

# Sammlung aller oben angeführter Parameter für Robocopy
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$ROBOCOPYLOG,$OPTIONS)
#Write-Host $cmdArgs

# Robocopy mit den oben angegebenen Parametern starten
& C:\Windows\System32\Robocopy.exe @cmdArgs
Write-Host "Profil wird von $($global:Dir) nach $($global:CurrentUser) kopiert."

# System-Variable "LastExitCode" in Variable schreiben
$ExitCode = $LastExitCode

$MSGType=@{
"16"="Fehler"
"9"="Fehler"
"8"="Information"
"4"="Information"
"3"="Information"
"2"="Information"
"1"="Information"
"0"="Information"
}

# Beschreibungen verschiedener ExitCodes
$MSG=@{
"16"="Schwerwiegender Fehler. Robocopy hat keine Dateien kopiert."
"9"="Neue Dateien ins Zielverzeichnis kopiert. Einige Dateien oder Ordner konnten nicht kopiert werden, da Fehler auftraten und das Versuche-Limit überschritten wurde."
"8"="Einige Dateien oder Ordner konnten nicht kopiert werden, es traten Fehler auf und das Versuche-Limit wurde berschritten."
"4"="Einige nicht synchrone Dateien oder Ordner gefunden. Manuelles Eingreifen ist hier nötig."
"3"="Neue Dateien kopiert. Einige Dateien oder Ordner wurden im Ziel entfernt."
"2"="Einige Dateien oder Ordner wurden im Ziel entfernt."
"1"="Neue Dateien ins Zielverzeichnis kopiert."
"0"="Quelle und Ziel sind synchron. Kopiervorgang nicht notwendig."
}

# Email-Funktion
#function SendEmail($Subject, $Body) {
#	$From = "xxx"
#	$To = $Mailto
#	$SMTPClient = New-Object System.Net.Mail.SmtpClient($SMTPServer)
#	$SMTPClient.Send($From, $To, $Subject, $Body)
#}

# Bekannte ExitCodes ins Log schreiben, Email versenden bei ExitCode != 0
if ("$ExitCode" -ge 0) {
    Add-content $LOGFILE ($TIMESTAMP + ' ' + $TIME + ' ' + $MSG."$ExitCode") -PassThru
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode" -PassThru
    if ("$ExitCode" -ne 0) {
        SendEmail "$JOB -",$MSGType."$ExitCode" ($MSGType."$ExitCode","`n`n","Quelle `t$SOURCE `n Ziel `t`t$DESTINATION `n","`n ExitCode $ExitCode `n",$MSG."$ExitCode","`n`n Details siehe $LOGFILE")
    }
}

# Unbekannte ExitCodes ins Log schreiben, Email versenden
else {
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode (UNKNOWN)" -PassThru
    SendEmail "$JOB - Information" ("Achtung!","`n","Es ist ein unbekannter Fehler aufgetreten!","`n","ExitCode $ExitCode","`n","Möglicherweise hilft das Addieren der bekannten Exit-Codes.")
}

cls
Write-Host "Benutzerprofil wird kopiert -  44% - Mozilla"

#################################
#                               #
# Mozilla-Profil local kopieren #
#                               #
#################################

# Name des Jobs.
$JOB = "migration-$($global:CurrentUser)"
#Write-Host $JOB
# Quelle. Dateien werden von hier zum Ziel gespiegelt.
$SOURCE = "C:\Users\$global:Dir\AppData\Local\Mozilla\"
#Write-Host $SOURCE
# Zielverzeichnis. Dateien werden hierher gespiegelt oder entsprechend von hier entfernt.
$DESTINATION = "C:\Users\$global:CurrentUser\AppData\Local\Mozilla\"
#Write-Host $DESTINATION
# Email-Einstellungen
$SMTPServer = "YOUR SMTP"
$Mailto = "YOUR MAIL"

# Pfad zur Logdatei
$LOGFILE = "C:\$JOB.log"

# Maximal 5 Sekunden versuchen (/W:5), maximal einen weiteren Versuch (/R:1), FAT-Zeitstempel verwenden (/FFT) --> Verbessert Kompatibilität Win<->Linux
$WHAT = @("/E", "/B", "/W:3","/R:1","/FFT")

# Fortsetzen des Kopiervorgangs ermöglichen
$OPTIONS = @("/Z")

# Datum erstellen (YYYY-MM-DD)
$TIMESTAMP = get-date -uformat "%Y-%m%-%d"

# Uhrzeit erstellen (HH:MM:SS)
$TIME = get-date -uformat "%T"

# Ausgaben ans Log anhängen, alternativ ohne '+' zum Neu-Erstellen der Log-Datei
$ROBOCOPYLOG = "/LOG+:$LOGFILE"

# Sammlung aller oben angeführter Parameter für Robocopy
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$ROBOCOPYLOG,$OPTIONS)
#Write-Host $cmdArgs

# Robocopy mit den oben angegebenen Parametern starten
& C:\Windows\System32\Robocopy.exe @cmdArgs
Write-Host "Profil wird von $($global:Dir) nach $($global:CurrentUser) kopiert."

# System-Variable "LastExitCode" in Variable schreiben
$ExitCode = $LastExitCode

$MSGType=@{
"16"="Fehler"
"9"="Fehler"
"8"="Information"
"4"="Information"
"3"="Information"
"2"="Information"
"1"="Information"
"0"="Information"
}

# Beschreibungen verschiedener ExitCodes
$MSG=@{
"16"="Schwerwiegender Fehler. Robocopy hat keine Dateien kopiert."
"9"="Neue Dateien ins Zielverzeichnis kopiert. Einige Dateien oder Ordner konnten nicht kopiert werden, da Fehler auftraten und das Versuche-Limit überschritten wurde."
"8"="Einige Dateien oder Ordner konnten nicht kopiert werden, es traten Fehler auf und das Versuche-Limit wurde berschritten."
"4"="Einige nicht synchrone Dateien oder Ordner gefunden. Manuelles Eingreifen ist hier nötig."
"3"="Neue Dateien kopiert. Einige Dateien oder Ordner wurden im Ziel entfernt."
"2"="Einige Dateien oder Ordner wurden im Ziel entfernt."
"1"="Neue Dateien ins Zielverzeichnis kopiert."
"0"="Quelle und Ziel sind synchron. Kopiervorgang nicht notwendig."
}

# Email-Funktion
#function SendEmail($Subject, $Body) {
#	$From = "xxx"
#	$To = $Mailto
#	$SMTPClient = New-Object System.Net.Mail.SmtpClient($SMTPServer)
#	$SMTPClient.Send($From, $To, $Subject, $Body)
#}

# Bekannte ExitCodes ins Log schreiben, Email versenden bei ExitCode != 0
if ("$ExitCode" -ge 0) {
    Add-content $LOGFILE ($TIMESTAMP + ' ' + $TIME + ' ' + $MSG."$ExitCode") -PassThru
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode" -PassThru
    if ("$ExitCode" -ne 0) {
        SendEmail "$JOB -",$MSGType."$ExitCode" ($MSGType."$ExitCode","`n`n","Quelle `t$SOURCE `n Ziel `t`t$DESTINATION `n","`n ExitCode $ExitCode `n",$MSG."$ExitCode","`n`n Details siehe $LOGFILE")
    }
}

# Unbekannte ExitCodes ins Log schreiben, Email versenden
else {
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode (UNKNOWN)" -PassThru
    SendEmail "$JOB - Information" ("Achtung!","`n","Es ist ein unbekannter Fehler aufgetreten!","`n","ExitCode $ExitCode","`n","Möglicherweise hilft das Addieren der bekannten Exit-Codes.")
}

cls
Write-Host "Benutzerprofil wird kopiert -  55% - Desktop"

###########################
#                         #
# Profil Desktop kopieren #
#                         #
###########################

# Name des Jobs.
$JOB = "migration-$($global:CurrentUser)"
#Write-Host $JOB
# Quelle. Dateien werden von hier zum Ziel gespiegelt.
$SOURCE = "C:\Users\$global:Dir\Desktop\"
#Write-Host $SOURCE
# Zielverzeichnis. Dateien werden hierher gespiegelt oder entsprechend von hier entfernt.
$DESTINATION = "C:\Users\$global:CurrentUser\Desktop\"
#Write-Host $DESTINATION
# Email-Einstellungen
$SMTPServer = "YOUR SMTP"
$Mailto = "YOUR MAIL"

# Pfad zur Logdatei
$LOGFILE = "C:\$JOB.log"

# Maximal 5 Sekunden versuchen (/W:5), maximal einen weiteren Versuch (/R:1), FAT-Zeitstempel verwenden (/FFT) --> Verbessert Kompatibilität Win<->Linux
$WHAT = @("/E", "/B", "/W:3","/R:1","/FFT")

# Fortsetzen des Kopiervorgangs ermöglichen
$OPTIONS = @("/Z")

# Datum erstellen (YYYY-MM-DD)
$TIMESTAMP = get-date -uformat "%Y-%m%-%d"

# Uhrzeit erstellen (HH:MM:SS)
$TIME = get-date -uformat "%T"

# Ausgaben ans Log anhängen, alternativ ohne '+' zum Neu-Erstellen der Log-Datei
$ROBOCOPYLOG = "/LOG+:$LOGFILE"

# Sammlung aller oben angeführter Parameter für Robocopy
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$ROBOCOPYLOG,$OPTIONS)
#Write-Host $cmdArgs

# Robocopy mit den oben angegebenen Parametern starten
& C:\Windows\System32\Robocopy.exe @cmdArgs
Write-Host "Profil wird von $($global:Dir) nach $($global:CurrentUser) kopiert."

# System-Variable "LastExitCode" in Variable schreiben
$ExitCode = $LastExitCode

$MSGType=@{
"16"="Fehler"
"9"="Fehler"
"8"="Information"
"4"="Information"
"3"="Information"
"2"="Information"
"1"="Information"
"0"="Information"
}

# Beschreibungen verschiedener ExitCodes
$MSG=@{
"16"="Schwerwiegender Fehler. Robocopy hat keine Dateien kopiert."
"9"="Neue Dateien ins Zielverzeichnis kopiert. Einige Dateien oder Ordner konnten nicht kopiert werden, da Fehler auftraten und das Versuche-Limit überschritten wurde."
"8"="Einige Dateien oder Ordner konnten nicht kopiert werden, es traten Fehler auf und das Versuche-Limit wurde berschritten."
"4"="Einige nicht synchrone Dateien oder Ordner gefunden. Manuelles Eingreifen ist hier nötig."
"3"="Neue Dateien kopiert. Einige Dateien oder Ordner wurden im Ziel entfernt."
"2"="Einige Dateien oder Ordner wurden im Ziel entfernt."
"1"="Neue Dateien ins Zielverzeichnis kopiert."
"0"="Quelle und Ziel sind synchron. Kopiervorgang nicht notwendig."
}

# Email-Funktion
#function SendEmail($Subject, $Body) {
#	$From = "xxx"
#	$To = $Mailto
#	$SMTPClient = New-Object System.Net.Mail.SmtpClient($SMTPServer)
#	$SMTPClient.Send($From, $To, $Subject, $Body)
#}

# Bekannte ExitCodes ins Log schreiben, Email versenden bei ExitCode != 0
if ("$ExitCode" -ge 0) {
    Add-content $LOGFILE ($TIMESTAMP + ' ' + $TIME + ' ' + $MSG."$ExitCode") -PassThru
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode" -PassThru
    if ("$ExitCode" -ne 0) {
        SendEmail "$JOB -",$MSGType."$ExitCode" ($MSGType."$ExitCode","`n`n","Quelle `t$SOURCE `n Ziel `t`t$DESTINATION `n","`n ExitCode $ExitCode `n",$MSG."$ExitCode","`n`n Details siehe $LOGFILE")
    }
}

# Unbekannte ExitCodes ins Log schreiben, Email versenden
else {
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode (UNKNOWN)" -PassThru
    SendEmail "$JOB - Information" ("Achtung!","`n","Es ist ein unbekannter Fehler aufgetreten!","`n","ExitCode $ExitCode","`n","Möglicherweise hilft das Addieren der bekannten Exit-Codes.")
}

cls
Write-Host "Benutzerprofil wird kopiert -  66% - Downloads"

#############################
#                           #
# Profil Downloads kopieren #
#                           #
#############################

# Name des Jobs.
$JOB = "migration-$($global:CurrentUser)"
#Write-Host $JOB
# Quelle. Dateien werden von hier zum Ziel gespiegelt.
$SOURCE = "C:\Users\$global:Dir\Downloads\"
#Write-Host $SOURCE
# Zielverzeichnis. Dateien werden hierher gespiegelt oder entsprechend von hier entfernt.
$DESTINATION = "C:\Users\$global:CurrentUser\Downloads\"
#Write-Host $DESTINATION
# Email-Einstellungen
$SMTPServer = "YOUR SMTP"
$Mailto = "YOUR MAIL"

# Pfad zur Logdatei
$LOGFILE = "C:\$JOB.log"

# Maximal 5 Sekunden versuchen (/W:5), maximal einen weiteren Versuch (/R:1), FAT-Zeitstempel verwenden (/FFT) --> Verbessert Kompatibilität Win<->Linux
$WHAT = @("/E", "/B", "/W:3","/R:1","/FFT")

# Fortsetzen des Kopiervorgangs ermöglichen
$OPTIONS = @("/Z")

# Datum erstellen (YYYY-MM-DD)
$TIMESTAMP = get-date -uformat "%Y-%m%-%d"

# Uhrzeit erstellen (HH:MM:SS)
$TIME = get-date -uformat "%T"

# Ausgaben ans Log anhängen, alternativ ohne '+' zum Neu-Erstellen der Log-Datei
$ROBOCOPYLOG = "/LOG+:$LOGFILE"

# Sammlung aller oben angeführter Parameter für Robocopy
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$ROBOCOPYLOG,$OPTIONS)
#Write-Host $cmdArgs

# Robocopy mit den oben angegebenen Parametern starten
& C:\Windows\System32\Robocopy.exe @cmdArgs
Write-Host "Profil wird von $($global:Dir) nach $($global:CurrentUser) kopiert."

# System-Variable "LastExitCode" in Variable schreiben
$ExitCode = $LastExitCode

$MSGType=@{
"16"="Fehler"
"9"="Fehler"
"8"="Information"
"4"="Information"
"3"="Information"
"2"="Information"
"1"="Information"
"0"="Information"
}

# Beschreibungen verschiedener ExitCodes
$MSG=@{
"16"="Schwerwiegender Fehler. Robocopy hat keine Dateien kopiert."
"9"="Neue Dateien ins Zielverzeichnis kopiert. Einige Dateien oder Ordner konnten nicht kopiert werden, da Fehler auftraten und das Versuche-Limit überschritten wurde."
"8"="Einige Dateien oder Ordner konnten nicht kopiert werden, es traten Fehler auf und das Versuche-Limit wurde berschritten."
"4"="Einige nicht synchrone Dateien oder Ordner gefunden. Manuelles Eingreifen ist hier nötig."
"3"="Neue Dateien kopiert. Einige Dateien oder Ordner wurden im Ziel entfernt."
"2"="Einige Dateien oder Ordner wurden im Ziel entfernt."
"1"="Neue Dateien ins Zielverzeichnis kopiert."
"0"="Quelle und Ziel sind synchron. Kopiervorgang nicht notwendig."
}

# Email-Funktion
#function SendEmail($Subject, $Body) {
#	$From = "xxx"
#	$To = $Mailto
#	$SMTPClient = New-Object System.Net.Mail.SmtpClient($SMTPServer)
#	$SMTPClient.Send($From, $To, $Subject, $Body)
#}

# Bekannte ExitCodes ins Log schreiben, Email versenden bei ExitCode != 0
if ("$ExitCode" -ge 0) {
    Add-content $LOGFILE ($TIMESTAMP + ' ' + $TIME + ' ' + $MSG."$ExitCode") -PassThru
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode" -PassThru
    if ("$ExitCode" -ne 0) {
        SendEmail "$JOB -",$MSGType."$ExitCode" ($MSGType."$ExitCode","`n`n","Quelle `t$SOURCE `n Ziel `t`t$DESTINATION `n","`n ExitCode $ExitCode `n",$MSG."$ExitCode","`n`n Details siehe $LOGFILE")
    }
}

# Unbekannte ExitCodes ins Log schreiben, Email versenden
else {
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode (UNKNOWN)" -PassThru
    SendEmail "$JOB - Information" ("Achtung!","`n","Es ist ein unbekannter Fehler aufgetreten!","`n","ExitCode $ExitCode","`n","Möglicherweise hilft das Addieren der bekannten Exit-Codes.")
}

cls
Write-Host "Benutzerprofil wird kopiert -  77% - Bilder"

##########################
#                        #
# Profil Bilder kopieren #
#                        #
##########################

# Name des Jobs.
$JOB = "migration-$($global:CurrentUser)"
#Write-Host $JOB
# Quelle. Dateien werden von hier zum Ziel gespiegelt.
$SOURCE = "C:\Users\$global:Dir\Pictures\"
#Write-Host $SOURCE
# Zielverzeichnis. Dateien werden hierher gespiegelt oder entsprechend von hier entfernt.
$DESTINATION = "C:\Users\$global:CurrentUser\Pictures\"
#Write-Host $DESTINATION
# Email-Einstellungen
$SMTPServer = "YOUR SMTP"
$Mailto = "YOUR MAIL"

# Pfad zur Logdatei
$LOGFILE = "C:\$JOB.log"

# Maximal 5 Sekunden versuchen (/W:5), maximal einen weiteren Versuch (/R:1), FAT-Zeitstempel verwenden (/FFT) --> Verbessert Kompatibilität Win<->Linux
$WHAT = @("/E", "/B", "/W:3","/R:1","/FFT")

# Fortsetzen des Kopiervorgangs ermöglichen
$OPTIONS = @("/Z")

# Datum erstellen (YYYY-MM-DD)
$TIMESTAMP = get-date -uformat "%Y-%m%-%d"

# Uhrzeit erstellen (HH:MM:SS)
$TIME = get-date -uformat "%T"

# Ausgaben ans Log anhängen, alternativ ohne '+' zum Neu-Erstellen der Log-Datei
$ROBOCOPYLOG = "/LOG+:$LOGFILE"

# Sammlung aller oben angeführter Parameter für Robocopy
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$ROBOCOPYLOG,$OPTIONS)
#Write-Host $cmdArgs

# Robocopy mit den oben angegebenen Parametern starten
& C:\Windows\System32\Robocopy.exe @cmdArgs
Write-Host "Profil wird von $($global:Dir) nach $($global:CurrentUser) kopiert."

# System-Variable "LastExitCode" in Variable schreiben
$ExitCode = $LastExitCode

$MSGType=@{
"16"="Fehler"
"9"="Fehler"
"8"="Information"
"4"="Information"
"3"="Information"
"2"="Information"
"1"="Information"
"0"="Information"
}

# Beschreibungen verschiedener ExitCodes
$MSG=@{
"16"="Schwerwiegender Fehler. Robocopy hat keine Dateien kopiert."
"9"="Neue Dateien ins Zielverzeichnis kopiert. Einige Dateien oder Ordner konnten nicht kopiert werden, da Fehler auftraten und das Versuche-Limit überschritten wurde."
"8"="Einige Dateien oder Ordner konnten nicht kopiert werden, es traten Fehler auf und das Versuche-Limit wurde berschritten."
"4"="Einige nicht synchrone Dateien oder Ordner gefunden. Manuelles Eingreifen ist hier nötig."
"3"="Neue Dateien kopiert. Einige Dateien oder Ordner wurden im Ziel entfernt."
"2"="Einige Dateien oder Ordner wurden im Ziel entfernt."
"1"="Neue Dateien ins Zielverzeichnis kopiert."
"0"="Quelle und Ziel sind synchron. Kopiervorgang nicht notwendig."
}

# Email-Funktion
#function SendEmail($Subject, $Body) {
#	$From = "xxx"
#	$To = $Mailto
#	$SMTPClient = New-Object System.Net.Mail.SmtpClient($SMTPServer)
#	$SMTPClient.Send($From, $To, $Subject, $Body)
#}

# Bekannte ExitCodes ins Log schreiben, Email versenden bei ExitCode != 0
if ("$ExitCode" -ge 0) {
    Add-content $LOGFILE ($TIMESTAMP + ' ' + $TIME + ' ' + $MSG."$ExitCode") -PassThru
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode" -PassThru
    if ("$ExitCode" -ne 0) {
        SendEmail "$JOB -",$MSGType."$ExitCode" ($MSGType."$ExitCode","`n`n","Quelle `t$SOURCE `n Ziel `t`t$DESTINATION `n","`n ExitCode $ExitCode `n",$MSG."$ExitCode","`n`n Details siehe $LOGFILE")
    }
}

# Unbekannte ExitCodes ins Log schreiben, Email versenden
else {
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode (UNKNOWN)" -PassThru
    SendEmail "$JOB - Information" ("Achtung!","`n","Es ist ein unbekannter Fehler aufgetreten!","`n","ExitCode $ExitCode","`n","Möglicherweise hilft das Addieren der bekannten Exit-Codes.")
}

cls
Write-Host "Benutzerprofil wird kopiert -  88% - Dokumente"

#############################
#                           #
# Profil Dokumente kopieren #
#                           #
#############################

# Name des Jobs.
$JOB = "migration-$($global:CurrentUser)"
#Write-Host $JOB
# Quelle. Dateien werden von hier zum Ziel gespiegelt.
$SOURCE = "C:\Users\$global:Dir\Documents\"
#Write-Host $SOURCE
# Zielverzeichnis. Dateien werden hierher gespiegelt oder entsprechend von hier entfernt.
$DESTINATION = "C:\Users\$global:CurrentUser\Documents\"
#Write-Host $DESTINATION
# Email-Einstellungen
$SMTPServer = "YOUR SMTP"
$Mailto = "YOUR MAIL"

# Pfad zur Logdatei
$LOGFILE = "C:\$JOB.log"

# Maximal 5 Sekunden versuchen (/W:5), maximal einen weiteren Versuch (/R:1), FAT-Zeitstempel verwenden (/FFT) --> Verbessert Kompatibilität Win<->Linux
$WHAT = @("/E", "/B", "/W:3","/R:1","/FFT")

# Fortsetzen des Kopiervorgangs ermöglichen
$OPTIONS = @("/Z")

# Datum erstellen (YYYY-MM-DD)
$TIMESTAMP = get-date -uformat "%Y-%m%-%d"

# Uhrzeit erstellen (HH:MM:SS)
$TIME = get-date -uformat "%T"

# Ausgaben ans Log anhängen, alternativ ohne '+' zum Neu-Erstellen der Log-Datei
$ROBOCOPYLOG = "/LOG+:$LOGFILE"

# Sammlung aller oben angeführter Parameter für Robocopy
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$ROBOCOPYLOG,$OPTIONS)
#Write-Host $cmdArgs

# Robocopy mit den oben angegebenen Parametern starten
& C:\Windows\System32\Robocopy.exe @cmdArgs
Write-Host "Profil wird von $($global:Dir) nach $($global:CurrentUser) kopiert."

# System-Variable "LastExitCode" in Variable schreiben
$ExitCode = $LastExitCode

$MSGType=@{
"16"="Fehler"
"9"="Fehler"
"8"="Information"
"4"="Information"
"3"="Information"
"2"="Information"
"1"="Information"
"0"="Information"
}

# Beschreibungen verschiedener ExitCodes
$MSG=@{
"16"="Schwerwiegender Fehler. Robocopy hat keine Dateien kopiert."
"9"="Neue Dateien ins Zielverzeichnis kopiert. Einige Dateien oder Ordner konnten nicht kopiert werden, da Fehler auftraten und das Versuche-Limit überschritten wurde."
"8"="Einige Dateien oder Ordner konnten nicht kopiert werden, es traten Fehler auf und das Versuche-Limit wurde berschritten."
"4"="Einige nicht synchrone Dateien oder Ordner gefunden. Manuelles Eingreifen ist hier nötig."
"3"="Neue Dateien kopiert. Einige Dateien oder Ordner wurden im Ziel entfernt."
"2"="Einige Dateien oder Ordner wurden im Ziel entfernt."
"1"="Neue Dateien ins Zielverzeichnis kopiert."
"0"="Quelle und Ziel sind synchron. Kopiervorgang nicht notwendig."
}
Write-Host "Benutzerprofil wird kopiert -  99%"

# Email-Funktion
# TODO: Insert personal mail-address
function SendEmail($Subject, $Body) {
	$From = "YOUR MAIL"
	$To = $Mailto
	$SMTPClient = New-Object System.Net.Mail.SmtpClient($SMTPServer)
	$SMTPClient.Send($From, $To, $Subject, $Body)
}

# Bekannte ExitCodes ins Log schreiben, Email versenden bei ExitCode != 0
if ("$ExitCode" -ge 0) {
    Add-content $LOGFILE ($TIMESTAMP + ' ' + $TIME + ' ' + $MSG."$ExitCode") -PassThru
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode" -PassThru
    if ("$ExitCode" -ne 0) {
        SendEmail "$JOB -",$MSGType."$ExitCode" ($MSGType."$ExitCode","`n`n","Quelle `t$SOURCE `n Ziel `t`t$DESTINATION `n","`n ExitCode $ExitCode `n",$MSG."$ExitCode","`n`n Details siehe $LOGFILE")
    }
}

# Unbekannte ExitCodes ins Log schreiben, Email versenden
else {
    Add-content $LOGFILE "$TIMESTAMP $TIME ExitCode`=$ExitCode (UNKNOWN)" -PassThru
    SendEmail "$JOB - Information" ("Achtung!","`n","Es ist ein unbekannter Fehler aufgetreten!","`n","ExitCode $ExitCode","`n","Möglicherweise hilft das Addieren der bekannten Exit-Codes.")
}

cls
Write-Host "Skript erfolgreich."
