
import pytest
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait


@pytest.fixture
def driver():
    options = UiAutomator2Options()
    options.platform_name = "Android"
    options.automation_name = "UiAutomator2"
    options.udid = "adb-ae251480-IbuwiW._adb-tls-connect._tcp"
    options.app_package = "com.example.stallseeker"
    options.app_activity = ".MainActivity"
    options.no_reset = True

    driver = webdriver.Remote(
        "http://127.0.0.1:4723",
        options=options
    )

    yield driver
    driver.quit()


def test_empty_login_validation(driver):
    wait = WebDriverWait(driver, 15)

    # Step 1: Restart StallSeeker
    driver.terminate_app("com.example.stallseeker")
    driver.activate_app("com.example.stallseeker")

    # Step 2: Open login form
    login_button = wait.until(
        lambda d: d.find_element(
            AppiumBy.ACCESSIBILITY_ID,
            "Log in or sign up"
        )
    )
    login_button.click()

    # Step 3: Submit empty login form
    continue_button = wait.until(
        lambda d: d.find_element(
            AppiumBy.ACCESSIBILITY_ID,
            "Continue"
        )
    )
    continue_button.click()

    # Step 4: Verify email validation error
    email_error = wait.until(
        lambda d: d.find_element(
            AppiumBy.ACCESSIBILITY_ID,
            "Enter a valid email address."
        )
    )

    assert email_error.is_displayed(), \
        "Email validation error not displayed"

    # Step 5: Verify password validation error
    password_error = wait.until(
        lambda d: d.find_element(
            AppiumBy.ACCESSIBILITY_ID,
            "Enter your password."
        )
    )

    assert password_error.is_displayed(), \
        "Password validation error not displayed"

    # Step 6: Verify login form remains open
    cancel_button = wait.until(
        lambda d: d.find_element(
            AppiumBy.ACCESSIBILITY_ID,
            "Cancel"
        )
    )

    assert cancel_button.is_displayed(), \
        "Login form is no longer visible"

    print("TC003 PASSED: Empty login validation works")
