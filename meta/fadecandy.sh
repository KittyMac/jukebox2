#!/bin/sh

# script to create fadecandy install from scratch in linux

priv_create() {	
	git clone git://github.com/scanlime/fadecandy
	
	cd fadecandy/server
	make submodules
	make
}

priv_install() {
	# install fade candy server so that it boots when the device boots
	sudo cp fadecandy/server/fcserver /usr/local/bin
	sudo cp fcserver.json /usr/local/bin/fcserver.json
	
	sudo cp fcserver.service /etc/systemd/system/fcserver.service
	
	sudo chmod u+x run_fcserver.sh
	
	sudo systemctl start fcserver
	sudo systemctl enable fcserver
}

mkdir -p fadecandy
cd fadecandy

if [ $1 = "create" ]
then
	priv_create
fi

if [ $1 = "install" ]
then
	priv_install
fi

