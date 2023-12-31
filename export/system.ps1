# Script runs indefinitely
# A script that controls the script built in part 1
while ($true) {
    $current = Get-Date
    $currentInEST = $current.ToUniversalTime().AddHours(-5)
    $currentTime = Get-Date $currentInEST -Format HH:mm
    $currentDayOfWeek = (Get-Date $currentInEST).DayOfWeek
    Write-Host "Dow: $currentDayOfWeek"
    Write-Host "Time: $currentTime"
    # Define times for actions
    $timeToPlay = "13:07"
    $timeToPause = "13:08"

    # Grab the root of the script
    $PSScriptRoot
    Write-Host "Script dir: $PSScriptRoot"
    # If it's weekday and time to play
    if (($currentDayOfWeek -ne "Saturday" -and $currentDayOfWeek -ne "Sunday") -and $currentTime -eq $timeToPlay) {
        Write-Host "Time to play! Running script with action play."
        & "$PSScriptRoot\playlist_controller1.ps1" -action play
        # Sleep for a minute to avoid triggering the action multiple times in the same minute
        Start-Sleep -Seconds 60
    }
    # If it's weekday and time to pause
    elseif (($currentDayOfWeek -ne "Saturday" -and $currentDayOfWeek -ne "Sunday") -and $currentTime -eq $timeToPause) {
        Write-Host "Time to pause! Running script with action play."
        & "$PSScriptRoot\playlist_controller1.ps1" -action pause
        # Sleep for a minute to avoid triggering the action multiple times in the same minute
        Start-Sleep -Seconds 60
    }

    # Sleep for a few seconds before checking again
    Start-Sleep -Seconds 10
}