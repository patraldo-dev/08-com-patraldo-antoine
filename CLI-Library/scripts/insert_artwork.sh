#!/bin/bash

# Function to source environment variables from .env file
load_env_vars() {
    local env_file=""
    # Determine parent directory of current working directory
    local LIB_ROOT="$(dirname "$PWD")"
    # Determine directory where this script resides, resolving symlinks
    local SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Search priority:
    # 1. Current directory
    # 2. Library root (parent of current working directory)
    # 3. Script's directory
    # 4. User's home directory

    if [ -f ".env" ]; then
        env_file=".env"
    elif [ -f "$LIB_ROOT/.env" ]; then
        env_file="$LIB_ROOT/.env"
    elif [ -f "$SCRIPTS_DIR/.env" ]; then
        env_file="$SCRIPTS_DIR/.env"
    elif [ -f "$HOME/.env.cli-library" ]; then
        env_file="$HOME/.env.cli-library"
    fi

    if [ -n "$env_file" ]; then
        echo "Loading environment variables from: $env_file"
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ $line =~ ^[^#]*= ]] && [[ -n "$line" ]]; then
                export "$line"
            fi
        done < "$env_file"
    else
        echo "Warning: No .env file found in current dir, $LIB_ROOT, $SCRIPTS_DIR, or $HOME"
    fi
}

# Function to check if required tools are available
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed."
        echo "Install it with: sudo apt install jq (on Ubuntu/Debian) or brew install jq (on macOS)"
        return 1
    fi
    
    if ! command -v npx &> /dev/null; then
        echo "Error: npx is required but not found. Make sure Node.js is installed."
        return 1
    fi
    return 0
}

# Function to get image metadata from Cloudflare Images API
get_cloudflare_image_info() {
    local image_id="$1"
    local account_id="${ACCOUNT_ID:-$CLOUDFLARE_ACCOUNT_ID}"
    local api_token="${API_TOKEN:-$CLOUDFLARE_API_TOKEN}"
    
    if [ -z "$account_id" ] || [ -z "$api_token" ]; then
        echo "ERROR: Missing Cloudflare credentials. Please set ACCOUNT_ID and API_TOKEN in your .env file." >&2
        return 1
    fi
    
    # Send debug output to stderr so it displays but doesn't get captured
    echo "DEBUG: Using account ID: $account_id" >&2
    echo "DEBUG: Using image ID: $image_id" >&2
    echo "DEBUG: Token length: ${#api_token} characters" >&2
    
    local url="https://api.cloudflare.com/client/v4/accounts/$account_id/images/v1/$image_id"
    echo "DEBUG: URL: $url" >&2
    
    # Fetch image info from Cloudflare Images API
    response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -H "Authorization: Bearer $api_token" \
        "$url")
    
    # Extract HTTP status code
    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_STATUS:/d')
    
    echo "DEBUG: HTTP Status: $http_status" >&2
    echo "DEBUG: Response body (first 500 chars):" >&2
    echo "$response_body" | head -c 500 >&2
    echo "" >&2
    
    # Check if response is valid JSON
    if ! echo "$response_body" | jq empty 2>/dev/null; then
        echo "ERROR: Response is not valid JSON" >&2
        return 1
    fi
    
    # Check success field
    success=$(echo "$response_body" | jq -r '.success // false')
    echo "DEBUG: Success field: $success" >&2
    
    if [ "$success" = "true" ]; then
        filename=$(echo "$response_body" | jq -r '.result.filename // empty' 2>/dev/null)
        width=$(echo "$response_body" | jq -r '.result.meta.width // .result.width // empty' 2>/dev/null)
        height=$(echo "$response_body" | jq -r '.result.meta.height // .result.height // empty' 2>/dev/null)
        
        echo "DEBUG: Extracted filename: $filename" >&2
        
        if [ -n "$filename" ]; then
            title=$(basename "$filename" | sed 's/\.[^.]*$//')
            echo "TITLE:$title|FILENAME:$filename|WIDTH:$width|HEIGHT:$height"
            return 0
        else
            echo "TITLE:|FILENAME:|WIDTH:|HEIGHT:"
            return 0
        fi
    else
        error_msg=$(echo "$response_body" | jq -r '.errors[0].message // "Unknown error"')
        error_code=$(echo "$response_body" | jq -r '.errors[0].code // "Unknown code"')
        echo "ERROR: API returned failure. Code: $error_code, Message: $error_msg" >&2
        return 1
    fi
}


# Function to prompt for input with default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        if [ -z "$input" ]; then
            declare -g "$var_name=$default"
        else
            declare -g "$var_name=$input"
        fi
    else
        read -p "$prompt: " input
        declare -g "$var_name=$input"
    fi
}

# Main script
echo "=== Artwork Database Entry Script with Cloudflare Integration ==="
echo ""

# Check dependencies
if ! check_dependencies; then
    exit 1
fi

# Load environment variables
load_env_vars

# Ask if user wants to fetch from Cloudflare
read -p "Do you want to fetch image info from Cloudflare? (y/N): " fetch_cloudflare

