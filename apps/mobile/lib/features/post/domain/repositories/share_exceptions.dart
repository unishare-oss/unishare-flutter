/// Thrown when the OS share sheet is unavailable and the URL has been copied
/// to the clipboard instead. The presentation layer should show a
/// "Link copied to clipboard" SnackBar.
class ShareFallbackException implements Exception {
  const ShareFallbackException();
}
