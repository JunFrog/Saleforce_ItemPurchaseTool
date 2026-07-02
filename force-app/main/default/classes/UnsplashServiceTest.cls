@IsTest
private class UnsplashServiceTest {
  private class SuccessMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setBody(
        '{"results":[{"urls":{"regular":"https://images.unsplash.com/photo-test"}}]}'
      );
      return res;
    }
  }

  private class EmptyResultsMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setBody('{"results":[]}');
      return res;
    }
  }

  private class ErrorResponseMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(401);
      res.setBody('{"errors":["OAuth error: The access token is invalid"]}');
      return res;
    }
  }

  private class NoUrlsMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setBody('{"results":[{"id":"abc123"}]}');
      return res;
    }
  }

  @IsTest
  static void testGetImageUrl_success_returnsUrl() {
    Test.setMock(HttpCalloutMock.class, new SuccessMock());
    Test.startTest();
    String url = UnsplashService.getImageUrl('apple');
    Test.stopTest();
    System.assertEquals('https://images.unsplash.com/photo-test', url);
  }

  @IsTest
  static void testGetImageUrl_emptyResults_returnsNull() {
    Test.setMock(HttpCalloutMock.class, new EmptyResultsMock());
    Test.startTest();
    String url = UnsplashService.getImageUrl('xyznotfound');
    Test.stopTest();
    System.assertEquals(null, url);
  }

  @IsTest
  static void testGetImageUrl_errorStatus_returnsNull() {
    Test.setMock(HttpCalloutMock.class, new ErrorResponseMock());
    Test.startTest();
    String url = UnsplashService.getImageUrl('apple');
    Test.stopTest();
    System.assertEquals(null, url);
  }

  @IsTest
  static void testGetImageUrl_blankQuery_returnsNull() {
    Test.startTest();
    String url = UnsplashService.getImageUrl('');
    Test.stopTest();
    System.assertEquals(null, url);
  }

  @IsTest
  static void testGetImageUrl_nullQuery_returnsNull() {
    Test.startTest();
    String url = UnsplashService.getImageUrl(null);
    Test.stopTest();
    System.assertEquals(null, url);
  }

  @IsTest
  static void testGetImageUrl_noUrlsField_returnsNull() {
    Test.setMock(HttpCalloutMock.class, new NoUrlsMock());
    Test.startTest();
    String url = UnsplashService.getImageUrl('apple');
    Test.stopTest();
    System.assertEquals(null, url);
  }
}
