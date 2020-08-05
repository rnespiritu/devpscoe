<#
Description:        Using SQLPackage, export a dacpac from an instance of SQL Server. 
                    Dependencies for the function: dbatools powershell script library. 
                    
Created On:         2020-04-25

Change History:
====================================================================================================================================================================
Changed On:		By:		TaskID		Details
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
2020-04-25		RNE		1278063     1.   Input parameters has built in validation, Parameter with no value gets the Default value set in $PSDefaultParameterValues block
                                    2.   With Logging Feature that stores verbose data
                                    3.   Folders and LogFile is created if does not exist
                                    4.   Exports DacPac
                                    5.   Writes "Export-DbaDacPackage" custom Warnings to the Log file 
                                         with default $FilePath = "c:\DeltekDacPacExport"
                                    6.   If Invalid Drive letter is set the path is automatically set to the Default Path.
                                    7.   Command Text and Summary of Export is Displayed on Screen and Saved to LOG.  Note Command Text can be copied to log and Executed
                                         on the Powershell console
                                    8.   Named Instance is supported

====================================================================================================================================================================
#>

Clear-Host

###################### INITIALIZE VARIABLES ########################

[string]$global:ComputerName = gc env:computername
$global:isDriveLetterExist = $false
$global:isWarningDriveLetterWrittenInLog = $false
$global:InvalidPathValue = ""

$VerbosePreference = "SilentlyContinue"
[string]$global:LogFile = "c:\DeltekDacPacExport"

#---------------------------------------------------------------------
$PSDefaultParameterValues += @{
  "write-deltekLogger:LogFileName"="DeltekDacPacExport";
  "write-deltekLogger:LogType"="";
  "write-deltekLogger:FilePath"=$global:LogFile;

### Remove the Hash (#) at the start of the line if you want to use the Default Values
#  "Export-DeltekDacPac:SqlInstance"=$global:ComputerName;
#  "Export-DeltekDacPac:Database"="DeltekFirstOperations";
#  "Export-DeltekDacPac:FilePath"="c:\DeltekDacPacExport";
#  "Export-DeltekDacPac:DacMajorVersion"=0;
#  "Export-DeltekDacPac:DacMinorVersion"=0;

  "Export-DeltekDacPac:DacApplicationDescription"="Dacpac";
  "Export-DeltekDacPac:DacApplicationName"="DeltekDacPacPackage"
} ## PSDefaultParameterValues


############################# FUNCTIONS #############################
function write-deltekLogger{
    [cmdLetBinding()]
    param(

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]$Message="",

    [Parameter(Mandatory=$true, Position=1)]
    #[AllowEmptyString()]
    [string]$LogFileName,

    [Parameter(Mandatory=$true,Position=2,
    HelpMessage='Can either be: "[<Empty String>]","[<Any 50 char String>]","LOG","DEBUG","INFO","WARN","ERROR","FATAL"')]
    [ValidateLength(0,50)]
    [ValidatePattern('^[a-zA-Z0-9 ]*$')]
    [AllowEmptyString()]
    [string]$LogType,
    
    [Parameter(Mandatory=$true,Position=3,
    HelpMessage='default path is c:\DeltekDacPacPackage. Invalid Characters: \/:*?"<>|')]
<##################################################
<#Bug: 
    Cannot Include "[" this character ###>
    [ValidatePattern('^((?!\/\*\?"<>\|\[).)*$')]
    [string]$FilePath
    
    )##Param Block

