import requests
import json
import time
import os
from requests.auth import HTTPBasicAuth
import tkinter as tk
from tkinter.scrolledtext import ScrolledText

"""
FEXT Python by koh-gt
Tested to work on the following Ferrite Core versions:
 
Recommended -- v3.2.0, v3.1.4, v4.0.0 (rev 0)
Compatible -- v3.1.3, v3.1.2, v3.1.1, v3.1.0, v3.0.1, v3.0.0 

A Python script to retrive and inscribe data on the Ferrite blockchain.

Run this script after launching Ferrite Core.
"""

# VARIABLES ------------------------------------------------------------
# Peer configuration for your Ferrite connection
rpc_user = "user"
rpc_password = "password"
rpc_host = "localhost"
# FEXT transmission settings
wallet_name = ""  # Specify your wallet name here - for FEXT sending use

# FEXT update settings
UPDATE_LOOP_INTERVAL_MS = 1000
DEFAULT_LAST_PROCESSED_BLOCK = 202000

# CONSTANTS ------------------------------------------------------------
# Peer parameters
rpc_port = 9573  # Default port for bitcoind
if wallet_name:
    url = f"http://{rpc_host}:{rpc_port}/wallet/{wallet_name}"
else:
    url = f"http://{rpc_host}:{rpc_port}"
# Filepath to store OP_RETURN data
data_file = "op_return_data.txt"
last_block_file = "last_processed_block.txt"
# File save/load format settings - Do not change
HEIGHT_HEADER_PAD_SIZE = 10 # pad size in previously gathered block data
#     123456: 606162636465
OP_RETURN_DELIMITER = ": "
LEN_OP_RETURN_DELIMITER = len(OP_RETURN_DELIMITER)


# Function to send JSON-RPC request

def rpc_request(method, params=None):
    headers = {'content-type': 'application/json'}
    payload = json.dumps({
        "method": method,
        "params": params or [],
        "jsonrpc": "2.0",
        "id": 1,
    })
    
    response = requests.post(url, data=payload, headers=headers, auth=HTTPBasicAuth(rpc_user, rpc_password))
    
    if response.status_code != 200:
        raise Exception(f"Error: {response.status_code}, {response.text}")
    
    return response.json()['result']

# Retrieve block hash for a given height
def get_block_hash(height):
    return rpc_request('getblockhash', [height])

# Retrieve OP_RETURN data from a given block
def get_op_return_data_from_block(block_hash):
    block = rpc_request('getblock', [block_hash])

    op_return_data = []

    # Skip blocks that have only the coinbase transaction
    if len(block['tx']) == 1:
        return op_return_data  # Skip the block if it only contains the coinbase transaction
    
    for txid in block['tx']:
        tx = rpc_request('getrawtransaction', [txid, True])  # Get full transaction details
        
        for vout in tx['vout']:
            script_pubkey = vout['scriptPubKey']
            
            # Look for OP_RETURN in the script
            if 'hex' in script_pubkey and script_pubkey['hex'].startswith("6a") and not script_pubkey['hex'].startswith("6a24aa21a9ed"):

                line = script_pubkey['hex']
                if not any(line.startswith(opcode) for opcode in ["6a4c", "6a4d", "6a4e"]):
                    op_return_data.append(line[4:])     # default length, next byte is message length
                elif line.startswith("6a4c"):
                    op_return_data.append(line[6:])     # 2 bytes for 6a4c and 1 byte for message length
                elif line.startswith("6a4d"):
                    op_return_data.append(line[8:])     # 1 bytes for 6a4d and 2 bytes for message length
                elif line.startswith("6a4e"):
                    op_return_data.append(line[12:])    # 2 bytes for 6a4e and 4 bytes for message length
    
    return op_return_data

# Function to read the last processed block height from file
def read_last_processed_block():
    if os.path.exists(last_block_file):
        with open(last_block_file, "r") as f:
            return int(f.read().strip())
    return DEFAULT_LAST_PROCESSED_BLOCK  # If no record found, start from block 0

# Function to save the last processed block height to file
def save_last_processed_block(block_height):
    with open(last_block_file, "w") as f:
        f.write(str(block_height))

