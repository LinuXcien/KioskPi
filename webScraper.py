#!/usr/bin/env python3
import sys
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from bs4 import BeautifulSoup
#
# Following class can be instanced without parameters, defaults are:
#  url = the HTTP adress of the page that needs fetching
#  titleText = content of TITLE tag in HTML header
#  driverLocation = where in your filesystem the binary for phantomjs is located
#  lookForTag = tells BeautifulSoup to search for this instance of this HTML tag
#  lookForClass = tells BeautifulSoup to search for the above tag with this class definition
#
class WebPage():
    "Fetches the web page in collect and remove all tages in removeTags functions"
    def __init__(self):
        pass
        
    def collect(self, url = "http://www.linuxcien.nl/laatste-nieuws", titleText = "Laatste nieuws | LinuXcien B.V.", driverLocation = "/usr/local/bin/phantomjs", lookForTag = "div", lookForClass = "entry-content excerpt"):
        driver = webdriver.PhantomJS(driverLocation)
        pageFound = False
        driver.get(url)
        #Check titleText in driver.title
        if (titleText in driver.title):
            pageFound = True
            html_source = driver.page_source.encode('utf-8')
            soup = BeautifulSoup(html_source)
            latestArticle = soup.find(lookForTag, class_=lookForClass)
        else:
            latestArticle = "Page [" + url + "] not found" 
        driver.close()
        driver.quit()
        return latestArticle, pageFound
    def removeTags(self, latestArticle):
        latestArticle = latestArticle.prettify(formatter="html")
        #latestArticle = latestArticle.text
        return latestArticle

def main(): 
    # Variations on creating an instance from object WebPage:
    #latestArticle, pageFound = WebPage.collect( url = "http://www.linuxcien.nl/laatste-nieuws")
    #latestArticle, pageFound = WebPage.collect( url = "http://doesntwork.rubbish")
    #latestArticle, pageFound = WebPage.collect( titleText = "Rubbish")
    url = "http://www.linuxcien.nl/laatste-nieuws"
    titleText = "Laatste nieuws | LinuXcien B.V."
    driverLocation = "/usr/local/bin/phantomjs"
    lookForTag = "div"
    lookForClass = "entry-content excerpt"
    latestArticle, pageFound = WebPage.collect('', url, titleText, driverLocation, lookForTag, lookForClass)
    if pageFound:
        latestArticle = WebPage.removeTags('', latestArticle)
    #content = latestArticle.encode('utf-8')
    content = latestArticle
    sys.stdout.write(str(content))

if __name__ == "__main__":
    main()
