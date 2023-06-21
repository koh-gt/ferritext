
#####
#
# FECWall by koh-gt
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

#####
#
# RPC parameters
#
#####

[string] $rpcuser = "user"
[string] $rpcpass = "password"
[string] $wallet_name = ""                # leave as "" for [default wallet] -- wallet.dat
[string] $rpchost = "127.0.0.1"
[int] $TESTNET = 1                        # leave as 1 for testnet

#####
#
# Text return parameters
#
#####

# load latest blocks at startup from cli (default 30) 
$INIT_BLOCKS_SHOW = 20

# 0 - blocks strings that contain non standard characters
# 1 - filters strings that contain non standard characters
$ALLOW_NONSTANDARD = 0   

# 0 - only characters 32 to 126 " !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
# 1 - non-operation ascii from 32 to 126 and 128 to 255
$STANDARD_SETTING = 0   

# show or skip invalid blocks
$SHOW_EMPTY_OR_INVALID_BLOCKS = 0

# number of digits for block number (default: 9)
$BLOCKNUM_DIGITS = 9

#####
#
# Window settings
#
#####



$WINDOW_HEIGHT = 40
$WINDOW_WIDTH = 100

$uisettings = (get-host).UI.RawUI
$b = $uisettings.WindowSize
$ba = $uisettings.MaxPhysicalWindowSize

# adjust buffer size according to max physical window size
$bf = $uisettings.BufferSize
$bf.Height = [math]::Ceiling($ba.Height - 1) # increase this so that buffer can handle more at once...
$bf.Width = [math]::Ceiling($ba.Width - 1)
$uisettings.BufferSize = $bf

# let window size be max physical window size
# $b.Height = $ba.Height - 1 # a bit smaller than maxphysical window size
# $b.Width = $ba.Width - 1 # a bit smaller than maxphysical window size
$b.Height = $WINDOW_HEIGHT
$b.Width = $WINDOW_WIDTH
$height_window = $b.Height
$width_window = $b.Width
$uisettings.WindowSize = $b # apply window size changes

#window title stat of columns x rows
[string] $titlename = "Ferritext Wall -- FECWall ~ $height_window x $width_window"
$uisettings.WindowTitle = $titlename # apply window name title changes
$uisettings.CursorSize = 0 # hide cursor
#####

#####
# 
# Console commands
#
#####
if ($TESTNET -eq 1){$testnet_arg = "-testnet"} else {$testnet_arg = ""}

# get latest block height
[string] $current_path = $PWD.Path

# commands
[string] $ferrite_cli = "$current_path\ferrite-cli -rpcconnect=`"$rpchost`" -rpcuser=$rpcuser -rpcpassword=$rpcpass $testnet_arg"
[string] $getblockcount = "$ferrite_cli getblockcount"
[string] $getblockhash = "$ferrite_cli getblockhash"
[string] $getblock = "$ferrite_cli getblock"
[string] $getrawtransaction = "$ferrite_cli getrawtransaction"
[string] $getnetworkinfo = "$ferrite_cli getnetworkinfo"
[string] $getrawmempool = "$ferrite_cli getrawmempool"

# blockchain variables
[string] $maxheight = iex -Command $getblockcount
[string] $genesishash = iex -Command "$getblockhash 0"

# initial synchronisation
$blocks_show = $INIT_BLOCKS_SHOW
$last_block = $maxheight
$START_BLOCK = $last_block - $blocks_show
$LINES_DISPLAY_SHOW = $WINDOW_HEIGHT - 10  # unused

function get-rawmempool(){
    $rawmempool = iex -Command "$getrawmempool" | ConvertFrom-Json
    return $rawmempool
}

function get-networkinfo-subversion() {
    $networkinfo = iex -Command "$getnetworkinfo"
    $netinfo = $networkinfo | ConvertFrom-Json
    $netinfo.gettype()
    $version = $netinfo.version
    [console]::WriteLine($version)
}

#get-networkinfo-subversion

#####
#
# debug functions
#
#####

function print-object([Object[]] $arr){
    [console]::Write("`n`n")
    for ($i = 0; $i-lt $arr.count; $i++){
        $element = $arr[$i] 
        [console]::Write("$element`n")
    }
}

#####
#
# main functions
#
#####


# useful function to check for transaction count -- skip blocks that only contain one transaction
function get-blocktransactionhashes([int]$height){
    [string] $blockdatahash = iex -Command "$getblockhash $height"
    [string] $jsonblockdata = iex -Command "$getblock $blockdatahash"
    $blockdata = $jsonblockdata | ConvertFrom-Json 
    $txdata = $blockdata.tx
    return $txdata
}

function Get-BlockOpReturnHex-FromHeight([int]$height){
    return Get-BlockOpReturnHex(get-blocktransactionhashes($height))
}


