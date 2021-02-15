import 'dart:io';

import 'package:ondemand_messenger_backend/token_cache.dart';
import 'package:webdriver/async_io.dart';

class TokenFetcher {

  WebDriver _driver;
  TokenCache _tokenCache;

  TokenFetcher() {
    _tokenCache = TokenCache(_getToken);
  }

  void init(int port) async {
    print('Connecting to driver: http://127.0.0.1:$port/');
    _driver = await createDriver(uri: Uri.parse('http://127.0.0.1:$port/wd/hub/'), spec: WebDriverSpec.JsonWire, desired: {'chromeOptions': {
      'args': ['--headless', '--no-sandbox', '--disable-dev-shm-usage']
    }});

    await _driver.get('https://ondemand.rit.edu/');
  }

  Future<String> _getToken() async {
    await _driver.get('https://ondemand.rit.edu/');
    await getElement(By.className('header-text'), duration: 10000);
    return await _driver.execute('return window.localStorage.getItem("access-token");', []) as String;
  }

  Future<String> getToken() async => _tokenCache.getToken();

  Future<WebElement> getElement(By by, {int duration = 5000, int checkInterval = 100}) async {
    var element;
    do {
      try {
        element = await _driver.findElement(by);
        if (element != null) return element;
      } catch (ignored) {}
      sleep(Duration(milliseconds: checkInterval));
      duration -= checkInterval;
    } while (element == null && duration > 0);
    return element;
  }
}
