boinc_installation_scripts
==========================

## What is this ##

I sometimes want to install BOINC with no major hassle or thought effort, start the client, connect to projects, then forget all about it again. In particular, when using EC2 virtual machines.

This is how to do it with minimal extras.

## Idea ##

All the BOINC files needed for a new installation shall be in a =boinc_64.tgz= file that can be downloaded from a webserver. No keys or anything of importance will be in that package, just:

- Scripts to start the BOINC client
- The BOINC client itself
- Scripts to publish the state of the BOINC client to a web page
     
## How to use this ##

### Create the tarball ###

On a given "master machine", create a tarball of the whole directory tree (the tarball is named `boing_64.tgz`) 
and put it into a world-accessible web directory.

Practically, you need to: 

- Make sure the BOINC client included here is the one you want. 
- Edit `install_on_ec2/builder/makepackage.sh` so that the paths to the web directory are correct
- Then run `install_on_ec2/builder/makepackage.sh`
    
### Install BOINC on the new machine ###

Once logged in onto your new machine:

- Create user boinc: `sudo useradd boinc`
- Start and configure the webserver:
  - `sudo install --owner boinc --group boinc --mode 775 --directory /var/www/html/boinc`
  - `sudo ln -s /var/www/html/boinc/composite.html /var/www/html/index.html`
  - `sudo /etc/rc.d/init.d/httpd start` (or similar)
- Become user "boinc"
  - `sudo su - boinc`
- Get package created earlier from your master machine and unpack
  - `wget http://mastermachine.example.com/boinc_64.tgz`
  - `tar xzf boinc_64.tgz`
  - `cp webtransfer/www_logo.gif /var/www/html/boinc/`
  - `echo "*/1 * * * * /home/boinc/webtransfer/copy_html.sh /var/www/html/boinc 2>/dev/null 1>/dev/null" | crontab -`
  - `/bin/rm boinc_64.tgz`
- Punch in your "weak account keys" (modify as needed):
  - `SCRIPT=~/bin/hidden/operation.sh`
  - `sed --in-place 's/SETI@HOME_WEAKPK/XXXXX_XXXXXXXXXXXXXXXXXXXXX/' $SCRIPT`
  - `sed --in-place 's/EINSTEIN@HOME_WEAKPK/XXXXX_XXXXXXXXXXXXXXXXXXXXX/' $SCRIPT`
  - `sed --in-place 's/DOCKING@HOME_WEAKPK/XXXXX_XXXXXXXXXXXXXXXXXXXXX/' $SCRIPT`
  - `sed --in-place 's/CLIMATEPREDICTION_WEAK_PK/XXXXX_XXXXXXXXXXXXXXXXXXXXX/' $SCRIPT`
- If you want to install `cc_config.xml` (debugging flags), let it at the toplevel, otherwise remove it.
- Remove any "attach" commands in `~/bin/` for projects that you are not interested in; but `~/bin/boot.sh` will ask you anyway.
- Start the BOINC client and attach to relevant projects (it will ask you; add --attachall for noninteractive attach)
  - `~/bin/boot.sh

And that should be it, "boinc" should be running and the data in the log file visible on the web!

Stop requesting more work using: `sudo su - boinc ; ./bin/winddown.sh`

