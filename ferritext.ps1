
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

$MAX_DISPLAY_LINES_OUTPUT = 20 # maximum number of lines of last seen messages

$BLOCK_UPDATE_INTERVAL = 10 #block update interval in seconds
$MEMPOOL_UPDATE_INTERVAL = 2 #block update interval in seconds



#####
#
# Chainparams
#
#####

# default update times
$BLOCK_TIME = 60

function get-block-update-interval($BLOCK_UPDATE_INTERVAL){
    if ($BLOCK_UPDATE_INTERVAL -gt $BLOCK_TIME){
        return $BLOCK_TIME
    }
    return $BLOCK_UPDATE_INTERVAL
}

function get-mempool-update-interval($BLOCK_UPDATE_INTERVAL, $MEMPOOL_UPDATE_INTERVAL){
    if ($BLOCK_UPDATE_INTERVAL -gt $BLOCK_TIME){
        $BLOCK_UPDATE_INTERVAL = $BLOCK_TIME
    }
    if ($MEMPOOL_UPDATE_INTERVAL -gt $BLOCK_UPDATE_INTERVAL){
        $MEMPOOL_UPDATE_INTERVAL = $BLOCK_UPDATE_INTERVAL
    }
    return $MEMPOOL_UPDATE_INTERVAL
}

$BLOCK_UPDATE_INTERVAL = get-block-update-interval($BLOCK_UPDATE_INTERVAL)
$MEMPOOL_UPDATE_INTERVAL = get-mempool-update-interval($BLOCK_UPDATE_INTERVAL)($MEMPOOL_UPDATE_INTERVAL)

#####
#
# debug functions
#
#####

function print-object([Object[]] $arr){
    foreach ($line in $arr){
        [console]::Write("$line`n")
    }
}

#####
#
# main functions
#
#####

# check for version
function get-networkinfo-subversion() {
    $networkinfo = iex -Command "$getnetworkinfo"
    $netinfo = $networkinfo | ConvertFrom-Json
    $netinfo.gettype()
    $version = $netinfo.version
    [console]::WriteLine($version)
}

# get mempool for unconfirmed transactions
function get-rawmempool(){
    $rawmempool = iex -Command "$getrawmempool" | ConvertFrom-Json
    return $rawmempool
}

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


function format-output-arr($block_height, $block_data){

    $spacer = " " * ($BLOCKNUM_DIGITS)
    $block_height_str = ([string] $block_height).PadLeft($BLOCKNUM_DIGITS, " ")
    $txindex = 0

    $block_data_count = $block_data.count
    $output_arr = ,$null * $block_data_count
    foreach ($tx in $block_data){
        if ($txindex -eq 0){
            #[console]::WriteLine("$block_height_str | $tx") 
            $output_arr[$txindex] = "$block_height_str | $tx"
            $txindex++
        } else {
            #[console]::WriteLine("$spacer | $tx")
            $output_arr[$txindex] = "$spacer | $tx"
            $txindex++
        }
    }
    return $output_arr
}

function get-total-tx-multiblock($2d_object){
    $total_lines = 0
    foreach ($block in $2d_object){
        $total_lines = $total_lines + $block[1].count
    }
    return $total_lines
}

function output-2d-object-str([Object[]] $2d_object){

    # If the array is only @($height, $strarr), this will return 1
    # if it is a nested array it will return 2 since the first element is an array
    #
    # case with only 1 block
    $2d_object_count = $2d_object[0].Count  
    if ($2d_object_count -eq 1){
        $block_height = $2d_object[0]
        $block_data = $2d_object[1]

        return format-output-arr($block_height)($block_data)

    } else {
        $total_lines = get-total-tx-multiblock($2d_object)
        $ui_arr = ,$null * $total_lines
        $line_index = 0

        foreach ($block in $2d_object){
            $block_height = $block[0]
            $block_data = $block[1]

            $block_output_arr = format-output-arr($block_height)($block_data)

            foreach ($line in $block_output_arr){
                $ui_arr[$line_index] = $line
                $line_index++
            }
        }
        return $ui_arr
    }
}

function cursor-goto ([int] $x, [int] $y){
    [console]::SetCursorPosition($x, $y)
}

# "$esc[$offset_rows;$start_x`H"

