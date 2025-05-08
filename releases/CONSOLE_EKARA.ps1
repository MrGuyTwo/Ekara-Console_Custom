#####################################################################################################
#                           Example of use of the EKARA API                                         #
#####################################################################################################
# Swagger interface : https://api.ekara.ip-label.net/                                               #
# To be personalized in the code before use:                                                        #
#     username / password / client  / RefreshPage / IntervalInventory / HTMLFile                   #
# Purpose of the script : Dynamic Inventory of scenarios.                                           #
#####################################################################################################
# Author : Guy Sacilotto
# Last Update : 01/05/2025
# Version : 8.1

<#
Authentication :  user / password
Method call : 
    auth/login
    results-api/scenarios/status?clientId={$clientId}"

Grouping : by scenarios
Restitution : HTML Page with images / Dynamic refresh
#>

Clear-Host

#region VARIABLES
#========================== SETTING THE VARIABLES ===============================
$error.clear() 
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[String]$global:Version = "8.1"                                                               # Version du script
$global:API = "https://api.ekara.ip-label.net"                                                # Webservice URL
$global:UserName = ""                                                                         # EKARA Account
$global:PlainPassword = ""                                                                    # EKARA Password
$global:API_KEY = ""                                                                          # EKARA Key account
$global:RefreshPage = 310                                                                     # Fréquence de rafraichissement de la page Web en seconde
$global:IntervalInventory = 300                                                               # Fréquence de l'inventaire (en seconde)
$Global:clientId = ""

$global:DefaultDebut = ((Get-Date).adddays(-1)).tostring("yyyy-MM-dd") + " 00:00:00"          # Set the start date
$global:DefaultFin = (Get-Date).tostring("yyyy-MM-dd") + " 00:00:00"                          # Set the End Date
$global:CurrentDate = (Get-Date).tostring("yyyy-MM-dd HH:mm:ss")                              # Set current Date  

