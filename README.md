# iOS App Template

A production-ready iOS app template built with SwiftUI and MVVM-C, featuring Apple Sign-In, Supabase integration, RevenueCat subscriptions, and a clean starter architecture.

Quick Start

Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- Supabase CLI (optional, for backend setup)
- RevenueCat account (optional, for real purchases)

Choose your setup path

A) Create a new project from this template (recommended)
1) Deploy the template
   ./deploy_template.sh /path/to/MyNewApp --name "My New App" --bundle-id com.myco.mynewapp --mode project
   Notes:
   - Safe by default: the script does NOT modify project.pbxproj unless you pass --modify-pbxproj.
   - Set your bundle ID and Team in Xcode after opening the project.
   - You can opt-in to pbxproj mutation with --modify-pbxproj (use cautiously; a backup is created).

2) Open in Xcode
   - File → Open… → select MyNewApp.xcodeproj
   - Set Signing & Capabilities → Team
   - Confirm iOS Deployment Target

3) Add Swift Packages
   - File → Add Packages…
   - Supabase: https://github.com/supabase-community/supabase-swift
   - RevenueCat: https://github.com/RevenueCat/purchases-ios

4) Provide configuration values
   - Create Config/DebugConfig.plist and Config/ReleaseConfig.plist in your app target.
   - Add keys:
     SupabaseURL (string)
     SupabaseAnonKey (string)
     RevenueCatAPIKey (string, public key starting with appl_)
     RevenueCatEntitlementID (string, optional)
     TermsURL (string)
     PrivacyURL (string)
   - See CONFIGURATION.md for examples. Environment variables override plist values.

5) Run
   - Product → Run (Cmd+R)

B) Integrate into an existing blank Xcode app (no project settings changed)
1) Deploy sources only
   ./deploy_template.sh /path/to/ExistingBlankApp --mode integrate --name "Existing Blank App"
   This creates /path/to/ExistingBlankApp/TemplateSources with all app sources.

2) Add sources to your project
   - Drag TemplateSources into your Xcode project (check “Copy items if needed”).
   - Either:
     - Use the provided @main App (AppTemplateApp) and remove your App file, or
     - Keep your App struct and integrate by providing the coordinator:
       @main
       struct YourApp: App {
           @StateObject private var coordinator = AppCoordinator(services: .shared)
           var body: some Scene {
               WindowGroup {
                   ContentView()
                       .environmentObject(coordinator)
               }
           }
       }

3) Add Swift Packages
   - Supabase and RevenueCat as above.

4) Provide configuration values
   - Add Config/DebugConfig.plist and Config/ReleaseConfig.plist as described in CONFIGURATION.md.

5) Enable Signing & capabilities
   - Set your Team and bundle identifier.

6) Run

Configuration overview

- Runtime configuration lives in app-template/Configuration.swift.
- Precedence:
  1) Environment variables: SUPABASE_URL, SUPABASE_ANON_KEY, REVENUECAT_API_KEY, REVENUECAT_ENTITLEMENT_ID, TERMS_URL, PRIVACY_URL
  2) Config/DebugConfig.plist or Config/ReleaseConfig.plist (depending on build)
- Configuration.validateConfiguration() surfaces human-friendly errors in-app if something is missing or invalid.
- See CONFIGURATION.md for examples.

Backend setup (optional)

If you want to run a local Supabase backend or apply the sample schema:

1) Install Supabase CLI
   npm install -g supabase
   supabase login

2) Initialize or navigate to your Supabase project directory
   supabase init

3) Run the setup script from the repo root
   ./setup_supabase.sh
   Options:
   - Local development (starts containers and resets DB with supabase_migrations.sql)
   - Remote project (push migrations)
   - Just show migration commands (for manual application)

Notes:
- The script includes example function deploy calls (get-onboarding-screens, get-survey-questions). If your repo doesn’t include these function sources under supabase/functions, choose “Just show migration commands” or comment out those deploy lines. The app falls back to mock onboarding data.

What’s included

- MVVM-C architecture with AppCoordinator and ServiceLocator
- Apple Sign-In via AuthenticationServices and Supabase Auth
- Supabase integration with DTO models and async services
- RevenueCat subscriptions with a lightweight paywall flow
- Centralized error handling with OSLog and a global banner
- Core tabs: Home, Library, Special, Profile
- Scripts:
  - deploy_template.sh: safe deployment in project or integrate mode
  - build_release.sh: archive build with auto-detected project/scheme

Common gotchas

- Missing Config plists: Create Config/DebugConfig.plist and Config/ReleaseConfig.plist with the required keys.
- Missing packages: Add Supabase and RevenueCat via File → Add Packages….
- Signing: Set your Team and bundle ID in Xcode before running on device.
- Supabase functions: Optional; onboarding will use fallback mock data if functions are not deployed.

Useful scripts

- New project: ./deploy_template.sh /path/to/MyNewApp --mode project
- Integrate sources: ./deploy_template.sh /path/to/ExistingBlankApp --mode integrate
- Build release archive: ./build_release.sh

License

MIT