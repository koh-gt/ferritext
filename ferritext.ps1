#####
#
# FECWall by koh-gt
#
# Tested to work on the following Ferrite Core versions:
# 
# Recommended -- v3.1.2, v3.1.1, v3.1.0, v3.0.1, v3.0.0
# Deprecated -- v2.1.2, v2.1.1, v2.1.0, v2.0.0
#
# A Powershell script to search for text inscriptions on the Ferrite blockchain.
#
# Place this script in the same directory level as ferrite-cli.exe
#
#####

$ferrite_coin_splash = "
                      -:+*#%@@@@@@@@@@%#*+:-
                 .:*%@@@@@@@@@@@@@@@@@@@@@@@@%*:.
              -+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+-
           ':%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%:'
         ';@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;'
        +@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
      -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#-
     :@@@@@@@@@@@@@@@@@@@@@@@@@@@-.:#@@@@@@@@@@@@@@@@@@@@@@@:
    ;@@@@@@@@@@@@@@@@@@@@@@@@@@%-     :;%@@@@@@@@@@@@@@@@@@@@+
   +@@@@@@@@@@@@@@@@@@@@@@@@@@%.         .+#@@@@@@@@@@@@@@@@@@+
  -@@@@@@@@@@@@@@@@@@@@@@@@@@#     ;+-       :*%@@@@@@@@@@@@@@@-
  %@@@@@@@@@@@@@@@@@@@@@@@@@*    .#@@@@*:.     -@@@@@@@@@@@@@@@%
 +@@@@@@@@@@@@@@@@@@@@@@@@@;    .%@@@@@@@-    :@@@@@@@@@@@@@@@@@+
 #@@@@@@@@@@@@@@@@@@@@@@@@:    -@@@@@@@%-    +@@@@@@@@@@@@@@@@@@#
 @@@@@@@@@@%%%%%%%%%%%%%%-    :@@@@@@@%.    +%%%%%%%%%%@@@@@@@@@@
 @@@@@@@@@@                  +@@@@@@@#                 @@@@@@@@@@
 @@@@@@@@@@                 ;@@@@@@@*                  @@@@@@@@@@
 @@@@@@@@@@%%%%%%%%%%;     *@@@@@@@+    .#%%%%%%%%%%%%%@@@@@@@@@@
 #@@@@@@@@@@@@@@@@@@*    .#@@@@@@@:    -@@@@@@@@@@@@@@@@@@@@@@@@#
 +@@@@@@@@@@@@@@@@@+    .%@@@@@@@-    :@@@@@@@@@@@@@@@@@@@@@@@@@+
  %@@@@@@@@@@@@@@@:      :;%@@@%-    +@@@@@@@@@@@@@@@@@@@@@@@@@%
  -@@@@@@@@@@@@@@@@#:.      -+*.    ;@@@@@@@@@@@@@@@@@@@@@@@@@@-
   +@@@@@@@@@@@@@@@@@@%+-          #@@@@@@@@@@@@@@@@@@@@@@@@@@+
    +@@@@@@@@@@@@@@@@@@@@@*:.    .#@@@@@@@@@@@@@@@@@@@@@@@@@@;
     :@@@@@@@@@@@@@@@@@@@@@@@#+-.%@@@@@@@@@@@@@@@@@@@@@@@@@@:
      -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#-
        +@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
         ';@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;'
           ':%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%:'
              -+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+-
                 .:*%@@@@@@@@@@@@@@@@@@@@@@@@%*:.
                      -:+*#%@@@@@@@@@@%#*+:-
"

#####
#
# RPC parameters
#
#####

[string] $rpcuser = "user"
[string] $rpcpass = "password"
[string] $rpchost = "127.0.0.1"

$MAINNET_RPC_PORT = 9573
$TESTNET_RPC_PORT = 19573

#####
#
# Future
#
#####

[int] $UTF_ENABLE = 1
[int] $TESTNET = 0                        # leave as 1 for testnet


#####
#
# Text return parameters
#
#####

# load latest blocks at startup from cli (default 30) 
$INIT_BLOCKS_SHOW = 10 ##########################################

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
[string] $titlename = "Ferritext Wall -- FEXT ~ $height_window x $width_window"
$uisettings.WindowTitle = $titlename # apply window name title changes

#####
if ($TESTNET) {
    $COIN_SHORTHAND = "tFEC"  # for units
} else {
    $COIN_SHORTHAND = "FEC"  # for units  
}

