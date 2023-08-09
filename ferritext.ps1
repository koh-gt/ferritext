
#####
#
# FECWall by koh-gt
#
# Tested to work on the following Ferrite Core versions:
# 
# Recommended -- v3.1.2, v3.1.0, v3.0.1, v3.0.0
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
$INIT_BLOCKS_SHOW = 30

# 0 - blocks strings that contain non standard characters
# 1 - filters strings that contain non standard characters
$ALLOW_NONSTANDARD = 0   

# 1 - only characters 32 to 126 " !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~"

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

$TIMEOUT_ALERT = 15 # alert mode - loop checks every 1 ms
$TIMEOUT_ALERT_HYPER = 2



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

# ferritext explorer
function hex-to-str([string]$hexraw){
    
    $hex = $hexraw -replace '[^0-9a-fA-F]', ''

    $standard = 1
    $arr = @(1..$hex.length)
    $arr_index = 0

    for ($i = 0; $i -lt $hex.Length; $i = $i + 2){
        $nib1 = $hex[$i] 
        $nib2 = $hex[($i + 1)]
        $byte = [system.convert]::ToInt16("$nib1$nib2", 16)
        
        if (($byte -ge 32) -and ($byte -lt 127)){                 # only standard ASCII
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

function hexarr-to-strarr([Object[]] $hexarr){

    $hexarr_count = $hexarr.count
    if ($hexarr_count -eq 1){
        [string] $hex = $hexarr
        
        $strdata = hex-to-str($hex)
        if ($strdata -ne ""){
            $str_hex = $strdata
        }
        
        return $str_hex
        # [console]::Write("$str_hex")
    } else {
        $arr = @(1..$hexarr_count)
        $valid_index = 0
        
        for ($i = 0; $i -lt $hexarr_count; $i++){
            [string] $hex = $hexarr[$i]
            $strdata = hex-to-str($hex)
            if ($strdata -ne ""){
                $arr[$valid_index] = $strdata
                $valid_index++  
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

function cursor-return (){
    cursor-goto(0)(0)
}

function cursor-return-corner (){
    cursor-goto($WINDOW_WIDTH - 1)($WINDOW_HEIGHT - 1)
}

function cursor-hide (){
    $uisettings.CursorSize = 0 # hide cursor
}

function cursor-show (){
    $uisettings.CursorSize = 1 # hide cursor
}

# "$esc[$offset_rows;$start_x`H"

function delay ($time_now, $time_last_keyavailable){
    if (($time_last_keyavailable + $TIMEOUT_ALERT) -gt $time_now){
        if (($time_last_keyavailable + $TIMEOUT_ALERT_HYPER) -gt $time_now){
            
        } else {
            start-sleep -Milliseconds 1
        }
    } else {
        start-sleep -Milliseconds 10
    }
}

$SHOW_FULL_STRINGS = 1  # shows entire string even those longer than $WINDOW_WIDTH
function process-oversized-str($ui_obj_string_arr){   # in case strings are too long, they wrap around and take multiple lines

    [int] $lines = 0 
    $maxlinelength = $WINDOW_WIDTH - 1

    foreach ($tx_string in $ui_obj_string_arr){
        $strlength = $tx_string.length
        
        if ($strlength -gt $maxlinelength){
            $lines = $lines + [math]::Ceiling($strlength / $maxlinelength)
        } else {
            $lines++
        }
    }
    
    if ($lines -eq $ui_obj_string_arr.count){
        return $ui_obj_string_arr
    }

    $output_arr = ,$null * $lines
    $index = 0
    foreach ($tx_string in $ui_obj_string_arr){

        $strlength = $tx_string.length

        if ($strlength -gt $maxlinelength){
            $splitstrings_num = [math]::Ceiling($strlength / $maxlinelength)

            for ($i = 0; $i -lt $strlength; $i += $maxlinelength){
                $output_arr[$index] = $tx_string.Substring($i, [Math]::Min($maxlinelength, $strlength - $i))
                $index++
            }

        } else {
            $output_arr[$index] = $tx_string
            $index++
        }
    }

    return $output_arr

}

function output-main-format-str($ui_obj, $ui_obj_mem, [int] $INDEX, [int] $MAX_LINES){

    
    
    if ($MAX_LINES -eq 0){
        return
    }

    $ui = process-oversized-str($ui_obj + $ui_obj_mem)

    [int] $linecount = $ui.count

    $start_offset = $linecount - $MAX_LINES # starting lines truncated because of MAX_LINES

    if ($start_offset -lt 0){
        $start_offset = 0
    }
    if (($start_offset - $INDEX) -lt 0){
        # Error
        [console]::WriteLine("`nINVALID INDEX FOR OUTPUT STRING WINDOW`n")
        return
    }

    if ($linecount -gt $MAX_LINES){
        return $ui[($start_offset - $INDEX)..($linecount - $INDEX - 1)]
    } else {
        return $ui
    }

}

function indexchecker($ui_obj, $ui_obj_mem, [int] $INDEX, [int]$MAX_LINES){
    
    if ($INDEX -lt 0){             # 0 is the latest block
        return 0
    }

    $ui = process-oversized-str($ui_obj + $ui_obj_mem)
    $linecount = $ui.count

    if ($INDEX -gt ($linecount - $MAX_LINES)){
        if (($linecount - $MAX_LINES) -lt 0){       # no need to use different index since MAX_LINES is sufficient
            return 0
        } else {
            return $linecount - $MAX_LINES          # the earliest tx available
        }
    }
    
    return $INDEX
}

$update_output_wipe_line = " " * ($WINDOW_WIDTH - 1) + "`n"

function update-output-main-format-str($ui_obj, $ui_obj_mem, [int] $INDEX, [int] $MAX_LINES){
    
     # replace with a cursor wipe <----------------------------------- once main loop has no cls
    # WIP
    cursor-return
    $wipe_lines = $update_output_wipe_line * $MAX_LINES
    [console]::Write($wipe_lines)

    cursor-return
     ####
    #[console]::WriteLine("print out $INDEX")
    print-object(output-main-format-str($ui_obj)($ui_obj_mem)($INDEX)($MAX_LINES))
    
    
}

function hex([string] $text){return ([System.Text.Encoding]::UTF8.GetBytes($text) | ForEach-Object { $_.ToString("X2") }) -join ""}

$createrawtransaction = "$ferrite_cli createrawtransaction"
$fundrawtransaction = "$ferrite_cli -rpcwallet=$wallet_name fundrawtransaction"

function get-createrawtx-output([string] $messagedata){
    $data = hex($messagedata)    
    return iex -command ($createrawtransaction + ' "[]" "{""""""data"""""":""""""' + "$data" + '""""""}"')
}

function ferritext-send([string] $wallet_name, [string] $messagedata){
    
    # $messagedata = Read-Host "Input data here"
    $messagedata_length = $messagedata.Length

    $raw_tx_output = get-createrawtx-output($messagedata)

    $fundrawtx_output =  iex -command ("$fundrawtransaction $raw_tx_output")

    # -or ($_ -match '0\.[0-9]+')
    $fundrawtx_arr =  ($fundrawtx_output -split ":") -split ","

    $fundrawtx_hex, $fundrawtx_fee = $fundrawtx_arr | ForEach-Object {
        $hex = [regex]::Match($_, '[0-9a-f]{10,}').Value
        $fee = [regex]::Match($_, '[0-9]\.[0-9]{8}').Value
        if ($hex -or $fee) {
            [PSCustomObject]@{ Hex = $hex; Fee = $fee }
        }
    } | Select-Object -Property Hex, Fee | ForEach-Object { $_.Hex, $_.Fee }

    [console]::Write("`n`nLength: $messagedata_length char`nFee`nFEC $fundrawtx_fee`n`n")
    Read-Host "Press Enter to send this transaction..."


    $signrawtx_output = iex -Command ("$ferrite_cli -rpcwallet=$wallet_name signrawtransactionwithwallet $fundrawtx_hex")  
    $signrawtx_arr =  ($signrawtx_output -split ":") -split ","
    $signrawtx_hex = $signrawtx_arr |
            Where-Object { ($_ -match '[0-9a-f]{10,}') } |
            ForEach-Object {
                [regex]::Matches($_, '[0-9a-f]{10,}').Value
            }
    $sendrawtx_output = iex -Command ("$ferrite_cli -rpcwallet=$wallet_name sendrawtransaction $signrawtx_hex")  
    cls


}

function ferritext($textline, $index, $keypress_key, $keypress_keychar, [int] $enable_text){

    cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y)
    [console]::Write("Ferritext Input:")

    if ($enable_text -eq 0){
        $order = [int] $keypress_keychar
        if (($order -ge 32) -and ($order -lt 127)){
            cursor-goto($FERRITEXT_INPUT_OFFSET_X + $index)($FERRITEXT_INPUT_OFFSET_Y + 1)
            [console]::Write("$keypress_keychar")
            $textline[$index] = $keypress_keychar
            $index++

        }

        Switch ($keypress_key) {
            Backspace {
                if ($index -ne 0){
                    $index--
                }
                $textline[$index] = $null
                cursor-goto($FERRITEXT_INPUT_OFFSET_X + $index)($FERRITEXT_INPUT_OFFSET_Y + 1)
                [console]::WriteLine(" ")
            }
            Enter {
            #ferritext
                $output = ($textline -join "") -replace "`0", ''


                ferritext-send($wallet_name)($output)

                cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y + 1)
                [console]::Write((" " * $index))
                return (,$null * $FERRITEXT_LIMIT), 0
            }
        }
    }

    


    return $textline, $index

}

$FERRITEXT_LIMIT = 16000
$FERRITEXT_INPUT_OFFSET_Y = $MAX_DISPLAY_LINES_OUTPUT + 2
$FERRITEXT_INPUT_OFFSET_X = $BLOCKNUM_DIGITS + 3

$SELECTION_X = 0
$OLD_SELECTION_X = 0

function main(){

    # TODO: indexing function

    # return an array - to reuse indexed blocks when blocks are updated

    # store last indexed block number as text
    #

    #[console]::Write("Synchronising from $START_BLOCK to $LAST_BLOCK`n")

    # actual blocks
    $obj = get-output-2d-object-str($START_BLOCK)($LAST_BLOCK)
    $ui_obj = output-2d-object-str($obj)                             # contains multiple lines so that they can be retrieved

    # mempool only
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
    
    #textline
    [Char[]] $textline = ,$null * $FERRITEXT_LIMIT
    $textline_index = 0
    [console]::WriteLine("`nPress `` to chat.")

    # timers
    $time = [System.Diagnostics.Stopwatch]::StartNew()
    $time_now = $time.elapsed.totalseconds
    $time_last_blockupdate = $time_now
    $time_last_mempoolupdate = $time_now
    $time_last_keyavailable = $time_now

    $feature_enable = 0
    $disable_input = 0
    cursor-return-corner

    $loop = $true
    while ($loop){
        $time_now = $time.elapsed.totalseconds

        if ([console]::KeyAvailable) {

            $time_last_keyavailable = $time_now

            $keypress = [system.console]::ReadKey();
            $keypress_key = $keypress.key
            $keypress_keychar = $keypress.keychar
            Switch ($keypress_key){
                UpArrow {
                    $SELECTION_X++
                }
                DownArrow {
                    $SELECTION_X--
                }
                Escape {
                    if ($feature_enable -ne 0){
                        $feature_enable = 0       # exit
                        $feature_enable_change = $true
                    }
                }
                Oem3 {
                    if ($feature_enable -eq 0){
                        $feature_enable = 1       # enter into input
                        $disable_input = 1
                    } 
                }
            }
            
            
            $SELECTION_X = indexchecker($ui_obj)($ui_obj_mem)($SELECTION_X)($MAX_DISPLAY_LINES_OUTPUT)
            
            if ($SELECTION_X -ne $OLD_SELECTION_X){
                update-output-main-format-str($ui_obj)($ui_obj_mem)($SELECTION_X)($MAX_DISPLAY_LINES_OUTPUT)
                $OLD_SELECTION_X = $SELECTION_X
            } 

            if (($feature_enable -eq 0) -and $feature_enable_change){   # feature 0 Nothing
                cursor-goto(1)(($MAX_DISPLAY_LINES_OUTPUT + 1))
                [console]::Write("Press `` to chat.")
                $feature_enable_change = $false
            }
            if ($feature_enable -eq 1){   # feature 1 Ferritext - constantly updating input field async
                $textline, $textline_index = ferritext($textline)($textline_index)($keypress_key)($keypress_keychar)($disable_input)
            }

            if ($disable_input -ne 0){ # no double registering when ferritext is enabled
                $disable_input = 0     # re-enable input
            }

            cursor-return-corner
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

                # update mempool str array
                $new_added_obj_mem = get-output-2d-object-str-mempool($height_current)
                $ui_obj_mem = output-2d-object-str($new_added_obj_mem)

                # block recently updated
                if ($mempool_size -eq 0){
                    # update block height again to check - last update set to be outdated instantly
                    $time_last_blockupdate = $time_last_blockupdate - $BLOCK_UPDATE_INTERVAL
                    $mempool_last_size = 0

                    #[console]::WriteLine("blockupdate activated")
                } else {
                    $mempool_last_size = $mempool_size

                    # TODO update txt database
                    # update output
                    update-output-main-format-str($ui_obj)($ui_obj_mem)($SELECTION_X)($MAX_DISPLAY_LINES_OUTPUT)
                }
            }    
        }
        
        delay($time_now)($time_last_keyavailable)

    }
}

main

########

 


start-sleep 5000