# Function to save OP_RETURN data to the file
def save_op_return_data(block_height, op_return_data):
    with open(data_file, "a", encoding='utf-8') as f:  # Ensure file is encoded in UTF-8
        for data in op_return_data:
            f.write(f"{block_height:{HEIGHT_HEADER_PAD_SIZE}}{OP_RETURN_DELIMITER}{data}\n")  # Write decoded message

# Function to retrieve OP_RETURN data for all blocks starting from the last processed block
def process_new_blocks():
    last_processed_block = read_last_processed_block()
    block_count = rpc_request('getblockcount')
    
    new_op_return_data = []
    if block_count > last_processed_block:
        for height in range(last_processed_block + 1, block_count + 1):

            op_return_data = get_op_return_data_from_block(get_block_hash(height))
            
            if op_return_data:
                save_op_return_data(height, op_return_data)
                new_op_return_data.append((height, op_return_data))

                # Save the progress after OP_RETURN is found
                save_last_processed_block(height)

            if height % 100 == 0 or height == block_count:
                save_last_processed_block(height)

            print(height, op_return_data)

    return new_op_return_data

# Retrieve OP_RETURN data from the mempool
def get_op_return_data_from_mempool():
    mempool_txids = rpc_request('getrawmempool')
    op_return_data = []
    
    for txid in mempool_txids:
        tx = rpc_request('getrawtransaction', [txid, True])  # Get full transaction details
        
        for vout in tx['vout']:
            script_pubkey = vout['scriptPubKey']
            
            # Look for OP_RETURN in the script

            if 'hex' in script_pubkey and script_pubkey['hex'].startswith("6a") and not script_pubkey['hex'].startswith("6a24aa21a9ed"):

                line = script_pubkey['hex']
                if not any(line.startswith(opcode) for opcode in ["6a4c", "6a4d", "6a4e", "6a0100"]):  # 6a0100 is null byte OP_RETURN
                    op_return_data.append(line[4:])     # default length, next byte is message length
                elif line.startswith("6a4c"):
                    op_return_data.append(line[6:])     # 2 bytes for 6a4c and 1 byte for message length
                elif line.startswith("6a4d"):
                    op_return_data.append(line[8:])     # 1 bytes for 6a4d and 2 bytes for message length
                elif line.startswith("6a4e"):
                    op_return_data.append(line[12:])    # 2 bytes for 6a4e and 4 bytes for message length
    
    return op_return_data

# Function to convert hexadecimal OP_RETURN data to UTF-8
# Function to convert hexadecimal OP_RETURN data to ASCII
def hex_to_ascii(hex_string):
    try:
        bytes_object = bytes.fromhex(hex_string)
        ascii_string = bytes_object.decode("ascii", errors="replace")  # ASCII decoding
        # Check if the decoded string contains only ASCII characters
        return ascii_string if all(ord(c) < 128 for c in ascii_string) else "<Non-ASCII Character Found>"
    except ValueError:
        return "<Invalid HEX>"

# Function to convert an ASCII string to hex
def ascii_to_hex(ascii_string):
    if all(ord(c) < 128 for c in ascii_string):  # Ensure the string is ASCII
        return ascii_string.encode("ascii").hex()
    else:
        raise ValueError("Input string contains non-ASCII characters.")

# Function to load previously gathered OP_RETURN data on startup
def load_previous_data(text_widget, exclude_non_ascii, filter_string):
    text_widget.delete(1.0, tk.END)  # Clear previous mempool messages
    if os.path.exists(data_file):
        with open(data_file, "r", encoding='utf-8') as f:
            for line in f:
                
                op_return = line[HEIGHT_HEADER_PAD_SIZE + LEN_OP_RETURN_DELIMITER:]  # why 2?
                ascii_data = hex_to_ascii(op_return)
                if exclude_non_ascii and any((ord(c) >= 128 or ord(c) < 32) for c in ascii_data):
                    continue
                if filter_string and filter_string.lower() not in ascii_data.lower():
                    continue

                block_height = int(line[0:HEIGHT_HEADER_PAD_SIZE])
                text_widget.insert(tk.END, f"{block_height}{OP_RETURN_DELIMITER}{ascii_data}\n")
                print(f"{line}", end="")
        text_widget.yview(tk.END)  # Scroll to the bottom

