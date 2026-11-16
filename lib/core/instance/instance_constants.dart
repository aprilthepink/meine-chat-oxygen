abstract final class InstanceConstants {
  static const int apiCodeVersion = 1;
  static const String defaultApiBaseUrl = String.fromEnvironment(
    'FLUXER_DEFAULT_API_BASE_URL',
    defaultValue: 'https://fluxer.com/api/v1',
  );
  static const String defaultGatewayUrl = String.fromEnvironment(
    'FLUXER_DEFAULT_GATEWAY_URL',
    defaultValue: 'wss://gateway.fluxer.com',
  );
  static const String defaultInstanceInputUrl = String.fromEnvironment(
    'FLUXER_DEFAULT_INSTANCE',
    defaultValue: 'fluxer.com',
  );
  static const bool lockInstance = bool.fromEnvironment('FLUXER_LOCK_INSTANCE');
  static const String canaryApiBaseUrl = 'https://canary.fluxer.com/api/v1';
  static const String canaryInstanceInputUrl = 'canary.fluxer.com';
  static const String defaultTermsUrl = 'https://fluxer.com/terms';
  static const String defaultPrivacyUrl = 'https://fluxer.com/privacy';
  static const String helpCenterUrl = 'https://fluxer.com/help';
  static const String defaultProductName = 'Fluxer';
  static const String defaultPremiumProductName = 'Plutonium';
  static const int maxRecentInstances = 5;

  static const Set<String> officialInstanceHosts = <String>{
    'fluxer.app',
    'web.fluxer.app',
    'canary.fluxer.app',
    'web.canary.fluxer.app',
    'fluxer.com',
    'web.fluxer.com',
    'canary.fluxer.com',
    'web.canary.fluxer.com',
  };
}
