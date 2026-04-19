#!/usr/bin/env python3
import os
import sys
import json
import subprocess

# Configuration paths
DB_PATH = "/Users/tommy/Yandex.Disk.localized/db/cola.db"
LINKS_FILE = "/Users/tommy/Downloads/links.txt"
APP_PATH = "/Applications/Las Notes.app/Contents/MacOS/Las Notes"

def run_docker(ids, token):
    if os.path.exists(LINKS_FILE):
        command = [
            "docker", "run", "--rm", 
            "--env", "YANDEX_TOKEN={token}",
            "--volume", "/Users/tommy/Downloads:/app", 
            "mitrakov/y-music:1.0.0"
        ]
        try:
            result = subprocess.run(command)
            if result.returncode != 0:
                print(f"Error: Docker command failed with code {result.returncode}")
                return
            
            # Docker finished successfully, now clean up
            os.remove(LINKS_FILE)
            remove_notes(ids)
            print("Process completed and notes removed successfully!")
        except Exception as e: 
            print(f"Error during Docker execution: {e}")
    else: 
        print(f"File not found: {LINKS_FILE}")

def remove_notes(ids):
    for note_id in ids:
        command = [
            APP_PATH,
            "delete", "--id", str(note_id),
            "--db", DB_PATH
        ]
        try:
            result = subprocess.run(command)
            if result.returncode != 0:
                print(f"Error: Failed to delete note ID {note_id}")
            else:
                print(f"Deleted note: {note_id}")
        except Exception as e: 
            print(f"Error deleting note {note_id}: {e}")

def extract_links(token):
    command = [
        APP_PATH,
        "search", "--tag", "!SHARED",
        "--db", DB_PATH
    ]

    try:
        result = subprocess.run(command, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Error: Search command failed with code {result.returncode}")
            return
        
        data = json.loads(result.stdout)

        if data.get("status") == "ok":
            items = data.get("result", [])
            
            # Extract both data (URLs) and IDs
            urls = [item["data"] for item in items if "data" in item]
            ids  = [item["id"]   for item in items if "id"   in item]

            if not urls:
                print("No notes found with the !SHARED tag.")
                return

            with open(LINKS_FILE, "w", encoding="utf-8") as f:
                for url in urls:
                    f.write(f"{url}\n")
            
            print(f"Extracted {len(urls)} links and stored {len(ids)} IDs in buffer.")
            
            # Pass the ID buffer to the next step
            run_docker(ids, token)
        else:
            print(f"API Error: Status was {data.get('status')}")
    except Exception as e: 
        print(f"Error extracting links: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./lasnotes2music.py <YANDEX_TOKEN>")
        sys.exit(1)
    
    yandex_token = sys.argv[1]
    extract_links(yandex_token)