# UTF-8 support for characters outside ASCII. 
# Experimental !
# (Mandarin, Spanish, Hindi, Arabic, Bengali, Portuguese, Russian, Japanese)
if ($UTF_ENABLE){
    [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
    [Console]::Writeline("你好，世界 | नमस्ते दुनिया | مرحبا بالعالم | ওহে বিশ্ব | Olá Mundo")
    [console]::Writeline("Привет, мир | こんにちは、世界 | ਹੈਲੋ ਵਰਲਡ | హలో వరల్డ్ | नमस्कार जग")
    [console]::Writeline("Xin chào thế giới | வணக்கம் உலகம் | 안녕하세요, 세계 | สวัสดีโลก | Γειά σας κόσμος")
    [console]::Writeline("မင်္ဂလာပါ | Привіт, світе | नमस्कार संसार | سلام نړی | سلام دنیا")

    # Hindi, Arabic fonts do not load in NSimSun
}


# Console codes
$esc = "$([char]27)"
$reset = "$esc[0m"
$highlight_white = "$esc[30;47m"
$red_text = "$esc[31;40m"
$green_text = "$esc[32;40m"

$SERVERCONN_TIMEOUT_MILLIS = 500
function test-ferrite-server-connection($rpchost, $port_test, $timeout) {
    $requestCallback = $state = $null
    $client = New-Object System.Net.Sockets.TcpClient
    $beginConnect = $client.BeginConnect($rpchost,$port_test,$requestCallback,$state)
    Start-Sleep -milli $timeout

    if ($client.Connected) { 
    $open = $true 
    } else { 
    $open = $false 
    }
    $client.Close()

    if ($open){
        [console]::Writeline("TCP test $rpchost port $port_test ($COIN_SHORTHAND)...$green_text`yes$reset")
    } else {
        [console]::Writeline("TCP test $rpchost port $port_test ($COIN_SHORTHAND)...$red_text no$reset")
    }
    return $open
}

function get-ferrite-server-status(){

    if ($testnet -eq 0){
        $port_test = $MAINNET_RPC_PORT
    } else {
        $port_test = $TESTNET_RPC_PORT
    }
    $ferrite_rpc_status = test-ferrite-server-connection($rpchost)($port_test)($SERVERCONN_TIMEOUT_MILLIS)

    if ($ferrite_rpc_status){
        [console]::Writeline("Connection test successful.")
    } else {
        [console]::Writeline("Connection cannot be made to $rpchost.")
        [console]::Writeline("$highlight_white`Check if Ferrite Core or ferrited is running.$reset")
        return $false
    }
    [console]::Writeline("Checking if process name is Ferrite Core.")

    $process_names = "ferrite-qt"
    $running = Get-Process | Where-Object { $_.ProcessName -like "*$process_names*" }

    if ($running.Count -gt 0) {
        $running | ForEach-Object {
            [console]::Write("Ferrite Core...")
            [console]::Write("$green_text`yes$reset ")
            [console]::WriteLine("Client: $($_.ProcessName) (PID: $($_.Id))")
        }
        return $true
    } else {
        [console]::Write("$red_text no$reset`n")
        [console]::WriteLine("$red_text Ferrite-qt is not running.$reset Filters:`"$process_names`"`nPlease run ferrite-qt or ferrited to use Ferritext.")
        return $false
    }

}

$ferrite_run_status = get-ferrite-server-status

if (-not $ferrite_run_status){
    start-sleep -seconds 5000
    break
}

############################################################################################################################################
#
# ferrite-cli searcher
#
############################################################################################################################################

$FERRITE_CLI_EXE = "ferrite-cli.exe"
$LATEST_VERSION_STR = "v3.1.2"
$LATEST_VNUM = 30102
$CUTOFF_VNUM = 30000

$SEARCH_TIMEOUT_SECONDS = 10

function ferrite-software-search($current_path, $ferrite_exe, $timeout){
    # Define the timeout (in seconds)

    # Start a background job to run Get-ChildItem
    $job = Start-Job -ScriptBlock {
        param (
            [string]$path,
            [string]$filename
        )
        Get-ChildItem -Path $path -Recurse -Include $filename
    } -ArgumentList $current_path, "$ferrite_exe"

    # Wait for the job to complete or timeout
    $jobCompleted = $job | Wait-Job -Timeout $timeout

    if ($jobCompleted) {
        # Job completed within the timeout
        $ferrite_cli_paths = Receive-Job -Job $job

        $output = @(1..$ferrite_cli_paths.count)
        $index = 0
        foreach ($filepath in $ferrite_cli_paths){
            $output[$index] = $filepath.FullName
            $index++
        }
        return $output

    } else {
        # Timeout reached
        Stop-Job -Job $job
        Remove-Job -Job $job
        [console]::Writeline("The operation exceeded the timeout of $timeoutSeconds seconds.`n$ferrite_exe cannot be found.")
    }
}

# version checker
function get-numversion($versionString) {
    # version XX.YY.ZZ.WW = 10000 * XX + 100 * YY + ZZ
    # Extract the version number part (X.Y.Z)
    $version_number = [regex]::Match($versionString, 'v(\d+\.\d+\.\d+)').Groups[1].Value
    $parts = $version_number -split '\.'
    $x = [int]$parts[0]
    $y = [int]$parts[1]
    $z = [int]$parts[2]
    $numericVersion = (10000 * $x) + (100 * $y) + $z
    return $numericVersion
}

function check-ferrite([string] $current_path){               # TODO Test for hardcoded C:\Program files ferrite-cli
    try {

        # Run the executable and capture the output
        $output = & $current_path -version

        # Display the captured output
        $num_version = get-numversion($output)

        return $num_version
    } catch [System.Management.Automation.CommandNotFoundException] {

        return $false  # no such command ferrite-cli
    } catch [System.Management.Automation.ItemNotFoundException] {

        return $false  # no such directory
    }
}

function start-check-version-ferrite($ver, $pathx){
    if ($ver) {
        [console]::Write("$pathx...$ver`n")
        if ($ver -ge $CUTOFF_VNUM){
            [console]::Writeline("Using ferrite-cli $ver from $pathx")
            return $true
        } else {
            return $false
        }
    } else {
        [console]::Write("$pathx...no`n")
        return $false
    }
}

function start-checks-cli(){
    
    [console]::Write("`n`nFerritext will search for the latest ferrite-cli`nLatest version: $LATEST_VERSION_STR ($LATEST_VNUM) Cutoff ($CUTOFF_VNUM)`n")
    [console]::Write("Checking for ferrite-cli in same directory...`n")
    $immediatev = check-ferrite("ferrite-cli.exe")
    if (start-check-version-ferrite($immediatev)("current path")){
        return "$CURRENT_PATH\ferrite-cli.exe"
    }
    
    $ferritefilepaths = @(
        "C:\Program Files\Ferrite\daemon\ferrite-cli.exe",                    # v3.1.2 and future
        "C:\Program Files\_Ferrite_Core\daemon\ferrite-cli.exe",
        "C:\Program Files\Ferrite\ferrite-cli.exe",
        "C:\Program Files\_Ferrite_Core\ferrite-cli.exe"
    )

    [console]::Write("Checking for ferrite-cli in default program file paths...`n")
    foreach ($path in $ferritefilepaths){
        $pathv = check-ferrite($path)
        if (start-check-version-ferrite($pathv)($path)){
            return $path
        }
    }

    [console]::Write("Performing deeper search for ferrite-cli in child directories...`n")
    $ferriteallpaths = ferrite-software-search($PWD.Path)($FERRITE_CLI_EXE)($SEARCH_TIMEOUT_SECONDS)
    foreach ($ferritepath in $ferriteallpaths){
        $ferritepathv = check-ferrite($ferritepath)
        if (start-check-version-ferrite($ferritepathv)($ferritepath)){
            return $ferritepath
        }
    }
    [console]::Write("No suitable ferrite-cli found.")
    return $false

} 

############################################################################################################################################

# get latest block height
[string] $CURRENT_PATH = $PWD.Path
$actual_path = start-checks-cli

$actual_path_directory = Split-Path -Path $actual_path -Parent

Set-location -Path "$actual_path_directory"

#####
# 
# Console commands
#
#####
if ($TESTNET){$testnet_arg = "-testnet"} else {$testnet_arg = ""}


# commands
[string] $ferrite_cli = ".\ferrite-cli -rpcconnect=`"$rpchost`" -rpcuser=`"$rpcuser`" -rpcpassword=`"$rpcpass`" $testnet_arg"
[string] $listwallets = "$ferrite_cli listwallets"

[string] $getblockcount = "$ferrite_cli getblockcount"
[string] $getblockhash = "$ferrite_cli getblockhash"
[string] $getblock = "$ferrite_cli getblock"
[string] $getrawtransaction = "$ferrite_cli getrawtransaction"
[string] $getnetworkinfo = "$ferrite_cli getnetworkinfo"
[string] $getrawmempool = "$ferrite_cli getrawmempool"

# wallet commands
[string] $listwallets = "$ferrite_cli listwallets"

# transaction creation
[string] $createrawtransaction = "$ferrite_cli createrawtransaction"

# blockchain variables
[string] $maxheight = iex -Command $getblockcount
[string] $genesishash = iex -Command "$getblockhash 0"

# initial synchronisation
$blocks_show = $INIT_BLOCKS_SHOW
$last_block = $maxheight
$START_BLOCK = $last_block - $blocks_show
$LINES_DISPLAY_SHOW = $WINDOW_HEIGHT - 10  # unused

$MAX_DISPLAY_LINES_OUTPUT = 20 # maximum number of lines of last seen messages
$WALLETINFO_LINES = 2 # number of lines for wallet information

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

function print-object-multiline([Object[]] $arr){
    $lines = $arr -join "`n"
    [console]::Write("$lines`n")
}


$LINE_CLEAR = " " * $WINDOW_WIDTH
function clear-lines([int]$lines){
    $LINES_CLEAR = "$LINE_CLEAR`n" * $lines
    [console]::Write($LINES_CLEAR)
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
    $version = $netinfo.version
    return $version
}

function get-message-fee-rate(){
    [long] $ferrite_core_version = get-networkinfo-subversion
    if ($ferrite_core_version -ge 3010200){
        return 10, 2
    } else {
        return 0.1, 4
    }
}

function get-skipblock-fee-rate([int] $height){
    [long] $ferrite_core_version = get-networkinfo-subversion
    if ($ferrite_core_version -ge 3010200){
        # can skip blocks
    } else {
        #
    }
}

# clear previous outputs from searching for ferrite-cli
[console]::Write("$ferrite_coin_splash")
[double] $MESSAGE_FEE_RATE, $DECIMAL_PRECISION = get-message-fee-rate
[double] $SKIPBLOCK_FEE_RATE = get-skipblock-fee-rate($maxheight)   # fee rate for pushing stuck blocks - expensive!

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

function get-tx-vout($tx){
    # gets the hex value of the opreturn from the vout of the getrawtransaction output
    return $tx.vout | Where-Object {$_.scriptPubKey.hex.StartsWith("6a")} | ForEach-Object {
            $scriptpubkey_hex = $_.scriptPubKey.hex
            $scriptpubkey_hex_substring = $scriptpubkey_hex.Substring(2, 2)
            if ($scriptpubkey_hex_substring -eq "4c") {
                $_.scriptPubKey.hex.Substring(6)
            } elseif ($scriptpubkey_hex_substring -eq "4d") {
                $_.scriptPubKey.hex.Substring(8)
            } elseif ($scriptpubkey_hex_substring -eq "4e") {
                $_.scriptPubKey.hex.Substring(12)
            } else {
                $_.scriptPubKey.hex.Substring(4)
            }
        }
}

# returns transaction data from transaction hashes
function Get-BlockOpReturnHex([Object[]]$txdata){
    
    $txnum = $txdata.count
    if ($txnum -eq 1){
        $tx = iex -Command "$getrawtransaction $txdata 1" | ConvertFrom-Json
        # return $tx.vout | Where-Object {$_.scriptPubKey.asm -match 'OP_RETURN'} | ForEach-Object { $_.scriptPubKey.asm } | ForEach-Object { $_ -replace '^OP_RETURN\s*', '' }
        $tx_vout = get-tx-vout($tx)

        return $tx_vout

    }
    $output = @(1..$txnum)
    foreach ($i in 0..($txnum-1)) {
        $txhash = $txdata[$i]
        $tx = iex -Command "$getrawtransaction $txhash 1" | ConvertFrom-Json
        $tx_vout = get-tx-vout($tx)

        $output[$i] = $tx_vout
    }
    return $output
    
}

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
            start-sleep -Milliseconds 10
        }
    } else {

        start-sleep -Milliseconds 20
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
    print-object-multiline(output-main-format-str($ui_obj)($ui_obj_mem)($INDEX)($MAX_LINES))
    
    cursor-return-corner
}