# returns transaction data from transaction hashes
function Get-BlockOpReturnHex([Object[]]$txdata){
    
    $txnum = $txdata.count
    if ($txnum -eq 1){
        $tx = iex -Command "$getrawtransaction $txdata 1" | ConvertFrom-Json
        return $tx.vout | Where-Object {$_.scriptPubKey.asm -match 'OP_RETURN'} | ForEach-Object { $_.scriptPubKey.asm } | ForEach-Object { $_ -replace '^OP_RETURN\s*', '' }
    }
    $output = @(1..$txnum)
    foreach ($i in 0..($txnum-1)) {
        $txhash = $txdata[$i]
        $tx = iex -Command "$getrawtransaction $txhash 1" | ConvertFrom-Json
        $opreturn_data = $tx.vout | Where-Object { $_.scriptPubKey.asm -match 'OP_RETURN' } | ForEach-Object { $_.scriptPubKey.asm -replace '^OP_RETURN\s*', '' }
        $output[$i] = $opreturn_data
    }
    return $output
    
}

#Get-BlockOpReturnHex-FromHeight(144590)
#Get-BlockOpReturnHex-FromHeight(6265)

function hex-to-str([string]$hex){

    $standard = 1
    $arr = @(1..$hex.length)
    $arr_index = 0

    for ($i = 0; $i -lt $hex.Length; $i = $i + 2){
        $nib1 = $hex[$i] 
        $nib2 = $hex[($i + 1)]
        $byte = [system.convert]::ToInt16("$nib1$nib2", 16)
        
        if (($byte -ge 32) -and ($byte -lt 127)){
            $char = [char][byte]$byte
            $arr[$arr_index] = $char
            $arr_index++ 
        } else {
            $standard = 0
        }
           
    }

    if (($ALLOW_NONSTANDARD + $standard) -ne 0){ # $ALLOW_NONSTANDARD = 1 will force this to equal 1
        return [string]::join("", $arr[0..($arr_index - 1)])    
    } else { 
        return ""
    }
}

function hex-to-str-extended([string]$hex){

    $arr = @(1..$hex.length)
    $arr_index = 0

    for ($i = 0; $i -lt $hex.Length; $i = $i + 2){
        $nib1 = $hex[$i] 
        $nib2 = $hex[($i + 1)]
        $byte = [system.convert]::ToInt16("$nib1$nib2", 16)
        
        if ((($byte -ge 32) -and ($byte -lt 127)) -or (($byte -ge 128) -and ($byte -lt 256))){
            $char = [char][byte]$byte
            $arr[$arr_index] = $char
            $arr_index++ 
        }
           
    }

    if (($ALLOW_NONSTANDARD + $standard) -ne 0){ # $ALLOW_NONSTANDARD = 1 will force this to equal 1
        return [string]::join("", $arr[0..($arr_index - 1)])    
    } else { 
        return ""
    }
}



function hexarr-to-strarr([Object[]] $hexarr){

    $hexarr_count = $hexarr.count
    if ($hexarr_count -eq 1){
        [string] $hex = $hexarr
        if ($STANDARD_SETTING -eq 0){
            $strdata = hex-to-str($hex)
            if ($strdata -ne ""){
                $str_hex = $strdata
            }
        }
        if ($STANDARD_SETTING -eq 1){
            $strdata = hex-to-str-extended($hex)
            if ($strdata -ne ""){
                $str_hex = $strdata
            }
        }
        return $str_hex
        # [console]::Write("$str_hex")
    } else {
        $arr = @(1..$hexarr_count)
        $valid_index = 0
        if ($STANDARD_SETTING -eq 0){
            for ($i = 0; $i -lt $hexarr_count; $i++){
                [string] $hex = $hexarr[$i]
                $strdata = hex-to-str($hex)
                if ($strdata -ne ""){
                    $arr[$valid_index] = $strdata
                    $valid_index++  
                }
            }
        }
        if ($STANDARD_SETTING -eq 1){
            for ($i = 0; $i -lt $hexarr_count; $i++){
                [string] $hex = $hexarr[$i]
                $strdata = hex-to-str-extended($hex)
                if ($strdata -ne ""){
                    $arr[$valid_index] = $strdata
                    $valid_index++  
                }
            }
        }
        if ($valid_index -ne 0){
            return $arr[0..($valid_index - 1)]
        } else {
            return $null
        }
    }

}

function get-output-2d-object-str-mempool([int] $maxheight){
    
    $nextheight = $maxheight + 1
    $rawmempool_tx = get-rawmempool
    $rawmempool_tx_count = $rawmempool_tx.count

    if ($rawmempool_tx_count -ne 0){
        $nextblock_strarr = hexarr-to-strarr(Get-BlockOpReturnHex($rawmempool_tx))   # cannot index into null array - why? because mempool can be empty
    } else {
        $nextblock_strarr = $null
    }

    return @(@($nextheight, $nextblock_strarr))
}

