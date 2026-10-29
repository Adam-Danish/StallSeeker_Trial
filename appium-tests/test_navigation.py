
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
    options.no_reset = True
    options.set_capability("appium:autoLaunch", False)

    driver = webdriver.Remote(
        "http://127.0.0.1:4723",
        options=options
    )

    yield driver
    driver.quit()


def test_home_to_following(driver):
    wait = WebDriverWait(driver, 15)

    # Step 1: Tap Home
    home = wait.until(
        lambda d: d.find_element(
            AppiumBy.ACCESSIBILITY_ID,
            "Home\nTab 1 of 4"
        )
    )
    home.click()

    # Step 2: Tap Following
    following = wait.until(
        lambda d: d.find_element(
            AppiumBy.ACCESSIBILITY_ID,
            "Following\nTab 2 of 4"
        )
    )
    following.click()

    # Step 3: Verify Following page heading
    heading = wait.until(
        lambda d: next(
            (
                element
                for element in d.find_elements(
                    AppiumBy.ACCESSIBILITY_ID,
                    "Following"
                )
                if element.is_displayed()
            ),
            None
        )
    )

    assert heading.is_displayed()

    print("TC001 PASSED: Following screen opened")
