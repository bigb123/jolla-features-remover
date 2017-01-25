# jolla-features-remover
Bash script to change features from jolla phone:
- removes high volume headphones warning indicator 
- removes word prediction in keyboard
- sets umask and fmask options for sd card mount (fmask=umask=0002). Needed to:
-- bind mounting sd directory as owncloud folder with data
-- whatsapp folder is being mounted the same way
- removes auto capitalization keyboard feature 

Remember that you have to be root to run this script (so you need to have "developer mode" activated on your phone)!
