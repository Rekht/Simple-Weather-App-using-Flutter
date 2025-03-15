String apiURL(String endpoint, {String provinsi = ''}) {
  String baseUrl = "https://weather-api-tau-six.vercel.app";

  String url;

  switch (endpoint) {
    case 'provinsi':
      url = "$baseUrl/provinces";
      break;
    case 'cuaca':
      url = "$baseUrl/weather/$provinsi";
      break;
    default:
      url = "$baseUrl/provinces";
      break;
  }
  return url;
}