function get-wallet-list(){

    $wallet_list = iex -Command $listwallets | ConvertFrom-Json
    return $wallet_list

}

function set-txfee([string] $wallet_name){  
    $txfee_status = iex -Command "$ferrite_cli -rpcwallet=`"$wallet_name`" settxfee $MESSAGE_FEE_RATE"   # getwalletinfo has a variable wallet_name
    return $txfee_status
}

function get-wallet-info([string] $wallet_name){
    # returns wallet info in array form (converted from json) of a wallet name
    [string] $getwalletinfo = "$ferrite_cli -rpcwallet=`"$wallet_name`" getwalletinfo"   # getwalletinfo has a variable wallet_name
    $wallet_info = iex -Command $getwalletinfo | ConvertFrom-Json
    return $wallet_info
}

function get-wallet-balance($walletinfo){
    return "{0:F$DECIMAL_PRECISION}" -f  $walletinfo.balance
}

function generate-wallet-infoline($walletinfo){
    [double] $walletinfo_balance = $walletinfo.balance   # get balance in 
    [double] $walletinfo_unc_balance = $walletinfo.unconfirmed_balance
    [double] $walletinfo_imm_balance = $walletinfo.immature_balance

    $balance = "{0:F$DECIMAL_PRECISION}" -f $walletinfo_balance
    
    # highlight red if zero
    if ($walletinfo_balance -ne 0){
        [string] $balance_str = " | $balance"                 
    } else {
        [string] $balance_str = " | $red_text$balance$reset" 
    }

    if ($walletinfo_unc_balance -ne 0){
        $unc_balance = "{0:F$DECIMAL_PRECISION}" -f $walletinfo_unc_balance
        [string] $unc_balance_str = " + $unc_balance"
    } else {
        $unc_balance_str = ""
    }
    if ($walletinfo_imm_balance -ne 0){
        $imm_balance = "{0:F$DECIMAL_PRECISION}" -f $walletinfo_imm_balance
        [string] $imm_balance_str = " + $imm_balance"
    } else {
        $imm_balance_str = ""
    }

    return "$balance_str$unc_balance_str$imm_balance_str $COIN_SHORTHAND"
}

