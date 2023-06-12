
#####
#
# FECwall by koh-gt
#
# Tested to work on the following Ferrite Core versions:
# 
# Recommended -- v3.1.0, v3.0.1, v3.0.0
# Depreciated -- v2.1.2, v2.1.1, v2.1.0, v2.0.0
#
# A Powershell script to search for text inscriptions on the Ferrite blockchain.
#
# Place this script in the same directory level as ferrite-cli.exe
#
#####

[string] $rpcuser = "user"
[string] $rpcpass = "password"
[string] $rpchost = "127.0.0.1"

# get latest block height
[string] $current_path = $PWD.Path

# commands
[string] $ferrite_cli = "$current_path\ferrite-cli -rpcconnect=`"$rpchost`" -rpcuser=$rpcuser -rpcpassword=$rpcpass -testnet"
[string] $getblockcount = "$ferrite_cli getblockcount"
[string] $getblockhash = "$ferrite_cli getblockhash"
[string] $getblock = "$ferrite_cli getblock"
[string] $getrawtransaction = "$ferrite_cli getrawtransaction"

# blockchain variables
[string] $maxheight = iex -Command $getblockcount
[string] $genesishash = iex -Command "$getblockhash 0"

#[console]::Write("$maxheight`n$genesishash")

# limits
$MAX_OP_RETURN_PER_BLOCK = 10

#####
#
# debug functions
#
#####

function hex([string] $text){return ([System.Text.Encoding]::UTF8.GetBytes($text) | ForEach-Object { $_.ToString("X2") }) -join ""}

#####
#
# main functions
#
#####

