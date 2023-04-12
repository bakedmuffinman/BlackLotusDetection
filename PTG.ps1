#Powershell The Gathering

# Make c:\temp directory if it doesn't exist
if (!(Test-Path "c:\temp")) {
    New-Item -Path "c:\" -Name "temp" -ItemType "directory"
}

# Set the output file path
$outputFilePath = "c:\temp\output.txt"

# Write the hostname of the machine to the output file
$hostname = hostname
Add-Content -Path $outputFilePath -Value $hostname

# Mount the EFI partition to J:
Mountvol J: /s

# Check if J: exists, if not display error message and exit script
if (!(Test-Path J:\)) {
    Write-Host "Mounting EFI partition failed. J drive not found."
    Exit
}

# Check if System32 folder exists in root of J: and output result to file
$system32Exists = Test-Path J:\System32
if ($system32Exists) {
    Add-Content -Path $outputFilePath -Value "System32 folder exists on J:"
} else {
    Add-Content -Path $outputFilePath -Value "System32 folder does not exist on J:"
}

# Find all *.efi files in J:\efi\microsoft\boot and output their timestamps to file
$efiFiles = Get-ChildItem -Path J:\efi\microsoft\boot -Filter *.efi
foreach ($file in $efiFiles) {
    $fileTimeStamp = $file.LastWriteTime
    $filePath = $file.FullName

    # Get hash of the file using certutil and output result to file
    $hashResult = certutil -hashfile $filePath SHA256
    if ($hashResult -match "CertUtil: -hashfile command completed successfully.") {
        $hash = ($hashResult | Select-String -Pattern "[0-9A-F]{64}")[0].Matches.Value
        Add-Content -Path $outputFilePath -Value "$fileTimeStamp, $hash, $filePath"
    } else {
        $errorMessage = ($hashResult | Select-String -Pattern "CertUtil: -hashfile.*Error.*")
        Add-Content -Path $outputFilePath -Value "$file.Name, $errorMessage"
    }
}

# Check if registry key HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity exists and output result to file
$keyExists = Test-Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity
if ($keyExists) {
    $value = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity).value
    Add-Content -Path $outputFilePath -Value "Registry key HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity exists with value: $value"
} else {
    Add-Content -Path $outputFilePath -Value "Registry key HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity does not exist"
}

# Unmount J: drive
mountvol J: /d
