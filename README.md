# jolla-features-remover
Bash script to remove annoying features like high volume headphones warning indicator and word prediction in keyboard

It also sets umask and fmask options for sd card mount (fmask=umask=0002). Needed for bind mounting sd directory as owncloud folder with data.

Remember that you have to be root to run this script (so you need to have "developer mode" activated on your phone)!