# ($wallet_select_index)($keypress_key)($keypress_keychar)($wallet_list)($disable_input)

function generate-wallet-output-line($walletname, $wallet_select_index, $longest, $offset_line_x){
    $walletinfo = get-wallet-info($walletname)  #wallet info
    $walletinfo_line = generate-wallet-infoline($walletinfo)         # the string after the wallet name

    if ($walletname -eq ""){
        $defaultname = "[default wallet]"
        $walletname_out = $defaultname.PadRight($longest)
    } else {
        $walletname_out = $walletname.PadRight($longest)
    }

    if ($i -eq $wallet_select_index){
        return "$offset_line_x$highlight_white$walletname_out$reset$walletinfo_line"
    } else {
        return "$offset_line_x$walletname_out$walletinfo_line"
    }
}

function display-select-wallet($wallet_select_index, $wallet_list){

    #show balance too!

    $offset_line_x = " " * $FERRITEXT_INPUT_OFFSET_X                   # spacing each line horizontal
    $wallet_list_count = $wallet_list.count
    $wallet_output_arr = ,$null * $wallet_list_count

    # find longest name, else use 16 letters of padding for [default wallet]
    $longest = 16  # [default wallet] has length 16 - used for wallets without name
    foreach ($wname in $wlist){
        $wname_length = $wname.length
        if ($wname_length -gt $longest){
            $longest = $wname_length
        }
    }

    if ($wallet_list_count -eq 1){
        $walletname = [string]$wallet_list
        $wallet_output_arr = generate-wallet-output-line($walletname)($wallet_select_index)($longest)($offset_line_x)
    } else {
        if ($wallet_list_count -ne 0){
            for ($i = 0; $i -lt $wallet_list_count; $i++){
                $walletname = $wallet_list[$i]
                $wallet_output_arr[$i] = generate-wallet-output-line($walletname)($wallet_select_index)($longest)($offset_line_x)
            }
        } else {
            $wallet_output_arr = ""
        }
    }
    cursor-goto(0)($FERRITEXT_INPUT_OFFSET_Y + $SEL_WALLET_OFFSET)
    print-object-multiline($wallet_output_arr)

}