function output-main-format-str($ui_obj, $ui_obj_mem, [int] $INDEX, [int] $MAX_LINES){
    
    if ($MAX_LINES -eq 0){
        return
    }

    $output = ,$null * $MAX_LINES
    $output_index = 0

    $ui = $ui_obj + $ui_obj_mem
    [int] $txcount = $ui.count
    $start_offset = $txcount - $MAX_LINES # starting lines truncated because of MAX_LINES

    if ($start_offset -lt 0){
        $start_offset = 0
    }
    if ($start_offset - $INDEX -lt 0){
        # Error
        [console]::WriteLine("`nINVALID INDEX FOR OUTPUT STRING WINDOW`n")
        return
    }

    if ($txcount -gt $MAX_LINES){
        return $ui[($start_offset - $INDEX)..($txcount - $INDEX - 1)]
    } else {
        return $ui
    }

}

function indexchecker($ui_obj, $ui_obj_mem, [int] $INDEX, [int]$MAX_LINES){

    $txcount = $ui_obj.count + $ui_obj_mem.count

    if ($INDEX -lt 0){             # 0 is the latest block
        return 0
    }

    if ($INDEX -gt ($txcount - $MAX_LINES)){
        if (($txcount - $MAX_LINES) -lt 0){       # no need to use different index since MAX_LINES is sufficient
            return 0
        } else {
            return $txcount - $MAX_LINES          # the earliest tx available
        }
    }
    return $INDEX
}

function update-output-main-format-str($ui_obj, $ui_obj_mem, [int] $INDEX, [int] $MAX_LINES){

    $INDEX = indexchecker($ui_obj, $ui_obj_mem, $INDEX, $MAX_LINES)

    #cls
    print-object(output-main-format-str($ui_obj)($ui_obj_mem)($INDEX)($MAX_LINES))
    
}



function hex([string] $text){return ([System.Text.Encoding]::UTF8.GetBytes($text) | ForEach-Object { $_.ToString("X2") }) -join ""}

function ferritext-send([string]$wallet_name, [string] $op_return){
    
    $messagedata = $op_return
    $messagedata_length = $messagedata.Length
    $raw_tx_output = iex -command ("$ferrite_cli -rpcwallet=$wallet_name settxfee 0.1")
    $data = hex($messagedata)
    #[console]::Write("`n------------------------------`n`nConsole commands: `n`nInput: `ncreaterawtransaction $data")
    $raw_tx_output = iex -command ("$ferrite_cli -rpcwallet=$wallet_name createrawtransaction" + ' "[]" "{""""""data"""""":""""""' + "$data" + '""""""}"')
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

    #[console]::Write("`nMessage:`n`n$messagedata`n`nLength: $messagedata_length char`n`nThe network fee for sending this message is`nFEC $fundrawtx_fee`n`n")

    #[console]::Write("`n------------------------------`n`nConsole commands: `n`nInput: `nsignrawtransactionwithwallet $fundrawtx_hex")
    $signrawtx_output = iex -Command ("$ferrite_cli -rpcwallet=$wallet_name signrawtransactionwithwallet $fundrawtx_hex")  
    #[console]::Write("`nOutput:`n $signrawtx_output`n`n------------------------------`n")

    $signrawtx_arr =  ($signrawtx_output -split ":") -split ","
    $signrawtx_hex = $signrawtx_arr |
            Where-Object { ($_ -match '[0-9a-f]{10,}') } |
            ForEach-Object {
                [regex]::Matches($_, '[0-9a-f]{10,}').Value
            }

    #[console]::Write("`n------------------------------`n`nConsole commands: `n`nInput: `nsendrawtransactionwithwallet $signrawtx_mhex")
    $sendrawtx_output = iex -Command ("$ferrite_cli -rpcwallet=$wallet_name sendrawtransaction $signrawtx_hex")  
    #[console]::Write("`nOutput:`n$sendrawtx_output`n`n------------------------------`n")

}


$SELECTION_X = 0

