### Description:
A Powershell script using the spotify api to control a spotify playlist for a small business. Written in powershell to integreate seamlessly within a windows automation system. 

### Configuration Guide: 

Step 1. Replace clientID, clientSecret, and redirectWri variables with your own info. \
Step 2. Replace deviceID, playlist ID with your own info. \
Step 3. Run `playlist_controller.ps1 -action initialize_token` to generate a current_token.txt file in the same directory as your script. \
Step 4. Run `playlist_controller.ps1 -action play` and other action commands to run your spotify script.\

### Command Use Guide:

`playlist_controller.ps1 -action initialize_token`  
-> Used for getting an entirely authorization token new token, only use for hard reset or when setting up script.           
`playlist_controller.ps1 -action play` \
-> Resumes or plays the playlist\
`playlist_controller.ps1 -action pause`\
-> Pauses the playlist\
`playlist_controller.ps1 -action restart` \
-> Restart the playlist. 
~~~