function getblockarray([int] $height){

    [string] $blockdatahash = iex -Command "$getblockhash $height"
    [string] $blockdata = iex -Command "$getblock $blockdatahash"
    [string[]] $blockdataarr = $blockdata -split ":"

    # filter out headers, split by comma
    $blockdataarr = $blockdataarr[1..$blockdataarr.count]

    # output clean string array from getblock output
    $cleanarrlength = $blockdataarr.count + 1
    $clean_blockdataarr = @(0..$cleanarrlength)

    $blockdataarr_count = $blockdataarr.count
    for ($i = 0; $i -lt $blockdataarr_count; $i++){

        $line = $blockdataarr[$i]

        $linearr = $blockdataarr[$i] -split ","
        $linearr_count = $linearr.count

        # remove the last element - it is the header for the next line
        if ($linearr_count -ne 1){
            [int] $len_linedata = $linearr_count - 2
            $linedata = $linearr[0..$len_linedata]
        } else {
            $linedata = $linearr
        }
        $linedata = $linedata.Trim("[", "]", " ", "{", "}", "`"")

        [string[]] $clean_blockdataarr[$i] = $linedata

    }
    return $clean_blockdataarr

}

# useful function to check for transaction count -- skip blocks that only contain one transaction
function getblocktransactioncount([int] $blocknum){
    $blockdata = getblockarray($blocknum)
    return $blockdata[16]
}


# takes in output of getblock and returns array of transaction hashes
function getblocktransactionids([Object[]] $blockarr){return $blockarr[9]}

# returns array of transaction hashes in block
function getblocktransactionhashes([int]$blocknum){return getblocktransactionids(getblockarray($blocknum))}

# returns transaction data from transaction hashes
function getrawtransactioninfo([string] $transactionhash){return iex -Command "$getrawtransaction $transactionhash 1"} # verbose

function getblocktxinfo([int]$blocknum){
    $transactionhash = getblocktransactionhashes($blocknum)

    $transaction_num = $transactionhash.count
    if ($transaction_num -eq 1){
        return getrawtransactioninfo($transactionhash)
    } else {
        $output = @(1..$transaction_num)
        for ($i = 0; $i -lt $transaction_num; $i++){
            $txhash = $transactionhash[$i]
            $output[$i] = getrawtransactioninfo($txhash)
        }
        return $output
    }
}

function GetBlockOpReturnHex([int]$blocknum) {
    $tx_hashes_output = (GetBlockTxInfo $blocknum) -split ':' |
        Where-Object { $_ -match '\b\w*OP_RETURN\w*\b' } |
        ForEach-Object {
            [regex]::Matches($_, '[0-9a-f]+').Value
        }

    if ($tx_hashes_output) {
        return $tx_hashes_output
    }
}


function hex-to-str([string]$hex){

    $arr = @(1..$hex.length)
    $arr_index = 0
    for ($i = 0; $i -lt $hex.Length; $i = $i + 2){
        $nib1 = $hex[$i] 
        $nib2 = $hex[($i + 1)]
        $byte = [system.convert]::ToInt16("$nib1$nib2", 16)
        $char = [char][byte]$byte

        $arr[$arr_index] = $char
        $arr_index++    
    }

    return [string]::join("", $arr[0..($arr_index - 1)])

}

function hexarr-to-strarr([Object[]] $hexarr){

    $hexarr_count = $hexarr.count
    if ($hexarr_count -eq 1){
        [string] $hex = $hexarr
        $str_hex = hex-to-str($hex)
        # [console]::Write("$str_hex")
    } else {
        $arr = @(1..$hexarr_count)
        for ($i = 0; $i -lt $hexarr_count; $i++){
            [string] $hex = $hexarr[$i]
            $arr[$i] = hex-to-str($hex)
        }
        return $arr
    }

}

function getblockopreturnstr ([int] $blocknum){
    $blockopreturn = getblockopreturnhex($blocknum)
    $blockopreturn_count = $blockopreturn.count
    if ($blockopreturn_count -ne 0){
        return hexarr-to-strarr($blockopreturn)
    } else {
        return
    }
}

$blocks = 6
$START = $maxheight - $blocks

[console]::WriteLine("Message explorer:")
for ($i = $start; $i -le $maxheight; $i++){
    [console]::WriteLine("Blockheight $i")
    getblockopreturnstr($i)
}

#####

[console]::WriteLine("------------------------------`n")
$messagedata = Read-Host "Input data here"
$messagedata_length = $messagedata.Length

$data = hex($messagedata)
#[console]::Write("`n------------------------------`n`nConsole commands: `n`nInput: `ncreaterawtransaction $data")
$raw_tx_output = iex -command ("$ferrite_cli createrawtransaction" + ' "[]" "{""""""data"""""":""""""' + "$data" + '""""""}"')
#[console]::Write("`nOutput: `n$raw_tx_output`n`nInput: fundrawtransaction $raw_tx_output")
$fundrawtx_output =  iex -command ("$ferrite_cli -rpcwallet=$wallet_name fundrawtransaction  $raw_tx_output")
#[console]::Write("`nOutput:`n $fundrawtx_output`n`n------------------------------`n")

# -or ($_ -match '0\.[0-9]+')
$fundrawtx_arr =  ($fundrawtx_output -split ":") -split ","

$fundrawtx_hex, $fundrawtx_fee = $fundrawtx_arr | ForEach-Object {
    $hex = [regex]::Match($_, '[0-9a-f]{10,}').Value
    $fee = [regex]::Match($_, '[0-9]\.[0-9]{8}').Value
    if ($hex -or $fee) {
        [PSCustomObject]@{ Hex = $hex; Fee = $fee }
    }
} | Select-Object -Property Hex, Fee | ForEach-Object { $_.Hex, $_.Fee }

$nextheight = $maxheight + 1
#[console]::Write("Message at block $nextheight | $messagedata | Length: $messagedata_length char`nNetwork fee: TFEC $fundrawtx_fee`n")
#Read-Host "Press Enter to sign this transaction..."

#[console]::Write("`n------------------------------`n`nConsole commands: `n`nInput: `nsignrawtransactionwithwallet $fundrawtx_hex")
$signrawtx_output = iex -Command ("$ferrite_cli -rpcwallet=$wallet_name signrawtransactionwithwallet $fundrawtx_hex")  
#[console]::Write("`nOutput:`n $signrawtx_output`n`n------------------------------`n")

$signrawtx_arr =  ($signrawtx_output -split ":") -split ","
$signrawtx_hex = $signrawtx_arr |
        Where-Object { ($_ -match '[0-9a-f]{10,}') } |
        ForEach-Object {
            [regex]::Matches($_, '[0-9a-f]{10,}').Value
        }

Read-Host "Press Enter to send this transaction..."

#[console]::Write("`n------------------------------`n`nConsole commands: `n`nInput: `nsendrawtransactionwithwallet $signrawtx_mhex")
$sendrawtx_output = iex -Command ("$ferrite_cli -rpcwallet=$wallet_name sendrawtransaction $signrawtx_hex")  
[console]::Write("Output:`n$sendrawtx_output`n------------------------------`nMessage sent.")

start-sleep 5000















