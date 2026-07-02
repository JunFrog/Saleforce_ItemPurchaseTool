/**
 * Handles HTTP callouts to the Unsplash API to retrieve item images.
 * Requires a Named Credential "Unsplash" and the Unsplash_Access_Key custom label.
 */
public with sharing class UnsplashService {
  private static final String NAMED_CREDENTIAL = 'callout:Unsplash';
  private static final String SEARCH_ENDPOINT = '/search/photos?query=';
  private static final Integer HTTP_OK = 200;
  private static final String ACCESS_KEY_PLACEHOLDER = 'REPLACE_WITH_UNSPLASH_ACCESS_KEY';

  /**
   * Searches Unsplash for a photo matching the query and returns the regular-size URL.
   * Returns null if no results found or callout fails.
   * @param query Search term (typically the item name)
   * @return URL string of the first matching photo, or null
   */
  public static String getImageUrl(String query) {
    if (String.isBlank(query)) {
      return null;
    }
    try {
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        NAMED_CREDENTIAL +
          SEARCH_ENDPOINT +
          EncodingUtil.urlEncode(query, 'UTF-8')
      );
      req.setMethod('GET');
      req.setTimeout(10000);
      String accessKey = Label.Unsplash_Access_Key;
      if (!String.isBlank(accessKey) && accessKey != ACCESS_KEY_PLACEHOLDER) {
        req.setHeader('Authorization', 'Client-ID ' + accessKey);
      }

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() != HTTP_OK) {
        return null;
      }

      Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );
      List<Object> results = (List<Object>) body.get('results');
      if (results == null || results.isEmpty()) {
        return null;
      }

      Map<String, Object> firstPhoto = (Map<String, Object>) results[0];
      Map<String, Object> urls = (Map<String, Object>) firstPhoto.get('urls');
      if (urls == null) {
        return null;
      }
      return (String) urls.get('regular');
    } catch (Exception e) {
      return null;
    }
  }
}
