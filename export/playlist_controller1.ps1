param($action)

# Replace with your own clientID, clientSecret, and redirectUri
Write-Host "Reading client credentials..."
$clientID = "03f1459766fe45b587f8d1514a5f6f9f"
Write-Host "Client ID: $clientID"
$clientSecret = "e465a9a39c36477197b1cf8db8f0bf10"
Write-Host "Client Secret: $clientSecret"
$redirectUri = "http://localhost:7777/callback"

Add-Type -AssemblyName System.Web
[System.Web.HttpUtility]::UrlEncode("www.spotify.com")

# Spotify API Endpoints
$authEndpoint = "https://accounts.spotify.com/authorize"
$tokenEndpoint = "https://accounts.spotify.com/api/token"
$playerEndpoint = "https://api.spotify.com/v1/me/player"

# Device and playlist information -> putting in my own device id, playlist id
$deviceID = "63b37c0ed2f874c97ed5eed8b5793129aace40c5"
$playlistID = "5WC6YVPLHb8JRgW1UE4rAt"
$playlistURI = "spotify:playlist:$playlistID"

function Get-SpotifyUserAccessToken {
    $state = Get-Random
    Write-Host "Building authorization URL..."
    $scopes = "user-modify-playback-state"
    $authUrl = "{0}?client_id={1}`"&`"response_type=code`"&`"redirect_uri={2}`"&`"scope={3}`"&`"state={4}" -f $authEndpoint, $clientID, [System.Web.HttpUtility]::UrlEncode($redirectUri), [System.Web.HttpUtility]::UrlEncode($scopes), $state

      # Start a listener for the redirect URI
    Write-Host "Starting listener for authorization code..."
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($redirectUri + "/")
    $listener.Start()

    # Open the authorization URL in the default browser
    Write-Host "Authorization URL: $authUrl"
    $edgeUrl = "$authurl"
    cmd.exe /c "start $edgeUrl"

    # Wait for the response
    $context = $listener.GetContext()
	
    # Send a response to close the browser window
    $response = $context.Response
    $response.StatusCode = 200
    $response.OutputStream.Close()

	#stop the listener
	$listener.Stop()

    # Parse the query string
    $query = [System.Web.HttpUtility]::ParseQueryString($context.Request.Url.Query)

    # Check state
    if ($query['state'] -ne $state) {
        throw "Invalid state"
    }

    # Exchange the authorization code for an access token
    $code = $query['code']
	
    Write-Host "Received authorization code: $code"
 
    $authHeader = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $clientID, $clientSecret)))
    $headers = @{
        "Authorization" = "Basic $authHeader"
    }
    $body = @{
        "grant_type" = "authorization_code"
        "code" = $code
        "redirect_uri" = $redirectUri
    }

    $response = Invoke-WebRequest -Uri $tokenEndpoint -Method Post -Headers $headers -Body $body -ContentType "application/x-www-form-urlencoded"
    # Grabbing the whole response
    $accessToken2 = (ConvertFrom-Json $response.Content)
    # Get current timem use to calculate expiring time
    $time_now = Get-Date 
    $ts = New-TimeSpan -Minutes 60
    $expiring_time = $time_now + $ts
    # Add expiring time to token hash table
    $accessToken2 | add-member Noteproperty "expiring_time"       $expiring_time

    # Write to file 
    $accessToken2 | ConvertTo-Json | Out-File "current_token.txt"
    Write-Host "Succesfully wrote new token to file: current_token.txt."
    return $accessToken2
}

function Get-Refresh-Token($current_token){ 
    # Grab the refresh token 
    $refresh_token =$current_token.refresh_token
    $authHeader = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $clientID, $clientSecret)))
    $headers = @{
        "Authorization" = "Basic $authHeader"
    }
    $body = @{
        "grant_type" = "refresh_token"
        "refresh_token" = $refresh_token
    }

    $response = Invoke-WebRequest -Uri $tokenEndpoint -Method Post -Headers $headers -Body $body -ContentType "application/x-www-form-urlencoded"
    $new_token = (ConvertFrom-Json $response.Content)
    $time_now = Get-Date 
    $expiring_time = $time_now.AddHours(1)

    # Add expiring time to token hash table
    $new_token | add-member Noteproperty "expiring_time"       $expiring_time
    $new_token | ConvertTo-Json | Out-File "current_token.txt"

    return $new_token
}


function Playlist-Controller($action){ 
    # Get the current time, convert to utc
    $time_now = Get-Date 
    $time_now_utc  = ([DateTime]$time_now).ToUniversalTime()
    # Get the currently saved token
    $current_token = Get-Content 'current_token.txt' | Out-String | ConvertFrom-Json
    $token_expired_time = $current_token.expiring_time
    # Determine if the token is expired or not, if it is, get refresh it
    if (($time_now_utc) -gt ($token_expired_time))
    {
        Write-Host "Refreshing Token"
        $current_token = Get-Refresh-Token($current_token)
    }
    # Get the access Token and print out relevant info
    $access_token = $current_token.access_token
    Write-Host "Access token: $access_token"
    Write-Host "Time Now: $time_now_utc"
    $token_expired_time = $current_token.expiring_time
    Write-Host "Expiring time: $token_expired_time"

   # Initiliaze header with access token
    $headers = @{
        "Authorization" = "Bearer $access_token"
    }

    # Control the playlist based on user inputs or actions
    switch ($action) {
        "play" {
            Invoke-WebRequest -Uri "$playerEndpoint/play?device_id=$deviceID" -Method Put -Headers $headers
        }
        "pause" {
            Invoke-WebRequest -Uri "$playerEndpoint/pause?device_id=$deviceID" -Method Put -Headers $headers
        }
        "restart" {
            $body = @{
                "context_uri" = $playlistURI
            } | ConvertTo-Json
            Invoke-WebRequest -Uri "$playerEndpoint/play?device_id=$deviceID" -Method Put -Headers $headers -Body $body -ContentType "application/json"
        }
        "initialize_token"{
            # Get a completley new token
            Get-SpotifyUserAccessToken

        }
        default{
            throw "No valid command passed, try 'play', 'pause',  'restart', or 'initialize_token'."
        }
    }

}

Playlist-Controller -action $action

