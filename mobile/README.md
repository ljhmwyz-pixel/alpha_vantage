# Mobile App

Flutter source for iOS and Android.

Generate native platform files after installing Flutter:

```powershell
flutter create . --project-name alpha_vantage_monitor --org com.example.alpha_vantage --platforms android,ios
flutter pub get
```

Run against the local backend:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Use your computer LAN IP instead of `10.0.2.2` when testing on a physical Android device.