Begin{
	Test-DeltekDbaToolsExisting
	
    # Clean FilePath Remove Quotations " and Backslash \
    $FilePath = (($FilePath.TrimEnd('"')).TrimStart('"')).TrimEnd("\")
    [string]$LogFilePath = $FilePath +"\"+ $LogFileName.ToUpper() +".LOG"
} ## Begin Block

Process{

    #Check if the Folder Structure and File exist if not existing Create it
    if(!(Test-Path -path $FilePath  )){

        if(!($global:isDriveLetterExist)){
            $FilePath = $global:LogFile
            $LogFilePath = $FilePath +"\"+ $LogFileName.ToUpper() +".LOG"
        } ## IF Block    
        
        #Create the Folder(s) if the Dir Structure is/are not created
        new-item -type directory -path $FilePath -Force | Out-Null
       

        # Create the File if does not exist
        if(!(Test-Path -path $LogFilePath )){

            
            ## Create the Log File
            New-Item -path $FilePath -name "$LogFileName.LOG" -type "file" | Out-Null
        } ## If Block
    } ## If Block

    
    #Write to the LOG File
    IF($LogType) { 
        ((get-date).ToString('yyyy-MM-dd HH:mm:ss') + " " + "["+$LogType+"]" + " - " + $Message) >> $LogFilePath
  
    } else {
        ((get-date).ToString('yyyy-MM-dd HH:mm:ss') + " - " + $Message) >> $LogFilePath
    }
    
    ## Copy the Validated Path of the Log to a Global variable named LogFile
    $global:LogFile = $LogFilePath

} ## Process Block

End{
    # Clears the Contents of the following Variables
    $Message = $null
    $LogFilePath = $null
    $LogFileName = $null

} ## End Block

} ## End Function Block

#----------------------------------------------------------------------------

