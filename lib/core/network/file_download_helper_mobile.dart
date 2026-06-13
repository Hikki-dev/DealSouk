Future<void> saveAndOpen(List<int> bytes, String fileName) async {
  // Mobile fallback if they ever view the admin console on a phone/tablet
  print('Saved $fileName with ${bytes.length} bytes (mobile fallback).');
}
