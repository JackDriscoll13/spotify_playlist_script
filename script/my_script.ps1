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
	$accessToken = (ConvertFrom-Json $response.Content).access_token
    # Grabbing the whole response
    $accessToken2 = (ConvertFrom-Json $response.Content)
    # Calculate current time
    $time_now = Get-Date 
    $ts = New-TimeSpan -Minutes 60
    $expiring_time = $time_now + $ts
    $accessToken2 | add-member Noteproperty "expiring_time"       $expiring_time
    Write-Host "Dict?: $accessToken2"
    $accessToken2 | ConvertTo-Json | Out-File "current_token.txt"
    # - Grabbing these additional things (time to expiration, refresh token)
    $accessTokenExpiredtime = (ConvertFrom-Json $response.Content).expires_in
    $refreshToken = (ConvertFrom-Json $response.Content).refresh_token
	# Write-Host "Token from request: $accessToken"
    # Write-Host "Expires at: $accessTokenExpiredtime"
    # Write-Host "Refresh Token: $refreshToken"

    return $accessToken, $refreshToken, $accessTokenExpiredtime
}

function write_token($accessToken, $refreshToken, $accessTokenExpiredtime){
    Out-File -FilePath .\token.txt InputObject $accessToken

}

function Invoke-SpotifyPlayback($action) {
    # Add some logic here to allow for not using the same token


    $accessToken, $refreshToken, $accessTokenExpiredtime = Get-SpotifyUserAccessToken
    $time_now = Get-Date 
    $ts = New-TimeSpan -Minutes 60
    $expiring_time = $time_now + $ts
    Write-Host "Time: $time_now"
    Write-Host "Expiring at: $expiring_time"
    $currentoken = Get-Content 'token.txt' | Out-String | ConvertFrom-Json
    $expiringtime2 = $currentoken.expiring_time

    Write-Host "Current token: $currentoken"
    Write-Host "v2: $expiringtime2"

    $headers = @{
        "Authorization" = "Bearer $accessToken"
    }

    switch ($action) {
        "play" {
            $body = @{
                "context_uri" = $playlistURI
            } | ConvertTo-Json
            Invoke-WebRequest -Uri "$playerEndpoint/play?device_id=$deviceID" -Method Put -Headers $headers -Body $body -ContentType "application/json"
        }
        "pause" {
            Invoke-WebRequest -Uri "$playerEndpoint/pause?device_id=$deviceID" -Method Put -Headers $headers
        }
        default{
            throw "No valid command passed, try play, pause, or start"
        }
    }
}

function CheckToken($access_token){
    
}


Invoke-SpotifyPlayback -action $action


# Start 1; Get token, 



