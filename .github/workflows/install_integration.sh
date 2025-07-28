apt-get update
apt-get install -y unzip gconf2 libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2 libxtst6 xauth xvfb cpanminus libtest-simple-perl libwebdriver-tiny-perl;

# We're running integration tests, so we need to set up browsers
curl -o- https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
&& echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
apt-get update && apt-get install google-chrome-stable -y
