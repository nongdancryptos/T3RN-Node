#!/bin/bash
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ORANGE='\033[38;5;214m'
NC='\033[0m' # No Color

echo ">>============================================================<<"
echo "||      ██████╗ ███╗   ██╗    ████████╗ ██████╗ ██████╗       ||"
echo "||     ██╔═══██╗████╗  ██║    ╚══██╔══╝██╔═══██╗██╔══██╗      ||"
echo "||     ██║   ██║██╔██╗ ██║       ██║   ██║   ██║██████╔╝      ||"
echo "||     ██║   ██║██║╚██╗██║       ██║   ██║   ██║██╔═══╝       ||"
echo "||     ╚██████╔╝██║ ╚████║       ██║   ╚██████╔╝██║           ||"
echo "||      ╚═════╝ ╚═╝  ╚═══╝       ╚═╝    ╚═════╝ ╚═╝           ||"
echo ">>============================================================<<"

sleep 3

# Log file for debugging
LOG_FILE="setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to display usage instructions
usage() {
    echo -e "${GREEN}Usage: $0 [--verbose] [--dry-run]${NC}"
    echo -e "${GREEN}  --verbose: Enable verbose logging for debugging.${NC}"
    echo -e "${GREEN}  --dry-run: Simulate script execution without making changes.${NC}"
    exit 0
}

# Function to check and kill running executor process
kill_running_executor() {
    local pid
    pid=$(pgrep -f "./executor")

    if [ -n "$pid" ]; then
        if $DRY_RUN; then
            echo -e "${GREEN}[Dry-run] Would kill running executor process (PID: $pid)${NC}"
        else
            echo -e "${ORANGE}$MSG_KILLING_EXECUTOR${NC}"
            kill "$pid"
            sleep 2
            echo -e "${GREEN}$MSG_EXECUTOR_KILLED${NC}"
        fi
    else
        echo -e "${BLUE}$MSG_NO_EXECUTOR_RUNNING${NC}"
    fi
}

# Function to install jq if not present
install_jq_if_needed() {
    if ! command -v jq &>/dev/null; then
        echo -e "${ORANGE}$MSG_JQ_REQUIRED${NC}"
        
        # Detect OS and install jq
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y jq
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install jq  # macOS
        elif [[ "$OSTYPE" == "alpine"* ]]; then
            apk add jq      # Alpine Linux
        else
            echo -e "${RED}$MSG_JQ_INSTALL_FAILED${NC}"
            echo "Install jq manually: https://stedolan.github.io/jq/download/"
            exit 1
        fi

        # Verify installation
        if command -v jq &>/dev/null; then
            echo -e "${GREEN}$MSG_JQ_INSTALL_SUCCESS${NC}"
        else
            echo -e "${RED}$MSG_JQ_INSTALL_FAILED${NC}"
            exit 1
        fi
    fi
}

# Parse command-line arguments
VERBOSE=false
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --verbose)
            VERBOSE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown argument: $arg${NC}"
            usage
            ;;
    esac
done

# Install jq 
install_jq_if_needed

# Enable verbose mode if requested
if $VERBOSE; then
    set -x
fi

# Dry-run mode message
if $DRY_RUN; then
    echo -e "${ORANGE}Dry-run mode enabled. No changes will be made.${NC}"
	sleep 1
fi

# Function to ask for user input
ask_for_input() {
    local prompt="$1"
    local input

    read -p "$prompt: " input
    echo "$input"
}

