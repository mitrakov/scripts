#!/usr/bin/env python3
import subprocess
import csv
from datetime import datetime
import os

master = "origin/master"
git_cmd = [
    "git", "for-each-ref", "refs/remotes/origin",
    "--sort=-committerdate",
    "--format=%(committerdate:iso)|%(authorname)|%(refname:short)"
]
output = subprocess.check_output(git_cmd, text=True, encoding='utf-8')
branches_data = []

# Get list of merged branches
merged_branches = subprocess.check_output(["git", "branch", "-r", "--merged", master], text=True, encoding='utf-8')

for line in output.strip().split('\n'):
    if not line: continue
    
    # Split using the explicit pipe character we injected
    parts = line.split('|', 2)
    if len(parts) < 3: continue
    
    date_str, author, branch = parts[0], parts[1], parts[2]
    
    # Clean up branch name to remove 'origin/' if present for matching
    short_branch = branch.replace("origin/", "").strip()
    is_merged = "Yes" if short_branch in merged_branches else "No"
    
    # Calculate age safely from the ISO timestamp
    clean_date = date_str.split()[0]
    last_commit_date = datetime.strptime(clean_date, "%Y-%m-%d")
    age_days = (datetime.now() - last_commit_date).days
    
    # Categorize status
    status = "Active" if age_days < 90 else ("Stale" if is_merged == "Yes" else "Abandoned")
    branches_data.append([branch, clean_date, age_days, author, is_merged, status])

# save to CSV
with open("git_branch_report.csv", "w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Branch Name", "Last Commit Date", "Age (Days)", "Author", "Merged to Main?", "Suggested Action"])
    writer.writerows(branches_data)

print("SUCCESS. Generated 'git_branch_report.csv'")
