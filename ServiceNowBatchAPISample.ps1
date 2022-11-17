#Using the ServiceNow Batch API access to run several table queries

#Using an access account defined in ServiceNow. Hashing it so that you don't have a password in plain text

$passhash=ConvertTo-SecureString <string>

#Password string is encrypted by current login and needs to be regenerated for new login/machine by following two lines

#$password=Read-Host -AsSecureString

#$password=ConvertFrom-SecureString $password

$pass=$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($passhash))));

$user = <username>

 

# Build auth header

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $pass)))

 

# Set proper headers

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"

$headers.Add('Authorization',('Basic {0}' -f $base64AuthInfo))

$headers.Add('Accept','application/json')

#Make a json payload for the requests body. Each API call will have a different id. The examples are numbers but we will use a descriptive name for the data

#note the relative path for the api call. You can get the URL for each from the API explorer

$requests='{

   "batch_request_id":"Group","enforce_order":false,"rest_requests":[

      {

         "id":"TeamCatalogTasks","exclude_response_headers":true,"headers":[

            {"name":"Content-Type","value":"application/json"},

            {"name":"Accept","value":"application/json"}

         ],

         "url":"api/now/table/sc_task?sysparm_query=active%3Dtrue%5Eassignment_group%3D<UID of group>%5EstateIN1%2C2%2C-5%2C8&sysparm_display_value=true&sysparm_exclude_reference_link=true"

         ,"method":"GET"

      },

      {

         "id":"TeamIncidents","exclude_response_headers":true,"headers":[

            {"name":"Content-Type","value":"application/json"},

            {"name":"Accept","value":"application/json"}

         ],

         "url":"api/now/table/incident?sysparm_query=active%3Dtrue%5Eassignment_group%3D<UID of group>%5EstateIN1%2C2%2C3&sysparm_display_value=true",

         "method":"GET"

      }

   ]

}'

 

# Specify HTTP method - for the batch we use POST and each report in the batch is a GET or POST

$method = "POST"

 

# Specify endpoint uri - this will change depending what you need

$uri = "https://<instance>/api/now/v1/batch"

 

# Send HTTP request

$response = Invoke-RestMethod -Headers $headers -Method $method -Uri $uri -ContentType 'application/json' -Body $requests

 

#Oh look, they are base64 encoded we walk through them

foreach($line in $response.serviced_requests){

    #the id is the one we gave in the batch json

    Write-host "$($line.id).csv saved`n"

    #convert the body to a string again. No native base64 stuff in PS yet

    $body=[Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($line.body))

    $result=$body|ConvertFrom-Json

    #now we have an array of objects

    $($result.result) | Export-Csv -Path "$($line.id).csv" -NoTypeInformation

}