# Language selection
while true; do
    # Define MSG_INVALID_LANG for all cases
    MSG_INVALID_LANG="Invalid language code. Please try again."
    echo -e "${GREEN}Select your language: English (en) or Vietnamese (vi):${NC}"
    echo -e "${ORANGE}English (en)${NC}"
    echo -e "${ORANGE}Vietnamese (vi)${NC}"
    read -p "Enter language code (e.g., en, vi): " LANG_CODE
    
	# Language-specific strings
    case "$LANG_CODE" in
        en)
            MSG_VERSION_CHOICE="Select version to install:"
            MSG_LATEST_OPTION="1) Latest version"
            MSG_SPECIFIC_OPTION="2) Specific version"
            MSG_ENTER_VERSION="Enter the version number you want to install (e.g., v0.51.0):"
            MSG_INVALID_VERSION_CHOICE="Invalid choice. Please enter 1 or 2"
            MSG_CLEANUP="Cleaning up previous installations..."
            MSG_DOWNLOAD="Downloading the latest release..."
            MSG_EXTRACT="Extracting the archive..."
            MSG_INVALID_INPUT="Invalid input. Please enter 'api' or 'rpc'."
            MSG_PRIVATE_KEY="Enter your wallet private key"
            MSG_GAS_VALUE="Enter the gas value (must be an integer between 100 and 20000)"
            MSG_INVALID_GAS="Error: Gas value must be between 100 and 20000."
            MSG_NODE_TYPE="Do you want to run an API node or RPC node? (api/rpc)"
            MSG_RPC_ENDPOINTS="Do you want to add custom public RPC endpoints? (y/n)"
            MSG_THANKS="If this script helped you, don't forget to give a ⭐ on GitHub 😉..."
            break
            ;;
        vi)
            MSG_VERSION_CHOICE="Chọn phiên bản để cài đặt:"
            MSG_LATEST_OPTION="1) Phiên bản mới nhất"
            MSG_SPECIFIC_OPTION="2) Phiên bản cụ thể"
            MSG_ENTER_VERSION="Nhập số phiên bản bạn muốn cài đặt (ví dụ: v0.51.0):"
            MSG_INVALID_VERSION_CHOICE="Lựa chọn không hợp lệ. Vui lòng nhập 1 hoặc 2"
            MSG_CLEANUP="Đang dọn dẹp các cài đặt trước..."
            MSG_DOWNLOAD="Đang tải bản phát hành mới nhất..."
            MSG_EXTRACT="Đang giải nén..."
            MSG_INVALID_INPUT="Dữ liệu không hợp lệ. Vui lòng nhập 'api' hoặc 'rpc'."
            MSG_PRIVATE_KEY="Nhập khóa riêng ví của bạn"
            MSG_GAS_VALUE="Nhập giá trị gas (phải là số nguyên từ 100 đến 20000)"
            MSG_INVALID_GAS="Lỗi: Giá trị gas phải nằm trong khoảng từ 100 đến 20000."
            MSG_NODE_TYPE="Bạn muốn chạy node API hay node RPC? (api/rpc)"
            MSG_RPC_ENDPOINTS="Bạn có muốn thêm điểm cuối RPC công cộng tùy chỉnh? (y/n)"
            MSG_THANKS="Nếu script này giúp bạn, đừng quên để lại ⭐ trên GitHub 😉..."
            break
            ;;
        *)
            echo -e "${RED}$MSG_INVALID_LANG${NC}"
            ;;
    esac
done

# Step 0: Clean up previous installations
echo -e "${GREEN}$MSG_CLEANUP${NC}"
if $DRY_RUN; then
    echo -e "${ORANGE}$MSG_DRY_RUN_DELETE${NC}"
	sleep 1
else
    if [ -d "t3rn" ]; then
        echo -e "${ORANGE}$MSG_DELETE_T3RN_DIR${NC}"
        rm -rf t3rn
    fi
	
	sleep 1

    if [ -d "executor" ]; then
        echo -e "${ORANGE}$MSG_DELETE_EXECUTOR_DIR${NC}"
        rm -rf executor
    fi
	
	sleep 1
	
    if ls executor-linux-*.tar.gz 1> /dev/null 2>&1; then
        echo -e "${ORANGE}$MSG_DELETE_TAR_GZ${NC}"
        rm -f executor-linux-*.tar.gz
    fi
	
	sleep 1
fi

# Step 1: Create and navigate to t3rn directory
echo -e "${ORANGE}$MSG_CREATE_DIR${NC}"
if $DRY_RUN; then
    echo -e "${GREEN}$MSG_DRY_RUN_CREATE_DIR${NC}"
else
    mkdir -p t3rn
    cd t3rn || { echo -e "${RED}$MSG_FAILED_CREATE_DIR${NC}"; exit 1; }
fi

# Step 2.5: Version selection
echo -e "${GREEN}${MSG_VERSION_CHOICE}${NC}"
echo -e " ${ORANGE}${MSG_LATEST_OPTION}${NC}"
echo -e " ${ORANGE}${MSG_SPECIFIC_OPTION}${NC}"

