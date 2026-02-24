#!/usr/bin/env python3
import sys
import json
import re

# Read the raw HTML
html = sys.stdin.read()

# Extract JSON data from the Next.js script tags
# Look for self.__next_f.push data
matches = re.findall(r'self\.next_f\.push\(\[1,"([^"]*)"\]\)', html)

articles = []
for match in matches:
    try:
        # Try to find post data within
        if '_type":"post"' in match:
            # Extract all post objects from this string
            post_matches = re.findall(r'_type":"post"[^}]*"title":"([^"]*)"[^}]*"publishedOn":"([^"]*)"', match)
            for title, date in post_matches:
                articles.append((title, date))
            
            # Also try reverse order (date might come before title)
            post_matches2 = re.findall(r'"publishedOn":"([^"]*)"[^}]*"title":"([^"]*)"[^}]*_type":"post"', match)
            for date, title in post_matches2:
                articles.append((title, date))
    except:
        pass

# Try a simpler regex approach on the raw HTML
title_date_matches = re.findall(r'"title":"([^"]{10,200})".*?"publishedOn":"([^"]{10,30})"', html)
for title, date in title_date_matches[:10]:
    articles.append((title, date))

# Remove duplicates and sort by date
seen = set()
unique_articles = []
for title, date in articles:
    key = (title, date)
    if key not in seen:
        seen.add(key)
        unique_articles.append((title, date))

# Print top 5
for title, date in unique_articles[:5]:
    print(f'{date}|{title}')