function main(){

    # TODO: indexing function

    # return an array - to reuse indexed blocks when blocks are updated

    # store last indexed block number as text
    #

    #[console]::Write("Synchronising from $START_BLOCK to $LAST_BLOCK`n")

    $obj = get-output-2d-object-str($START_BLOCK)($LAST_BLOCK)
    $ui_obj = output-2d-object-str($obj)                             # contains multiple lines so that they can be retrieved

    $rawmempool = get-rawmempool
    $mempool_size = $rawmempool.count # zero when empty
    $mempool_last_size = $mempool_size
    $obj_mem = get-output-2d-object-str-mempool($LAST_BLOCK)
    $ui_obj_mem = output-2d-object-str($obj_mem)
    
    $output = output-main-format-str($ui_obj)($ui_obj_mem)($SELECTION_X)($MAX_DISPLAY_LINES_OUTPUT)
    print-object($output)

    #[console]::Write("Synchronisation complete.`n")

    $height_last_update = $LAST_BLOCK
    $height_current = $height_last_update

    #output-2d-object-str($obj)
    

    # timers
    $time = [System.Diagnostics.Stopwatch]::StartNew()
    $time_now = $time.elapsed.totalseconds
    $time_last_blockupdate = $time_now
    $time_last_mempoolupdate = $time_now

    $loop = $true

    [console]::WriteLine("`nPress enter to send a message...`n")
    while ($loop){
        $time_now = $time.elapsed.totalseconds

        if ([console]::KeyAvailable) {
            $keypress = [system.console]::ReadKey();
            Switch ($keypress.key){
                UpArrow {  #WIP
                    $SELECTION_X++
                }
                DownArrow {  #WIP
                    $SELECTION_X--
                }
                Enter {
                    $data = Read-Host("Message")
                    $cost = 10000 * ($data.length + 121) / 100000000
                    $response = Read-Host("Network fee is $cost FEC, 1 to confirm, 0 to cancel")
                    if ($response -eq 1){
                        ferritext-send($wallet_name)($data)
                    }
                }

            }
            $NEW_SELECTION_X = indexchecker($ui_obj)($ui_obj_mem)($INDEX)($MAX_LINES)
            if ($NEW_SELECTION_X -ne $SELECTION_X){
                update-output-main-format-str($ui_obj)($ui_obj_mem)($SELECTION_X)($MAX_DISPLAY_LINES_OUTPUT)
            }
            $SELECTION_X = $NEW_SELECTION_X

            [console]::WriteLine("`nPress enter to send a message...`n") #temp
               
        }

        # check every $BLOCK_UPDATE_INTERVAL seconds
        if (($time_last_blockupdate + $BLOCK_UPDATE_INTERVAL) -lt $time_now){
            #[console]::WriteLine("blockupdate")
            $height_current = iex -Command $getblockcount
            $time_last_blockupdate = $time.elapsed.totalseconds

            if ($height_current -ne $height_last_update){
                #[console]::WriteLine("new block found")
                #update current height
                $height_last_update = $height_current

                # update blocks str array
                $new_added_obj = get-output-2d-object-str($height_current)($height_current)
                $new_added_ui_obj = output-2d-object-str($new_added_obj)
                $ui_obj = $ui_obj + $new_added_ui_obj

                # TODO update txt database
                # update output
                update-output-main-format-str($ui_obj)($ui_obj_mem)($SELECTION_X)($MAX_DISPLAY_LINES_OUTPUT)
            }
        }

        # check every $MEMPOOL_UPDATE_INTERVAL seconds
        if (($time_last_mempoolupdate + $MEMPOOL_UPDATE_INTERVAL) -lt $time_now){
            #[console]::WriteLine("mempoolupdate")
            $rawmempool = get-rawmempool
            $mempool_size = $rawmempool.count

            $time_last_mempoolupdate = $time.elapsed.totalseconds

            # check mempool change
            if ($mempool_size -ne $mempool_last_size){
                # block recently updated
                if ($mempool_size -eq 0){
                    # update block height again to check - last update set to be outdated instantly
                    $time_last_blockupdate = $time_last_blockupdate - $BLOCK_UPDATE_INTERVAL
                    $mempool_last_size = 0
                    #[console]::WriteLine("blockupdate activated")
                } else {
                    $mempool_last_size = $mempool_size

                    # update mempool str array
                    $new_added_obj_mem = get-output-2d-object-str-mempool($height_current)
                    $ui_obj_mem = output-2d-object-str($new_added_obj_mem)

                    # TODO update txt database
                    # update output
                    update-output-main-format-str($ui_obj)($ui_obj_mem)($SELECTION_X)($MAX_DISPLAY_LINES_OUTPUT)
                }
            }    
        }        
        start-sleep -Milliseconds 10
    }
}

main

########

 


start-sleep 5000















