##https://sidequests.blog/2021/02/01/exporting-all-your-power-bi-reports-at-once/

#Log in to Power BI Service
Login-PowerBI -Environment Public 	

#$CapacityId = 

#First, Collect all (or one) of the workspaces in a parameter called PBIWorkspace
$Groups = Get-PowerBIWorkspace 						# Collect all workspaces you have access to
#$Groups = Get-PowerBIWorkspace -Name 'My Workspace Name' 	# Use the -Name parameter to limit to one workspace
#$Groups = Get-PowerBIWorkspace -Scope Organization -Include All -All | Where-Object {$_.CapacityId -eq $CapacityId} 

#Now collect todays date
$TodaysDate = Get-Date -Format "yyyyMMdd_hhmmss" 

#Almost finished: Build the outputpath. This Outputpath creates a news map, based on todays date
$OutPutPath = ".\PowerBIReportsBackup\" + $TodaysDate 

#Object to save the result
$ScriptResult = @()

$ScriptResult  = [PSCustomObject]@{
    WorksapceId = ""
    ReportId = ""
    OutFile = ""
    Action = ""
    Message = ""
    Timestamp = ""
}

#Now loop through the workspaces, hence the ForEach
ForEach($Group in $Groups)
{
	#For all workspaces there is a new Folder destination: Outputpath + Workspacename
	$Folder = $OutPutPath + "\" + $Group.name 
	#If the folder doens't exists, it will be created.
	If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
	}
	#At this point, there is a folder structure with a folder for all your workspaces 
	
	
	#Collect all (or one) of the reports from one or all workspaces 
	$PBIReports = Get-PowerBIReport -WorkspaceId $Group.Id 						 # Collect all reports from the workspace we selected.
	#$PBIReports = Get-PowerBIReport -WorkspaceId $Group.Id -Name "My Report Name" # Use the -Name parameter to limit to one report
		
		#Now loop through these reports: 
		ForEach($Report in $PBIReports)
		{
			#Your PowerShell comandline will say Downloading Workspacename Reportname
			Write-Host "Downloading "$Group.name":" $Report.name 
			
			#The final collection including folder structure + file name is created.
			$OutputFile = $OutPutPath + "\" + $Group.name + "\" + $Report.name + ".pbix"
			
			# If the file exists, delete it first; otherwise, the Export-PowerBIReport will fail.
			 if (Test-Path $OutputFile)
				{
					Remove-Item $OutputFile
				}
			
			#The pbix is now really getting downloaded
            try {
			    Export-PowerBIReport -WorkspaceId $Group.ID -Id $Report.ID -OutFile $OutputFile
                
                $ScriptResult += [PSCustomObject]@{
                    WorksapceId = $Group.ID
                    ReportId = $Report.ID
                    OutFile = $OutputFile
                    Action = "Success"
                    Timestamp = $(get-date -f "yyyy-MM-dd hh:mm:ss")
                }
            } 
            catch {

                $(Resolve-PowerBIError -Last)[0].Message

                $ScriptResult += [PSCustomObject]@{
                    WorksapceId = $Group.ID
                    ReportId = $Report.ID
                    OutFile = $OutputFile
                    Action = "Failed"
                    Message = $(Resolve-PowerBIError -Last)[0].Message
                    Timestamp = $(get-date -f "yyyy-MM-dd hh:mm:ss")
                }
            }
		}
}

$ScriptResult | Export-CSV "$OutPutPath\log.$TodaysDate.csv" -NoTypeInformation