function clean-select-wallet ([int] $lines, $key) {
    cursor-return-corner
    Switch ($key){Escape{cursor-goto(0)($FERRITEXT_INPUT_OFFSET_Y);[console]::WriteLine("uwu")}}   #escape deletes a char
    cursor-goto(0)($FERRITEXT_INPUT_OFFSET_Y)

    if ($lines -gt 0){
        clear-lines($lines + $SEL_WALLET_OFFSET)
    } else {
        clear-lines($SEL_WALLET_OFFSET)
    }
}

$SEL_WALLET_INSTRUCTIONS_OFFSET = 0
$SEL_WALLET_INFO_OFFSET = 1
$DISPLAY_MORE_WALLET_INFO_LINES = 2 # for function display-more-wallet-info

$SEL_WALLET_OFFSET = 4

function select-wallet-menu(){
    cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y + $SEL_WALLET_INSTRUCTIONS_OFFSET)
    [console]::Write("Wallet selection menu - Exit [Esc], Move [Arrow Up/Arrow Down], Select [Enter]")
}

function display-more-wallet-info($wallet_info){
    cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y + $SEL_WALLET_INFO_OFFSET)
    clear-lines($DISPLAY_MORE_WALLET_INFO_LINES)
    
    $walletname = $wallet_info.walletname
    $walletformat = $wallet_info.format
    $wallettxcount = $wallet_info.txcount
    $walletkeypoololdest = $wallet_info.keypoololdest

    $datetime_wallet = [System.DateTimeOffset]::FromUnixTimeSeconds($walletkeypoololdest).DateTime
    $formatted_datetime_wallet = $datetime_wallet.ToString("dddd, MMMM d, yyyy h:mm:ss tt")

    if ($walletname -eq ""){
        $name = "[default wallet]"
    } else {
        $name = $walletname
    }
    
    cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y + $SEL_WALLET_INFO_OFFSET)
    [console]::Write("$name | Transaction count: $wallettxcount")
    cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y + $SEL_WALLET_INFO_OFFSET + 1)
    [console]::Write("Created on $formatted_datetime_wallet.")
}

function select-wallet($wallet_select_index, $feature_enable, $keypress_key, $keypress_keychar, $wallet_list, $disable_input){

    $update = $false

    $cleanup_var = 0
    $selectwallet = 0

    if ($disable_input -eq 0){

        Switch ($keypress_key) {
            UpArrow {
                $wallet_select_index--
                $update = $true
            }
            DownArrow {
                $wallet_select_index++
                $update = $true
            }
            Enter {
                $wallet_name = $wallet_list[$wallet_select_index]
                $wallet_info = get-wallet-info($wallet_name)
                # selector cleared on exit
                $cleanup_var = 1
            }

            #cleanup
            {($_ -eq 'Escape') -or ($_ -eq 'F2')} {
                $cleanup_var = 1
            }

        }
    } else {
        $update = $true # first update when input is disabled
    }
    if ($wallet_select_index -lt 0){
        $wallet_select_index = 0
        $update = $false
    }
    $wallet_list_count = $wallet_list.count    
    if ($wallet_select_index -ge $wallet_list_count){
        $wallet_select_index = $wallet_list_count - 1
    }

    if ($update){
        display-select-wallet($wallet_select_index)($wallet_list)
        select-wallet-menu
        if ($wallet_list_count -ne 0){
            display-more-wallet-info(get-wallet-info($wallet_list[$wallet_select_index])) 
        }
    }
    
    if ($cleanup_var -eq 1){

        clean-select-wallet($wallet_list_count)($keypress_key) # if the key is Escape console should write additional char
        return $wallet_name, $wallet_info, $wallet_select_index, 0
    }
    # $wallet_name = $wallet_list[$wallet_select_index]
    #[console]::WriteLine($keypress_key)

    return $wallet_name, $wallet_info, $wallet_select_index, $feature_enable
}

