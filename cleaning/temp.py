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

    # Click the "Show More" button to reveal all meetings
    # This part is specific to how the 'Show More' button is implemented
    # You might need to adjust the selector based on the actual implementation
    #show_more_button = WebDriverWait(driver, 20).until(
   #     EC.element_to_be_clickable((By.XPATH, '//button[contains(text(),"Show more")]'))
   # )

    #driver.execute_script('arguments[0].click();', show_more_button)


    # Wait for AJAX content to load (e.g., new list items)
    #time.sleep(5)  # Explicit wait; adjust as needed or use a better wait condition


    # Wait for the page to load all elements
   # WebDriverWait(driver, 10).until(
    #    EC.presence_of_all_elements_located((By.LINK_TEXT, "Committee on Zoning, Landmarks and Building Standards"))
   # )

    # Get all the links for the committee meetings
    committee_meeting_links = driver.find_elements(By.LINK_TEXT, "Committee on Zoning, Landmarks and Building Standards")

    # Loop through each link and download the 'Agenda'
    for link in committee_meeting_links:
        # Click on the committee meeting link
        link.click()

        try:
            # Wait for the "Agenda" link to be clickable and then click to download
            agenda_link = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.PARTIAL_LINK_TEXT, 'Agenda'))
            )
            agenda_link.click()

            # Wait a bit for the download to start, replace with a more robust solution if possible

        except TimeoutException:
            # If the "Agenda" link isn't present, skip to the next one
            print("No agenda link found, skipping to the next file.")

        # Navigate back to the committee list page to continue the process
        driver.back()

        # Pause to ensure the download starts (the actual wait time may need to be adjusted)
        WebDriverWait(driver, 15).until(lambda driver: any([filename.endswith(".pdf") for filename in os.listdir(download_directory)]))

        # Navigate back to the list of committee meetings
        driver.back()

        # Re-identify the 'Show More' button and links since the DOM has been refreshed
        show_more_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//a[@class='show-more']"))
        )
        show_more_button.click()

        committee_meeting_links = WebDriverWait(driver, 10).until(
            EC.presence_of_all_elements_located((By.LINK_TEXT, "Committee on Zoning, Landmarks and Building Standards"))
        )

    print("All available agendas should be downloaded.")

except NoSuchElementException:
    print("Some element was not found on the page.")
except ElementClickInterceptedException:
    print("Some element was not clickable.")
except TimeoutException:
    print("The page took too long to load or some element did not become clickable within the expected time.")
except Exception as e:
    print(f"An unexpected error occurred: {e}")
finally:
    # Close the browser when done
    driver.quit()



# Click on each link
    for link in committee_links:
        try:
        # Scroll the link into view to ensure it's clickable
            driver.execute_script("arguments[0].scrollIntoView(true);", link)
            link.click()
        
        # After clicking, the page may navigate away, or a new tab may open
        # Handle that situation appropriately, such as switching back to the main tab
        # Here I'm assuming we are just navigating back
            driver.back()


        # Wait for the page to reload and for links to be present again
            committee_links = wait.until(EC.presence_of_all_elements_located(
                (By.LINK_TEXT, "Committee on Zoning, Landmarks and Building Standards")
            ))

        # Wait for the element with id 'more-events' to be clickable
        more_events_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.ID, 'more-events'))
        )
        # Click the 'more-events' button
        more_events_button.click()


except ElementClickInterceptedException:
    print("The link was not clickable at the moment.")
 except Exception as e:
    print(f"An error occurred while clicking the link: {e}")