# Define the source path as a parameter
param([string]$source)

# Log the source path to ensure it's correctly received
Write-Host "Checking path: $source"

# Check if the source path exists
if (-Not (Test-Path -LiteralPath $source)) {
    Write-Error "Source path does not exist: $source"
    exit
}

# Initialize an array to hold the files to process
$files = @()
$failedFiles = @()  # List to track failed files

# Check if the source is a directory or a file
if ((Get-Item $source).PSIsContainer) {
    # It's a directory, so get all the video files in the directory and subfolders
    $files = Get-ChildItem -LiteralPath $source -Recurse -Include *.mp4, *.avi, *.mkv, *.mov
}
else {
    # It's a file, check if it has a valid video extension
    $extension = [System.IO.Path]::GetExtension($source)
    Write-Host "found extension - $extension"
    if ($extension -in @(".mp4", ".avi", ".mkv", ".mov")) {
        $files += Get-Item -LiteralPath $source
    }
    else {
        Write-Error "The provided file is not a valid video format: $source" -ForegroundColor Red
        exit
    }
}

Write-Host "Found files:" -ForegroundColor Green
foreach ($f in $files) {
    Write-Host " - $f" -ForegroundColor Green
}

# Check if any files were found
if ($files.Count -eq 0) {
    Write-Error "No video files found to process." -ForegroundColor Red
    exit
}

# Loop through each file and convert it using ffmpeg
foreach ($file in $files) {
    # Get the full path of the source file
    $userInput = $file.FullName

    # Get the name of the source file without extension
    $name = $file.Name

    # Replace any spaces in the name with _
    $name = $name -replace " ", "_"

    # Get the full path of the destination file with _h265 suffix and the same extension
    $output = Join-Path -Path $file.DirectoryName -ChildPath "$name"

    # Define the argument list for ffmpeg
    $ArgumentList = @(
        "-loglevel", "warning",
        "-i", "`"$userInput`"",
        "-map", "0",
        "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2",
        "-c:v", "libx265",
        "-crf", "21",
        "-preset", "fast",
        "-vtag", "hvc1",
        "-c:a", "aac",
        "-b:a", "128k",
        "-c:s", "copy",
        "-map_metadata", "0",
        "`"$output`"")

    # Try to start ffmpeg process using the specified path and argument list
    try {
        Write-Host "Executing: 'Start-Process -FilePath .\ffmpeg-7.1-full_build\bin\ffmpeg.exe -ArgumentList $ArgumentList -Wait -NoNewWindow'" -ForegroundColor Cyan
        Start-Process -FilePath D:\DOWNLOADS\ffmpeg-7.1-full_build\bin\ffmpeg.exe -ArgumentList $ArgumentList -Wait -NoNewWindow
    }
    catch {
        # Catch any exception that occurs and write an error message
        $failedFiles += $userInput  # Add failed file to list
        Write-Error "Failed to convert $file" -ForegroundColor Red
    }
}

Write-Host "Conversion $source completed successfully!" -ForegroundColor Green

# Print failed files if there are any
if ($failedFiles.Count -gt 0) {
    Write-Host "`nFailed Files:`n" -ForegroundColor Red
    foreach ($failedFile in $failedFiles) {
        Write-Host " - $failedFile" -ForegroundColor Red
    }
}