# Function to update the GUI with new OP_RETURN messages from blocks
# filter_string doesnt work because it only filters the new blocks and lines, not the existing ones.
# unless a reload is done...
def update_gui_with_block_data(text_widget, new_data, exclude_non_ascii, filter_string):  
    for block_height, op_returns in new_data:
        for op_return in op_returns:
            ascii_data = hex_to_ascii(op_return)
            if exclude_non_ascii and any(ord(c) >= 128 for c in ascii_data):
                continue
            if filter_string and filter_string.lower() not in ascii_data.lower():
                continue
            text_widget.insert(tk.END, f"{block_height}{OP_RETURN_DELIMITER}{ascii_data}\n")
            text_widget.yview(tk.END)  # Scroll to the bottom

# Function to update the GUI with new OP_RETURN messages from the mempool
def update_gui_with_mempool_data(text_widget, op_returns, exclude_non_ascii, filter_string):
    text_widget.delete(1.0, tk.END)  # Clear previous mempool messages
    for op_return in op_returns:
        ascii_data = hex_to_ascii(op_return)
        if exclude_non_ascii and any(ord(c) >= 128 for c in ascii_data):
            continue
        if filter_string and filter_string.lower() not in ascii_data.lower():
            continue
        text_widget.insert(tk.END, f"Mempool: {ascii_data}\n")
        print(op_return, ascii_data)
        text_widget.yview(tk.END)  # Scroll to the bottom

# Function to send OP_RETURN message
def send_op_return_message(rpc_url, wallet_name, message):

    rpc_request('settxfee', [1])

    def message_to_hex(s):
        return s.encode('utf-8').hex()

    # Convert the message to hex (UTF-8 encoding)
    hex_message = message_to_hex(message)
    
    def hex_to_lil_endian(hex_string):
        # Convert hex string to integer
        decimal_value = int(hex_string, 16)
        # Calculate the number of bytes needed
        byte_length = (len(hex_string) + 1) // 2
        # Convert to big-endian byte sequence and then to a hexadecimal string
        lil_endian_hex = decimal_value.to_bytes(byte_length, byteorder='little').hex()
        return lil_endian_hex

    # 0200000000010000000000000000036a016100000000
    # 0200000000010000000000000000016a016100000000


    header = "0200000000010000000000000000"
    footer = "00000000"
    opreturn = "6a"
    i = len(hex_message) // 2
    msg_len_hex = f'{i:x}'  # int 125 -> str 7d

    if i < 76: # 4c - 6a
        len_indicator_prefix = ""
        msg_len_hex = f"{msg_len_hex:0>2}"
        total_len_hex_prefix = ""
    elif i < 250:
        len_indicator_prefix = "4c"  # OP_PUSHDATA1
        msg_len_hex = f"{msg_len_hex:0>2}"
        total_len_hex_prefix = ""
    elif i < 256:
        len_indicator_prefix = "4c"  # OP_PUSHDATA1
        msg_len_hex = f"{msg_len_hex:0>2}"
        total_len_hex_prefix = "fd"
    elif i < 65500:
        len_indicator_prefix = "4d"  # OP_PUSHDATA2
        msg_len_hex = hex_to_lil_endian(f"{msg_len_hex:0>4}")
        total_len_hex_prefix = "fd"
    else:
        return

    prefix = opreturn + len_indicator_prefix + msg_len_hex
    j = len(prefix) // 2

    if i < 250:
        total_len_hex = total_len_hex_prefix + f'{(i + j):x}'   # 2 : length and opreturn
        total_len_hex = f"{total_len_hex:0>2}"  #
    elif i < 65500:
        total_msg_len_hex = f'{(i + j):x}'
        total_msg_len_hex_padded = f"{total_msg_len_hex:0>4}"
        total_len_hex = total_len_hex_prefix + hex_to_lil_endian(total_msg_len_hex_padded)
        
    raw_tx = f"{header}{total_len_hex}{prefix}{hex_message}{footer}"
    
    print(raw_tx)
    
    # Fund raw transaction
    fundraw_tx = rpc_request('fundrawtransaction', [raw_tx])

    print(fundraw_tx)

    signraw_tx = rpc_request('signrawtransactionwithwallet', [fundraw_tx['hex']])

    print(signraw_tx)

    txid = rpc_request('sendrawtransaction', [signraw_tx['hex']])
    
    return txid