function wallet-data-line($wallet_name, $wallet_info, $explorer_only){
    cursor-goto(0)($MAX_DISPLAY_LINES_OUTPUT)
    clear-lines($WALLETINFO_LINES)

    cursor-goto(0)($MAX_DISPLAY_LINES_OUTPUT)
    if ($explorer_only){
        [console]::Write("Chat $red_text[F1]$reset, Wallet Settings $red_text[F2]$reset $highlight_white Wallet not found - create new and relaunch FEXT $reset")
    } else {
        [console]::Write("Chat [F1], Wallet Settings [F2]")
    }
    
    if ($wallet_name -eq ""){
        $display_wallet_name = "[default wallet]"
    } else {
        $display_wallet_name = $wallet_name
    }
    
    $balance = get-wallet-balance($wallet_info)

    cursor-goto(0)($MAX_DISPLAY_LINES_OUTPUT + 1)
    [console]::Write("Selected wallet: $display_wallet_name | Balance: $balance $COIN_SHORTHAND")

}

function str-to-hex([string] $text){return ([System.Text.Encoding]::UTF8.GetBytes($text) | ForEach-Object { $_.ToString("X2") }) -join ""}
function get-createrawtx-output([string] $messagedata){
    $data = str-to-hex($messagedata)    
    return iex -command ($createrawtransaction + ' "[]" "{""""""data"""""":""""""' + "$data" + '""""""}"')
}

function ferritext-infoline([string] $info){
    cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y + $FERRITEXT_INFO_OFFSET)
    clear-lines(1)
    cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y + $FERRITEXT_INFO_OFFSET)
    [console]::Write($info)
}

function ferritext-menu(){
    cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y)
    [console]::Write("Ferritext - Exit [Esc], Send [Enter]")
    cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y + $FERRITEXT_INPUT_OFFSET)
    [console]::Write("Input:")
}

function ferritext-send([string] $wallet_name, $wallet_info, [string] $messagedata){

    ferritext-infoline("Processing...")
    $txfee_status = set-txfee($wallet_name)($MESSAGE_FEE_RATE)
    # $messagedata = Read-Host "Input data here"
    $messagedata_length = $messagedata.Length

    $raw_tx_output = get-createrawtx-output($messagedata)

    $fundrawtransaction = "$ferrite_cli -rpcwallet=`"$wallet_name`" fundrawtransaction"
    $fundrawtx_output =  iex -command "$fundrawtransaction $raw_tx_output" | ConvertFrom-Json
    $fundrawtx_hex, $fundrawtx_fee = $fundrawtx_output.hex, $fundrawtx_output.fee

    $rawtx_fee_atoms = [double] $fundrawtx_fee * 100000000
    $balance = get-wallet-balance($wallet_info)
    $balance_num_atoms = [double] $balance * 100000000

    if ($balance_num_atoms -ge $rawtx_fee_atoms){
        $signrawtx_output = iex -Command "$ferrite_cli -rpcwallet=`"$wallet_name`" signrawtransactionwithwallet $fundrawtx_hex" | ConvertFrom-Json 
        $signrawtx_hex = $signrawtx_output.hex

        $sendrawtx_output = iex -Command ("$ferrite_cli -rpcwallet=`"$wallet_name`" sendrawtransaction $signrawtx_hex") 

        ferritext-infoline("Transaction complete.")
    } else {
        ferritext-infoline("Insufficient funds.")
    }
}

$ASSUMED_BASE_FEE = 121  # empty opreturn tx 121 bytes

$FERRITEXT_INFO_OFFSET = 1
$FERRITEXT_INPUT_OFFSET = 2
$FERRITEXT_INPUT_TEXT_OFFSET = 3

function display-get-fee($index){
    [int] $fee_estimate_atoms = ($ASSUMED_BASE_FEE + $message_index) * 100000 * $MESSAGE_FEE_RATE
    $fee_estimate = $fee_estimate_atoms / 100000000
    $fee_str = "{0:F$DECIMAL_PRECISION}" -f $fee_estimate
    return $fee_str
}

function display-ferritext-fee-line($walletname, $walletinfo, $message_index){
    
    $fee_str = display-get-fee($index)

    $balance = get-wallet-balance($walletinfo)
    
    $balance_num = [double] $balance
    $fee_str_num = [double] $fee_str

    if ($balance_num -lt $fee_str){
        ferritext-infoline("Fee: $red_text$fee_str$reset $COIN_SHORTHAND")
    } else {
        ferritext-infoline("Fee: $fee_str $COIN_SHORTHAND")
    }
}

function ferritext($textline, $index, $feature_enable, $keypress_key, $keypress_keychar, [int] $disable_input, [string] $wallet_name, $wallet_info){
    
    if (-not $disable_input){
        $order = [int] $keypress_keychar
        if (($order -ge 32) -and ($order -lt 127)){
            cursor-goto($FERRITEXT_INPUT_OFFSET_X + $index)($FERRITEXT_INPUT_OFFSET_Y + $FERRITEXT_INPUT_TEXT_OFFSET)
            [console]::Write("$keypress_keychar")
            $textline[$index] = $keypress_keychar
            $index++
        }

        #special keys

        # add in wallet functions later.
        # what about delete?
        Switch ($keypress_key) {

            #cleanup
            {($_ -eq 'Escape') -or ($_ -eq 'F1')} {
                cursor-goto(0)($FERRITEXT_INPUT_OFFSET_Y)
                [console]::WriteLine("uwu")
                cursor-goto(0)($FERRITEXT_INPUT_OFFSET_Y)
                clear-lines(4 + [math]::Floor(($index + $FERRITEXT_INPUT_OFFSET_X) / $WINDOW_WIDTH) )
                $recently_cleared = $true
                return (,$null * $FERRITEXT_LIMIT), 0, 0
            }

            Backspace {
                if ($index -gt 0){
                    $index--
                }
                $textline[$index] = $null
                cursor-goto($FERRITEXT_INPUT_OFFSET_X + $index)($FERRITEXT_INPUT_OFFSET_Y + $FERRITEXT_INPUT_TEXT_OFFSET)
                [console]::WriteLine(" ")
            }

            Enter {
            #ferritext
                $output = ($textline -join "") -replace "`0", ''    # strip $null bytes from $FERRITEXT_LIMIT sized array

                if ($index -ne 0){
                    ferritext-send($wallet_name)($wallet_info)($output) #####   
                }

                cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y + $FERRITEXT_INPUT_TEXT_OFFSET)
                clear-lines(1 + [math]::Floor(($index + $FERRITEXT_INPUT_OFFSET_X) / $WINDOW_WIDTH) )

                # reset and clean info line
                cursor-goto($FERRITEXT_INPUT_OFFSET_X)($FERRITEXT_INPUT_OFFSET_Y + $FERRITEXT_INFO_OFFSET)
                clear-lines(1)
                display-ferritext-fee-line($wallet_name)($wallet_info)(0)   #display fee after index changes

                return (,$null * $FERRITEXT_LIMIT), 0, 1    # null array, index 0, feature enable 1
            }
        }
    } else {
        ferritext-menu
    }

    display-ferritext-fee-line($wallet_name)($wallet_info)($index)   #display fee after index changes

    return $textline, $index, $feature_enable

}


