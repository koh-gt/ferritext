#####
#
# Ferritext by koh-gt
# Place this script in the same directory level as ferrite-cli.exe
#
# Tested to work on the following Ferrite Core versions:
# 
# Recommended -- v3.1.0, v3.0.1, v3.0.0
# Depreciated -- v2.1.2, v2.1.1, v2.1.0, v2.0.0
#
# A Powershell script to add text inscriptions on the Ferrite blockchain.
#
#
#####

[string] $rpcuser = "user"
[string] $rpcpass = "password"
[string] $wallet_name = ""                # leave as "" for [default wallet] -- wallet.dat

# commands
[string] $current_path = $PWD.Path
[string] $ferrite_cli = "$current_path\ferrite-cli -rpcuser=$rpcuser -rpcpassword=$rpcpass"

function hex([string] $text){return ([System.Text.Encoding]::UTF8.GetBytes($text) | ForEach-Object { $_.ToString("X2") }) -join ""}

$messagedata = Read-Host "Input data here"
$messagedata_length = $messagedata.Length

$data = hex($messagedata)
[console]::Write("`n------------------------------`n`nConsole commands: `n`nInput: `ncreaterawtransaction $data")
$raw_tx_output = iex -command ("$ferrite_cli createrawtransaction" + ' "[]" "{""""""data"""""":""""""' + "$data" + '""""""}"')
[console]::Write("`nOutput: `n$raw_tx_output`n`nInput: fundrawtransaction $raw_tx_output")
$fundrawtx_output =  iex -command ("$ferrite_cli -rpcwallet=$wallet_name fundrawtransaction  $raw_tx_output")
[console]::Write("`nOutput:`n $fundrawtx_output`n`n------------------------------`n")

# -or ($_ -match '0\.[0-9]+')
$fundrawtx_arr =  ($fundrawtx_output -split ":") -split ","

$fundrawtx_hex, $fundrawtx_fee = $fundrawtx_arr | ForEach-Object {
    $hex = [regex]::Match($_, '[0-9a-f]{10,}').Value
    $fee = [regex]::Match($_, '[0-9]\.[0-9]{8}').Value
    if ($hex -or $fee) {
        [PSCustomObject]@{ Hex = $hex; Fee = $fee }
    }
} | Select-Object -Property Hex, Fee | ForEach-Object { $_.Hex, $_.Fee }

[console]::Write("`nMessage:`n`n$messagedata`n`nLength: $messagedata_length char`n`nThe network fee for sending this message is`nFEC $fundrawtx_fee`n`n")
Read-Host "Press Enter to sign this transaction..."

[console]::Write("`n------------------------------`n`nConsole commands: `n`nInput: `nsignrawtransactionwithwallet $fundrawtx_hex")
$signrawtx_output = iex -Command ("$ferrite_cli -rpcwallet=$wallet_name signrawtransactionwithwallet $fundrawtx_hex")  
[console]::Write("`nOutput:`n $signrawtx_output`n`n------------------------------`n")

$signrawtx_arr =  ($signrawtx_output -split ":") -split ","
$signrawtx_hex = $signrawtx_arr |
        Where-Object { ($_ -match '[0-9a-f]{10,}') } |
        ForEach-Object {
            [regex]::Matches($_, '[0-9a-f]{10,}').Value
        }

Read-Host "Press Enter to send this transaction..."

[console]::Write("`n------------------------------`n`nConsole commands: `n`nInput: `nsendrawtransactionwithwallet $signrawtx_mhex")
$sendrawtx_output = iex -Command ("$ferrite_cli -rpcwallet=$wallet_name sendrawtransaction $signrawtx_hex")  
[console]::Write("`nOutput:`n$sendrawtx_output`n`n------------------------------`n")

start-sleep 5000
