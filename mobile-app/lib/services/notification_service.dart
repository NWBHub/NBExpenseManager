class NotificationService {
  const NotificationService();

  Future<String?> initialize() async {
    // Push notifications are not enabled yet in pubspec/Firebase messaging setup.
    // Keep a no-op service so imports stay safe until that feature is added.
    return null;
  }
}
