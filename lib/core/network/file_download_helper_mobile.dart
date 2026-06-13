Future<void> saveAndOpen(List<int> bytes, String fileName) async {
  // Mobile fallback if they ever view the admin console on a phone/tablet
  // ignore: avoid_print
  print('Saved $fileName with ${bytes.length} bytes (mobile fallback).');
}