$SEL_PUSHBLOCK_OFFSET = 4

function display-select-pushblock($push_block_select_index, $push_block_fee, $pushblock_fixedfee_list){

    #show balance too!

    $offset_line_x = " " * $FERRITEXT_INPUT_OFFSET_X                   # spacing each line horizontal
    $pushblock_fixedfee_list_count = $pushblock_fixedfee_list.count
    $pushblock_output_arr = ,$null * ($pushblock_fixedfee_list_count + 1)

    $pushblock_output_arr[0] = "<- Send variable fee ($push_block_fee $COIN_SHORTHAND) ->"
    [console]::WriteLine("aaaaaaaaaaaaaaaaaaaaaaaaaa")
    foreach ($pushblock_fixedfee in $pushblock_fixedfee_list){

    }

    cursor-goto(0)($FERRITEXT_INPUT_OFFSET_Y + $SEL_PUSHBLOCK_OFFSET)
    print-object-multiline($pushblock_output_arr)

}

function push-block($push_block_select_index, $push_block_fee, $feature_enable, $keypress_key, $keypress_keychar, $disable_input, $wallet_name, $wallet_info){
    
    $update = $false

    $cleanup_var = 0

    if ($disable_input -eq 0){

        Switch ($keypress_key) {
            UpArrow {
                $push_block_select_index--
                $update = $true
            }
            DownArrow {
                $push_block_select_index++
                $update = $true
            }
            LeftArrow {
                if ($push_block_select_index -eq 0){   # free selection
                    $push_block_fee--
                    $update = $true
                }
            }
            RightArrow {
                if ($push_block_select_index -eq 0){   # free selection
                    $push_block_fee++
                    $update = $true
                }
            }
            Enter {
                #
                # send empty tx with fee
                #
                $cleanup_var = 1
            }

            #cleanup
            {($_ -eq 'Escape') -or ($_ -eq 'F5')} {
                $cleanup_var = 1
            }

        }
    } else {
        $update = $true # first update when input is disabled
    }

    if ($push_block_select_index -lt 0){
        $push_block_select_index = 0
        $update = $false
    }
    $pushblock_fixedfee_list = @(200,150,100,50)
    $pushblock_fixedfee_list_count = $pushblock_fixedfee_list.count    
    if ($push_block_select_index -ge $pushblock_fixedfee_list_count + 1){
        $push_block_select_index = $pushblock_fixedfee_list_count
    }

    if ($update){
        display-select-pushblock($push_block_select_index)($push_block_fee)($pushblock_fixedfee_list)
        
    }

    if ($cleanup_var -eq 1){

        return $push_block_select_index, $push_block_fee, 0
    }

    return $push_block_select_index, $push_block_fee, $feature_enable
}

$FERRITEXT_LIMIT = 16000
$FERRITEXT_INPUT_OFFSET_Y = $MAX_DISPLAY_LINES_OUTPUT + $WALLETINFO_LINES + 1
$FERRITEXT_INPUT_OFFSET_X = $BLOCKNUM_DIGITS + $WALLETINFO_LINES + 1

