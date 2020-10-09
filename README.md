Following packages neesd to be install on a fresh pi image:
clone the repo
sudo apt install gpac vim 
sudo cp cam-rec.service /lib/systemd/system/
sudo systemctl enable cam-rec.service .
