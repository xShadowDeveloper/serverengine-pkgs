# Example script to handle api call to AI in this example we are using ChatGPT 4.1 Mini
# We also store the response in the store variable which can be loaded/accesed in the next script

# Please replace the API key with your own
$apiKey = "sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
# Please replace the API URL with your own
$url = "https://api.openai.com/v1/chat/completions"
# Please enter desired API model 
$model = "gpt-4.1-mini"
# Please enter your question or task
$askAI = "Explain AI in 100 words"

$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

$body = @{
    "model" = "$model"
    "messages" = @(
        @{ "role" = "user"; "content" = "$askAI" }
    )
} | ConvertTo-Json -Depth 5

# Store response in $result variable
$result = (Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $body).choices[0].message.content

# Now you can use $result anywhere
Write-Host "AI Response: $result"

$store = "AI Response: $result"