KioskPi
=======

Installation script and Python Webscraping code to build your own Kiosk appliance based on the RaspberryPi

# Introduction

For a customer project we needed to quickly build a Raspberry Pi based Web - scraper and kiosk application. The Raspberry Pi is mounted behind a standard HD television, together they are mounted on the wall. The Kiosk application needs to be able to display local pages (standard HTML and CSS) with a section displaying scraped content from an Internet web site (after installation defaults to http://www.linuxcien.nl/laatste-nieuws).

We managed to implement this using the Python Selenium and Beautiful soup libraries. As webserver we used the standard Python `http.server.CGIHTTPRequestHandler` listening for localhost on port 8000. The web page is automatically loaded after bootup on URL: `http://127.0.0.0:8000/cgi-bin/kiosk.py` 

# Files

The following files are required for a succesful installation, they must be copied to the `~/bin` directory of the pi user (or any other user who is enabled for sudo with `NOPASSWD: ALL` option):

+ `footer.html` static footer page (included using `kiosk.py`)
+ `header.html`
+ `installKiosk.sh`
+ `kiosk.py`
+ `phantomjs`
+ `scraped_included.html`
+ `styles.css`
+ `webScraper.py`

After installation the script will have copied the files to the appropriate directories and created a few new files:

`~/cgi-bin/kiosk.py`

The static HTML and CSS to:

`~/includes`

The webscraper software and output is installed and generated in:
`~/bin`

In addition to the files described above the installation script also generates the following files:

* `CGIServer.py` small Python script to launch the `CGIHTTPRequestHandler`, executed atomatically by the LXDE startup process 
* `cronScript.sh` script that is run by cron for the installation user (pi)
* `startChromium.sh` Bash script that is executed by the LXDE startup functionality to launch the Chromium browser in full screen kiosk mode. It also "cleans" up the Chromium installation during a restart. Chromium, despite having a Kiosk mode, still requires user interaction after a crash or anything unexpexted to happen. The script resets the Chromium configuration.

A cronjob for the user (default pi) launches the webscraper and, if succesful, copies the output file from `~/bin` to `~/include`. The file in `~/include` is picked up by the Kiosk app.

# Installation

Install fresh new Raspbian based Raspberry Pi. Login as the use pi (password: raspberry) and create a work directory called bin:

>mkdir bin

Copy all the files in this Github repository to this directory.
Change into bin and run the installation program:

>cd ~/bin
>./installKiosk.sh

Check for any errors (all output is also logged to an installation log file, filename something like: `installKiosk_YYYYMMDDHHMMSS.log`

Reboot the Raspberry Pi and watch the console!
