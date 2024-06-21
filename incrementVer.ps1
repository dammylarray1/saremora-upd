# Define the path to your repository
$repositoryPath = "C:\Path\To\Your\Repository"
$versionFileName = "version.txt"

# Change to the repository directory
Set-Location -Path $repositoryPath

# Fetch the latest changes from the repository
git pull

# Function to increment the version
function Increment-Version {
    param (
        [string]$version
    )

    $versionParts = $version -split '\.'
    $versionParts[-1] = [int]$versionParts[-1] + 1
    return ($versionParts -join '.')
}

# Get the list of folders in the repository
$folders = Get-ChildItem -Directory

foreach ($folder in $folders) {
    # Define the path to the version file
    $versionFilePath = Join-Path -Path $folder.FullName -ChildPath $versionFileName

    # Check if the version file exists
    if (Test-Path -Path $versionFilePath) {
        # Read the current version
        $currentVersion = Get-Content -Path $versionFilePath

        # Increment the version
        $newVersion = Increment-Version -version $currentVersion

        # Write the new version back to the file
        Set-Content -Path $versionFilePath -Value $newVersion

        # Stage the changes
        git add $versionFilePath

        # Commit the changes
        git commit -m "Increment version in $folder to $newVersion"
    } else {
        Write-Host "Version file not found in $folder"
    }
}

# Push the changes to the repository
git push