Function Export-DeltekDacPac{
  <#
    .SYNOPSIS
        Exports a dacpac from a server.
    .DESCRIPTION
        Using dbatools (export-dbaDacPackage), export a dacpac from an instance of SQL Server.
    .PARAMETER SqlInstance
        [Input] Alpha numeric minimum of zero(0) to two hunddred (200) characters only
        The target SQL Server instance or instances.
    .PARAMETER Database
        [Input] Alpha numericand Special characters _-%&!# is allowed minimum of zero(0) to two hunddred (200) characters only
        The database to process - this list is auto-populated from the server. If unspecified, all databases will be processed.
    .PARAMETER FilePath
        Special Characters ?!/*"<>|
        Specifies the full file path of the output file.
        Default PAth = "c:\DeltekDacPacExport"
    .PARAMETER DacApplicationDescription
        [Optional] Should have no whitespace character.
        Description of the Application
    .PARAMETER DacMajorVersion
        Numeric value
    .PARAMETER DacMinorVersion
        Numeric value
    .PARAMETER DacApplicationName
        [Optional]
        Name of the application
    .LINK

    .EXAMPLE
        PS C:\> Export-DeltekDacPac
		If No parameters you will be prompted to input the Required parameters

    .EXAMPLE
        PS C:\> Export-DeltekDacPac -SqlInstance "USEATTss1db1" -Database "DELTEKFIRSTOPERATIONS" -FilePath "c:\deltekDACPACExport" -DacMajorVersion 1 -DacMinorVersion 0
		Minimum Parameters to execute the commadlet
    #>
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidatePattern('^[a-zA-Z0-9\\]*$')]
        [ValidateLength(0,200)]
        [String] $SqlInstance,

        [Parameter(Mandatory=$true, Position=1)]
        [ValidatePattern('^[a-zA-Z0-9_\-%&!#]*$')]
        [ValidateLength(0,200)]
        [String] $Database,
        
        [Parameter(Mandatory=$true, Position=2)]
        [ValidatePattern('^((?!\/\*\?"<>\|).)*$')]
        [String] $FilePath,

        # Should not contain whitespace
        [Parameter(Mandatory=$false, Position=3)]
        #Will not accept Whitespace character DacPac DBaTools won't allow it
        [ValidatePattern('^[a-zA-Z0-9_\-]*$')]
        [String] $DacApplicationDescription,
        
        [Parameter(Mandatory=$true, Position=4)]
        [int] $DacMajorVersion=0,

        [Parameter(Mandatory=$true, Position=5)]
        [int] $DacMinorVersion=0,

        [Parameter(Mandatory=$false, Position=6)]
        [ValidatePattern('^[a-zA-Z0-9]*$')]
        [String] $DacApplicationName

    )  ## Param END
  
Begin{ ## Block

    ## Check if the Drive letter is Valid before creating the Folder Structure
    Get-WmiObject -Class Win32_logicaldisk | `
        Select-Object deviceid | `
            ForEach-Object { 
                
                if(($FilePath.Substring(0,2).ToUpper()) -match $_.deviceID) { 
                    $global:isDriveLetterExist = $true
                }## IF
            
            }## Foreach
    
    ## If Drive letter is Invalid Set the Default Path
    if(!($global:isDriveLetterExist)){
        $global:InvalidPathValue =  $FilePath
        $FilePath = $global:LogFile    
    } ## IF Block
       

    # Initiate Log File
    "=============================================================================================" | `
        write-deltekLogger -FilePath $FilePath


    ## Write the Warning of Invalid Drive Letter to the LOG File
    if(($global:isWarningDriveLetterWrittenInLog -eq $false) -and ($global:isDriveLetterExist -eq $false)) {
        $global:isDriveLetterExist = $true
        $global:isWarningDriveLetterWrittenInLog = $true
        Write-warning "The Drive Letter is Invalid! `"$global:InvalidPathValue`", Set to Default Path $global:LogFile " 3>&1 | `
            write-deltekLogger -FilePath $FilePath -LogType "WARNING"
    }


    # Everything not declared in `param` goes to $args.
    # If $args is not empty then there are "invalid" parameters or "unexpected" arguments
    # check $args and throw an error (in here we just write a warning)
    if ($args) { Write-Warning "Unknown arguments: $args" 3>&1 | `
            write-deltekLogger -FilePath $FilePath -LogType "WARNING"
    }  ##IF Block



    [string]$getTimeTemp = ((get-date).ToString('yyyy-MM-dd HH:mm:ss'))
    $FilePath = (($FilePath.TrimEnd('"')).TrimStart('"')).TrimEnd("\")
    $tempBacktickChar = [char]96

    # Build the Command Structure for Logging and Screen Display
    $CommandText = "Export-DeltekDacPac "
    if($SqlInstance)               {$CommandText+="```r`n`t`t -SqlInstance `"$SqlInstance`" "}
    if($Database)                  {$CommandText+="```r`n`t`t -Database `"$Database`" "}
    if($FilePath)                  {$CommandText+="```r`n`t`t -FilePath `"$FilePath`" "}
    if($DacApplicationDescription) {$CommandText+="```r`n`t`t -DacApplicationDescription `"$DacApplicationDescription`" "}
    if($DacMajorVersion -ge 0)     {$CommandText+="```r`n`t`t -DacMajorVersion "+$DacMajorVersion+" "}
    if($DacMinorVersion -ge 0)     {$CommandText+="```r`n`t`t -DacMinorVersion "+$DacMinorVersion+" "}
    if($DacApplicationName)        {$CommandText+="```r`n`t`t -DacApplicationName `"$DacApplicationName`" "}


    write-output "`r`nProcessing Export Dacpac Package for $Database Version: $DacMajorVersion.$DacMinorVersion"
    write-output "Processing Export Dacpac Package for $Database Version: $DacMajorVersion.$DacMinorVersion" | `
        write-deltekLogger -FilePath $FilePath

    
    ## Check Folder if not Exist Create the Folder
    If(!(test-path $FilePath))
    {
          New-Item -ItemType Directory -Force -Path $FilePath -Confirm | `
                write-deltekLogger -FilePath $FilePath | Out-Null
          
          Write-verbose "Folder Created: $FilePath `r`n" -Verbose 4>&1 | `
                write-deltekLogger -FilePath $FilePath
    
    } ##End IF Block

    Write-Output "Started :  $getTimeTemp `r`n"
    Write-Output "Started" | `
        write-deltekLogger -FilePath $FilePath

   
    Write-Verbose "Parameter input SqlInstance : $SqlInstance " -Verbose 4>&1 | `
        write-deltekLogger -FilePath $FilePath
    
    Write-Verbose "Parameter input Database    : $Database " -Verbose 4>&1 | `
        write-deltekLogger -FilePath $FilePath
    
    Write-Verbose "Parameter input FilePath    : $FilePath " -Verbose 4>&1 | `
        write-deltekLogger -FilePath $FilePath
   
    Write-Verbose "Parameter input DacApplicationDescription: $DacApplicationDescription " -Verbose 4>&1 | `
        write-deltekLogger -FilePath $FilePath
    
    Write-Verbose "Parameter input DacMajorVersion     : $DacMajorVersion " -Verbose 4>&1 | `
        write-deltekLogger -FilePath $FilePath
    
    Write-Verbose "Parameter input DacMinorVersion    : $DacMinorVersion " -Verbose 4>&1 | `
        write-deltekLogger -FilePath $FilePath

#todo:
#    Create  try catch block with logging for warning and errors    
    try{
        $options = New-DbaDacOption -Type Dacpac -Action Export
        $options.ExtractAllTableData = $true
        $options.CommandTimeout = 0
        
       
        $VerifyExtraction = $true
        
        $ExtendedParameters = "/OverwriteFiles:$true /Quiet:$false"

        
        $ExtendedProperties = "/p:VerifyExtraction=$true
            /p:DacApplicationDescription=$DacApplicationDescription
            /p:DacApplicationName=$DacApplicationName
            /p:DacMajorVersion=$DacMajorVersion
            /p:DacMinorVersion=$DacMinorVersion"
        

        ## Prepare FileName Path
        $FileNamePath = $FilePath.TrimEnd("\") + "\" + $Database + "_v." + $DacMajorVersion + "." + $DacMinorVersion + ".dacpac"
        


        write-verbose "--- Call function start: Export-DbaDacPackage ---" -Verbose 4>&1 | `
            write-deltekLogger -FilePath $FilePath

        write-Output "Command Text: `r`n`t$CommandText"
        Write-Verbose "$CommandText" -Verbose 4>&1 | `
            write-deltekLogger -FilePath $FilePath


        Write-Output "`r`nProcessing... `r`n"

    }catch{
        Write-warning $Error[0] *>&1 | `
            write-deltekLogger -FilePath $FilePath -LogType "WARNING"    

    } ## TryCatch Block
    
} ## End Begin Block

Process{
   
    try{
        ## RUN DBATools DACPackage
        Export-DbaDacPackage -SqlInstance $SqlInstance -Database $Database -FilePath $FileNamePath -ExtendedParameters $ExtendedParameters -ExtendedProperties $ExtendedProperties *>&1 | `
                Tee-Object -FilePath $global:LogFile -Append

        write-verbose "--- Call function end: Export-DbaDacPackage ---" -Verbose 4>&1 | `
            write-deltekLogger -FilePath $FilePath

        Write-Output "LogFile output file path:  `r`n`t$global:LogFile`r`n"
        Write-Output "LogFile output file path:  $global:LogFile" | `
            write-deltekLogger -FilePath $FilePath

        Write-Output "DacPac output file path: `r`n`t$FileNamePath`r`n"
        Write-Verbose "DacPac output file path: $FileNamePath" -Verbose 4>&1 | `
            write-deltekLogger -FilePath $FilePath


        $getTimeTemp = ((get-date).ToString('yyyy-MM-dd HH:mm:ss'))

        Write-Output "Function Ended : $getTimeTemp `r`n"
        Write-Output "Function Ended" | `
            write-deltekLogger -FilePath $FilePath

    }catch {
        Write-warning $Error[0] *>&1 | `
            write-deltekLogger -FilePath $FilePath -LogType "WARNING"   
    } ## TryCatch Block
    
}## End Process
END{
    $global:isDriveLetterExist = $false
    $global:isWarningDriveLetterWrittenInLog = $false
    $global:LogFile = "c:\DeltekDacPacExport"
    $global:InvalidPathValue = ""
} ## End Block

} ## Function
