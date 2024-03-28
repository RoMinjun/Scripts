import requests

#Scrape json file from website
page_scraped = requests.get("https://beheer.syntaxis.nl/api/ishethokalopen")
hok_status = page_scraped.json()["payload"]

# Get hok open status
open_status = hok_status['open']

#Check for open status for webhook
if open_status == 0:
    status = "dicht"
else:
    status = "open"

#setting file path
file='/path/to/openstatus.txt'

# Read current status from file
f = open(file,"r")
current_status = (f.readline())

if status == current_status:
    exit()

#Write status to file if there's a difference
with open (file,'r+') as f:
    f.seek(0)
    f.write(status)
    f.truncate()

#webhook configs
webhook_url = "https://discord.com/api/webhooks/[REDACTED]"
message = f"Het hok is **{status}**"

#running webhook if status has changed
requests.post(webhook_url, data = {"content": message})