$SELECT_WALLET_OFFSET_Y = $MAX_DISPLAY_LINES_OUTPUT + $WALLETINFO_LINES + 1
$SELECT_WALLET_OFFSET_X = 3


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
    
    cls
    update-output-main-format-str($ui_obj)($ui_obj_mem)($SELECTION_X)($MAX_DISPLAY_LINES_OUTPUT)



    $height_last_update = $LAST_BLOCK
    $height_current = $height_last_update

    # ferritext - textline
    [Char[]] $textline = ,$null * $FERRITEXT_LIMIT
    $textline_index = 0

    

    # ferritext - wallet selection  
    $wallet_info = get-wallet-info($wallet_name)
    $wallet_list = get-wallet-list
                    # leave as "" for [default wallet] -- wallet.dat
    $wallet_list_startup_count = $wallet_list.count
    if ($wallet_list_startup_count -eq 0){ 
        #[console]::WriteLine("No wallets detected.`nFerritext Messenger requires $COIN_SHORTHAND to use`nEntering explorer-only mode.")
        $explorer_only = $true
    } else {
        [string] $wallet_name = $wallet_list[0]
        $explorer_only = $false
    }

    $wallet_select_index = 0
    # wallet data info
    wallet-data-line($wallet_name)($wallet_info)($explorer_only)

    # push block select index
    $push_block_fee = 300
    $push_block_select_index = 0

    # timers
    $time = [System.Diagnostics.Stopwatch]::StartNew()
    $time_now = $time.elapsed.totalseconds
    $time_last_blockupdate = $time_now
    $time_last_mempoolupdate = $time_now
    $time_last_keyavailable = $time_now

    $feature_enable = 0
    $disable_input = 0
    $clean_feature = $false
    cursor-return-corner

    $loop = $true
    while ($loop){
        $time_now = $time.elapsed.totalseconds

        if ([console]::KeyAvailable) {

            $time_last_keyavailable = $time_now

            $keypress = [system.console]::ReadKey();
            $keypress_key = $keypress.key
            $keypress_keychar = $keypress.keychar

            if (($feature_enable -eq 0) -and (-not $explorer_only)){
                Switch ($keypress_key){
                    F1 {
                            $feature_enable = 1       # enter into input
                            $disable_input = $true
                            # check fees, balance
                    }
                    F2 {                        # enter into wallet selection
                            $feature_enable = 2
                            $disable_input = $true
                    }
                    F5 {                        # push-block
                            $feature_enable = 5
                            $disable_input = $true
                    }
                }
            }
            if (($feature_enable -eq 0) -or ($feature_enable -eq 1)){
                Switch ($keypress_key){
                    UpArrow {
                            $SELECTION_X++
                    }
                    DownArrow {
                            $SELECTION_X--
                    }
                }
            }
             
            $SELECTION_X = indexchecker($ui_obj)($ui_obj_mem)($SELECTION_X)($MAX_DISPLAY_LINES_OUTPUT)
            
            if ($SELECTION_X -ne $OLD_SELECTION_X){
                update-output-main-format-str($ui_obj)($ui_obj_mem)($SELECTION_X)($MAX_DISPLAY_LINES_OUTPUT)
                $OLD_SELECTION_X = $SELECTION_X
            } 
     
            if ($feature_enable -eq 1){   # feature 1 Ferritext - constantly updating input field async
                $textline, $textline_index, $feature_enable = ferritext($textline)($textline_index)($feature_enable)($keypress_key)($keypress_keychar)($disable_input)($wallet_name)($wallet_info)
            }
            if ($feature_enable -eq 2){   # feature 2 wallet selector - constantly updating input field async
                $wallet_name, $wallet_info, $wallet_select_index, $feature_enable = select-wallet($wallet_select_index)($feature_enable)($keypress_key)($keypress_keychar)($wallet_list)($disable_input)
            }
            if ($feature_enable -eq 5){   # feature 5 block "pusher" - adds fees to subsidy - constantly updating input field async
                $push_block_select_index, $push_block_fee, $feature_enable = push-block($push_block_select_index)($push_block_fee)($feature_enable)($keypress_key)($keypress_keychar)($disable_input)($wallet_name)($wallet_info)
            }

            # back to menu
            if ($feature_enable -eq 0){
                wallet-data-line($wallet_name)($wallet_info)($explorer_only)
            }
            
            if ($disable_input){ # no double registering when ferritext is enabled
                $disable_input = $false    # re-enable input
            }

            # exit all if Esc
            if ($feature_enable -ne 0){
                Switch ($keypress_key){
                    Escape {                 
                            $feature_enable = 0       # exit only if not in feature_enable 0 (menu)
                    }    
                }
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

                $new_added_obj_mem = get-output-2d-object-str-mempool($height_current)  # instantly update mempool
                $ui_obj_mem = output-2d-object-str($new_added_obj_mem)                  #

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

                # block recently updated - activates blockupdate, which then updates the empty mempool status
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

if ($actual_path -and $ferrite_run_status){
    main  #TODO - do not start if ferrite-cli not found, or if ferrite-qt not found
}

########

start-sleep 5000