while true; do
    read -p "$(echo -e "${GREEN}${MSG_SELECT_NODE_TYPE}${NC}")" VERSION_CHOICE
    
    case $VERSION_CHOICE in
        1)
            LATEST_TAG=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
            [ -z "$LATEST_TAG" ] && { echo -e "${RED}$MSG_FAILED_FETCH_TAG${NC}"; exit 1; }
            break
            ;;
        2)
            while true; do
                echo -e "${GREEN}${MSG_ENTER_VERSION}${NC}"
                read LATEST_TAG
                [[ "$LATEST_TAG" =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] && break
                echo -e "${RED}${MSG_INVALID_VERSION_FORMAT}${NC}"
            done
            break
            ;;
        *)
            echo -e "${RED}${MSG_INVALID_VERSION_CHOICE}${NC}"
            ;;
    esac
done

# Step 0: Clean up previous installations
echo -e "${GREEN}$MSG_CLEANUP${NC}"
if $DRY_RUN; then
    echo -e "${ORANGE}$MSG_DRY_RUN_DELETE${NC}"
    sleep 1
else
    if [ -d "t3rn" ]; then
        echo -e "${ORANGE}$MSG_DELETE_T3RN_DIR${NC}"
        rm -rf t3rn
    fi

    sleep 1

    if [ -d "executor" ]; then
        echo -e "${ORANGE}$MSG_DELETE_EXECUTOR_DIR${NC}"
        rm -rf executor
    fi

    sleep 1

    if ls executor-linux-*.tar.gz 1> /dev/null 2>&1; then
        echo -e "${ORANGE}$MSG_DELETE_TAR_GZ${NC}"
        rm -f executor-linux-*.tar.gz
    fi

    sleep 1
fi

# Step 1: Create and navigate to t3rn directory
echo -e "${ORANGE}$MSG_CREATE_DIR${NC}"
if $DRY_RUN; then
    echo -e "${GREEN}$MSG_DRY_RUN_CREATE_DIR${NC}"
else
    mkdir -p t3rn
    cd t3rn || { echo -e "${RED}$MSG_FAILED_CREATE_DIR${NC}"; exit 1; }
fi

# Step 2.5: Version selection
echo -e "${GREEN}${MSG_VERSION_CHOICE}${NC}"
echo -e " ${ORANGE}${MSG_LATEST_OPTION}${NC}"
echo -e " ${ORANGE}${MSG_SPECIFIC_OPTION}${NC}"

while true; do
    read -p "$(echo -e "${GREEN}${MSG_SELECT_NODE_TYPE}${NC}")" VERSION_CHOICE

    case $VERSION_CHOICE in
        1)
            LATEST_TAG=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
            [ -z "$LATEST_TAG" ] && { echo -e "${RED}$MSG_FAILED_FETCH_TAG${NC}"; exit 1; }
            break
            ;;
        2)
            while true; do
                echo -e "${GREEN}${MSG_ENTER_VERSION}${NC}"
                read LATEST_TAG
                [[ "$LATEST_TAG" =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] && break
                echo -e "${RED}${MSG_INVALID_VERSION_FORMAT}${NC}"
            done
            break
            ;;
        *)
            echo -e "${RED}${MSG_INVALID_VERSION_CHOICE}${NC}"
            ;;
    esac
done

# Step 2: Download the latest release
DOWNLOAD_URL="https://github.com/t3rn/executor-release/releases/download/$LATEST_TAG/executor-linux-$LATEST_TAG.tar.gz"
wget --progress=bar:force:noscroll "$DOWNLOAD_URL" -O "executor-linux-$LATEST_TAG.tar.gz"
if [ $? -ne 0 ]; then
    echo "${RED}$MSG_FAILED_DOWNLOAD${NC}"
    sleep 2
    exit 1
fi
echo -e "${GREEN}$MSG_DOWNLOAD_COMPLETE${NC}"
sleep 1

# Step 3: Extract the archive
echo -e "${ORANGE}$MSG_EXTRACT${NC}"
tar -xvzf "executor-linux-$LATEST_TAG.tar.gz"
if [ $? -ne 0 ]; then
    echo -e "${RED}$MSG_FAILED_EXTRACT${NC}"
    sleep 2
    exit 1
fi

echo -e "${GREEN}$MSG_EXTRACTION_COMPLETE${NC}"
sleep 1

# Step 4: Navigate to the executor binary location
echo -e "${ORANGE}$MSG_NAVIGATE_BINARY${NC}"
if $DRY_RUN; then
    echo -e "${GREEN}$MSG_DRY_RUN_DELETE${NC}"
    sleep 1
