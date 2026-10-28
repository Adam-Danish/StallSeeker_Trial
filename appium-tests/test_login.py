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


def test_login_form_opens(driver):
    wait = WebDriverWait(driver, 15)

    # Step 1: Open StallSeeker from a fresh app process
    driver.terminate_app("com.example.stallseeker")
    driver.activate_app("com.example.stallseeker")

    # Step 2: Click Log in or sign up
    login_button = wait.until(
        lambda d: d.find_element(
            AppiumBy.ACCESSIBILITY_ID,
            "Log in or sign up"
        )
    )
    login_button.click()

    # Step 3: Check if Email address field appears
    email_field = wait.until(
        lambda d: next(
            (
                e for e in d.find_elements(
                    AppiumBy.CLASS_NAME,
                    "android.widget.EditText"
                )
                if e.is_displayed()
            ),
            None
        )
    )

    # Step 4: Verify result
    assert email_field.is_displayed()

    print("TC002 PASSED: Login form opened successfully")