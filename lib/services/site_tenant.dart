/// Keeps the two customer sites from showing each other's accounts.
///
/// Demo and Thong Guan are served from two hostnames off one deployment and
/// share a single `customers` collection. Every account on both carries the
/// same `factory_id` today — the demo login is itself assigned to Thong Guan —
/// so the tenant field cannot tell them apart, and adding or removing a user on
/// one site appeared on the other.
///
/// Splitting them properly means giving the demo accounts a customer of their
/// own. Until that happens this separates them by the one thing that does
/// differ: the email domain the accounts were created under. It is a stopgap
/// and reads like one on purpose — when the accounts carry their own customer,
/// every caller here goes back to comparing `factory_id` and this file is
/// deleted.
///
/// It lives in one place because the account list is read by more than one
/// screen, and a rule applied on some of them is not a boundary at all.
class SiteTenant {
  SiteTenant._();

  static const String thongGuanHost = 'thongguan.sf365.novaplus.my';
  static const String demoHost = 'demo.sf365.novaplus.my';
  static const String _thongGuanEmail = '@thongguan.com';

  /// The one client each customer site serves and shows.
  ///
  /// Written here rather than read from the integration config: a config
  /// record can be edited or re-saved without the field, and a site that
  /// quietly falls back to account-based resolution is how demo came to read
  /// and write Thong Guan's data. Demo runs on its own Firestore under `DEV`;
  /// Thong Guan stays on `F0004` and never lists the demo client.
  static const Map<String, String> _clientByHost = {
    demoHost: 'DEV',
    thongGuanHost: 'F0004',
  };

  /// The client this site is locked to, or null anywhere else (localhost,
  /// preview URLs), where the usual resolution still applies.
  static String? get lockedClientId => _clientByHost[_host];

  /// True when this build is being served from one of the two customer sites.
  /// Anywhere else — localhost, a preview URL — nothing is hidden, so testing
  /// still sees every account.
  static bool get isSplitHost {
    final h = _host;
    return h == thongGuanHost || h == demoHost;
  }

  static String get _host => Uri.base.host.toLowerCase();

  static bool _isThongGuanAccount(String email) =>
      email.toLowerCase().trim().endsWith(_thongGuanEmail);

  /// Whether an account belongs on the site currently being viewed.
  static bool allows(String email) {
    final h = _host;
    if (h == thongGuanHost) return _isThongGuanAccount(email);
    if (h == demoHost) return !_isThongGuanAccount(email);
    return true;
  }

  /// Filters any list of account-shaped maps, reading the email from [emailOf].
  static List<T> filter<T>(List<T> rows, String Function(T) emailOf) {
    if (!isSplitHost) return rows;
    return rows.where((r) => allows(emailOf(r))).toList();
  }
}
