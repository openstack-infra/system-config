#!/usr/bin/env python

from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.ui import WebDriverWait # available since 2.4.0
from selenium.webdriver.support import expected_conditions as EC # available since 2.26.0
import os
import pdb

# Create a new instance of the Firefox driver
profile = webdriver.FirefoxProfile(os.path.expanduser("~/Library/Application Support/Firefox/Profiles/selenium"))
# profile = webdriver.FirefoxProfile("/Users/ananth/Library/Application Support/Firefox/Profiles/selenium")

driver = webdriver.Firefox() #firefox_profile=profile)
for i in driver.window_handles:
    print i

util.sleep(10)
driver.quit()
exit()

# go to the google home page
driver.get("https://review.opencontrail.org/#/c/68/")

# the page is ajaxy so the title is originally this:
print driver.title


# find the element that's name attribute is q (the google search box)
inputElement = driver.find_element_by_name("q")

# type in the search
inputElement.send_keys("cheese!")

# submit the form (although google automatically searches now without submitting)
inputElement.submit()

try:
    # we have to wait for the page to refresh, the last thing that seems to be updated is the title
    WebDriverWait(driver, 10).until(EC.title_contains("cheese!"))

    # You should see "cheese! - Google Search"
    print driver.title

finally:
    driver.quit()