else
    mkdir -p executor/executor/bin
    cd executor/executor/bin || { echo -e "${RED}$MSG_FAILED_NAVIGATE${NC}"; exit 1; }
    sleep 1
fi

# Ask if the user wants to run an API node or RPC node
echo -e "${GREEN}$MSG_NODE_TYPE_OPTIONS${NC}"
echo -e " ${ORANGE}${MSG_API_MODE}${NC}"
echo -e " ${ORANGE}${MSG_ALCHEMY_MODE}${NC}"
echo -e " ${ORANGE}${MSG_CUSTOM_MODE}${NC}"

while true; do
    read -p "$(echo -e "${GREEN}${MSG_SELECT_NODE_TYPE}${NC}")" NODE_TYPE_CHOICE

    case $NODE_TYPE_CHOICE in
        1)
            NODE_TYPE="api"
            echo -e "${GREEN}${MSG_API_MODE_DESC}${NC}"
            export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
            export EXECUTOR_PROCESS_ORDERS_API_ENABLED=true
            break
            ;;
        2)
            NODE_TYPE="alchemy-rpc"
            echo -e "${GREEN}${MSG_ALCHEMY_MODE_DESC}${NC}"
            export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
            export EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
            break
            ;;
        3)
            NODE_TYPE="custom-rpc"
            echo -e "${GREEN}${MSG_CUSTOM_MODE_DESC}${NC}"
            export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
            export EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
            break
            ;;
        *)
            echo -e "${RED}${MSG_INVALID_NODE_TYPE}${NC}"
            ;;
    esac
done

# Ask for wallet private key (masked input)
echo -e "${GREEN}$MSG_PRIVATE_KEY${NC}"
WALLET_PRIVATE_KEY=$(ask_for_input "")

# Ask for Alchemy API key (masked input, if RPC node is selected)
if [[ "$NODE_TYPE" == "alchemy-rpc" ]]; then
    echo -e "${GREEN}$MSG_ALCHEMY_API_KEY${NC}"
    ALCHEMY_API_KEY=$(ask_for_input "")
elif [[ "$NODE_TYPE" == "custom-rpc" ]]; then
    echo -e "${ORANGE}${MSG_CUSTOM_RPC_WARNING}${NC}"
    sleep 2
fi

# Ask for gas value and validate it
while true; do
    echo -e "${GREEN}$MSG_GAS_VALUE${NC} "
    read GAS_VALUE
    if [[ "$GAS_VALUE" =~ ^[0-9]+$ ]] && (( GAS_VALUE >= 100 && GAS_VALUE <= 20000 )); then
        break
    else
        echo -e "${RED}$MSG_INVALID_GAS${NC}"
    fi
done

# Configure RPC endpoints
configure_rpc_endpoints() {
    case $NODE_TYPE in
        "alchemy-rpc")
            echo -e "${GREEN}Merging Alchemy endpoints...${NC}"
            RPC_ENDPOINTS_JSON=$(echo "$RPC_ENDPOINTS_JSON" | jq \
                --arg arbt "https://arb-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
                --arg bast "https://base-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
                --arg opst "https://opt-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
                --arg blst "https://blast-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
                '.arbt += [$arbt] | .bast += [$bast] | .opst += [$opst] | .blst += [$blst]')
            ;;
        "custom-rpc")
            echo -e "${GREEN}Using custom RPC endpoints only...${NC}"
            RPC_ENDPOINTS_JSON=$(echo "$RPC_ENDPOINTS_JSON" | jq 'del(.arbt, .bast, .opst, .blst)')
            ;;
    esac
}

# Execute configuration
configure_rpc_endpoints

# Set Node Environment
export ENVIRONMENT=testnet

# Set log settings
export LOG_LEVEL=debug
export LOG_PRETTY=false

# Process bids, orders, and claims
export EXECUTOR_PROCESS_BIDS_ENABLED=true
export EXECUTOR_PROCESS_ORDERS_ENABLED=true
export EXECUTOR_PROCESS_CLAIMS_ENABLED=true

# Default RPC endpoints
DEFAULT_RPC_ENDPOINTS_JSON='{
  "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
  "arbt": ["https://arbitrum-sepolia.drpc.org"],
  "bast": ["https://base-sepolia-rpc.publicnode.com"],
  "blst": ["https://sepolia.blast.io"],
  "opst": ["https://sepolia.optimism.io"],
  "unit": ["https://unichain-sepolia.drpc.org"]
}'

