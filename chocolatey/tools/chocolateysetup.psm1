function Request-ElevatedChocolateyPermissions
{
  $file, [string]$arguments = $args;
  $psi = new-object System.Diagnostics.ProcessStartInfo $file;
  $psi.Arguments = $arguments;
  $psi.Verb = "runas";
  $psi.WorkingDirectory = get-location;
  $s = [System.Diagnostics.Process]::Start($psi);
	$s.WaitForExit(8000);
}

Set-Alias sudo-chocolatey Request-ElevatedChocolateyPermissions;

function Create-ChocolateyBinFile {
param([string] $nugetChocolateyBinFile)
"@echo off
""$nugetChocolateyPath\chocolatey.cmd"" %*" | Out-File $nugetChocolateyBinFile -encoding ASCII
}

function Initialize-Chocolatey {
  #set up variables to add
  $statementTerminator = ";"
  $nugetPath = 'C:\NuGet'
	$nugetExePath = Join-Path $nuGetPath 'bin'
	$nugetLibPath = Join-Path $nuGetPath 'lib'
	$nugetChocolateyPath = Join-Path $nuGetPath 'chocolateyInstall'
  $nugetChocolateyBinFile = Join-Path $nugetExePath 'chocolatey.bat'

  $nugetYourPkgPath = [System.IO.Path]::Combine($nugetLibPath,"yourPackageName")
  write-host 'We are setting up the Chocolatey repository for NuGet packages that should be at the machine level. Think executables/application packages, not library packages.'
	Write-Host 'That is what Chocolatey NuGet goodness is for.'
  write-host 'The repository is set up at ' $nugetPath.
  write-host 'The packages themselves go to ' $nugetLibPath '(i.e. ' $nugetYourPkgPath ').'
  write-host 'A batch file for the command line goes to ' $nugetExePath ' and points to an executable in ' $nugetYourPkgPath.
  write-host ''
	
	Write-Host 'Creating Chocolatey NuGet folders if they do not already exist.'

  #create the base structure if it doesn't exist
  if (![System.IO.Directory]::Exists($nugetExePath)) {[System.IO.Directory]::CreateDirectory($nugetExePath)}
  if (![System.IO.Directory]::Exists($nugetLibPath)) {[System.IO.Directory]::CreateDirectory($nugetLibPath)}
  if (![System.IO.Directory]::Exists($nugetChocolateyPath)) {[System.IO.Directory]::CreateDirectory($nugetChocolateyPath)}


	Write-Host ''
	
	#$chocInstallFolder = Get-ChildItem .\ -Recurse | ?{$_.name -match  "chocolateyInstall*"} | sort name -Descending | select -First 1 
	$thisScript = (Get-Variable MyInvocation -Scope 1).Value 
	$thisScriptFolder = Split-Path $thisScript.MyCommand.Path
	$chocInstallFolder = Join-Path $thisScriptFolder "chocolateyInstall"
	Write-Host 'Copying the contents of ' $chocInstallFolder ' to ' $nugetPath '.'
	Copy-Item $chocInstallFolder $nugetPath �recurse -force
	Write-Host 'Creating ' $nugetChocolateyBinFile ' so you can call chocolatey from anywhere.'
	Create-ChocolateyBinFile $nugetChocolateyBinFile
	Write-Host ''
		
  #get the PATH variable from the machine
  #$envPath = $env:PATH
  $envPath = [Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

  #if you do not find C:\NuGet\bin, add it 
  if (!$envPath.ToLower().Contains($nugetExePath.ToLower()))
  {
  	Write-Host ''
		#now we update the path
    Write-Host 'PATH environment variable does not have ' $nugetExePath ' in it. Adding.'
  
    #does the path end in ';'?
    $hasStatementTerminator= $envPath.EndsWith($statementTerminator)
    # if the last digit is not ;, then we are adding it
    If (!$hasStatementTerminator) {$nugetExePath = $statementTerminator + $nugetExePath}
    $envPath = $envPath + $nugetExePath + $statementTerminator

	  #[Environment]::SetEnvironmentVariable( "Path", $envPath, [System.EnvironmentVariableTarget]::Machine )
	  $psArgs = "[Environment]::SetEnvironmentVariable( 'Path', '" + $envPath + "', [System.EnvironmentVariableTarget]::Machine )"  #-executionPolicy Unrestricted"

	  Write-Host '' 
	  Write-Host 'You may be being asked for permission to add ' $nugetExePath ' to the PATH system environment variable. This gives you the ability to execute nuget applications from the command line.'
	  Write-Host 'Please select [Yes] when asked for privileges...'
		Write-Host '' 
	  Start-Sleep 3

	  sudo-chocolatey powershell "$psArgs"
		
		
		#add it to the local path as well so users will be off and running
		$envPSPath = $env:PATH
		$env:Path = $envPSPath + $statementTerminator + $nugetExePath + $statementTerminator
	}
	
	Write-Host 'Chocolatey is now ready.'
	Write-Host 'You can call chocolatey from anywhere, command line or powershell by typing chocolatey.'
	Write-Host 'Run chocolatey /? for a list of functions.'
  
}

export-modulemember -function Initialize-Chocolatey;