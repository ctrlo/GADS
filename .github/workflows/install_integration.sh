apt-get update
apt-get install -y unzip gconf2 libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2 libxtst6 xauth xvfb cpanminus libtest-simple-perl;
cpanm --notest WebDriver::Tiny Test2::Tools::Compare;

# We're running integration tests, so we need to set up browsers
curl -o- https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
&& echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
apt-get update && apt-get install google-chrome-stable -y

mkdir -p /chromedriver
curl -o /chromedriver/chromedriver_linux64.zip "http://chromedriver.storage.googleapis.com/2.19/chromedriver_linux64.zip"
unzip /chromedriver/chromedriver* -d /chromedriver
ln /chromedriver/chromedriver /usr/local/bin/chromedriver