function get-output-2d-object-str([int] $start_block, [int] $last_block){

    if($start_block -eq $last_block){
        $height = $start_block
        $strarr = hexarr-to-strarr(Get-BlockOpReturnHex-FromHeight($height))
        return @($height, $strarr)
    }

    $blocks = @($start_block..$last_block)
    $output = @($start_block..$last_block)
    $index = 0
    foreach ($block in $blocks){

        $height = $block
        $strarr = hexarr-to-strarr(Get-BlockOpReturnHex-FromHeight($height))

        $output[$index] = @($height, $strarr)
        $index++
    }
    return $output
}



function output-2d-object-str([Object[]] $2d_object){
    
    $output = ,$null * $2d_object_count

    # If the array is only @($height, $strarr), this will return 1
    # if it is a nested array it will return 2 since the first element is an array
    #
    # case with only 1 block
    $2d_object_count = $2d_object[0].Count  
    if ($2d_object_count -eq 1){
        $block_height = $2d_object[0]
        $block_data = $2d_object[1]

        $block_height_str = ([string] $block_height).PadLeft($BLOCKNUM_DIGITS, " ")
        if ($block_data -ne $null){
            $block_data_str = [system.string]::Join("`n" + " " * ($BLOCKNUM_DIGITS + 1) + "| ", $block_data)
            [console]::Write("$block_height_str | $block_data_str`n")
        } else {
            if ($SHOW_EMPTY_OR_INVALID_BLOCKS -eq 1){
                [console]::Write("$block_height_str |`n")
            }
        }
    } else {

        foreach ($block in $2d_object){
            $block_height = $block[0]
            $block_data = $block[1]

            $txcount = $block_data.count # case with only 1 tx in this block

            $block_height_str = ([string] $block_height).PadLeft($BLOCKNUM_DIGITS, " ")

            $txindex = 0
            
            
            if ($block_data -ne $null){
                $block_data_str = [system.string]::Join("`n" + " " * ($BLOCKNUM_DIGITS + 1) + "| ", $block_data)
                [console]::Write("$block_height_str | $block_data_str`n")
            } else {
                if ($SHOW_EMPTY_OR_INVALID_BLOCKS -eq 1){
                    [console]::Write("$block_height_str |`n")
                }
            }
            


            #$block_height_str.GetType()
            #$block_data_str.GetType()


        }
    }
    
}

function cursor-goto ([int] $x, [int] $y){
    [console]::SetCursorPosition($x, $y)
}

# "$esc[$offset_rows;$start_x`H"

$BLOCK_UPDATE_INTERVAL = 30 #block update interval in seconds
function main(){

    # indexing function?

    # return an array - to reuse indexed blocks when blocks are updated


    #
    if ($TESTNET -eq 1){
        [console]::Write("Network: Testnet`n")
    } else {
        [console]::Write("Network: Mainnet`n")
    }
    [console]::Write("Synchronising from $START_BLOCK to $LAST_BLOCK`n")

    $obj = get-output-2d-object-str($START_BLOCK)($LAST_BLOCK)
    output-2d-object-str($obj)


    $obj_mem = get-output-2d-object-str-mempool($LAST_BLOCK)
    output-2d-object-str($obj_mem)
    

    [console]::Write("Synchronisation complete.`n")

    
    
    $height_last_update = $LAST_BLOCK
    $height_current = $height_last_update

    #output-2d-object-str($obj)
    

    # timers
    $time = [System.Diagnostics.Stopwatch]::StartNew()
    $time_now = $time.elapsed.totalseconds
    $time_last_blockupdate = $time_now

    $loop = $true
    <#
    while ($loop){
        $time_now = $time.elapsed.totalseconds

        # check every $BLOCK_UPDATE_INTERVAL seconds
        if (($time_last_blockupdate + $BLOCK_UPDATE_INTERVAL) -lt $time_now){
            $height_current = iex -Command $getblockcount
            $time_last_blockupdate = $time.elapsed.totalseconds

            if ($height_current -ne $height_last_update){
                
                #update current height
                $height_current = $height_last_update
            }
        }

        
        start-sleep -Milliseconds 500
    }
    #>
    ferritext

    [console]::Write("Close and re-run to see updated changes.`n")
}

function hex([string] $text){return ([System.Text.Encoding]::UTF8.GetBytes($text) | ForEach-Object { $_.ToString("X2") }) -join ""}

function ferritext(){
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
    [console]::Write("Output:`n$sendrawtx_output`n------------------------------`nMessage sent. ")
}

main

########

 


start-sleep 5000