# Initialize RPC_ENDPOINTS_JSON with defaults
RPC_ENDPOINTS_JSON="$DEFAULT_RPC_ENDPOINTS_JSON"

# Ask if the user wants to add custom RPC endpoints or use default ones
echo -e "${GREEN}$MSG_RPC_ENDPOINTS: ${NC}" 
read CUSTOM_RPC

if [[ "$CUSTOM_RPC" =~ ^[Yy]$ ]]; then
    echo -e "${ORANGE}$MSG_ENTER_CUSTOM_RPC${NC}"
    
    declare -A rpc_map=(
        ["arbt"]="Arbitrum Sepolia"
        ["bast"]="Base Sepolia"
        ["blst"]="Blast Sepolia"
        ["opst"]="Optimism Sepolia"
        ["unit"]="Unichain Sepolia"
        ["l2rn"]="L2RN"
    )

    RPC_ENDPOINTS_JSON="{"
    for network in "${!rpc_map[@]}"; do
        echo -e "${GREEN}Enter RPC endpoints for ${rpc_map[$network]} (comma-separated):${NC}"
        read -p "> " endpoints
        if [ -n "$endpoints" ]; then
            RPC_ENDPOINTS_JSON+="\"$network\": $(parse_rpc_input "$endpoints"),"
        else
            default_value=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -c ".$network")  # Fixed variable
            RPC_ENDPOINTS_JSON+="\"$network\": $default_value,"
        fi
    done
    RPC_ENDPOINTS_JSON="${RPC_ENDPOINTS_JSON%,}}"
else
    RPC_ENDPOINTS_JSON="$DEFAULT_RPC_ENDPOINTS_JSON"  # Fixed variable
fi


# Validate JSON structure
if ! jq empty <<< "$RPC_ENDPOINTS_JSON"; then
    echo -e "${RED}Invalid JSON. Using defaults.${NC}"
    RPC_ENDPOINTS_JSON="$DEFAULT_RPC_ENDPOINTS_JSON"
fi

# Minify JSON
export RPC_ENDPOINTS=$(echo "$RPC_ENDPOINTS_JSON" | jq -c .)

# Check and display the networks enabled
echo -e "${GREEN}$MSG_AVAILABLE_NETWORKS${NC}"
echo -e "${ORANGE}ARBT = arbitrum-sepolia${NC}"
echo -e "${ORANGE}BAST = base-sepolia${NC}"
echo -e "${ORANGE}BLST = blast-sepolia${NC}"
echo -e "${ORANGE}OPST = optimism-sepolia${NC}"
echo -e "${ORANGE}UNIT = unichain-sepolia${NC}"
echo -e "${RED}$MSG_L2RN_ALWAYS_ENABLED${NC}"

ENABLED_NETWORKS="l2rn"
while true; do
    read -p "$(echo -e "${GREEN}Enter networks to enable (comma-separated):\n[ARBT, BAST, BLST, OPST, UNIT] or 'all':${NC} ")" USER_NETWORKS
    if [[ -z "$USER_NETWORKS" || "$USER_NETWORKS" =~ ^[Aa][Ll][Ll]$ ]]; then
        ENABLED_NETWORKS="$ENABLED_NETWORKS,arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,unichain-sepolia"
        break
    else
        IFS=',' read -r -a networks <<< "$USER_NETWORKS"
        valid=true
        for network in "${networks[@]}"; do
            case "$network" in
                ARBT)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,arbitrum-sepolia"
                    ;;
                BAST)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,base-sepolia"
                    ;;
                BLST)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,blast-sepolia"
                    ;;
                OPST)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,optimism-sepolia"
                    ;;
                UNIT)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,unichain-sepolia"
                    ;;
                *)
                    echo -e "${RED}Invalid network: $network. Valid options: ARBT, BAST, BLST, OPST, UNIT${NC}"
                    valid=false
                    break
                    ;;
            esac
        done
        $valid && break
    fi
done
export ENABLED_NETWORKS

# Proceed with executor operation
echo -e "${GREEN}$MSG_THANKS${NC}"
sleep 3

if $DRY_RUN; then
    echo -e "${GREEN}$MSG_DRY_RUN_RUN_NODE${NC}"
else
    echo -e "\n${ORANGE}$MSG_CHECKING_EXECUTOR${NC}"
    kill_running_executor
    sleep 1

    echo -e "${BLUE}$MSG_RUNNING_NODE${NC}"
    ./executor
fi