# Global variable to store the previous mempool data
previous_mempool_data = None

# Tkinter GUI Setup
def start_gui():
    root = tk.Tk()
    root.title("Ferritext for Ferrite Mainnet")

    # Create a frame for block messages
    block_frame = tk.Frame(root)
    block_frame.pack(pady=10, padx=10)

    tk.Label(block_frame, text="OP_RETURN Messages from Blocks:").pack()
    block_text_widget = ScrolledText(block_frame, wrap=tk.WORD, height=20, width=100)
    block_text_widget.pack()

    # Create a frame for mempool messages
    mempool_frame = tk.Frame(root)
    mempool_frame.pack(pady=10, padx=10)

    tk.Label(mempool_frame, text="OP_RETURN Messages from Mempool:").pack()
    mempool_text_widget = ScrolledText(mempool_frame, wrap=tk.WORD, height=10, width=100)
    mempool_text_widget.pack()

    # Input field for sending OP_RETURN messages
    input_frame = tk.Frame(root)
    input_frame.pack(pady=5)
    
    tk.Label(input_frame, text="Message:").pack(side=tk.LEFT, padx=5)
    message_entry = tk.Entry(input_frame, width=100)
    message_entry.pack(side=tk.LEFT, padx=5)
    
    # Send button
    def send_message():
        message = message_entry.get()
        if message:
            try:
                txid = send_op_return_message(url, wallet_name, message)
                block_text_widget.insert(tk.END, f"Sent message: {message} (TXID: {txid})\n")
                block_text_widget.yview(tk.END)  # Scroll to the bottom
                message_entry.delete(0, tk.END)  # Clear input field
            except Exception as e:
                block_text_widget.insert(tk.END, f"Error sending message: {e}\n")

    send_button = tk.Button(input_frame, text="Send", command=send_message)
    send_button.pack(side=tk.LEFT)

    # Checkboxes for filtering options
    filter_frame = tk.Frame(root)
    filter_frame.pack(pady=10)

    exclude_non_ascii_var = tk.BooleanVar()
    exclude_non_ascii_checkbox = tk.Checkbutton(filter_frame, text="Exclude Non-ASCII", variable=exclude_non_ascii_var)
    exclude_non_ascii_checkbox.pack(side=tk.LEFT)
    exclude_non_ascii_checkbox.select()
 

    filter_string_var = tk.StringVar()
    filter_string_entry = tk.Entry(filter_frame, textvariable=filter_string_var, width=20)
    filter_string_entry.pack(side=tk.LEFT, padx=5)
    filter_string_entry.insert(0, "")

    def apply_filters():
        load_previous_data(block_text_widget, exclude_non_ascii_var.get(), filter_string_var.get())
        # Get new mempool data and refresh
        mempool_data = get_op_return_data_from_mempool()
        update_gui_with_mempool_data(mempool_text_widget, mempool_data, exclude_non_ascii_var.get(), filter_string_var.get())


    filter_button = tk.Button(filter_frame, text="Apply Search Filters", command=apply_filters)
    filter_button.pack(side=tk.LEFT, padx=10)

    # Load previously gathered data
    load_previous_data(block_text_widget, exclude_non_ascii_var.get(), filter_string_var.get())

    # Start processing blocks and mempool in a loop
    def update_loop():

        global previous_mempool_data  # Access the global variable

        # if filter settings have changed -> wipe and reset all data

        # Get new block data (check for new blocks) -> add new block data
        new_block_data = process_new_blocks()
        if new_block_data:
            update_gui_with_block_data(block_text_widget, new_block_data, exclude_non_ascii_var.get(), filter_string_var.get())

        # Get new mempool data
        mempool_data = get_op_return_data_from_mempool()
        # Check if the new mempool data is different from the previous mempool data
        if mempool_data != previous_mempool_data:
            update_gui_with_mempool_data(mempool_text_widget, mempool_data, exclude_non_ascii_var.get(), filter_string_var.get())
            previous_mempool_data = mempool_data  # Update the previous mempool data
        
        # Schedule the next update loop
        root.after(UPDATE_LOOP_INTERVAL_MS, update_loop)  # Update every 1 second

    # Start the update loop
    update_loop()

    root.mainloop()

if __name__ == "__main__":
    start_gui()
