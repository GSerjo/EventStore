param([string]$assemblyInfoFilePath)
 
if ($assemblyInfoFilePath -eq $null) {
	throw "No file passed. Usage: ./updateCommitHash.ps1 <filename>"
}

if ((Test-Path $assemblyInfoFilePath) -eq $false) {
	throw "File $assemblyInfoFilePath not found"
}

Copy-Item $assemblyInfoFilePath "$assemblyInfoFilePath.bak"

$assemblyVersionInformationalPattern = 'AssemblyInformationalVersion\(\"0\.0\.0\.0\..*"\)'


try {
	$branch = & { git rev-parse --abbrev-ref HEAD }
	$commitHashAndTimestamp = & { git log --max-count=1 --pretty=format:%H@%aD HEAD }
 
	$newAssemblyVersionInformational = 'System.Reflection.AssemblyInformationalVersion("0.0.0.0.' + $branch + '@' + $commitHashAndTimestamp + '")'
	
	 
	$edited = (Get-Content $assemblyInfoFilePath) | ForEach-Object {
	    % {$_ -replace "\/\*+.*\*+\/", "" } |
	    % {$_ -replace "\/\/+.*$", "" } |
	    % {$_ -replace "\/\*+.*$", "" } |
	    % {$_ -replace "^.*\*+\/\b*$", "" } |
	    % {$_ -replace $assemblyVersionInformationalPattern, $newAssemblyVersionInformational }
	}
	 
	if (!(($edited -match "AssemblyInformationalVersion") -ne "")) {
	    $edited += "[assembly: $newAssemblyVersionInformational]"
	}
	 
	Set-Content -Path $assemblyInfoFilePath -Value $edited
	 
	Write-Host "Patched $assemblyInfoFilePath with current commit hash."
} catch {
	Write-Host "Git not available on Powershell PATH"
	$fallback = 'System.Reflection.AssemblyInformationalVersion("0.0.0.0.Unavailable@0000000000000000000000000000000000000000@Mon, 1 Jan 1970 00:00:00 +0000")'

	$edited = (Get-Content $assemblyInfoFilePath) | ForEach-Object {
		% {$_ -replace $assemblyVersionInformationalPattern, $fallback }
	}

	if (!(($edited -match "AssemblyInformationalVersion") -ne "")) {
		$edited += "[assembly: $fallback]"
	}

	Set-Content -Path $assemblyInfoFilePath -Value $edited
	Write-Host "Patched $assemblyInfoFilePath with default commit hash."
}
