#!/usr/bin/env python3
import os
import subprocess
import time
from bs4 import BeautifulSoup
from selenium_stealth import stealth
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as condition
from selenium.webdriver.support.ui import WebDriverWait

cmd = 'ls'
process = subprocess.run(cmd, check=True, capture_output=True, text=True)
password = process.stdout

cmd = 'ls'
process = subprocess.run(cmd, check=True, capture_output=True, text=True)
username = process.stdout

options = webdriver.ChromeOptions()
options.add_argument("start-maximized")

# options.add_argument("--headless")
options.add_argument("user-data-dir=selenium")
options.add_experimental_option("excludeSwitches", ["enable-automation"])
options.add_experimental_option('useAutomationExtension', False)
driver = webdriver.Chrome(options=options, executable_path=r"./chromedriver")

stealth(driver,
        languages=["en-US", "en"],
        vendor="Google Inc.",
        platform="Win32",
        webgl_vendor="Intel Inc.",
        renderer="Intel Iris OpenGL Engine",
        fix_hairline=True,
        )
        
wait = WebDriverWait(driver, 10)
driver.get("https://www.awseducate.com/student/s/awssite")
wait.until(condition.element_to_be_clickable((By.ID, "loginPage:siteLogin:loginComponent:loginForm:username")))
driver.find_element_by_id("loginPage:siteLogin:loginComponent:loginForm:username").send_keys(username)
driver.find_element_by_id("loginPage:siteLogin:loginComponent:loginForm:password").send_keys(password)
time.sleep(1)
driver.find_element_by_class_name("loginText").click()

wait.until(condition.element_to_be_clickable((By.XPATH, "//a[@class='btn']")))
# lien = driver.find_element_by_class_name("btn").get_attribute("href")
driver.find_element_by_class_name("btn").click()

# driver.get(lien)
# Move to new opened tab
driver.switch_to.window(driver.window_handles[1])
wait.until(condition.presence_of_element_located((By.ID, "showawsdetail")))
wait.until(condition.element_to_be_clickable((By.ID, "showawsdetail")))

driver.find_element_by_id("showawsdetail").click()

wait.until(condition.element_to_be_clickable((By.ID, "clikeyboxbtn")))

driver.find_element_by_id("clikeyboxbtn").click()

content = driver.page_source
soup = BeautifulSoup(content, features="html.parser")

ele = soup.find(lambda tag: tag.name == "span" and "aws_access_key_id" in tag.text)

# Save the creds
path = "~/.aws"
path = os.path.expanduser(path)
if not os.path.exists(path):
    try:
        os.mkdir(path)
    except Exception as err:
        print(err)

with open(f"{path}/credentials", 'w') as creds:
    creds.write(ele.text)

driver.quit()
print("AWS credentials in " + path + "/credentials")
