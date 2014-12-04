KioskPi
=======

Installation script and Python Webscraping code to build your own Kiosk appliance based on the RaspberryPi

# Introduction

For a customer project we needed to quickly build a Raspberry Pi based Web - scraper and kiosk application. The Raspberry Pi is mounted behind a standard HD television, together they are mounted on the wall. The Kiosk application needs to be able to display a local pages (standard HTML and CSS) with a section displaying scraped content of an Internet web site.

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

After installation the script will have copied the above files to the appropriate directories:
`~/cgi-bin/kiosk.py`

The static HTML and CSS to:
`~/includes`

The webscraper software and output is installed and generated in:
`~/bin`

A cronjob for the user (default pi) launches the webscraper and, if succesful, copies the output file from `~/bin` to `~/include`. The file in `~/include` is picked up by the Kiosk app.

# Installation

Install fresh new Raspbian based Raspberry Pi. Login as the use pi (password: raspberry) and create a work directory called bin:

>mkdir bin

Copy all the files in this Github repository to this directory.
Change into bin and run the installation program:

>cd ~/bin
>./installKiosk.sh