if [[ $fetch_cloudflare =~ ^[Yy]$ ]]; then
    read -p "Enter Image ID: " image_id
    
    echo "Fetching image information..."
    api_response=$(get_cloudflare_image_info "$image_id")
    
    if [ $? -eq 0 ]; then
        if echo "$api_response" | grep -q "^ERROR:"; then
            error_msg=$(echo "$api_response" | sed 's/^ERROR://')
            echo "Error fetching image info: $error_msg"
            read -p "Enter Title: " title
        else
            title=$(echo "$api_response" | grep -o 'TITLE:[^|]*' | cut -d':' -f2)
            filename=$(echo "$api_response" | grep -o 'FILENAME:[^|]*' | cut -d':' -f2)
            width=$(echo "$api_response" | grep -o 'WIDTH:[^|]*' | cut -d':' -f2)
            height=$(echo "$api_response" | grep -o 'HEIGHT:[^|]*' | cut -d':' -f2)
            
            if [ -n "$title" ]; then
                echo "Successfully fetched title: $title"
                [ -n "$filename" ] && echo "Original filename: $filename"
                [ -n "$width" ] && [ -n "$height" ] && echo "Image dimensions: ${width}x${height}"
            else
                echo "Could not fetch title from Cloudflare. Please enter manually."
                read -p "Enter Title: " title
            fi
        fi
    else
        echo "Could not fetch image info. Please enter manually."
        read -p "Enter Title: " title
    fi
else
    read -p "Image ID: " image_id
    read -p "Title: " title
fi

# Set up default values
display_name="$title"

case "${LANG%_*}" in
  es) description="Subido el $(date +%Y-%m-%d). Nombre: ${title}.jpg" ;;
  fr) description="Téléchargé le $(date +%Y-%m-%d). Nom: ${title}.jpg" ;;
  *)       description="Uploaded on $(date +%Y-%m-%d). Filename: ${title}.jpg" ;;
esac

year=$(date +%Y)

# Rest of the script continues as before...
prompt_with_default "Display Name (user-friendly name shown in UI)" "$display_name" display_name
prompt_with_default "Video ID (from Cloudflare Stream, optional)" "" video_id
prompt_with_default "Description" "$description" description
prompt_with_default "Year" "$year" year

echo ""
echo "Select type:"
echo "1) still"
echo "2) animation" 
echo "3) gif"
read -p "Enter choice (1-3) [1]: " type_choice
case $type_choice in
    2) type="animation" ;;
    3) type="gif" ;;
    *) type="still" ;;
esac

echo ""
echo "Featured? (1 for Yes, 0 for No) [0]:"
read -p "(default 0): " featured_input
featured=${featured_input:-0}

echo ""
echo "Published? (1 for Yes, 0 for No) [1]:"
read -p "(default 1): " published_input
published=${published_input:-1}

echo ""
read -p "Order Index (number for sorting, default 999): " order_index_input
order_index=${order_index_input:-999}

echo ""
echo "Story Enabled? (1 for Yes, 0 for No) [0]:"
read -p "(default 0): " story_enabled_input
story_enabled=${story_enabled_input:-0}

echo ""
read -p "Story Intro (optional, press Enter to skip): " story_intro

# Build the SQL command
sql_command="INSERT INTO artworks (title, display_name, type, image_id, video_id, description, year, featured, published, order_index, story_enabled, story_intro) VALUES ("

# Escape single quotes in strings for SQL
title_escaped=$(printf '%s\n' "$title" | sed "s/'/''/g")
display_name_escaped=$(printf '%s\n' "$display_name" | sed "s/'/''/g")
description_escaped=$(printf '%s\n' "$description" | sed "s/'/''/g")
story_intro_escaped=$(printf '%s\n' "$story_intro" | sed "s/'/''/g")

sql_command+="'$title_escaped', "
sql_command+="'$display_name_escaped', "
sql_command+="'$type', "
sql_command+="'$image_id', "

if [ -n "$video_id" ]; then
    sql_command+="'$video_id', "
else
    sql_command+="NULL, "
fi

sql_command+="'$description_escaped', "
sql_command+="$year, "
sql_command+="$featured, "
sql_command+="$published, "
sql_command+="$order_index, "
sql_command+="$story_enabled, "

if [ -n "$story_intro" ]; then
    sql_command+="'$story_intro_escaped'"
else
    sql_command+="NULL"
fi

sql_command+=");"

# Display the SQL command
echo ""
echo "=== Generated SQL Command ==="
echo "$sql_command"
echo ""

# Confirm before executing
read -p "Execute this command now? (y/N): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo ""
    echo "Executing command with npx wrangler..."
    echo "----------------------------------------"
    
    result=$(npx wrangler d1 execute antoine-artworks --remote --command "$sql_command" 2>&1)
    exit_code=$?
    
    echo "$result"
    echo "----------------------------------------"
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ Success! Record inserted into the database."
        
        echo ""
        echo "Verifying insertion..."
        verify_query="SELECT id, title, display_name, image_id FROM artworks WHERE image_id = '$image_id' ORDER BY id DESC LIMIT 1;"
        verify_result=$(npx wrangler d1 execute antoine-artworks --remote --command "$verify_query" 2>&1)
        echo "$verify_result"
        echo ""
        echo "✅ Record successfully verified!"
    else
        echo "❌ Error: Failed to insert record into database."
        echo "Please check the error message above."
    fi
else
    echo ""
    echo "Command not executed."
fi
