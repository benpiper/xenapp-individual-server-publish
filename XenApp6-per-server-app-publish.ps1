################################################################################
# Script to publish existing applications on a per-server basis
# Created by Ben Piper
# web: http://blog.benpiper.com
# email: ben@benpiper.com
################################################################################

#Variables

$appFolder = "Applications"
$testfolderpath =  "Applications/Test/Single Server Test"
$sourceAppPath = "Applications/Test"	#apps in the root of this path will not be copied
$publishTo = "DOMAIN\GroupWithAccessToIndividualServers","DOMAIN\XenApp Administrators"
$targetWorkerGroup = "Main Farm Servers"
$clientFolder = "Test\Single Server Test"
$WhatIfPreference = $false		# Simulate script but do not execute any changes (will yield errors)

# Main Program

$servers = Get-XAServer -workergroupname $targetWorkerGroup
$sourceFolders = Get-XAFolder -folderpath $appFolder -recurse | where {$_ -notmatch $testfolderpath -and $_ -match $sourceAppPath -and $_ -ne $sourceAppPath}

# Create folder for each server
foreach ($server in $servers) {						
	#generate folder name for each server
	$createfolder = $testfolderpath+"/"+$server.servername
	#create folder for each server
	new-xafolder -folderpath $createfolder
	foreach ($folder in $sourceFolders) {
		#get list of apps to copy in each folder
		$appstocopy = Get-XAApplication -folderpath $folder			
		foreach ($app in $appstocopy) {
			## generate name for new app
			$newname = $app.displayname+" "+$server.servername
			$newclientfolder = $clientfolder+"\"+$server.servername
			## get existing accounts to remove			
			$accountsToRemove = ($app | Get-XAApplicationReport).accounts
			## copy application to server's folder		
			$newapp = $app | Copy-XAApplication -folderpath $createfolder
			## publish application to lone server		
			$newapp | set-xaapplication -servernames $server.servername -clientFolder $newclientFolder
			## remove existing accounts
			foreach ($account in $accountsToRemove) {
				$newapp | remove-xaapplicationaccount -Accounts $account
			}
			## publish application to AD group
			$newapp | add-xaapplicationaccount -Accounts $publishTo
			## rename new application
			$newapp | rename-xaapplication -newdisplayname $newname			
			
		}
	}
}