import os
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.action_chains import ActionChains
from selenium.common.exceptions import NoSuchElementException, ElementClickInterceptedException, TimeoutException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import (
    TimeoutException,
    ElementClickInterceptedException,
    ElementNotInteractableException
)


# Specify the directory you want to save the downloaded PDFs
download_directory = "/Users/tylerjacobson/Dropbox/development/data/raw/chicago_zoning_committee/agendas"

# Ensure the download directory exists
os.makedirs(download_directory, exist_ok=True)

# Set up Chrome options
chrome_options = Options()
chrome_options.add_experimental_option('prefs', {
    "download.default_directory": download_directory,
    "download.prompt_for_download": False,
    "plugins.always_open_pdf_externally": True
})

# Initialize the Chrome driver
service = Service(ChromeDriverManager().install())
driver = webdriver.Chrome(service=service, options=chrome_options)

try:
    # Open the specified webpage
    driver.get('https://chicago.councilmatic.org/committee/committee-on-zoning-landmarks-and-building-standards-0287e623565a/')

    # Wait for the element with id 'more-events' to be clickable
    more_events_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.ID, 'more-events'))
    )
    # Click the 'more-events' button
    more_events_button.click()

    #Find all Links
    committee_links = WebDriverWait(driver, 10).until(EC.presence_of_all_elements_located(
        (By.LINK_TEXT, "Committee on Zoning, Landmarks and Building Standards")
    ))

finally:
    # Close the browser when done
    driver.quit()
