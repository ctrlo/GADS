GADS WebDriver Integration Tests
================================

The test suite contained with the `webdriver` directory of GADS provides
WebDriver integration tests for the entire application.

# Preparation

```
# Install the required CPAN modules
cd webdriver; cpan .

# Run geckodriver (or similar for your browser, perhaps chromedriver)
geckodriver

# Run the application
perl bin/app.pl
```

# Environment

These tests rely on several environment variables:

## Required Environment Variables

* `GADS_USERNAME` defines the username to log in with
* `GADS_PASSWORD` defines the password to log in with

## Optional Environment Variables

* `GADS_HOME` defines the URL of a running application to test against
  (defaults to `http://localhost:3000`)

## geckodriver Environment Variables

To run these tests with geckodriver in headless mode, without a browser
window appearing, set `MOZ_HEADLESS=1`.

# Run Tests

```
prove -r webdriver/t
```

# Write Tests

The `webdriver/t/lib/GADSDriver.pm` library provides a GADS-specific
wrapper around `WebDriver::Tiny`.  The
`webdriver/t/lib/Test/GADSDriver.pm` contains GADS-specific reusable
test code.