# Recherche le chemin du script
if ($psISE) {
    [String]$global:Path = Split-Path -Parent $psISE.CurrentFile.FullPath
    Write-Host "Path ISE = $Path"
} else {
    #[String]$global:Path = split-path -parent $MyInvocation.MyCommand.Path
    [String]$global:Path = (Get-Item -Path ".\").FullName
    Write-Host "Path Direct = $Path"
}

[String]$global:HTMLTitle = "SUPERVISION APPLICATIVE EKARA"                                    # Tittre de la page HTML 
[String]$global:HTMLFile = "CONSOLE_EKARA.html"                                                # Nom du fichier HTML généré 
[String]$global:HTMLFullPath = $Path+"\"+$HTMLFile                                             # Chemin complet du fichier HTML  
[String]$global:HTMLicon = $Path+"\images\Ekara.ico"                                           # Fichier icon
[String]$global:HTMLLogo = $Path+"\images\PMU.png"                                             # Fichier Logo
[String]$global:cssFile = $Path+"\css\morning.css"                                             # Fichier CSS
[String]$global:cssFileCarousel = $Path+"\css\carousel.css"                                    # Fichier CSS
[String]$global:jsFileMorning = $Path+"\js\morning.js"                                         # Fichier JS
[String]$global:jsFileSortable = $Path+"\js\sorttable.js"                                      # Fichier JS
[String]$global:jsFileCarousel = $Path+"\js\carousel.js"                                       # Fichier JS
[String]$global:imageFile = $Path+"\images"                                                    # Chemin des fichier images
[String]$global:audioFile = $Path+"\audio"                                                     # Chemin des fichier audio
[String]$global:periode = "[$CurrentDate]"                                                     # Titre du rapport

# Select Authentication mode :
# 1 = Without asking for an account and password (you must configure the account and password in this script.)
# 2 = Request the entry of an account and a password (default)
# 3 = With API-KEY
$global:Auth = 1

# Setting the header for the API request
$global:headers = $null
$global:headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"       # Create Header
$headers.Add("Accept","application/json")                                                     # Setting Header
$headers.Add("Content-Type","application/json")                                               # Setting Header

#endregion


#region Functions
function Authentication{
    try{
        Switch($Auth){
            1{
                # Without asking for an account and password
                if(($null -ne $UserName -and $null -ne $PlainPassword) -and ($UserName -ne '' -and $PlainPassword -ne '')){
                    Write-Host "--- Automatic AUTHENTICATION (account) ---------------------------" -BackgroundColor Green
                    $uri = "$API/auth/login"                                                                                                    # Webservice Methode
                    $response = Invoke-RestMethod -Uri $uri -Method POST -Body @{ email = "$UserName"; password = "$PlainPassword"}             # Call WebService method
                    $global:Token = $response.token                                                                                             # Register the TOKEN
                    $global:headers.Add("authorization","Bearer $Token")                                                                        # Adding the TOKEN into header
                }Else{
                    Write-Host "--- Account and Password not set ! ---------------------------" -BackgroundColor Red
                    Write-Host "--- To use this connection mode, you must configure the account and password in this script." -ForegroundColor Red
                    Break Script
                }
            }
            2{
                # Requests the entry of an account and a password (default) 
                Write-Host "------------------------------ AUTHENTICATION with account entry ---------------------------" -ForegroundColor Green
                $MyAccount = $Null
                $MyAccount = Get-credential -Message "EKARA login account" -ErrorAction Stop                                                    # Request entry of the EKARA Account
                if(($null -ne $MyAccount) -and ($MyAccount.password.Length -gt 0)){
                    $UserName = $MyAccount.GetNetworkCredential().username
                    $PlainPassword = $MyAccount.GetNetworkCredential().Password
                    $uri = "$API/auth/login"
                    $response = Invoke-RestMethod -Uri $uri -Method POST -Body @{ email = "$UserName"; password = "$PlainPassword"}             # Call WebService method
                    $Token = $response.token                                                                                                    # Register the TOKEN
                    $global:headers.Add("authorization","Bearer $Token")
                }Else{
                    Write-Host "--- Account and password not specified ! ---------------------------" -BackgroundColor Red
                    Write-Host "--- To use this connection mode, you must enter Account and password." -ForegroundColor Red
                    Break Script
                }
            }
            3{
                # With API-KEY
                Write-Host "------------------------------ AUTHENTICATION With API-KEY ---------------------------" -ForegroundColor Green
                if(($null -ne $API_KEY) -and ($API_KEY -ne '')){
                    $global:headers.Add("X-API-KEY", $API_KEY)
                }Else{
                    Write-Host "--- API-KEY not specified ! ---------------------------" -BackgroundColor Red
                    Write-Host "--- To use this connection mode, you must configure API-KEY." -ForegroundColor Red
                    Break Script
                }
            }
        }
    }Catch{

    Write-Host "-------------------------------------------------------------" -ForegroundColor red 
        Write-Host "Erreur ...." -BackgroundColor Red
        Write-Host $Error.exception.Message[0]
        Write-Host $Error[0]
        Write-host $error[0].ScriptStackTrace
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
        Break Script
    }
}


function Inventory{
    #========================== results/overview =============================
    # Call WS : results-api/scenarios/status
    try{
        $uri ="$API/results-api/scenarios/status?clientId=$clientId"                                    # Webservice Methode
        $status = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers                            # Call WebService method
        $status = $status | Select-Object scenarioId, scenarioName, startTime, currentStatus, clientId, scenarioType | Where-Object { $_.currentStatus -ne 6 }   # Filter the result to exclude stopped scenarios
        Write-Host ("--> Nb scenarios ["+$status.currentStatus.Count+"]") -BackgroundColor Blue                                                                  # Display information

        $Global:CurrentDate = (Get-Date).tostring("yyyy-MM-dd HH:mm:ss")
        $nbscenario = 0                                                     # set the number of scenarios to 0
        $unknown = 0                                                        # set the number of unknown scenarios status to 0      
        $Success = 0                                                        # set the number of success scenarios status to 0
        $Failure = 0                                                        # set the number of failure scenarios status to 0
		$Aborted = 0                                                        # set the number of aborted scenarios status to 0
        $Noexecution = 0	                                                # set the number of no execution scenarios status to 0			        
        $Maintenance = 0                                                    # set the number of maintenance scenarios status to 0
		$Stopped = 0                                                        # set the number of stopped scenarios status to 0
		$Excluded = 0                                                       # set the number of excluded scenarios status to 0
		$Degraded = 0                                                       # set the number of degraded scenarios status to 0
		
        $Scenario_list_Failure = "" 
        $Scenario_list_unknown = ""
		$global:itemscarousel1 = ""                                         # Carousel items
        $global:itemscarousel2 = ""                                         # Carousel items
        $global:htmlPart1 = ""                                              # Set the HTML part 1
        $global:htmlPart2 = ""                                              # Set the HTML part 2
        $global:htmlPart3 = ""                                              # Set the HTML part 3
        $global:Formattrend = ""                                            # Set the HTML part 3 content
        $Global:Content_htmlPart3 = ""                                      # Set the HTML part 3 content
        $icon_status = ""                                                   # Set the icon for the HTML
        $errorItemsHtml = ""                                                # Set the HTML part for scenario error
        $successItemsHtml = ""                                              # Set the HTML part for scenario error
		
        $status = $status | Sort-Object -Property @{Expression = "currentStatus"; Descending = $true}, @{Expression = "startTime"; Descending = $false}, @{Expression = "scenarioName"; Descending = $false} # Sort the result by currentStatus and startTime

        # Display the result in the console for each scenario
        Foreach ($scenario in $status)
        {
            Write-Host "Monitor Name : "$scenario.scenarioName -BackgroundColor Green 				       # Display information
            Write-Host "Monitor currentStatus : "$scenario.currentStatus                                   # Display information 

            $ScenarioDate = (Get-Date $scenario.startTime -Format "yyyy-MM-dd HH:mm:ss")
            $Difdate=NEW-TIMESPAN -Start $CurrentDate -End $ScenarioDate                                   # Calcul interval entre les 2 dates                     
            $timeElapsed=$Difdate.ToString("dd' jour(s) 'hh' heure(s) 'mm' minute(s) 'ss' seconde(s)'")    # Formate la date
            Write-Host ($timeElapsed)                                                                      # Display information
            $nbscenario=$nbscenario+1                                                                      # Compte le nombre de scénario
            $content = $scenario.scenarioName                                                              # Mémorise le nom du scénario pour le carousel

            switch ($scenario.currentStatus){
                # 0=Unknown / 1=Success / 2=Failure / 3=Aborted / 4=Maintenance / 5=No execution / 6=Stopped / 7=Excluded / 8=Degraded
                0 {
                    $unknown++;
                    $ScenarioStatus = "Unknown"; 
                    $bgColor ="rgb(207, 163, 226)";
                    $icon_status="$imageFile\help.ico";
                    $errorItemsHtml +="<div class='carousel-item' style='background-color: $bgColor;'> <img src='$icon_status'/><span>$content</span><p>$timeElapsed</p></div>`n"
                    }
                1 {
                    $Success++; 
                    $ScenarioStatus = "Success";
                    $bgColor ="rgb(110, 182, 140)";
                    $icon_status="$imageFile\green_button.ico";
                    $successItemsHtml +="<div class='carousel-item' style='background-color: $bgColor;'> <img src='$icon_status'/><span>$content</span><p>$timeElapsed</p></div>`n"
                    }
                2 {
                    $Failure++; 
                    $ScenarioStatus = "Failure";
                    $bgColor ="rgb(235, 122, 132)";
                    $icon_status="$imageFile\red_button.ico";
                    $errorItemsHtml +="<div class='carousel-item' style='background-color: $bgColor;'> <img src='$icon_status'/><span>$content</span><p>$timeElapsed</p></div>`n"
                    }
                3 {
                    $Aborted++;
                    $ScenarioStatus = "Aborted";
					$bgColor ="rgb(171, 178, 185)";
                    $icon_status="$imageFile\delete.ico"; 
                    $errorItemsHtml +="<div class='carousel-item' style='background-color: $bgColor;'> <img src='$icon_status'/><span>$content</span><p>$timeElapsed</p></div>`n"
                    }
                4 {
                    $Maintenance++;
                    $ScenarioStatus = "Maintenance"; 
                    $bgColor ="rgb(191, 201, 202)";
                    $icon_status="$imageFile\pause.ico";
                    #$successItemsHtml +="<div class='carousel-item' style='background-color: $bgColor;'> <img src='$icon_status'/><span>$content</span><p>$timeElapsed</p></div>`n"
                    }
                5 {
                    $Noexecution++;
                    $ScenarioStatus = "Noexecution";
                    $bgColor ="rgb(91, 147, 216)";
                    $icon_status="$imageFile\play.ico"; 
                    $errorItemsHtml +="<div class='carousel-item' style='background-color: $bgColor;'> <img src='$icon_status'/><span>$content</span><p>$timeElapsed</p></div>`n"
                    }
                6 {
                    $Stopped++; 
                    $ScenarioStatus = "Stopped";
                    $bgColor ="rgb(171, 178, 185)";
                    $icon_status="$imageFile\stop.ico";
                    $errorItemsHtml +="<div class='carousel-item' style='background-color: $bgColor;'> <img src='$icon_status'/><span>$content</span><p>$timeElapsed</p></div>`n"
                    }
                7 {
                    $Excluded++; 
                    $ScenarioStatus = "Excluded";
                    $bgColor ="rgb(171, 178, 185)"; 
                    $icon_status="$imageFile\process.ico";
                    $errorItemsHtml +="<div class='carousel-item' style='background-color: $bgColor;'> <img src='$icon_status'/><span>$content</span><p>$timeElapsed</p></div>`n"
                    }
                8 {
                    $Degraded++; 
                    $ScenarioStatus = "Degraded";
                    $bgColor ="rgb(243, 151, 46)";
                    $icon_status="$imageFile\warning.ico";
                    $errorItemsHtml +="<div class='carousel-item' style='background-color: $bgColor;'> <img src='$icon_status'/><span>$content</span><p>$timeElapsed</p></div>`n"
                    }
                default{
                    $other++; 
                    $ScenarioStatus = "Other";
                    $bgColor ="rgb(171, 178, 185)";
                    $icon_status="$imageFile\info.ico";
                    $errorItemsHtml +="<div class='carousel-item' style='background-color: $bgColor;'> <img src='$icon_status'/><span>$content</span><p>$timeElapsed</p></div>`n"
                    }
            }

            $global:Formattrend = "<span style='font-family: Calibri; text-align: center!important; display: block; color: rgba(0, 0, 0, 0.0); font-size:15px;'>"+$scenario.currentStatus+"<img src=$icon_status width=40 height=40 title=$ScenarioStatus></></span>";

            # Add data for $global:htmlPart3
            $global:Content_htmlPart3 += "
                            <tr>
                                <td align=right>"+$global:Formattrend+"</td>
                                <td align=left>"+$scenario.scenarioType+"</td>
                                <td title="+$scenario.scenarioId+">"+$scenario.scenarioName+"</td>
                                <td align=center title="""+[string]$ScenarioDate +""">"+$timeElapsed+"</td>
                            </tr>"
        }

        # Si tous les scénarios sont Success, on affiche le message de succès dans le premier carrousel
        if($errorItemsHtml -eq ""){
            $bgColor = "#abebc6"; # Vert
            $icon_status="$imageFile\green_button.ico";
            $errorItemsHtml += "<div class='carousel-item' style='background-color:$bgColor;'> <img src='$icon_status'/><span>Tous les scenarios fonctionnent parfaitement</span> <img src='$icon_status'/></div>`n"
        }

        # Si tous les scénarios sont en erreur, on affiche le message de d'echec dans le second carrousel
        if($successItemsHtml -eq ""){
            $bgColor = "#f8d7da"; # rouge
            $icon_status="$imageFile\red_button.ico";
            $successItemsHtml += "<div class='carousel-item' style='background-color:$bgColor;'> <img src='$icon_status'/><span>Tous les scenarios sont en erreur ! </span> <img src='$icon_status'/></div>`n"
        }


        # Generation du contenu de la page WEB $global:htmlPart1
        $global:htmlPart1 = "
                    <div class='stats'>
                        <center>
                            <table>
                                <tr>
                                    <td>
                                        <table style='background-color: rgb(31, 102, 160);'>
                                            <thead>
                                                <tr><th>   Total   </th></tr>
                                            </thead>
                                            <tbody>
                                                <tr><td style='text-align:center; color:rgb(252, 252, 252);'><b>$nbscenario</b></td></tr>
                                            </tbody>
                                        </table>
                                    </td>
                                    <td> 
                                        <table style='background-color: rgb(31, 102, 160);'>
                                            <thead>
                                                <tr><th>  Succes  </th></tr>
                                            </thead>
                                            <tbody>
                                                <tr><td style='text-align:center; color:rgb(83, 218, 162);'><b>$Success</b></td></tr>
                                            </tbody>
                                        </table>
                                    </td>
                                    <td> 
                                        <table style='background-color: rgb(31, 102, 160);'>
                                            <thead>
                                                <tr><th>  Echec  </th></tr>
                                            </thead>
                                            <tbody>
                                                <tr><td style='text-align:center; color: rgb(218, 83, 83);'><b>$Failure</b></td></tr>
                                            </tbody>
                                        </table>
                                    </td>
                                    <td> 
                                        <table style='background-color: rgb(31, 102, 160);'>
                                            <thead>
                                                <tr><th>Degrade</th></tr>
                                            </thead>
                                            <tbody>
                                                <tr><td style='text-align:center;color: rgb(223, 120, 61);'><b>$Degraded</b></td></tr>
                                            </tbody>
                                        </table>
                                    </td>
                                    <td> 
                                        <table style='background-color: rgb(31, 102, 160);'>
                                            <thead>
                                                <tr><th>Maintenance</th></tr>
                                            </thead>
                                            <tbody>
                                                <tr><td style='text-align:center; color: rgb(167, 190, 211);'><b>$Maintenance</b></td></tr>
                                            </tbody>
                                        </table>
                                    </td>
                                    <td> 
                                        <table style='background-color: rgb(31, 102, 160);'>
                                            <thead>
                                                <tr><th>Interrompu</th></tr>
                                            </thead>
                                            <tbody>
                                                <tr><td style='text-align:center; color:rgb(203, 105, 241);'><b>$Aborted</b></td></tr>
                                            </tbody>
                                        </table>
                                    </td>
                                    <td> 
                                        <table style='background-color: rgb(31, 102, 160);'>
                                            <thead>
                                                <tr><th>Non Execute</th></tr>
                                            </thead>
                                            <tbody>
                                                <tr><td style='text-align:center; color:rgb(132, 133, 134);'><b>$Noexecution</b></td></tr>
                                            </tbody>
                                        </table>
                                    </td>
                                    <td> 
                                        <table style='background-color: rgb(31, 102, 160);'>
                                            <thead>
                                                <tr><th> Arrete </th></tr>
                                            </thead>
                                            <tbody>
                                                <tr><td style='text-align:center; color:rgb(132, 133, 134);'><b>$Stopped</b></td></tr>
                                            </tbody>
                                        </table>
                                    </td>
                                    <td> 
                                        <table style='background-color: rgb(31, 102, 160);'>
                                            <thead>
                                                <tr><th> Exclus </th></tr>
                                            </thead>
                                            <tbody>
                                                <tr><td style='text-align:center; color:rgb(132, 133, 134);'><b>$Excluded</b></td></tr>
                                            </tbody>
                                        </table>
                                    </td>
                                    <td> 
                                        <table style='background-color: rgb(31, 102, 160);'>
                                            <thead>
                                                <tr><th>Inconnu</th></tr>
                                            </thead>
                                            <tbody>
                                                <tr><td style='text-align:center; color:rgb(132, 133, 134);'><b>$unknown</b></td></tr>
                                            </tbody>
                                        </table>
                                    </td>
                                </tr>
                            </table>
                        </center>
                    </div>
                    "
        # Generation du contenu de la page WEB $global:htmlPart2
        $global:htmlPart2 = "
                    <h1 class='titre'>Incidents en cours</h1>
                    <div class='carousel-container' id='carousel-error'>
                        <div class='carousel-track' id='carousel-track-error'>
                            $errorItemsHtml
                        </div>
                    </div>
                    <h1 class='titre'>Scenarios fonctionnels</h1>
                    <div class='carousel-container' id='carousel-success'>
                        <div class='carousel-track multi-line' id='carousel-track-success'>
                            $successItemsHtml
                        </div>
                    </div>
                    "
        # Generation du contenu de la page WEB $global:htmlPart3
        $global:htmlPart3= "
                    <div class='stats2'>
                        <center>
                            <table class='sortable'>
                                <thead>
									<tr>
										<th>Status</th>
                                        <th>Type</th>
                                        <th>Scenarios</th>
										<th>Depuis</th>
									</tr>
								</thead>
                                <tbody>
                                    $Global:Content_htmlPart3
                                </tbody>
                                <tfoot></tfoot>
                            </table>
                        </center>
                    </div>
                    "
                
        # Affiche un message Windows en cas d'erreur
        if($Failure -gt 0){
            jouerAlarme
            info "Error" "$Failure Scénario(s) en erreur !" "Erreur"
            Write-Host "$Failure Scénario(s) en erreur !" -ForegroundColor Red
        }
        
        if($unknown -gt 0){
            info "Warning" "$unknown Scénario(s) en etat unknown !" "Inconnu"
            Write-Host "$unknown Scénario(s) en etat unknown !" -ForegroundColor Yellow
        }

        if($Degraded -gt 0){
            info "Warning" "$Degraded Scénario(s) en etat Degraded !" "Warning"
            Write-Host "$Degraded Scénario(s) en etat Degraded !" -ForegroundColor Yellow
        }

        Write-Host "--> Dernière execution de l'inventaire ----->[ $CurrentDate ]<-----" -ForegroundColor Blue
        create_TOP_HTML                                                                 # Création de la partie haute de la page HTML
        create_BOTTOM_HTML                                                              # Création de la partie basse de la page HTML
    }
    catch{
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
        Write-Host "Erreur ...." -BackgroundColor Red
        Write-Host $Error.exception.Message[0]
        Write-Host $Error[0]
        Write-host $error[0].ScriptStackTrace
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
    }                                                                      
}


function Create_HTML(){
    # Create WEB page with 5 parts : top / htmlPart1 / htmlPart2 / htmlPart3 / bottom
    Write-Host "--> Create WEB page" -ForegroundColor blue
    New-Item $HTMLFullPath -Type file -Force                                                                     # Create HTML file
    Add-Content -Path $HTMLFullPath -Value $top
    Add-Content -Path $HTMLFullPath -Value $global:htmlPart1
    Add-Content -Path $HTMLFullPath -Value $global:htmlPart2
    Add-Content -Path $HTMLFullPath -Value $global:htmlPart3
    Add-Content -Path $HTMLFullPath -Value $bottom
}

Function info($TipIcon, $title, $message){
    If (-NOT $global:objNotifyIcon) {		
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        Write-Host "Charge System.Windows.Forms"
    }
    $global:objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon 		
    $objNotifyIcon.Icon = $HTMLicon		                                                                # icon affiché dans la barre des tâches(sur la base d'un exe)
    $objNotifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::$TipIcon 						# icon dans l'info bulle
    $objNotifyIcon.BalloonTipText = $message 															# Message de l'info bulle
    $objNotifyIcon.BalloonTipTitle = $title														        # titre de l'info bulle
    $objNotifyIcon.Visible = $True                                                                      # rend visible l'info bulle
    $objNotifyIcon.ShowBalloonTip(1000)																    # temp d'affichage de l'info bulle
    $objNotifyIcon.Dispose()                                                                            # Efface le message	
}


function jouerAlarme { 
	# Joue un son d'alarme
    Add-Type -AssemblyName presentationCore
	$mediaPlayer = New-Object system.windows.media.mediaplayer
	$mediaPlayer.open("$audioFile\IOS-Notification.mp3")
	$mediaPlayer.Play()
}


function Hide-Console{
    # .Net methods Permet de réduire la console PS dans la barre des tâches
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    '
    $consolePtr = [Console.Window]::GetConsoleWindow()
    #0 hide / 1 normal / 2 réduit 
    [Console.Window]::ShowWindow($consolePtr, 2)
}


Function create_TOP_HTML{
    # Creation de la partie haute de la page HTML
    $LastUpdateInventory = (Get-Date).tostring("dd/MM/yyyy HH:mm:ss")                          # Pour afficher la mise à jour de la date d'execution du script
    # Content HTML top
        [String]$global:top = "
        <!DOCTYPE html>
        <html lang='fr'>
        <head>
            <meta charset='UTF-8'>
            <title>$global:HTMLTitle</title>
            <meta http-equiv='Content-type' content='text/html'>
            <meta http-equiv='refresh' content='$RefreshPage'/>
            <link rel='shortcut icon' href='$HTMLicon'>
            <link rel='stylesheet' href='$cssFile'>
            <link rel='stylesheet' href='$cssFileCarousel'>
            <script src='$jsFileMorning'></script>
            <script src='$jsFileSortable'></script>
        </head>
        <body onload='display_ct()'>
            <span onload='audio_alarme()'>
                <p style='background-color:grey;color:white;'>
                    <span id='RefreshPageDateTime' STYLE='padding:0 0 0 40px;'></span>
                    <span id='InventoryDateTime' STYLE='padding:0 0 0 80px;'>Last request update : $LastUpdateInventory</span>
                </p>
            </span>
            <span>
                <table class='titre'>
                    <tr>
                        <td style='width: 20%; background-color: #F2F2F2; '><img class='logo' src='$global:HTMLLogo' alt='Logo EKARA'/></td>
                        <td style='width: 60%;'><h1 class='titre'>$global:HTMLTitle</h1></td>
                        <td style='width: 20%; background-color: #F2F2F2;'><img class='logo' src='$global:HTMLicon' alt='Logo EKARA'/></td>
                    </tr>
                </table>
            </span>
            <p></p>    
            "
}


Function create_BOTTOM_HTML{
    # Creation de la partie basse de la page HTML
    # Content HTML bottom
        [String]$global:bottom = @"
            <center>
                <p style='background-color:grey;color:white;'>Version : $Version</p>
            </center>
        </body>
        <script src='$jsFileCarousel'></script>
        <script>
            initCarousel("carousel-error", "carousel-track-error");
            initCarousel("carousel-success", "carousel-track-success");
        </script>
    </html>
"@
}
#endregion


#region Main
    #========================== START SCRIPT ======================================
    info "Info" "EKARA Console" "EKARA request started"               # Lance la fonction pour afficher une POPUP d'information
    Hide-Console                                                      # Lance la fonction pour réduit la console PS dans la barre des taches
    Authentication                                                    # Lance la fonction pour l'authentification API
    Inventory                                                         # Lance la fonction pour effectuer l'inventaire
    Create_HTML | Out-Null                                            # Lance la fonction pour créer la page HTML
    Start-Process $HTMLFullPath                                       # Lance la fonction pour ouvrir la page HTML
    

    # Boucle pour relancer l'inventaire et mettre à jour le contenu du fichier HTML jusqu'à 23:55
    Do {
	    Write-Host "Debut de Boucle : Attente de $IntervalInventory secondes"
        Start-Sleep -Seconds $IntervalInventory
        Inventory
        Create_HTML | Out-Null              # Creating a HNML file for content
    }
    Until("1" -gt "2")
#endregion
